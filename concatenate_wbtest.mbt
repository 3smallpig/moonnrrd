///|
test "concatenation restores split grids and rejects wrong origin" {
  let t = spatial_fixture()
  let a = t.crop([0, 0, 0], [2, 1, 2])
  let b = t.crop([0, 1, 0], [2, 2, 2])
  let joined = concatenate(a, b, 1)
  assert_eq(joined.values(), t.values())
  assert_eq(joined.metadata(), t.metadata())
  assert_true(
    try {
      ignore(concatenate(a, a, 1))
      false
    } catch {
      _ => true
    },
  )
}
