///|
/// Validated header plan; payload is never opened implicitly.
pub struct Header {
  shape : Shape
  scalar : Scalar
  encoding : Encoding
  endian : Endian
  metadata : Metadata
  data_file : String?
  payload_offset : Int32
} derive(Debug)

///|
pub fn Header::shape(self : Header) -> Shape {
  self.shape
}

///|
pub fn Header::scalar(self : Header) -> Scalar {
  self.scalar
}

///|
pub fn Header::encoding(self : Header) -> Encoding {
  self.encoding
}

///|
pub fn Header::endian(self : Header) -> Endian {
  self.endian
}

///|
pub fn Header::metadata(self : Header) -> Metadata {
  self.metadata.copy_owned()
}

///|
pub fn Header::data_file(self : Header) -> String? {
  self.data_file
}

///|
pub fn Header::payload_offset(self : Header) -> Int32 {
  self.payload_offset
}

///|
fn required(
  fields : Map[String, String],
  key : String,
) -> String raise NrrdError {
  match fields.get(key) {
    Some(s) => s
    None => raise Invalid("required header field: " + key)
  }
}

///|
fn detached_name(name : String) -> Unit raise NrrdError {
  if name.is_empty() || name == "." || name == ".." || name.to_upper() == "LIST" {
    raise Invalid("empty or relative data filename")
  }
  for c in name.iter() {
    let n = c.to_int()
    if !((n >= 48 && n <= 57) ||
      (n >= 65 && n <= 90) ||
      (n >= 97 && n <= 122) ||
      c == '_' ||
      c == '-' ||
      c == '.') {
      raise Unsupported("data file must be a single safe basename")
    }
  }
}

///|
pub fn parse_header(
  bytes : Bytes,
  limits~ : Limits = Limits::default(),
) -> Header raise NrrdError {
  let (fields, custom, payload_offset) = scan_header(bytes, limits)
  for key, _ in fields {
    match key {
      "type"
      | "dimension"
      | "sizes"
      | "encoding"
      | "endian"
      | "content"
      | "labels"
      | "units"
      | "kinds"
      | "spacings"
      | "space"
      | "space dimension"
      | "space origin"
      | "space directions"
      | "data file"
      | "line skip"
      | "byte skip" => ()
      _ => raise Unsupported("header field: " + key)
    }
  }
  let scalar = parse_scalar(required(fields, "type"))
  let dimension = integer(required(fields, "dimension"))
  let sizes = words(required(fields, "sizes")).map(s => integer(s))
  let shape = Shape::new(sizes, limits~)
  if dimension != shape.dimension() {
    raise Invalid("dimension/sizes mismatch")
  }
  ignore(shape.byte_count(scalar, limits))
  let encoding = parse_encoding(required(fields, "encoding"))
  let endian = match fields.get("endian") {
    Some("little") => Little
    Some("big") => Big
    Some(_) => raise Invalid("endian must be little or big")
    None => {
      if encoding != Ascii && scalar.width() > 1 {
        raise Invalid("multi-byte binary data requires endian")
      }
      Little
    }
  }
  for key in ["line skip", "byte skip"] {
    if fields.get(key) is Some(value) {
      if integer(value) != 0 {
        raise Unsupported("nonzero " + key)
      }
    }
  }
  let data_file = fields.get("data file")
  if data_file is Some(name) {
    detached_name(name)
  }
  let labels = match fields.get("labels") {
    Some(s) => quoted_strings(s)
    None => []
  }
  let units = match fields.get("units") {
    Some(s) => quoted_strings(s)
    None => []
  }
  let kinds = match fields.get("kinds") {
    Some(s) => words(s)
    None => []
  }
  let spacings = match fields.get("spacings") {
    Some(s) => words(s).map(v => number(v))
    None => []
  }
  let space_dimension = match fields.get("space dimension") {
    Some(s) => Some(integer(s))
    None => None
  }
  let origin = match fields.get("space origin") {
    Some(s) => Some(vector(s))
    None => None
  }
  let directions = match fields.get("space directions") {
    Some(s) => direction_list(s)
    None => []
  }
  let metadata : Metadata = {
    content: fields.get("content"),
    labels,
    units,
    kinds,
    spacings,
    space: fields.get("space"),
    space_dimension,
    origin,
    directions,
    custom,
  }
  metadata.validate(shape)
  { shape, scalar, encoding, endian, metadata, data_file, payload_offset, }
}
