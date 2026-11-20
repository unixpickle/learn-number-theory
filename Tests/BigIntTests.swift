import NumberTheory
import Testing

@Test func bigIntNormalizesDigitsAndZero() {
  #expect(BigInt(digits: [1, 0, 0], sign: false) == BigInt(1))
  #expect(BigInt(digits: [1, 0, 0], sign: true) == BigInt(-1))
  for digits: [UInt16] in [[], [0], [0, 0, 0]] {
    let zero = BigInt(digits: digits, sign: true)
    #expect(zero.digits.isEmpty)
    #expect(!zero.sign)
    #expect(zero == BigInt(0))
    #expect(-zero == zero)
    #expect(zero * BigInt(-1) == zero)
    #expect(zero / BigInt(-1) == zero)
    #expect(zero % BigInt(-1) == zero)
  }
}

private func checkAgainstInt(_ a: Int, _ b: Int) {
  let lhs = BigInt(a)
  let rhs = BigInt(b)
  #expect((lhs == rhs) == (a == b))
  #expect((lhs != rhs) == (a != b))
  #expect((lhs < rhs) == (a < b))
  #expect((lhs <= rhs) == (a <= b))
  #expect((lhs > rhs) == (a > b))
  #expect((lhs >= rhs) == (a >= b))
  #expect(lhs & rhs == BigInt(a & b))
  #expect(lhs | rhs == BigInt(a | b))
  #expect(lhs ^ rhs == BigInt(a ^ b))
  #expect(~lhs == BigInt(~a))
  let sum = a.addingReportingOverflow(b)
  if !sum.overflow {
    #expect(lhs + rhs == BigInt(sum.partialValue))
  }
  let difference = a.subtractingReportingOverflow(b)
  if !difference.overflow {
    #expect(lhs - rhs == BigInt(difference.partialValue))
  }
  let product = a.multipliedReportingOverflow(by: b)
  if !product.overflow {
    #expect(lhs * rhs == BigInt(product.partialValue))
  }
  if b != 0 && !(a == Int.min && b == -1) {
    #expect(lhs / rhs == BigInt(a / b))
    #expect(lhs % rhs == BigInt(a % b))
  }
}

@Test func bigIntMatchesSmallIntegers() {
  for a in -20...20 {
    for b in -20...20 {
      checkAgainstInt(a, b)
    }
  }
}

@Test func bigIntMatchesIntegerBoundaries() {
  let values = [
    Int.min, Int.min + 1, -4_294_967_296, -65_537, -65_536, -65_535, -1,
    0, 1, 65_535, 65_536, 65_537, 4_294_967_295, 4_294_967_296, Int.max,
  ]
  for a in values {
    for b in values {
      checkAgainstInt(a, b)
    }
  }
  #expect(BigInt(Int.min) / BigInt(-1) == BigInt(Int.max) + BigInt(1))
  #expect(BigInt(Int.min) % BigInt(-1) == BigInt(0))
}

@Test func bigIntMatchesDeterministicRandomIntegers() {
  var state: UInt64 = 42
  func next() -> Int {
    state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
    return Int(Int64(bitPattern: state))
  }
  for _ in 0..<500 {
    checkAgainstInt(next(), next())
    // Smaller operands also let Int serve as an oracle for products.
    checkAgainstInt(next() >> 33, next() >> 33)
  }
}

@Test func bigIntLongCarryAndBorrow() {
  let ones = BigInt(digits: [UInt16](repeating: .max, count: 16), sign: false)
  let power = BigInt(digits: [UInt16](repeating: 0, count: 16) + [1], sign: false)
  #expect(ones + BigInt(1) == power)
  #expect(power - BigInt(1) == ones)
  #expect(-power + BigInt(1) == -ones)
  #expect(ones + (-ones) == BigInt(0))
  #expect(power > ones)
  #expect(-power < -ones)
  // (B^16 - 1)^2 = B^32 - 2*B^16 + 1, with B = 2^16.
  let squareDigits: [UInt16] = [1] + [UInt16](repeating: 0, count: 15)
    + [0xfffe] + [UInt16](repeating: .max, count: 15)
  let square = BigInt(digits: squareDigits, sign: false)
  #expect(ones * ones == square)
  #expect(square / ones == ones)
  #expect(square % ones == BigInt(0))
}

