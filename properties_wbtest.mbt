///|
test "dimension 1 through 8 layout and transform algebra" {
  for dimension in 1..<=8 {
    let sizes = Array::make(dimension, 2)
    let count = 1 << dimension
    let t = Tensor::new(
      sizes,
      I16,
      Array::makei(count, fn(i) { i.to_double() }),
    )
    let order = Array::makei(dimension, fn(a) { dimension - 1 - a })
    assert_eq(t.permute(order).permute(order).values(), t.values())
    for axis in 0..<dimension {
      assert_eq(t.flip(axis).flip(axis).values(), t.values())
      let a_sizes = sizes.copy()
      a_sizes[axis] = 1
      let start = Array::make(dimension, 0)
      let a = t.crop(start, a_sizes)
      start[axis] = 1
      let b = t.crop(start, a_sizes)
      assert_eq(concatenate(a, b, axis).values(), t.values())
    }
  }
}

///|
test "returned nested metadata is isolated from future reads" {
  let t = spatial_fixture()
  let m = t.metadata()
  if m.origin is Some(v) {
    v[0] = 999.0
  }
  if m.directions[0] is Some(v) {
    v[0] = 999.0
  }
  m.labels[0] = "modified"
  assert_eq(t.world([1.0, 0.0, 0.0]), [12.0, 20.0, 30.0])
  assert_eq(t.metadata().labels[0], "x")
}
