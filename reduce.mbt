///|
pub(all) enum Reduction {
  Sum
  Mean
  Minimum
  Maximum
} derive(Debug, Eq)

///|
/// Ignore nonfinite inputs; all-nonfinite groups produce NaN, output is F64.
/// Reducing a spatial axis removes geometry because the aggregate has no unique location.
pub fn Tensor::reduce(
  self : Tensor,
  axis : Int32,
  operation : Reduction,
  limits~ : Limits = Limits::default(),
) -> Tensor raise NrrdError {
  check_axis(self.shape, axis)
  if self.shape.dimension() == 1 {
    raise Unsupported("zero-dimensional reduction")
  }
  let axes = []
  for a in 0..<self.shape.dimension() {
    if a != axis {
      axes.push(a)
    }
  }
  let shape = Shape::new(axes.map(fn(a) { self.shape.axes[a] }), limits~)
  ignore(shape.byte_count(F64, limits))
  let values = Array::make(shape.count, 0.0)
  for offset in 0..<shape.count {
    let output_index = shape.indices(offset)
    let input_index = Array::make(self.shape.dimension(), 0)
    for i, a in axes {
      input_index[a] = output_index[i]
    }
    let mut aggregate = 0.0
    let mut count = 0
    let mut compensation = 0.0
    for position in 0..<self.shape.axes[axis] {
      input_index[axis] = position
      let value = self.data[self.shape.offset(input_index)]
      if !finite(value) {
        continue
      }
      count = count + 1
      match operation {
        Sum => {
          let adjusted = value - compensation
          let next = aggregate + adjusted
          compensation = next - aggregate - adjusted
          aggregate = next
          if !finite(aggregate) {
            raise Invalid("reduction sum overflow")
          }
        }
        Mean => {
          let n = count.to_double()
          aggregate = aggregate * ((n - 1.0) / n) + value / n
        }
        Minimum =>
          aggregate = if count == 1 { value } else { aggregate.min(value) }
        Maximum =>
          aggregate = if count == 1 { value } else { aggregate.max(value) }
      }
    }
    values[offset] = if count == 0 { 0.0 / 0.0 } else { aggregate }
  }
  let m = self.metadata
  let remapped = remap_metadata(m, axes)
  let metadata = if !m.directions.is_empty() && m.directions[axis] != None {
    {
      ..remapped,
      space: None,
      space_dimension: None,
      origin: None,
      directions: [],
    }
  } else {
    remapped
  }
  Tensor::new(shape.axes, F64, values, metadata~, limits~)
}
