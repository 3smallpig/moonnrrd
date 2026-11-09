///|
/// Only finite samples participate in numeric aggregates.
pub(all) struct Summary {
  finite_count : Int32
  nan_count : Int32
  positive_infinity_count : Int32
  negative_infinity_count : Int32
  minimum : Double?
  maximum : Double?
  mean : Double?
} derive(Debug, Eq)

///|
pub fn Tensor::summary(self : Tensor) -> Summary {
  let mut finite_count = 0
  let mut nan_count = 0
  let mut positive_infinity_count = 0
  let mut negative_infinity_count = 0
  let mut minimum : Double? = None
  let mut maximum : Double? = None
  let mut mean = 0.0
  for value in self.data {
    if value.is_nan() {
      nan_count = nan_count + 1
    } else if value.is_pos_inf() {
      positive_infinity_count = positive_infinity_count + 1
    } else if value.is_neg_inf() {
      negative_infinity_count = negative_infinity_count + 1
    } else {
      finite_count = finite_count + 1
      // Weighted terms avoid overflow of an intermediate running sum.
      let n = finite_count.to_double()
      mean = mean * ((n - 1.0) / n) + value / n
      minimum = Some(
        match minimum {
          None => value
          Some(v) => v.min(value)
        },
      )
      maximum = Some(
        match maximum {
          None => value
          Some(v) => v.max(value)
        },
      )
    }
  }
  {
    finite_count,
    nan_count,
    positive_infinity_count,
    negative_infinity_count,
    minimum,
    maximum,
    mean: if finite_count == 0 {
      None
    } else {
      Some(mean)
    },
  }
}

///|
pub(all) struct Histogram {
  counts : Array[Int32]
  below : Int32
  above : Int32
  non_finite : Int32
} derive(Debug, Eq)

///|
/// Equal-width bins over [lower, upper], with the upper endpoint in the last bin.
pub fn Tensor::histogram(
  self : Tensor,
  lower : Double,
  upper : Double,
  bins : Int32,
) -> Histogram raise NrrdError {
  if !finite(lower) ||
    !finite(upper) ||
    lower >= upper ||
    !finite(upper - lower) {
    raise Invalid("histogram finite increasing range")
  }
  if bins < 1 || bins > 65536 {
    raise Limit("histogram bins must be 1..65536")
  }
  let counts = Array::make(bins, 0)
  let mut below = 0
  let mut above = 0
  let mut non_finite = 0
  for value in self.data {
    if !finite(value) {
      non_finite = non_finite + 1
    } else if value < lower {
      below = below + 1
    } else if value > upper {
      above = above + 1
    } else {
      let bin = ((value - lower) / (upper - lower) * bins.to_double())
        .to_int()
        .min(bins - 1)
      counts[bin] = counts[bin] + 1
    }
  }
  { counts, below, above, non_finite, }
}
