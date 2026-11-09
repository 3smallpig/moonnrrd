///|
test "all encodings types endian and storage plans roundtrip" {
  try {
    for scalar in [I8, U8, I16, U16, I32, U32, F32, F64] {
      let tensor = Tensor::new([2, 2], scalar, [0.0, 1.0, 42.0, 127.0], metadata={
        ..Metadata::empty(),
        labels: ["a\"b", "x\\y"],
        custom: { "a": "v: x", "z": "end" },
      })
      for encoding in [Raw, Ascii, Hex] {
        for endian in [Little, Big] {
          let encoded = write_nrrd(tensor, encoding~, endian~)
          let decoded = read_nrrd(encoded.attached())
          assert_eq(decoded.values(), tensor.values())
          assert_eq(decoded.metadata(), tensor.metadata())
          let d = write_nrrd(tensor, encoding~, endian~, data_file="field.raw")
          assert_eq(
            read_nrrd(d.header, detached=d.payload).values(),
            tensor.values(),
          )
        }
      }
    }
  } catch {
    Invalid(s) | Unsupported(s) | Limit(s) | Truncated(s) => fail(s)
    e => raise e
  }
}
