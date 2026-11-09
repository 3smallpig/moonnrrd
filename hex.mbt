///|
fn hex_digit(byte : Byte) -> Int32 raise NrrdError {
  let n = byte.to_int()
  if n >= 48 && n <= 57 {
    return n - 48
  }
  if n >= 65 && n <= 70 {
    return n - 55
  }
  if n >= 97 && n <= 102 {
    return n - 87
  }
  raise Invalid("invalid hexadecimal digit")
}

///|
fn decode_hex(
  payload : Bytes,
  expected : Int32,
  limits : Limits,
) -> Bytes raise NrrdError {
  if payload.length() > limits.max_payload_bytes {
    raise Limit("hex encoded payload budget")
  }
  let result = FixedArray::make(expected, b'\x00')
  let mut high : Int32? = None
  let mut used = 0
  for b in payload {
    if b == b' ' || b == b'\t' || b == b'\n' || b == b'\r' {
      continue
    }
    let d = hex_digit(b)
    match high {
      None => high = Some(d)
      Some(h) => {
        if used >= expected {
          raise Invalid("extra hex bytes")
        }
        result[used] = (h * 16 + d).to_byte()
        used = used + 1
        high = None
      }
    }
  }
  if high != None {
    raise Invalid("odd hex digit count")
  }
  if used != expected {
    raise Truncated("hex payload")
  }
  Bytes::from_array(result[:])
}

///|
fn encode_hex(raw : Bytes, limits : Limits) -> Bytes raise NrrdError {
  if raw.length() > limits.max_payload_bytes / 2 {
    raise Limit("hex output budget")
  }
  let alphabet = b"0123456789abcdef"
  Bytes::makei(raw.length() * 2, fn(i) {
    let byte = raw[i / 2].to_int()
    alphabet[if i % 2 == 0 { byte >> 4 } else { byte & 15 }]
  })
}