@Test func bigIntKnownLargeArithmetic() {
  // Independent fixtures computed with Python's arbitrary-precision integers.
  let a = BigInt(
    digits: [0xcdef, 0x89ab, 0x4567, 0x0123, 0xcdef, 0x89ab,
      0x4567, 0x0123, 0x3210, 0x7654, 0xba98, 0xfedc], sign: false)
  let b = BigInt(
    digits: [0xa987, 0xedcb, 0xdeff, 0x9abc, 0x5678, 0x1234, 0x0008], sign: false)
  let sum = BigInt(
    digits: [0x7776, 0x7777, 0x2467, 0x9be0, 0x2467, 0x9be0,
      0x456f, 0x0123, 0x3210, 0x7654, 0xba98, 0xfedc], sign: false)
  let product = BigInt(
    digits: [0x6009, 0x9411, 0x8f6f, 0xe634, 0x209c, 0x708f, 0x69b5,
      0xf6d2, 0x98ad, 0x63cf, 0x6bd6, 0x8fac, 0x7424, 0x0848,
      0x04b2, 0x8a1f, 0x74ce, 0x0905, 0x0008], sign: false)
  let quotient = BigInt(
    digits: [0xc9e1, 0xdb24, 0x7aec, 0xb591, 0xbc55, 0x1f93], sign: false)
  let remainder = BigInt(
    digits: [0xcf48, 0x4d94, 0x0ba4, 0xaaa0, 0x1ecf, 0xfb54, 0x0007], sign: false)
  #expect(a + b == sum)
  #expect(sum - a == b)
  #expect(sum - b == a)
  #expect(-a + (-b) == -sum)
  for lhs in [a, -a] {
    for rhs in [b, -b] {
      let expectedProduct = lhs.sign == rhs.sign ? product : -product
      let expectedQuotient = lhs.sign == rhs.sign ? quotient : -quotient
      let expectedRemainder = lhs.sign ? -remainder : remainder
      #expect(lhs * rhs == expectedProduct)
      #expect(lhs / rhs == expectedQuotient)
      #expect(lhs % rhs == expectedRemainder)
      #expect((lhs / rhs) * rhs + lhs % rhs == lhs)
      #expect(rhs / lhs == BigInt(0))
      #expect(rhs % lhs == rhs)
    }
  }
}

@Test func bigIntIntegerConversions() {
  for value in [Int.min, -65_537, -1, 0, 1, 65_536, Int.max] {
    let number = BigInt(value)
    #expect(Int(exactly: number) == value)
    #expect(BigInt(exactly: value) == number)
    #expect(BigInt(clamping: value) == number)
    #expect(BigInt(truncatingIfNeeded: value) == number)
    #expect(BigInt(number) == number)
    #expect(number.words == Array(value.words))
    #expect(number.description == String(value))
    #expect(number.magnitude == (value < 0 ? -number : number))
  }
  let unsigned = BigInt(UInt.max)
  #expect(UInt(exactly: unsigned) == UInt.max)
  #expect(Int(exactly: unsigned) == nil)
  #expect(UInt(exactly: BigInt(-1)) == nil)
  #expect(Int(clamping: unsigned) == Int.max)
  #expect(Int(clamping: -unsigned) == Int.min)
  #expect(Int(truncatingIfNeeded: unsigned) == -1)
  #expect(BigInt(Int8.min) == -128)
  #expect(BigInt(UInt8.max) == 255)
  #expect(BigInt() == 0)
  let literal: BigInt = -9_223_372_036_854_775_808
  #expect(literal == BigInt(Int64.min))

  let huge = (BigInt(1) << 200) + 123
  #expect(BigInt(exactly: huge) == huge)
  #expect(BigInt(clamping: -huge) == -huge)
  #expect(BigInt(truncatingIfNeeded: huge) == huge)
  #expect(Int(exactly: huge) == nil)
  #expect(UInt(truncatingIfNeeded: huge) == 123)
  #expect(String(BigInt(1) << 100) == "1267650600228229401496703205376")
  #expect(String(-(BigInt(1) << 100)) == "-1267650600228229401496703205376")
  #expect(String(huge, radix: 16) == "1" + String(repeating: "0", count: 48) + "7b")
}

@Test func bigIntFloatingPointConversions() {
  for value: Double in [0, -0.0, 0.75, -0.75, 1, -1, 123_456.75, -123_456.75] {
    #expect(BigInt(value) == BigInt(Int(value)))
    #expect(BigInt(exactly: value) == (value == value.rounded(.towardZero) ? BigInt(value) : nil))
  }
  #expect(BigInt(exactly: Double.infinity) == nil)
  #expect(BigInt(exactly: -Double.infinity) == nil)
  #expect(BigInt(exactly: Double.nan) == nil)
  #expect(BigInt(Double.leastNonzeroMagnitude) == 0)
  #expect(BigInt(exactly: Double.leastNonzeroMagnitude) == nil)
  #expect(BigInt(Float.greatestFiniteMagnitude) == (BigInt(1) << 128) - (BigInt(1) << 104))
  #expect(BigInt(Double.greatestFiniteMagnitude) == (BigInt(1) << 1024) - (BigInt(1) << 971))
  let power = BigInt(1) << 200
  let floating = Double(sign: .plus, exponent: 200, significand: 1)
  #expect(BigInt(exactly: floating) == power)
  #expect(BigInt(exactly: -floating) == -power)
  #expect(Double(exactly: power) == floating)
  #expect(Double(exactly: power + 1) == nil)
  #expect(Double(power + 1) == floating)
}

