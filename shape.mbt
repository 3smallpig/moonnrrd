///|
/// Immutable, owned row-major-in-NRRD-order shape (axis zero is fastest).
pub struct Shape {
  axes : Array[Int32]
  strides : Array[Int32]
  count : Int32
} derive(Debug, Eq)

///|
pub fn Shape::new(
  sizes : Array[Int32],
  limits~ : Limits = Limits::default(),
) -> Shape raise NrrdError {
  limits.validate()
  if sizes.length() < 1 || sizes.length() > 8 {
    raise Invalid("dimension must be 1..8")
  }
  let axes = sizes.copy()
  let strides = []
  let mut count = 1
  for size in axes {
    if size <= 0 {
      raise Invalid("axis size must be positive")
    }
    if size > limits.max_samples / count {
      raise Limit("sample budget")
    }
    strides.push(count)
    count = count * size
  }
  { axes, strides, count, }
}

///|
pub fn Shape::sizes(self : Shape) -> Array[Int32] {
  self.axes.copy()
}

///|
pub fn Shape::dimension(self : Shape) -> Int32 {
  self.axes.length()
}

///|
pub fn Shape::sample_count(self : Shape) -> Int32 {
  self.count
}

///|
pub fn Shape::offset(
  self : Shape,
  index : Array[Int32],
) -> Int32 raise NrrdError {
  if index.length() != self.dimension() {
    raise Invalid("index dimension")
  }
  let mut offset = 0
  for axis, value in index {
    if value < 0 || value >= self.axes[axis] {
      raise Invalid("index out of bounds")
    }
    offset = offset + value * self.strides[axis]
  }
  offset
}

///|
pub fn Shape::indices(
  self : Shape,
  offset : Int32,
) -> Array[Int32] raise NrrdError {
  if offset < 0 || offset >= self.count {
    raise Invalid("offset out of bounds")
  }
  self.axes.mapi(fn(axis, size) { offset / self.strides[axis] % size })
}

///|
fn Shape::byte_count(
  self : Shape,
  scalar : Scalar,
  limits : Limits,
) -> Int32 raise NrrdError {
  if self.count > limits.max_payload_bytes / scalar.width() {
    raise Limit("payload budget")
  }
  self.count * scalar.width()
}

///|
fn check_axis(shape : Shape, axis : Int32) -> Unit raise NrrdError {
  if axis < 0 || axis >= shape.dimension() {
    raise Invalid("axis out of bounds")
  }
}
