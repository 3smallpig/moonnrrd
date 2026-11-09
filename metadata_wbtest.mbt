///|
test "metadata checks spatial and axis dimensions" {
  let shape = Shape::new([2, 3, 2])
  let m = {
    ..Metadata::empty(),
    space: Some("RAS"),
    origin: Some([1.0, 2.0, 3.0]),
    directions: [Some([1.0, 0.0, 0.0]), Some([0.0, 1.0, 0.0]), None],
  }
  m.validate(shape)
  let bad = try {
    { ..m, directions: [None], }.validate(shape)
    false
  } catch {
    _ => true
  }
  assert_true(bad)
}
