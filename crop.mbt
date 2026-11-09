///|
pub fn Tensor::crop(
  self : Tensor,
  start : Array[Int32],
  sizes : Array[Int32],
  limits~ : Limits = Limits::default(),
) -> Tensor raise NrrdError {
  if start.length() != self.shape.dimension() ||
    sizes.length() != self.shape.dimension() {
    raise Invalid("crop dimension")
  }
  let shape = Shape::new(sizes, limits~)
  for axis, first in start {
    if first < 0 ||
      first >= self.shape.axes[axis] ||
      sizes[axis] > self.shape.axes[axis] - first {
      raise Invalid("crop outside raster")
    }
  }
  let values = Array::make(shape.count, 0.0)
  for i in 0..<shape.count {
    let index = shape.indices(i)
    for a in 0..<index.length() {
      index[a] = index[a] + start[a]
    }
    values[i] = self.data[self.shape.offset(index)]
  }
  Tensor::new(
    sizes,
    self.scalar,
    values,
    metadata=shifted_metadata(self.metadata, start),
    limits~,
  )
}

///|
/// Remove a fixed axis. One-dimensional rasters cannot become scalar NRRD.
pub fn Tensor::slice(
  self : Tensor,
  axis : Int32,
  position : Int32,
  limits~ : Limits = Limits::default(),
) -> Tensor raise NrrdError {
  check_axis(self.shape, axis)
  if self.shape.dimension() == 1 {
    raise Unsupported("zero-dimensional output")
  }
  if position < 0 || position >= self.shape.axes[axis] {
    raise Invalid("slice position")
  }
  let axes = []
  for a in 0..<self.shape.dimension() {
    if a != axis {
      axes.push(a)
    }
  }
  let shape = Shape::new(axes.map(fn(a) { self.shape.axes[a] }), limits~)
  let values = Array::make(shape.count, 0.0)
  for i in 0..<shape.count {
    let output_index = shape.indices(i)
    let input_index = Array::make(self.shape.dimension(), position)
    for j, a in axes {
      input_index[a] = output_index[j]
    }
    values[i] = self.data[self.shape.offset(input_index)]
  }
  let offsets = Array::make(self.shape.dimension(), 0)
  offsets[axis] = position
  let metadata = remap_metadata(shifted_metadata(self.metadata, offsets), axes)
  Tensor::new(shape.axes, self.scalar, values, metadata~, limits~)
}
