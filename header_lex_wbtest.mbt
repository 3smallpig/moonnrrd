///|
test "header boundary, CRLF and custom field syntax" {
  let (fields, custom, end) = scan_header(
    b"NRRD0005\r\ntype: uint8\r\nx:= y:z\r\n\r\n\xFF",
    Limits::default(),
  )
  assert_eq(fields.get("type"), Some("uint8"))
  assert_eq(custom.get("x"), Some(" y:z"))
  assert_eq(end, 34)
  assert_eq(quoted_strings("\"x axis\" \"a\\\"b\""), ["x axis", "a\"b"])
  assert_eq(direction_list("(1, 0,0) none"), [Some([1.0, 0.0, 0.0]), None])
}
