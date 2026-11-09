///|
test "statistics segregate nonfinite samples and include range endpoints" {
  let t = Tensor::new([8], F64, [
    -1.0,
    0.0,
    1.0,
    2.0,
    3.0,
    0.0 / 0.0,
    1.0 / 0.0,
    -1.0 / 0.0,
  ])
  let s = t.summary()
  assert_eq(s.finite_count, 5)
  assert_eq(s.nan_count, 1)
  assert_eq(s.mean, Some(1.0))
  let h = t.histogram(0.0, 2.0, 2)
  assert_eq(h.counts, [1, 2])
  assert_eq(h.below, 1)
  assert_eq(h.above, 1)
  assert_eq(h.non_finite, 3)
}
