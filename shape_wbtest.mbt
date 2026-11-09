///|
test "NRRD axis zero fastest indexing and ownership" {
  let sizes = [2, 3, 4]
  let shape = Shape::new(sizes)
  sizes[0] = 99
  assert_eq(shape.sample_count(), 24)
  assert_eq(shape.offset([1, 2, 3]), 23)
  for i in 0..<24 {
    assert_eq(shape.offset(shape.indices(i)), i)
  }
  let bad = try {
    ignore(Shape::new([1000000, 1000000]))
    false
  } catch {
    _ => true
  }
  assert_true(bad)
}
