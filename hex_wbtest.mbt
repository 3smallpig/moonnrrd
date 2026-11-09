///|
test "hex oracle and malformed tokens" {
  assert_eq(decode_hex(b"00 A1\nff", 3, Limits::default()), b"\x00\xA1\xFF")
  assert_eq(encode_hex(b"\x01\xAB", Limits::default()), b"01ab")
  for b in [b"0", b"gg", b"0001", b""] {
    assert_true(
      try {
        ignore(decode_hex(b, 1, Limits::default()))
        false
      } catch {
        _ => true
      },
    )
  }
}
