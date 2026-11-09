///|
fn read_bits(
  payload : Bytes,
  offset : Int32,
  width : Int32,
  endian : Endian,
) -> UInt64 {
  let mut bits = 0UL
  for i in 0..<width {
    let shift = if endian == Little { i * 8 } else { (width - 1 - i) * 8 }
    bits = bits | (payload[offset + i].to_uint64() << shift)
  }
  bits
}

///|
fn decode_raw(
  payload : Bytes,
  scalar : Scalar,
  count : Int32,
  endian : Endian,
  limits : Limits,
) -> Array[Double] raise NrrdError {
  let width = scalar.width()
  if count > limits.max_payload_bytes / width {
    raise Limit("binary payload budget")
  }
  let expected = count * width
  if payload.length() < expected {
    raise Truncated("raw payload")
  }
  if payload.length() > expected {
    raise Invalid("trailing raw payload")
  }
  let values = []
  for i in 0..<count {
    let bits = read_bits(payload, i * width, width, endian)
    let value = match scalar {
      U8 | U16 | U32 => bits.to_double()
      I8 => {
        let n = bits.to_int()
        (if n >= 128 { n - 256 } else { n }).to_double()
      }
      I16 => {
        let n = bits.to_int()
        (if n >= 32768 { n - 65536 } else { n }).to_double()
      }
      I32 => bits.to_uint().reinterpret_as_int().to_double()
      F32 => @float.Float::reinterpret_from_uint(bits.to_uint()).to_double()
      F64 => bits.reinterpret_as_double()
    }
    values.push(value)
  }
  values
}

///|
fn encode_raw(
  data : Array[Double],
  scalar : Scalar,
  endian : Endian,
  limits : Limits,
) -> Bytes raise NrrdError {
  let width = scalar.width()
  if data.length() > limits.max_payload_bytes / width {
    raise Limit("binary output budget")
  }
  let result = FixedArray::make(data.length() * width, b'\x00')
  for i, value in data {
    let bits = match scalar {
      F64 => value.reinterpret_as_uint64()
      F32 => @float.Float::from_double(value).reinterpret_as_uint().to_uint64()
      I8 | I16 | I32 => value.to_int64().reinterpret_as_uint64()
      U8 | U16 | U32 => value.to_uint64()
    }
    for j in 0..<width {
      let shift = if endian == Little { j * 8 } else { (width - 1 - j) * 8 }
      result[i * width + j] = ((bits >> shift) & 255UL).to_byte()
    }
  }
  Bytes::from_fixedarray(result)
}
