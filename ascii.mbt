///|
fn decode_ascii(
  payload : Bytes,
  scalar : Scalar,
  count : Int32,
  limits : Limits,
) -> Array[Double] raise NrrdError {
  if payload.length() > limits.max_payload_bytes {
    raise Limit("ASCII payload budget")
  }
  let result = []
  let token = StringBuilder()
  for byte in payload {
    let n = byte.to_int()
    if n == 32 || n == 9 || n == 10 || n == 13 {
      if !token.is_empty() {
        if result.length() >= count {
          raise Invalid("extra ASCII samples")
        }
        result.push(scalar.canonical(number(token.to_string())))
        token.reset()
      }
    } else {
      if n < 33 || n > 126 {
        raise Invalid("non-ASCII payload token")
      }
      if token.to_string().length() >= 128 {
        raise Limit("numeric token length")
      }
      token.write_char(n.unsafe_to_char())
    }
  }
  if !token.is_empty() {
    if result.length() >= count {
      raise Invalid("extra ASCII samples")
    }
    result.push(scalar.canonical(number(token.to_string())))
  }
  if result.length() != count {
    raise Truncated("ASCII sample count")
  }
  result
}

///|
fn numeric_text(value : Double, scalar : Scalar) -> String {
  if value.is_nan() {
    return "nan"
  }
  if value.is_pos_inf() {
    return "inf"
  }
  if value.is_neg_inf() {
    return "-inf"
  }
  match scalar {
    F32 | F64 => value.to_string()
    _ => value.to_int64().to_string()
  }
}

///|
fn encode_ascii(
  data : Array[Double],
  scalar : Scalar,
  limits : Limits,
) -> Bytes raise NrrdError {
  let text = StringBuilder()
  let mut size = 0
  for value in data {
    let token = numeric_text(value, scalar)
    if token.length() + 1 > limits.max_payload_bytes - size {
      raise Limit("ASCII output budget")
    }
    text.write_string(token)
    text.write_char('\n')
    size = size + token.length() + 1
  }
  text.to_string().to_bytes()
}
