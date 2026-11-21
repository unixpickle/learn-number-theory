public protocol Integer: SignedInteger where Stride: SignedInteger {
  static func add(_ x: Self, _ y: Self, modulus: Self) -> Self
  static func multiply(_ x: Self, _ y: Self, modulus: Self) -> Self
  func positiveModulus(_ modulus: Self) -> Self
}

extension Integer {
  public func positiveModulus(_ modulus: Self) -> Self {
    var x = self % modulus
    if x < 0 {
      x = x + modulus
    }
    return x
  }
}

extension Integer where Self: FixedWidthInteger {
  public static func add(_ x: Self, _ y: Self, modulus: Self) -> Self {
    let (x, y) = (x.positiveModulus(modulus), y.positiveModulus(modulus))
    let (partial, overflow) = x.addingReportingOverflow(y)
    if !overflow {
      return partial.positiveModulus(modulus)
    }
    return (x - modulus) + y
  }

  public static func multiply(_ x: Self, _ y: Self, modulus: Self) -> Self {
    let (x, y) = (x.positiveModulus(modulus), y.positiveModulus(modulus))
    let (high, low) = x.multipliedFullWidth(by: y)
    let remainder = modulus.dividingFullWidth((high, low)).remainder
    return remainder
  }
}

extension Int: Integer {}
extension Int8: Integer {}
extension Int16: Integer {}
extension Int32: Integer {}
extension Int64: Integer {}

public struct BigInt: Integer {
  // Each digit is in the range [0, 2^16) starting with the least
  // significant digit.
  public let digits: [UInt16]

  /// True for negative values. Zero always has an empty digit array and a false sign.
  public let sign: Bool

  public init(digits: [UInt16], sign: Bool) {
    var digits = digits
    while digits.last == 0 {
      digits.removeLast()
    }
    self.digits = digits
    self.sign = sign && !digits.isEmpty
  }

  public static func + (lhs: BigInt, rhs: BigInt) -> BigInt {
    if lhs.sign == rhs.sign {
      var carry: UInt16 = 0
      var result = [UInt16]()
      for i in 0..<Swift.max(lhs.digits.count, rhs.digits.count) {
        let sum = UInt32(carry) + UInt32(lhs.digit(at: i)) + UInt32(rhs.digit(at: i))
        carry = UInt16(sum / 0x10000)
        result.append(UInt16(sum % 0x10000))
      }
      if carry != 0 {
        result.append(carry)
      }
      return BigInt(digits: result, sign: lhs.sign)
    } else {
      if lhs.magnitudeIsLess(than: rhs) {
        return BigInt(digits: rhs.subtractMagnitude(lhs), sign: rhs.sign)
      }
      return BigInt(digits: lhs.subtractMagnitude(rhs), sign: lhs.sign)
    }
  }

  public static prefix func - (value: BigInt) -> BigInt {
    BigInt(digits: value.digits, sign: !value.sign)
  }

  public static func - (lhs: BigInt, rhs: BigInt) -> BigInt {
    lhs + (-rhs)
  }

  public static func * (lhs: BigInt, rhs: BigInt) -> BigInt {
    guard !lhs.digits.isEmpty && !rhs.digits.isEmpty else {
      return BigInt(digits: [], sign: false)
    }
    var result = [UInt16](repeating: 0, count: lhs.digits.count + rhs.digits.count)
    for i in lhs.digits.indices {
      var carry: UInt32 = 0
      for j in rhs.digits.indices {
        // The product, existing digit, and carry together fit in UInt32.
        let product =
          UInt32(lhs.digits[i]) * UInt32(rhs.digits[j])
          + UInt32(result[i + j]) + carry
        result[i + j] = UInt16(product % 0x10000)
        carry = product / 0x10000
      }
      result[i + rhs.digits.count] = UInt16(carry)
    }
    return BigInt(digits: result, sign: lhs.sign != rhs.sign)
  }

  /// Divides with truncation toward zero. The divisor must be nonzero.
  public static func / (lhs: BigInt, rhs: BigInt) -> BigInt {
    lhs.quotientAndRemainder(dividingBy: rhs).quotient
  }

  /// The remainder has the dividend's sign, unless it is zero.
  public static func % (lhs: BigInt, rhs: BigInt) -> BigInt {
    lhs.quotientAndRemainder(dividingBy: rhs).remainder
  }

  public static func == (lhs: BigInt, rhs: BigInt) -> Bool {
    lhs.sign == rhs.sign && lhs.digits == rhs.digits
  }

  public static func < (lhs: BigInt, rhs: BigInt) -> Bool {
    if lhs.sign != rhs.sign {
      return lhs.sign
    }
    return lhs.sign ? rhs.magnitudeIsLess(than: lhs) : lhs.magnitudeIsLess(than: rhs)
  }

  private func digit(at index: Int) -> UInt16 {
    index < digits.count ? digits[index] : 0
  }

