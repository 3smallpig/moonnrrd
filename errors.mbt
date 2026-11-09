///|
/// Structured failures shared by codecs and tensor operations.
pub(all) suberror NrrdError {
  Invalid(String)
  Unsupported(String)
  Limit(String)
  Truncated(String)
} derive(Debug, Eq)

///|
/// Resource limits are per operation, before allocation or dimension products.
pub(all) struct Limits {
  max_header_bytes : Int32
  max_samples : Int32
  max_payload_bytes : Int32
} derive(Debug, Eq)

///|
pub fn Limits::default() -> Limits {
  {
    max_header_bytes: 65536,
    max_samples: 1000000,
    max_payload_bytes: 64000000,
  }
}

///|
fn Limits::validate(self : Limits) -> Unit raise NrrdError {
  if self.max_header_bytes < 8 ||
    self.max_samples < 1 ||
    self.max_payload_bytes < 1 {
    raise Invalid("positive budgets required (header >= 8)")
  }
}
