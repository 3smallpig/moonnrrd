///|
test "crop and slice shift origin with sample correspondence" {
  let t = spatial_fixture()
  let c = t.crop([1, 1, 0], [1, 2, 2])
  assert_eq(c.values(), [3.0, 5.0, 9.0, 11.0])
  assert_eq(c.world([0.0, 1.0, 1.0]), t.world([1.0, 2.0, 1.0]))
  let s = t.slice(1, 2)
  assert_eq(s.values(), [4.0, 5.0, 10.0, 11.0])
  assert_eq(s.world([1.0, 1.0]), t.world([1.0, 2.0, 1.0]))
  assert_true(
    try {
      ignore(t.crop([1, 1, 0], [2, 2, 2]))
      false
    } catch {
      _ => true
    },
  )
}
