///|
fn main raise {
  let scan = @nrrd.Tensor::new(
    [3, 2, 2],
    @nrrd.I16,
    Array::makei(12, fn(i) { i.to_double() }),
    metadata={
      ..@nrrd.Metadata::empty(),
      space: Some("right-anterior-superior"),
      origin: Some([10.0, 20.0, 30.0]),
      directions: [Some([2.0, 0.0, 0.0]), Some([0.0, -3.0, 0.0]), None],
      labels: ["x", "y", "channel"],
      kinds: ["space", "space", "list"],
    },
  )
  let roi = scan.crop([1, 0, 0], [2, 2, 2]).permute([2, 1, 0]).flip(2)
  assert_eq(roi.get([1, 1, 0]), scan.get([2, 1, 1]))
  assert_eq(roi.world([1.0, 1.0, 0.0]), scan.world([2.0, 1.0, 1.0]))
  let output = @nrrd.write_nrrd(roi, encoding=@nrrd.Hex, data_file="roi.hex")
  let back = @nrrd.read_nrrd(output.header, detached=output.payload)
  assert_eq(back.world([1.0, 1.0, 0.0]), [14.0, 17.0, 30.0])
  println(
    "spatial: crop, permutation, flip and detached hex preserve world coordinates",
  )
}