  private func magnitudeIsLess(than other: BigInt) -> Bool {
    if digits.count != other.digits.count {
      return digits.count < other.digits.count
    }
    return digits.reversed().lexicographicallyPrecedes(other.digits.reversed())
  }

  // Requires self's magnitude to be at least other's magnitude.
  private func subtractMagnitude(_ other: BigInt) -> [UInt16] {
    var result = [UInt16]()
    var borrow: Int32 = 0
    for i in digits.indices {
      var difference = Int32(digits[i]) - Int32(other.digit(at: i)) - borrow
      borrow = difference < 0 ? 1 : 0
      if difference < 0 {
        difference += 0x10000
      }
      result.append(UInt16(difference))
    }
    return result
  }

  public func quotientAndRemainder(dividingBy divisor: BigInt) -> (
    quotient: BigInt, remainder: BigInt
  ) {
    precondition(!divisor.digits.isEmpty, "Division by zero")
    if magnitudeIsLess(than: divisor) {
      return (BigInt(digits: [], sign: false), self)
    }

    var quotient = [UInt16](repeating: 0, count: digits.count)
    var remainder = BigInt(digits: [], sign: false)
    // Binary long division: bring down one bit at a time. The previous
    // remainder is smaller than the divisor, so at most one subtraction is needed.
    for i in digits.indices.reversed() {
      for bit in (0..<16).reversed() {
        var shifted = remainder.digits
        var carry = UInt32((digits[i] >> bit) & 1)
        for j in shifted.indices {
          let digit = UInt32(shifted[j]) * 2 + carry
          shifted[j] = UInt16(digit % 0x10000)
          carry = digit / 0x10000
        }
        if carry != 0 {
          shifted.append(UInt16(carry))
        }
        remainder = BigInt(digits: shifted, sign: false)
        if !remainder.magnitudeIsLess(than: divisor) {
          remainder = BigInt(digits: remainder.subtractMagnitude(divisor), sign: false)
          quotient[i] |= UInt16(1) << bit
        }
      }
    }
    return (
      BigInt(digits: quotient, sign: sign != divisor.sign),
      BigInt(digits: remainder.digits, sign: sign)
    )
  }

  public typealias Magnitude = BigInt
  public typealias Stride = BigInt
  public typealias IntegerLiteralType = Int64
  public typealias Words = [UInt]

  public init(integerLiteral value: Int64) {
    self.init(value)
  }

  public init<T: BinaryInteger>(_ source: T) {
    if let source = source as? BigInt {
      self = source
    } else {
      self.init(magnitudeWords: Array(source.magnitude.words), sign: source < 0)
    }
  }

  public init?<T: BinaryInteger>(exactly source: T) {
    self.init(source)
  }

  public init<T: BinaryInteger>(clamping source: T) {
    self.init(source)
  }

  public init<T: BinaryInteger>(truncatingIfNeeded source: T) {
    self.init(source)
  }

  /// Converts a finite floating-point value, rounding toward zero.
  public init<T: BinaryFloatingPoint>(_ source: T) {
    precondition(source.isFinite, "Cannot convert a non-finite value to BigInt")
    var value = source.magnitude.rounded(.towardZero)
    var digits = [UInt16]()
    // Extract bits directly so conversion also works beyond machine-integer
    // limits and for floating-point types with a small exponent range.
    while value != 0 {
      var digit: UInt16 = 0
      for bit in 0..<16 {
        if value.truncatingRemainder(dividingBy: 2) != 0 {
          digit |= UInt16(1) << bit
        }
        value = (value / 2).rounded(.towardZero)
      }
      digits.append(digit)
    }
    self.init(digits: digits, sign: source.sign == .minus)
  }

  public init?<T: BinaryFloatingPoint>(exactly source: T) {
    guard source.isFinite && source.rounded(.towardZero) == source else {
      return nil
    }
    self.init(source)
  }

  public var magnitude: BigInt {
    BigInt(digits: digits, sign: false)
  }

  /// The minimum two's-complement width, including a sign bit (one bit for zero).
  public var bitWidth: Int {
    guard let last = digits.last else { return 1 }
    let magnitudeWidth = (digits.count - 1) * 16 + 16 - last.leadingZeroBitCount
    // Negative powers of two need no additional sign bit.
    return magnitudeWidth + (sign && trailingZeroBitCount == magnitudeWidth - 1 ? 0 : 1)
  }

  public var trailingZeroBitCount: Int {
    for (i, digit) in digits.enumerated() where digit != 0 {
      return i * 16 + digit.trailingZeroBitCount
    }
    return bitWidth
  }

