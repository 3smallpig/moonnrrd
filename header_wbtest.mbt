///|
test "semantic header rejects unsupported branches and missing endian" {
  let good = b"NRRD0005\ntype: ushort\ndimension: 2\nsizes: 2 3\nencoding: raw\nendian: big\ndata file: a.raw\n\n"
  let h = parse_header(good)
  assert_eq(h.shape().sizes(), [2, 3])
  assert_eq(h.data_file(), Some("a.raw"))
  for
    bytes in [
      b"NRRD0005\ntype: float\ndimension: 1\nsizes: 2\nencoding: raw\n\n", b"NRRD0005\ntype: uint8\ndimension: 1\nsizes: 2\nencoding: gzip\n\n",
      b"NRRD0005\ntype: uint8\ndimension: 1\nsizes: 2\nencoding: raw\ndata file: ../x\n\n",
    ] {
    let bad = try {
      ignore(parse_header(bytes))
      false
    } catch {
      _ => true
    }
    assert_true(bad)
  }
}
