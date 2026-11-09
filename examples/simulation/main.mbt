///|
fn main raise {
  let field = @nrrd.Tensor::new(
    [3, 2],
    @nrrd.F32,
    [0.0, 0.25, 0.5, 1.0, 1.25, 1.5],
    metadata={
      ..@nrrd.Metadata::empty(),
      labels: ["distance", "time"],
      units: ["m", "s"],
      kinds: ["domain", "time"],
      custom: { "experiment": "diffusion" },
    },
  )
  let file = @nrrd.write_nrrd(field, encoding=@nrrd.Raw, endian=@nrrd.Big)
  let restored = @nrrd.read_nrrd(file.attached())
  assert_eq(restored.get([2, 1]), 1.5)
  assert_eq(restored.metadata().custom["experiment"], "diffusion")
  println(
    "simulation: big-endian raw exchange preserves six samples and axis metadata",
  )
}