  /// Little-endian two's-complement words, sign-extended through the last word.
  public var words: [UInt] {
    let digitsPerWord = UInt.bitWidth / 16
    var result = [UInt](repeating: 0, count: (bitWidth - 1) / UInt.bitWidth + 1)
    for (i, digit) in digits.enumerated() {
      result[i / digitsPerWord] |= UInt(digit) << ((i % digitsPerWord) * 16)
    }
    if sign {
      Self.negateWords(&result)
    }
    return result
  }

  public func distance(to other: BigInt) -> BigInt {
    other - self
  }

  public func advanced(by n: BigInt) -> BigInt {
    self + n
  }

  public static func += (lhs: inout BigInt, rhs: BigInt) {
    lhs = lhs + rhs
  }

  public static func -= (lhs: inout BigInt, rhs: BigInt) {
    lhs = lhs - rhs
  }

  public static func *= (lhs: inout BigInt, rhs: BigInt) {
    lhs = lhs * rhs
  }

  public static func /= (lhs: inout BigInt, rhs: BigInt) {
    lhs = lhs / rhs
  }

  public static func %= (lhs: inout BigInt, rhs: BigInt) {
    lhs = lhs % rhs
  }

  public static prefix func ~ (value: BigInt) -> BigInt {
    -value - 1
  }

  public static func &= (lhs: inout BigInt, rhs: BigInt) {
    lhs = lhs.bitwise(rhs, &)
  }

  public static func |= (lhs: inout BigInt, rhs: BigInt) {
    lhs = lhs.bitwise(rhs, |)
  }

  public static func ^= (lhs: inout BigInt, rhs: BigInt) {
    lhs = lhs.bitwise(rhs, ^)
  }

  public static func <<= <RHS: BinaryInteger>(lhs: inout BigInt, rhs: RHS) {
    lhs = lhs.shifted(by: rhs, left: true)
  }

  public static func >>= <RHS: BinaryInteger>(lhs: inout BigInt, rhs: RHS) {
    lhs = lhs.shifted(by: rhs, left: false)
  }

  private init(magnitudeWords: [UInt], sign: Bool) {
    var digits = [UInt16]()
    for word in magnitudeWords {
      for offset in stride(from: 0, to: UInt.bitWidth, by: 16) {
        digits.append(UInt16(truncatingIfNeeded: word >> offset))
      }
    }
    self.init(digits: digits, sign: sign)
  }

  private static func negateWords(_ words: inout [UInt]) {
    var carry = true
    for i in words.indices {
      let sum = (~words[i]).addingReportingOverflow(carry ? 1 : 0)
      words[i] = sum.partialValue
      carry = sum.overflow
    }
  }

  private func bitwise(_ other: BigInt, _ operation: (UInt, UInt) -> UInt) -> BigInt {
    let lhs = words
    let rhs = other.words
    var result = [UInt]()
    for i in 0..<Swift.max(lhs.count, rhs.count) {
      let a = i < lhs.count ? lhs[i] : (sign ? UInt.max : 0)
      let b = i < rhs.count ? rhs[i] : (other.sign ? UInt.max : 0)
      result.append(operation(a, b))
    }
    let negative = result.last! >> (UInt.bitWidth - 1) != 0
    if negative {
      Self.negateWords(&result)
    }
    return BigInt(magnitudeWords: result, sign: negative)
  }

  private func shifted<RHS: BinaryInteger>(by count: RHS, left: Bool) -> BigInt {
    guard !digits.isEmpty else { return self }
    let left = count < 0 ? !left : left
    guard let amount = Int(exactly: count.magnitude) else {
      precondition(!left, "Shift count is too large to represent in memory")
      return sign ? -1 : 0
    }
    let wholeDigits = amount / 16
    let bits = amount % 16
    if left {
      var result = [UInt16](repeating: 0, count: wholeDigits)
      var carry: UInt32 = 0
      for digit in digits {
        let shifted = (UInt32(digit) << bits) | carry
        result.append(UInt16(truncatingIfNeeded: shifted))
        carry = shifted >> 16
      }
      if carry != 0 {
        result.append(UInt16(carry))
      }
      return BigInt(digits: result, sign: sign)
    }

    guard amount < bitWidth else { return sign ? -1 : 0 }
    var result = Array(digits.dropFirst(wholeDigits))
    var carry: UInt16 = 0
    for i in result.indices.reversed() {
      let digit = result[i]
      result[i] = (digit >> bits) | carry
      carry = UInt16(truncatingIfNeeded: UInt32(digit) << (16 - bits))
    }
    var magnitude = BigInt(digits: result, sign: false)
    // Arithmetic right shift rounds negative values down, unlike division.
    if sign && amount > trailingZeroBitCount {
      magnitude += 1
    }
    return sign ? -magnitude : magnitude
  }

  public static func add(_ x: Self, _ y: Self, modulus: Self) -> Self {
    return (x + y) % modulus
  }

  public static func multiply(_ x: Self, _ y: Self, modulus: Self) -> Self {
    return (x * y) % modulus
  }
}
