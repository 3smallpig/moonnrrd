///|
test "permutation and flip preserve sample/world correspondence" {
  let t = spatial_fixture()
  let p = t.permute([2, 0, 1])
  assert_eq(p.get([1, 1, 2]), t.get([1, 2, 1]))
  assert_eq(p.world([1.0, 1.0, 2.0]), t.world([1.0, 2.0, 1.0]))
  assert_eq(p.permute([1, 2, 0]).values(), t.values())
  let f = t.flip(1)
  assert_eq(f.get([1, 0, 1]), t.get([1, 2, 1]))
  assert_eq(f.world([1.0, 0.0, 1.0]), t.world([1.0, 2.0, 1.0]))
  assert_eq(f.flip(1).metadata(), t.metadata())
}