@Test func bigIntBinaryRepresentation() {
  #expect(BigInt(0).bitWidth == 1)
  #expect(BigInt(0).trailingZeroBitCount == BigInt(0).bitWidth)
  #expect(BigInt(-1).bitWidth == 1)
  #expect(BigInt(1).bitWidth == 2)
  for exponent in [1, 15, 16, 31, 63, 64, 65, 127, 256] {
    let power = BigInt(1) << exponent
    #expect(power.bitWidth == exponent + 2)
    #expect((-power).bitWidth == exponent + 1)
    #expect((-power - 1).bitWidth == exponent + 2)
    #expect(power.trailingZeroBitCount == exponent)
    #expect((-power).trailingZeroBitCount == exponent)
    #expect((power + 1).trailingZeroBitCount == 0)
    #expect((power - 1).bitWidth == exponent + 1)
  }
  let wordBase = BigInt(1) << UInt.bitWidth
  #expect((wordBase - 1).words == [UInt.max, 0])
  #expect(wordBase.words == [0, 1])
  #expect((-wordBase).words == [0, UInt.max])
  #expect((-wordBase - 1).words == [UInt.max, UInt.max - 1])
}

@Test func bigIntBitwiseAndShiftOperations() {
  for value in [Int.min, -65_537, -65_536, -3, -1, 0, 1, 65_535, 65_536, Int.max] {
    let number = BigInt(value)
    for amount in 0...80 {
      #expect(number >> amount == BigInt(value >> amount))
      #expect(number << (-amount) == BigInt(value >> amount))
      #expect((number << amount) >> amount == number)
      #expect(number >> (-amount) == number << amount)
    }
  }
  let high = BigInt(1) << 200
  let low = (BigInt(1) << 64) - 1
  #expect(high | low == high + low)
  #expect((high + low) & low == low)
  #expect((high + low) ^ low == high)
  #expect((high + low) & ~low == high)
  #expect(~high == -high - 1)
  #expect(high & -1 == high)
  #expect(high | -1 == -1)
  #expect(high ^ -1 == ~high)
  #expect(~high & ~low == ~(high | low))
  #expect(~high | ~low == ~(high & low))
  #expect(high << BigInt(17) == high << 17)
  #expect(high >> UInt64.max == 0)
  #expect(-high >> UInt64.max == -1)
  #expect(high << Int.min == 0)
  #expect(-high << Int.min == -1)
  #expect(high >> high == 0)
  #expect(-high >> high == -1)
  #expect(BigInt(0) << high == 0)
}

@Test func bigIntCompoundAssignmentsAndHashing() {
  var value: BigInt = 10
  value += 5
  #expect(value == 15)
  value -= 20
  #expect(value == -5)
  value *= -7
  #expect(value == 35)
  value /= 2
  #expect(value == 17)
  value %= 5
  #expect(value == 2)
  value |= 9
  #expect(value == 11)
  value &= 6
  #expect(value == 2)
  value ^= 7
  #expect(value == 5)
  value <<= 20
  #expect(value == 5_242_880)
  value >>= 19
  #expect(value == 10)
  value.negate()
  #expect(value == -10)
  #expect(Set([BigInt(0), BigInt(digits: [0, 0], sign: true)]).count == 1)
  #expect(Set([BigInt(1), BigInt(digits: [1, 0], sign: false), BigInt(-1)]).count == 2)
}

@Test func bigIntWorksAsGenericInteger() {
  let base = BigInt(1) << 200
  #expect(base.distance(to: -base) == -2 * base)
  #expect(base.advanced(by: -2 * base) == -base)
  #expect(Array((base - 2)..<(base + 2)) == [base - 2, base - 1, base, base + 1])
  #expect(Array(stride(from: base, through: base - 6, by: BigInt(-2)))
    == [base, base - 2, base - 4, base - 6])
  #expect(gcd(21 * base, 15 * base) == 3 * base)
  let number = ModInt<BigInt>(value: 5, modulus: 23)
  #expect((number + number).value == 10)
  #expect((number * number).value == 2)
  #expect(number.invert(algorithm: .bruteForce).value == 14)
  #expect(number.invert(algorithm: .recursiveNaive).value == 14)
  #expect(number.invert(algorithm: .recursive).value == 14)
  #expect(number.maybeInvert(algorithm: .bruteForce)?.value == 14)
  #expect(number.maybeInvert(algorithm: .extendedEuclid)?.value == 14)
  #expect(ModInt<BigInt>(value: 6, modulus: 9).maybeInvert(algorithm: .extendedEuclid) == nil)
  let division = (-base - 3).quotientAndRemainder(dividingBy: base)
  #expect(division.quotient == -1)
  #expect(division.remainder == -3)
  #expect(base.isMultiple(of: 2))
  #expect((-base).signum() == -1)
}
