///|
/// axes[new_axis] = old_axis. Never transforms vector-valued components.
pub fn Tensor::permute(
  self : Tensor,
  axes : Array[Int32],
  limits~ : Limits = Limits::default(),
) -> Tensor raise NrrdError {
  if axes.length() != self.shape.dimension() {
    raise Invalid("permutation dimension")
  }
  let seen = Array::make(axes.length(), false)
  for axis in axes {
    check_axis(self.shape, axis)
    if seen[axis] {
      raise Invalid("duplicate permutation axis")
    }
    seen[axis] = true
  }
  let shape = Shape::new(axes.map(fn(a) { self.shape.axes[a] }), limits~)
  let values = Array::make(shape.count, 0.0)
  for i in 0..<shape.count {
    let new_index = shape.indices(i)
    let old_index = Array::make(axes.length(), 0)
    for new_axis, old_axis in axes {
      old_index[old_axis] = new_index[new_axis]
    }
    values[i] = self.data[self.shape.offset(old_index)]
  }
  Tensor::new(
    shape.axes,
    self.scalar,
    values,
    metadata=remap_metadata(self.metadata, axes),
    limits~,
  )
}

///|
/// Reverse samples and direction of one axis, with a matching origin shift.
pub fn Tensor::flip(
  self : Tensor,
  axis : Int32,
  limits~ : Limits = Limits::default(),
) -> Tensor raise NrrdError {
  check_axis(self.shape, axis)
  let offsets = Array::make(self.shape.dimension(), 0)
  offsets[axis] = self.shape.axes[axis] - 1
  let m = shifted_metadata(self.metadata, offsets)
  let directions = m.directions.copy()
  if !directions.is_empty() {
    if directions[axis] is Some(v) {
      directions[axis] = Some(v.map(fn(x) { -x }))
    }
  }
  let values = Array::make(self.shape.count, 0.0)
  for i in 0..<self.shape.count {
    let index = self.shape.indices(i)
    index[axis] = self.shape.axes[axis] - 1 - index[axis]
    values[i] = self.data[self.shape.offset(index)]
  }
  Tensor::new(
    self.shape.axes,
    self.scalar,
    values,
    metadata={ ..m, directions, },
    limits~,
  )
}
