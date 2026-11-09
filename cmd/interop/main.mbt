// Test-only exporter consumed by the independent Python oracle.

///|
fn main raise {
  for
    (scalar, values) in [
      (@nrrd.I8, [-128.0, -1.0, 0.0, 127.0]),
      (@nrrd.U8, [0.0, 1.0, 128.0, 255.0]),
      (@nrrd.I16, [-32768.0, -1.0, 0.0, 32767.0]),
      (@nrrd.U16, [0.0, 1.0, 32768.0, 65535.0]),
      (@nrrd.I32, [-2147483648.0, -1.0, 0.0, 2147483647.0]),
      (@nrrd.U32, [0.0, 1.0, 2147483648.0, 4294967295.0]),
      (@nrrd.F32, [-12.5, -0.125, 0.5, 1024.25]),
      (@nrrd.F64, [-1.0e100, -0.125, 0.5, 1.0e100]),
    ] {
    let tensor = @nrrd.Tensor::new([2, 2], scalar, values, metadata={
      ..@nrrd.Metadata::empty(),
      labels: ["x", "time"],
      custom: { "source": "MoonNRRD" },
    })
    for encoding in [@nrrd.Raw, @nrrd.Ascii, @nrrd.Hex] {
      for endian in [@nrrd.Little, @nrrd.Big] {
        for detached in [false, true] {
          let result = if detached {
            @nrrd.write_nrrd(
              tensor,
              encoding~,
              endian~,
              data_file="payload.raw",
            )
          } else {
            @nrrd.write_nrrd(tensor, encoding~, endian~)
          }
          let header : Array[Int32] = result.header
            .iter()
            .map(fn(b) { b.to_int() })
            .collect()
          let payload : Array[Int32] = result.payload
            .iter()
            .map(fn(b) { b.to_int() })
            .collect()
          println("[" + header.map(fn(x) { x.to_string() }).join(",") + "]")
          println("[" + payload.map(fn(x) { x.to_string() }).join(",") + "]")
        }
      }
    }
  }
}
