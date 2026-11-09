///|
/// Immutable scalar raster. Values are canonical for the declared scalar type.
pub struct Tensor {
  shape : Shape
  scalar : Scalar
  data : Array[Double]
  metadata : Metadata
} derive(Debug)

///|
pub fn Tensor::new(
  sizes : Array[Int32],
  scalar : Scalar,
  values : Array[Double],
  metadata~ : Metadata = Metadata::empty(),
  limits~ : Limits = Limits::default(),
) -> Tensor raise NrrdError {
  let shape = Shape::new(sizes, limits~)
  ignore(shape.byte_count(scalar, limits))
  if values.length() != shape.count {
    raise Invalid("sample count does not match shape")
  }
  metadata.validate(shape)
  let data = values.map(v => scalar.canonical(v))
  { shape, scalar, data, metadata: metadata.copy_owned(), }
}

///|
pub fn Tensor::shape(self : Tensor) -> Shape {
  self.shape
}

///|
pub fn Tensor::scalar(self : Tensor) -> Scalar {
  self.scalar
}

///|
pub fn Tensor::values(self : Tensor) -> Array[Double] {
  self.data.copy()
}

///|
pub fn Tensor::metadata(self : Tensor) -> Metadata {
  self.metadata.copy_owned()
}

///|
pub fn Tensor::get(
  self : Tensor,
  index : Array[Int32],
) -> Double raise NrrdError {
  self.data[self.shape.offset(index)]
}

///|
/// Convert explicitly; integer fractions or out-of-range values fail atomically.
pub fn Tensor::cast(
  self : Tensor,
  scalar : Scalar,
  limits~ : Limits = Limits::default(),
) -> Tensor raise NrrdError {
  Tensor::new(
    self.shape.axes,
    scalar,
    self.data,
    metadata=self.metadata,
    limits~,
  )
}

///|
/// Replace metadata after the same checks as construction.
pub fn Tensor::with_metadata(
  self : Tensor,
  metadata : Metadata,
) -> Tensor raise NrrdError {
  metadata.validate(self.shape)
  { ..self, metadata: metadata.copy_owned(), }
}
