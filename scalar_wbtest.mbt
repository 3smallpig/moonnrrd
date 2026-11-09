///|
test "scalar aliases, widths, and exact representability" {
  assert_eq(parse_scalar("unsigned short"), U16)
  assert_eq(F64.width(), 8)
  assert_eq(U32.canonical(4294967295.0), 4294967295.0)
  assert_eq(F32.canonical(16777217.0), 16777216.0)
  let bad = try {
    ignore(I8.canonical(128.0))
    false
  } catch {
    _ => true
  }
  assert_true(bad)
}
