///|
/// Input metadata. Tensor construction and access perform deep copies.
/// Empty per-axis lists mean absent; nonempty lists must cover every axis.
pub(all) struct Metadata {
  content : String?
  labels : Array[String]
  units : Array[String]
  kinds : Array[String]
  spacings : Array[Double]
  space : String?
  space_dimension : Int32?
  origin : Array[Double]?
  directions : Array[Array[Double]?]
  custom : Map[String, String]
} derive(Debug, Eq)

///|
pub fn Metadata::empty() -> Metadata {
  {
    content: None,
    labels: [],
    units: [],
    kinds: [],
    spacings: [],
    space: None,
    space_dimension: None,
    origin: None,
    directions: [],
    custom: {},
  }
}

///|
fn Metadata::copy_owned(self : Metadata) -> Metadata {
  {
    content: self.content,
    labels: self.labels.copy(),
    units: self.units.copy(),
    kinds: self.kinds.copy(),
    spacings: self.spacings.copy(),
    space: self.space,
    space_dimension: self.space_dimension,
    origin: self.origin.map(fn(v) { v.copy() }),
    directions: self.directions.map(fn(v) { v.map(fn(x) { x.copy() }) }),
    custom: self.custom.copy(),
  }
}

///|
fn clean_text(text : String) -> Bool {
  for c in text.iter() {
    if c.to_int() < 32 || c.to_int() == 127 {
      return false
    }
  }
  true
}

///|
fn finite(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf()
}

///|
fn space_size(space : String) -> Int32 raise NrrdError {
  match space.to_lower() {
    "right-anterior-superior"
    | "ras"
    | "left-anterior-superior"
    | "las"
    | "left-posterior-superior"
    | "lps"
    | "scanner-xyz"
    | "3d-right-handed"
    | "3d-left-handed" => 3
    "right-anterior-superior-time"
    | "rast"
    | "left-anterior-superior-time"
    | "last"
    | "left-posterior-superior-time"
    | "lpst"
    | "scanner-xyz-time"
    | "3d-right-handed-time"
    | "3d-left-handed-time" => 4
    _ => raise Unsupported("space: " + space)
  }
}

///|
fn Metadata::spatial_dimension(self : Metadata) -> Int32? raise NrrdError {
  match (self.space, self.space_dimension) {
    (Some(_), Some(_)) =>
      raise Invalid("space and space dimension are mutually exclusive")
    (Some(s), None) => Some(space_size(s))
    (None, d) => d
  }
}

///|
fn Metadata::validate(self : Metadata, shape : Shape) -> Unit raise NrrdError {
  let dim = shape.dimension()
  for
    length in [
      self.labels.length(),
      self.units.length(),
      self.kinds.length(),
      self.spacings.length(),
      self.directions.length(),
    ] {
    if length != 0 && length != dim {
      raise Invalid("metadata axis count")
    }
  }
  if self.content is Some(s) {
    if !clean_text(s) {
      raise Invalid("content contains controls")
    }
  }
  for text in self.labels + self.units {
    if !clean_text(text) {
      raise Invalid("axis text contains controls")
    }
  }
  for kind in self.kinds {
    let known = match kind {
      "domain"
      | "space"
      | "time"
      | "list"
      | "point"
      | "vector"
      | "covariant-vector"
      | "normal"
      | "stub"
      | "scalar"
      | "complex"
      | "2-vector"
      | "3-color"
      | "RGB-color"
      | "HSV-color"
      | "XYZ-color"
      | "4-color"
      | "RGBA-color"
      | "3-vector"
      | "3-gradient"
      | "3-normal"
      | "4-vector"
      | "quaternion"
      | "2D-symmetric-matrix"
      | "2D-masked-symmetric-matrix"
      | "2D-matrix"
      | "2D-masked-matrix"
      | "3D-symmetric-matrix"
      | "3D-masked-symmetric-matrix"
      | "3D-matrix"
      | "3D-masked-matrix"
      | "???"
      | "none" => true
      _ => false
    }
    if !known {
      raise Unsupported("axis kind: " + kind)
    }
  }
  for spacing in self.spacings {
    if !spacing.is_nan() && (!finite(spacing) || spacing <= 0.0) {
      raise Invalid("spacing must be positive or NaN")
    }
  }
  let sd = self.spatial_dimension()
  if sd is Some(d) {
    if d < 1 || d > 8 {
      raise Invalid("space dimension must be 1..8")
    }
  }
  if (self.origin != None || !self.directions.is_empty()) && sd == None {
    raise Invalid("spatial vectors require space or space dimension")
  }
  let vectors : Array[Array[Double]] = []
  if self.origin is Some(v) {
    vectors.push(v)
  }
  for v in self.directions {
    if v is Some(a) {
      vectors.push(a)
    }
  }
  for v in vectors {
    if Some(v.length()) != sd {
      raise Invalid("spatial vector dimension")
    }
    for x in v {
      if !finite(x) {
        raise Invalid("non-finite spatial vector")
      }
    }
  }
  if !self.directions.is_empty() && !self.spacings.is_empty() {
    raise Invalid("spacings and space directions cannot coexist")
  }
  for key, value in self.custom {
    if key.is_empty() ||
      !clean_text(key) ||
      key.contains(":=") ||
      !clean_text(value) {
      raise Invalid("custom key/value cannot be safely serialized")
    }
  }
}
