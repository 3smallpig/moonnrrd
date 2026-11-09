///|
test "ASCII numeric extremes and exact count" {
  assert_eq(decode_ascii(b"4294967295 0", U32, 2, Limits::default()), [
    4294967295.0, 0.0,
  ])
  let v = decode_ascii(b"nan -inf +inf -1.25e2", F64, 4, Limits::default())
  assert_true(v[0].is_nan())
  assert_true(v[1].is_neg_inf())
  assert_eq(v[3], -125.0)
  for bytes in [b"1 2 3", b"1", b"1 bad", b"1 2.5"] {
    assert_true(
      try {
        ignore(decode_ascii(bytes, U8, 2, Limits::default()))
        false
      } catch {
        _ => true
      },
    )
  }
}
