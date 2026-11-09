///|
/// Separate buffers; attached() combines them only for an attached plan.
pub(all) struct Encoded {
  header : Bytes
  payload : Bytes
  data_file : String?
} derive(Debug, Eq)

///|
pub fn Encoded::attached(self : Encoded) -> Bytes raise NrrdError {
  if self.data_file != None {
    raise Invalid("detached output has separate header/payload")
  }
  self.header + self.payload
}

///|
fn quote(text : String) -> String {
  let s = StringBuilder()
  s.write_char('"')
  for c in text.iter() {
    if c == '"' || c == '\\' {
      s.write_char('\\')
    }
    s.write_char(c)
  }
  s.write_char('"')
  s.to_string()
}

///|
fn vector_text(v : Array[Double]) -> String {
  "(" + v.map(fn(x) { x.to_string() }).join(",") + ")"
}

///|
fn header_bytes(
  tensor : Tensor,
  encoding : Encoding,
  endian : Endian,
  data_file : String?,
  limits : Limits,
) -> Bytes raise NrrdError {
  if data_file is Some(name) {
    detached_name(name)
  }
  let m = tensor.metadata
  let lines = [
    "NRRD0005",
    "# MoonNRRD 0.1.0",
    "type: " + tensor.scalar.name(),
    "dimension: " + tensor.shape.dimension().to_string(),
    "sizes: " + tensor.shape.axes.map(fn(n) { n.to_string() }).join(" "),
    "encoding: " +
    (match encoding {
      Raw => "raw"
      Ascii => "ascii"
      Hex => "hex"
    }),
  ]
  if encoding != Ascii && tensor.scalar.width() > 1 {
    lines.push(
      "endian: " +
      (match endian {
        Little => "little"
        Big => "big"
      }),
    )
  }
  if m.content is Some(v) {
    lines.push("content: " + v)
  }
  if !m.labels.is_empty() {
    lines.push("labels: " + m.labels.map(quote).join(" "))
  }
  if !m.units.is_empty() {
    lines.push("units: " + m.units.map(quote).join(" "))
  }
  if !m.kinds.is_empty() {
    lines.push("kinds: " + m.kinds.join(" "))
  }
  if !m.spacings.is_empty() {
    lines.push(
      "spacings: " + m.spacings.map(fn(v) { numeric_text(v, F64) }).join(" "),
    )
  }
  if m.space is Some(v) {
    lines.push("space: " + v)
  }
  if m.space_dimension is Some(v) {
    lines.push("space dimension: " + v.to_string())
  }
  if m.origin is Some(v) {
    lines.push("space origin: " + vector_text(v))
  }
  if !m.directions.is_empty() {
    lines.push(
      "space directions: " +
      m.directions
      .map(fn(v) {
        match v {
          Some(a) => vector_text(a)
          None => "none"
        }
      })
      .join(" "),
    )
  }
  // Deterministic ordering makes archives reproducible across hash implementations.
  let keys : Array[String] = m.custom.keys().collect()
  keys.sort()
  for key in keys {
    lines.push(key + ":=" + m.custom[key])
  }
  if data_file is Some(v) {
    lines.push("data file: " + v)
  }
  let mut size = 1
  for line in lines {
    if line.length() + 1 > limits.max_header_bytes - size {
      raise Limit("serialized header budget")
    }
    size = size + line.length() + 1
  }
  @utf8.encode((lines.join("\n") + "\n\n")[:])
}

///|
pub fn write_nrrd(
  tensor : Tensor,
  encoding~ : Encoding = Raw,
  endian~ : Endian = Little,
  data_file? : String,
  limits~ : Limits = Limits::default(),
) -> Encoded raise NrrdError {
  limits.validate()
  ignore(Shape::new(tensor.shape.axes, limits~))
  ignore(tensor.shape.byte_count(tensor.scalar, limits))
  let header = header_bytes(tensor, encoding, endian, data_file, limits)
  let payload = match encoding {
    Raw => encode_raw(tensor.data, tensor.scalar, endian, limits)
    Ascii => encode_ascii(tensor.data, tensor.scalar, limits)
    Hex =>
      encode_hex(encode_raw(tensor.data, tensor.scalar, endian, limits), limits)
  }
  { header, payload, data_file, }
}
