///|
fn rejected(action : () -> Unit raise NrrdError) -> Bool {
  try {
    action()
    false
  } catch {
    _ => true
  }
}

///|
fn ascii_header(extra : String) -> Bytes {
  @utf8.encode(
    ("NRRD0005\ntype: uint8\ndimension: 1\nsizes: 2\nencoding: ascii\n" +
    extra +
    "\n1 2")[:],
  )
}

///|
test "all truncated prefixes fail without panics" {
  let file = ascii_header("")
  // The last byte is a necessary sample, so every strict prefix is invalid.
  for n in 0..<file.length() {
    assert_true(
      rejected(fn() -> Unit raise NrrdError {
        ignore(read_nrrd(file[:n].to_owned()))
      }),
    )
  }
  assert_eq(read_nrrd(file).values(), [1.0, 2.0])
}

///|
test "duplicate unknown compressed skip and complex headers fail explicitly" {
  for
    field in [
      "type: uint8\n", "type: double\n", "unexpected: 1\n", "byte skip: -1\n", "line skip: 1\n",
      "data file: LIST\n", "data file: x%03d.raw 0 2 1\n", "measurement frame: (1,0) (0,1)\n",
    ] {
    assert_true(
      rejected(fn() -> Unit raise NrrdError {
        ignore(read_nrrd(ascii_header(field)))
      }),
    )
  }
  for
    magic in [
      b"NRRD0000\n\n", b"NRRD0006\n\n", b"nrrd0005\n\n", b"NRRD0005\r\n\r", b"NRRD0005\n\x00\n\n",
    ] {
    assert_true(
      rejected(fn() -> Unit raise NrrdError { ignore(parse_header(magic)) }),
    )
  }
}

///|
test "header and payload budgets are enforced at exact boundaries" {
  let t = Tensor::new([2], U8, [1.0, 2.0])
  let e = write_nrrd(t)
  let limit = {
    max_header_bytes: e.header.length(),
    max_samples: 2,
    max_payload_bytes: 2,
  }
  assert_eq(read_nrrd(e.attached(), limits=limit).values(), [1.0, 2.0])
  assert_true(
    rejected(fn() -> Unit raise NrrdError {
      ignore(
        read_nrrd(e.attached(), limits={
          ..limit,
          max_header_bytes: e.header.length() - 1,
        }),
      )
    }),
  )
  assert_true(
    rejected(fn() -> Unit raise NrrdError {
      ignore(read_nrrd(e.attached(), limits={ ..limit, max_samples: 1, }))
    }),
  )
  assert_true(
    rejected(fn() -> Unit raise NrrdError {
      ignore(read_nrrd(e.attached(), limits={ ..limit, max_payload_bytes: 1, }))
    }),
  )
  assert_true(
    rejected(fn() -> Unit raise NrrdError {
      ignore(write_nrrd(t, encoding=Hex, limits=limit))
    }),
  )
  assert_true(
    rejected(fn() -> Unit raise NrrdError {
      ignore(t.flip(0, limits={ ..limit, max_payload_bytes: 1, }))
    }),
  )
}

///|
test "scalar range fraction and float overflow rejected across constructors" {
  for
    (scalar, bad) in [
      (I8, 128.0),
      (U8, -1.0),
      (I16, -32769.0),
      (U16, 65536.0),
      (I32, 2147483648.0),
      (U32, 4294967296.0),
      (I32, 0.5),
      (F32, 1.0e100),
    ] {
    assert_true(
      rejected(fn() -> Unit raise NrrdError {
        ignore(Tensor::new([1], scalar, [bad]))
      }),
    )
  }
  for
    sizes in [
      [],
      [0],
      [-1],
      [1, 1, 1, 1, 1, 1, 1, 1, 1],
      [2147483647, 2147483647],
    ] {
    assert_true(
      rejected(fn() -> Unit raise NrrdError { ignore(Shape::new(sizes)) }),
    )
  }
}

///|
test "metadata cannot inject headers or change key meaning" {
  for key in ["a:b", "#comment", " padded", "", "a\nfield"] {
    assert_true(
      rejected(fn() -> Unit raise NrrdError {
        ignore(
          Tensor::new([2], U8, [1.0, 2.0], metadata={
            ..Metadata::empty(),
            custom: Map([(key, "v")]),
          }),
        )
      }),
    )
  }
  assert_true(
    rejected(fn() -> Unit raise NrrdError {
      ignore(
        Tensor::new([2], U8, [1.0, 2.0], metadata={
          ..Metadata::empty(),
          kinds: ["3-vector"],
        }),
      )
    }),
  )
  assert_true(
    rejected(fn() -> Unit raise NrrdError {
      ignore(
        Tensor::new([2], U8, [1.0, 2.0], metadata={
          ..Metadata::empty(),
          labels: ["a\nb"],
        }),
      )
    }),
  )
}

///|
test "nonfinite float samples and negative zero survive binary codecs" {
  for scalar in [F32, F64] {
    for endian in [Little, Big] {
      for encoding in [Raw, Hex, Ascii] {
        let t = Tensor::new([4], scalar, [
          -0.0,
          0.0 / 0.0,
          1.0 / 0.0,
          -1.0 / 0.0,
        ])
        let r = read_nrrd(write_nrrd(t, encoding~, endian~).attached())
        assert_true(r.values()[1].is_nan())
        assert_true(r.values()[2].is_pos_inf())
        assert_true(r.values()[3].is_neg_inf())
        assert_true((1.0 / r.values()[0]).is_neg_inf())
      }
    }
  }
}

///|
test "index and transformation errors are bounded" {
  let t = spatial_fixture()
  assert_true(
    rejected(fn() -> Unit raise NrrdError { ignore(t.get([2, 0, 0])) }),
  )
  assert_true(rejected(fn() -> Unit raise NrrdError { ignore(t.get([0])) }))
  assert_true(
    rejected(fn() -> Unit raise NrrdError { ignore(t.permute([0, 0, 2])) }),
  )
  assert_true(
    rejected(fn() -> Unit raise NrrdError { ignore(t.permute([0, 1, 3])) }),
  )
  assert_true(rejected(fn() -> Unit raise NrrdError { ignore(t.slice(1, 3)) }))
  assert_true(
    rejected(fn() -> Unit raise NrrdError { ignore(t.reduce(3, Mean)) }),
  )
  assert_true(
    rejected(fn() -> Unit raise NrrdError { ignore(t.histogram(1.0, 1.0, 2)) }),
  )
  assert_true(
    rejected(fn() -> Unit raise NrrdError {
      ignore(t.histogram(0.0, 1.0, 65537))
    }),
  )
  let m = {
    ..Metadata::empty(),
    space_dimension: Some(2),
    origin: Some([0.0, 0.0]),
  }
  assert_true(
    rejected(fn() -> Unit raise NrrdError {
      ignore(Tensor::new([2], U8, [1.0, 2.0], metadata=m).flip(0))
    }),
  )
}
