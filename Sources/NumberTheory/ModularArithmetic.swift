public struct ModInt: Equatable {
  public enum InversionAlgorithm {
    case bruteForce
    case recursiveNaive
  }

  public let value: Int
  public let modulus: Int

  public init(value: Int, modulus: Int) {
    self.value = value
    self.modulus = modulus
  }

  public static func + (lhs: ModInt, rhs: ModInt) -> ModInt {
    precondition(lhs.modulus == rhs.modulus)
    return lhs.with(value: (lhs.value + rhs.value) % lhs.modulus)
  }

  public static func * (lhs: ModInt, rhs: ModInt) -> ModInt {
    precondition(lhs.modulus == rhs.modulus)
    // TODO: deal with integer wraparound here.
    return lhs.with(value: (lhs.value * rhs.value) % lhs.modulus)
  }

  public func with(value: Int) -> ModInt {
    ModInt(value: value % modulus, modulus: modulus)
  }

  /// Find the multiplicative inverse for the number.
  ///
  /// This should only be used if the modulus is prime.
  public func invert(algorithm: InversionAlgorithm) -> ModInt {
    switch algorithm {
    case .bruteForce:
      for i in 1..<modulus {
        let n = with(value: i)
        if (self * n).value == 1 {
          return n
        }
      }
    case .recursiveNaive:
      let factor1 = with(value: 1 + modulus / value)
      let remainder = self * factor1
      if remainder.value == 1 {
        return factor1
      }
      assert(remainder.value < value)
      return factor1 * remainder.invert(algorithm: algorithm)
    }
    fatalError()
  }
}
