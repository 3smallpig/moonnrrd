///|
fn spatial_fixture() -> Tensor raise NrrdError {
  Tensor::new([2, 3, 2], I16, Array::makei(12, fn(i) { i.to_double() }), metadata={
    ..Metadata::empty(),
    space: Some("RAS"),
    origin: Some([10.0, 20.0, 30.0]),
    directions: [Some([2.0, 0.0, 0.0]), Some([0.0, -3.0, 0.0]), None],
    labels: ["x", "y", "channel"],
  })
}

///|
test "world coordinates respect nonspatial axis and oblique units" {
  let t = spatial_fixture()
  assert_eq(t.world([1.0, 2.0, 1.0]), [12.0, 14.0, 30.0])
  assert_eq(t.world([0.5, 0.0, 999.0]), [11.0, 20.0, 30.0])
}
