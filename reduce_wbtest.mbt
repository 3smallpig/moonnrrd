///|
test "reduction oracle and geometry boundary" {
  let t = spatial_fixture()
  let r = t.reduce(2, Mean)
  assert_eq(r.values(), [3.0, 4.0, 5.0, 6.0, 7.0, 8.0])
  assert_eq(r.world([1.0, 2.0]), [12.0, 14.0, 30.0])
  assert_eq(t.reduce(1, Sum).values(), [6.0, 9.0, 24.0, 27.0])
  assert_eq(t.reduce(1, Sum).metadata().origin, None)
  let n = Tensor::new([2, 2], F64, [0.0 / 0.0, 1.0, 1.0 / 0.0, 3.0]).reduce(
    1,
    Mean,
  )
  assert_true(n.values()[0].is_nan())
  assert_eq(n.values()[1], 2.0)
}
