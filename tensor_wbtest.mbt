///|
test "constructor owns data and nested metadata" {
  let values = [1.0, 2.0]
  let origin = [0.0, 1.0]
  let t = Tensor::new([2], U8, values, metadata={
    ..Metadata::empty(),
    space_dimension: Some(2),
    origin: Some(origin),
  })
  values[0] = 99.0
  origin[0] = 99.0
  let copy = t.values()
  copy[0] = 88.0
  assert_eq(t.get([0]), 1.0)
  assert_eq(t.metadata().origin, Some([0.0, 1.0]))
  assert_eq(t.cast(F64).scalar(), F64)
}
