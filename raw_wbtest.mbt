///|
test "binary oracle bytes including signed boundaries and endian" {
  assert_eq(decode_raw(b"\x80\xFF\x00\x7F", I8, 4, Big, Limits::default()), [
    -128.0, -1.0, 0.0, 127.0,
  ])
  assert_eq(
    encode_raw([-32768.0, 32767.0], I16, Big, Limits::default()),
    b"\x80\x00\x7F\xFF",
  )
  assert_eq(
    decode_raw(b"\x00\x00\x80\x3F", F32, 1, Little, Limits::default()),
    [1.0],
  )
  assert_eq(decode_raw(b"\xFF\xFF\xFF\xFF", U32, 1, Big, Limits::default()), [
    4294967295.0,
  ])
  for scalar in [I8, U8, I16, U16, I32, U32, F32, F64] {
    for endian in [Little, Big] {
      let values = [0.0, 1.0, 42.0]
      assert_eq(
        decode_raw(
          encode_raw(values, scalar, endian, Limits::default()),
          scalar,
          3,
          endian,
          Limits::default(),
        ),
        values,
      )
    }
  }
}
