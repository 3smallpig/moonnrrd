///|
fn main raise {
  let series = @nrrd.Tensor::new(
    [2, 3],
    @nrrd.F64,
    [1.0, 2.0, 3.0, 4.0, 5.0, 6.0],
    metadata={
      ..@nrrd.Metadata::empty(),
      labels: ["sensor", "time"],
      kinds: ["list", "time"],
    },
  )
  let early = series.crop([0, 0], [2, 1])
  let late = series.crop([0, 1], [2, 2])
  let joined = @nrrd.concatenate(early, late, 1)
  assert_eq(joined.values(), series.values())
  let mean = joined.reduce(1, @nrrd.Mean)
  assert_eq(mean.values(), [3.0, 4.0])
  assert_eq(series.slice(1, 2).values(), [5.0, 6.0])
  let histogram = series.histogram(1.0, 6.0, 5)
  assert_eq(histogram.counts, [1, 1, 1, 1, 2])
  let encoded = @nrrd.write_nrrd(mean, encoding=@nrrd.Ascii)
  assert_eq(@nrrd.read_nrrd(encoded.attached()).values(), [3.0, 4.0])
  println(
    "tensor: concatenate, slice, reduce, histogram and ASCII export verified",
  )
}
