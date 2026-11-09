///|
/// Affine evaluation in the header's declared space; non-spatial axes contribute zero.
pub fn Tensor::world(
  self : Tensor,
  index : Array[Double],
) -> Array[Double] raise NrrdError {
  if index.length() != self.shape.dimension() {
    raise Invalid("world index dimension")
  }
  let m = self.metadata
  let origin = match m.origin {
    Some(v) => v.copy()
    None => raise Invalid("world requires space origin")
  }
  if m.directions.is_empty() {
    raise Invalid("world requires space directions")
  }
  for axis, value in index {
    if !finite(value) {
      raise Invalid("non-finite world index")
    }
    if m.directions[axis] is Some(direction) {
      for component, step in direction {
        origin[component] = origin[component] + value * step
      }
    }
  }
  for x in origin {
    if !finite(x) {
      raise Invalid("world coordinate overflow")
    }
  }
  origin
}

///|
fn shifted_metadata(
  m : Metadata,
  offsets : Array[Int32],
) -> Metadata raise NrrdError {
  if m.origin != None && m.directions.is_empty() {
    for count in offsets {
      if count != 0 {
        raise Unsupported("cannot shift origin without directions")
      }
    }
  }
  if m.origin is Some(origin) {
    if !m.directions.is_empty() {
      let shifted = origin.copy()
      for axis, count in offsets {
        if m.directions[axis] is Some(direction) {
          for component, step in direction {
            shifted[component] = shifted[component] + count.to_double() * step
          }
        }
      }
      for x in shifted {
        if !finite(x) {
          raise Invalid("origin overflow")
        }
      }
      return { ..m, origin: Some(shifted), }
    }
  }
  m
}

///|
fn remap_metadata(m : Metadata, axes : Array[Int32]) -> Metadata {
  {
    ..m,
    labels: if m.labels.is_empty() {
      []
    } else {
      axes.map(fn(a) { m.labels[a] })
    },
    units: if m.units.is_empty() {
      []
    } else {
      axes.map(fn(a) { m.units[a] })
    },
    kinds: if m.kinds.is_empty() {
      []
    } else {
      axes.map(fn(a) { m.kinds[a] })
    },
    spacings: if m.spacings.is_empty() {
      []
    } else {
      axes.map(fn(a) { m.spacings[a] })
    },
    directions: if m.directions.is_empty() {
      []
    } else {
      axes.map(fn(a) { m.directions[a] })
    },
  }
}
