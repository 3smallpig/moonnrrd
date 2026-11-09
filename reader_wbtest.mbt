///|
test "reader attached and detached ownership contract" {
  let header = b"NRRD0005\ntype: uint8\ndimension: 2\nsizes: 2 2\nencoding: raw\n\n"
  assert_eq(read_nrrd(header + b"\x01\x02\x03\x04").get([1, 1]), 4.0)
  let detached = b"NRRD0005\ntype: uint8\ndimension: 1\nsizes: 2\nencoding: raw\ndata file: x.raw\n\n"
  assert_eq(read_nrrd(detached, detached=b"\x05\x06").values(), [5.0, 6.0])
  assert_true(
    try {
      ignore(read_nrrd(detached))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(read_nrrd(header, detached=b"\x00"))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(read_nrrd(detached + b"x", detached=b"\x00\x00"))
      false
    } catch {
      _ => true
    },
  )
}
