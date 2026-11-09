///|
/// Parse attached or explicitly supplied detached data. No filesystem access.
pub fn read_nrrd(
  bytes : Bytes,
  detached? : Bytes,
  limits~ : Limits = Limits::default(),
) -> Tensor raise NrrdError {
  let h = parse_header(bytes, limits~)
  let payload = match (h.data_file, detached) {
    (None, None) => {
      if bytes.length() - h.payload_offset > limits.max_payload_bytes {
        raise Limit("encoded payload budget")
      }
      bytes[h.payload_offset:].to_owned()
    }
    (Some(_), Some(data)) => {
      if h.payload_offset != bytes.length() {
        raise Invalid("detached header has inline data")
      }
      if data.length() > limits.max_payload_bytes {
        raise Limit("detached payload budget")
      }
      data
    }
    (Some(_), None) =>
      raise Invalid("detached header requires explicit payload")
    (None, Some(_)) =>
      raise Invalid("attached header cannot accept detached payload")
  }
  let values = match h.encoding {
    Raw => decode_raw(payload, h.scalar, h.shape.count, h.endian, limits)
    Ascii => decode_ascii(payload, h.scalar, h.shape.count, limits)
    Hex => {
      let raw = decode_hex(
        payload,
        h.shape.byte_count(h.scalar, limits),
        limits,
      )
      decode_raw(raw, h.scalar, h.shape.count, h.endian, limits)
    }
  }
  Tensor::new(h.shape.axes, h.scalar, values, metadata=h.metadata, limits~)
}
