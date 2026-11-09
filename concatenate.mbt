///|
/// Concatenate compatible grids. Spatial joins require exact adjacent origins.
pub fn concatenate(
  left : Tensor,
  right : Tensor,
  axis : Int32,
  limits~ : Limits = Limits::default(),
) -> Tensor raise NrrdError {
  check_axis(left.shape, axis)
  if left.scalar != right.scalar ||
    left.shape.dimension() != right.shape.dimension() {
    raise Invalid("concatenation type/dimension")
  }
  let sizes = left.shape.sizes()
  for a in 0..<sizes.length() {
    if a != axis && sizes[a] != right.shape.axes[a] {
      raise Invalid("concatenation nonjoining size")
    }
  }
  if right.shape.axes[axis] > limits.max_samples - sizes[axis] {
    raise Limit("concatenation axis budget")
  }
  sizes[axis] = sizes[axis] + right.shape.axes[axis]
  let shape = Shape::new(sizes, limits~)
  ignore(shape.byte_count(left.scalar, limits))
  let lm = left.metadata
  let rm = right.metadata
  let offsets = Array::make(sizes.length(), 0)
  offsets[axis] = left.shape.axes[axis]
  let expected = shifted_metadata(lm, offsets)
  // Compare NaN spacings by meaning rather than IEEE equality.
  if lm.spacings.length() != rm.spacings.length() {
    raise Invalid("concatenation spacings")
  }
  for a, s in lm.spacings {
    let r = rm.spacings[a]
    if s != r && !(s.is_nan() && r.is_nan()) {
      raise Invalid("concatenation spacings")
    }
  }
  if { ..expected, spacings: [], } != { ..rm, spacings: [], } {
    raise Invalid("concatenation metadata/grid discontinuity")
  }
  let values = Array::make(shape.count, 0.0)
  for i in 0..<shape.count {
    let index = shape.indices(i)
    if index[axis] < left.shape.axes[axis] {
      values[i] = left.data[left.shape.offset(index)]
    } else {
      index[axis] = index[axis] - left.shape.axes[axis]
      values[i] = right.data[right.shape.offset(index)]
    }
  }
  Tensor::new(sizes, left.scalar, values, metadata=lm, limits~)
}
