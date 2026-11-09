///|
/// Scalar samples are exposed as Double; all supported integers are exact.
pub(all) enum Scalar {
  I8
  U8
  I16
  U16
  I32
  U32
  F32
  F64
} derive(Debug, Eq)

///|
pub(all) enum Encoding {
  Raw
  Ascii
  Hex
} derive(Debug, Eq)

///|
pub(all) enum Endian {
  Little
  Big
} derive(Debug, Eq)

///|
pub fn Scalar::width(self : Scalar) -> Int32 {
  match self {
    I8 | U8 => 1
    I16 | U16 => 2
    I32 | U32 | F32 => 4
    F64 => 8
  }
}

///|
pub fn Scalar::name(self : Scalar) -> String {
  match self {
    I8 => "int8"
    U8 => "uint8"
    I16 => "int16"
    U16 => "uint16"
    I32 => "int32"
    U32 => "uint32"
    F32 => "float"
    F64 => "double"
  }
}

///|
pub fn parse_scalar(text : String) -> Scalar raise NrrdError {
  match text.to_lower() {
    "signed char" | "int8" | "int8_t" => I8
    "uchar" | "unsigned char" | "uint8" | "uint8_t" => U8
    "short"
    | "short int"
    | "signed short"
    | "signed short int"
    | "int16"
    | "int16_t" => I16
    "ushort"
    | "unsigned short"
    | "unsigned short int"
    | "uint16"
    | "uint16_t" => U16
    "int" | "signed int" | "int32" | "int32_t" => I32
    "uint" | "unsigned int" | "uint32" | "uint32_t" => U32
    "float" => F32
    "double" => F64
    _ => raise Unsupported("scalar type: " + text)
  }
}

///|
fn parse_encoding(text : String) -> Encoding raise NrrdError {
  match text.to_lower() {
    "raw" => Raw
    "ascii" | "text" | "txt" => Ascii
    "hex" => Hex
    _ => raise Unsupported("encoding: " + text)
  }
}

///|
/// Reject inexact integers and float32 overflow, instead of saturating casts.
fn Scalar::canonical(self : Scalar, value : Double) -> Double raise NrrdError {
  if self == F64 {
    return value
  }
  if self == F32 {
    let rounded = @float.Float::from_double(value).to_double()
    if !value.is_inf() && !value.is_nan() && rounded.is_inf() {
      raise Invalid("float32 overflow")
    }
    return rounded
  }
  if value.is_nan() || value.is_inf() || value.trunc() != value {
    raise Invalid("integer sample must be finite and integral")
  }
  let (low, high) = match self {
    I8 => (-128.0, 127.0)
    U8 => (0.0, 255.0)
    I16 => (-32768.0, 32767.0)
    U16 => (0.0, 65535.0)
    I32 => (-2147483648.0, 2147483647.0)
    U32 => (0.0, 4294967295.0)
    _ => (0.0, 0.0)
  }
  if value < low || value > high {
    raise Invalid("integer sample out of range")
  }
  value
}
