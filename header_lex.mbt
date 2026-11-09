///|
/// Header scanning never decodes binary payload as text.
fn scan_header(
  bytes : Bytes,
  limits : Limits,
) -> (Map[String, String], Map[String, String], Int32) raise NrrdError {
  limits.validate()
  let fields : Map[String, String] = Map([])
  let custom : Map[String, String] = Map([])
  let mut offset = 0
  let mut line_number = 0
  while offset < bytes.length() {
    let line = StringBuilder()
    let mut ended = false
    while offset < bytes.length() {
      if offset >= limits.max_header_bytes {
        raise Limit("header budget")
      }
      let b = bytes[offset].to_int()
      offset = offset + 1
      if b == 10 {
        ended = true
        break
      }
      if b == 13 {
        if offset >= bytes.length() || bytes[offset] != b'\n' {
          raise Invalid("bare CR in header")
        }
        continue
      }
      if b != 9 && (b < 32 || b > 126) {
        raise Invalid("header must contain printable ASCII")
      }
      line.write_char(b.unsafe_to_char())
    }
    if !ended {
      raise Truncated("unterminated header line")
    }
    let text = line.to_string()
    if line_number == 0 {
      match text {
        "NRRD0001" | "NRRD0002" | "NRRD0003" | "NRRD0004" | "NRRD0005" => ()
        _ => raise Invalid("NRRD magic/version")
      }
    } else if text.is_empty() {
      return (fields, custom, offset)
    } else if !text.has_prefix("#") {
      let (key, rest) = match text.split_once(":") {
        Some(pair) => pair
        None => raise Invalid("header line requires colon")
      }
      let key = key.trim().to_owned()
      if key.is_empty() {
        raise Invalid("empty header key")
      }
      if rest.has_prefix("=") {
        let value = rest.to_owned().split_at(1).1.to_owned()
        if custom.contains(key) {
          raise Invalid("duplicate custom key")
        }
        custom[key] = value
      } else {
        let key = key.to_lower()
        if fields.contains(key) {
          raise Invalid("duplicate field: " + key)
        }
        fields[key] = rest.trim().to_owned()
      }
    }
    line_number = line_number + 1
  }
  raise Truncated("missing blank header terminator")
}

///|
fn words(text : String) -> Array[String] {
  let result = []
  let current = StringBuilder()
  for c in text.iter() {
    if c == ' ' || c == '\t' || c == '\n' || c == '\r' {
      if !current.is_empty() {
        result.push(current.to_string())
        current.reset()
      }
    } else {
      current.write_char(c)
    }
  }
  if !current.is_empty() {
    result.push(current.to_string())
  }
  result
}

///|
fn integer(text : String) -> Int32 raise NrrdError {
  @string.parse_int(text[:]) catch {
    _ => raise Invalid("invalid integer: " + text)
  }
}

///|
fn number(text : String) -> Double raise NrrdError {
  match text.to_lower() {
    "nan" | "+nan" | "-nan" => 0.0 / 0.0
    "inf" | "+inf" | "infinity" | "+infinity" => 1.0 / 0.0
    "-inf" | "-infinity" => -1.0 / 0.0
    _ =>
      @string.parse_double(text[:]) catch {
        _ => raise Invalid("invalid number: " + text)
      }
  }
}

///|
/// NRRD quoted strings permit escaped quote and escaped backslash.
fn quoted_strings(text : String) -> Array[String] raise NrrdError {
  let chars = text.to_array()
  let result = []
  let mut i = 0
  while i < chars.length() {
    if chars[i] == ' ' || chars[i] == '\t' {
      i = i + 1
      continue
    }
    if chars[i] != '"' {
      raise Invalid("expected quoted axis string")
    }
    i = i + 1
    let s = StringBuilder()
    let mut closed = false
    while i < chars.length() {
      let c = chars[i]
      i = i + 1
      if c == '"' {
        closed = true
        break
      }
      if c == '\\' {
        if i >= chars.length() || (chars[i] != '\\' && chars[i] != '"') {
          raise Invalid("invalid quoted escape")
        }
        s.write_char(chars[i])
        i = i + 1
      } else {
        s.write_char(c)
      }
    }
    if !closed {
      raise Invalid("unterminated quoted string")
    }
    if i < chars.length() && chars[i] != ' ' && chars[i] != '\t' {
      raise Invalid("missing quoted-string separator")
    }
    result.push(s.to_string())
  }
  result
}

///|
fn vector(text : String) -> Array[Double] raise NrrdError {
  let text = text.trim().to_owned()
  if !text.has_prefix("(") || !text.has_suffix(")") {
    raise Invalid("vector parentheses")
  }
  let inner = text[1:text.length() - 1].to_owned()
  let values = []
  for item in inner.split(",") {
    values.push(number(item.trim().to_owned()))
  }
  values
}

///|
fn direction_list(text : String) -> Array[Array[Double]?] raise NrrdError {
  let result = []
  let chars = text.to_array()
  let mut i = 0
  while i < chars.length() {
    if chars[i] == ' ' || chars[i] == '\t' {
      i = i + 1
      continue
    }
    let token = StringBuilder()
    if chars[i] == '(' {
      while i < chars.length() {
        let c = chars[i]
        token.write_char(c)
        i = i + 1
        if c == ')' {
          break
        }
      }
      result.push(Some(vector(token.to_string())))
    } else {
      while i < chars.length() && chars[i] != ' ' && chars[i] != '\t' {
        token.write_char(chars[i])
        i = i + 1
      }
      if token.to_string() != "none" {
        raise Invalid("direction must be vector or none")
      }
      result.push(None)
    }
    if i < chars.length() && chars[i] != ' ' && chars[i] != '\t' {
      raise Invalid("direction separator")
    }
  }
  result
}
