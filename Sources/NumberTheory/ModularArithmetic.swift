public struct ModInt<I: Integer>: Equatable {
  public enum PrimeInversionAlgorithm {
    case bruteForce
    case recursiveNaive
    case recursive
  }

  public enum InversionAlgorithm {
    case bruteForce
    case extendedEuclid
  }

  public let value: I
  public let modulus: I

  public init(value: I, modulus: I) {
    self.value = value
    self.modulus = modulus
  }

  public static func + (lhs: ModInt, rhs: ModInt) -> ModInt {
    precondition(lhs.modulus == rhs.modulus)
    return lhs.with(value: I.add(lhs.value, rhs.value, modulus: lhs.modulus))
  }

  public static prefix func - (value: ModInt) -> ModInt {
    return value.with(value: value.modulus - value.value)
  }

  public static func - (lhs: ModInt, rhs: ModInt) -> ModInt {
    return lhs + (-rhs)
  }

  public static func * (lhs: ModInt, rhs: ModInt) -> ModInt {
    precondition(lhs.modulus == rhs.modulus)
    return lhs.with(value: I.multiply(lhs.value, rhs.value, modulus: lhs.modulus))
  }

  public func with(value: I) -> ModInt {
    var value = value % modulus
    if value < 0 {
      value = (value + modulus) % modulus
    }
    return ModInt(value: value, modulus: modulus)
  }

  /// Find the multiplicative inverse for the number.
  ///
  /// This should only be used if the modulus is prime.
  public func invert(algorithm: PrimeInversionAlgorithm) -> ModInt {
    switch algorithm {
    case .bruteForce:
      for i in 1..<modulus {
        let n = with(value: i)
        if (self * n).value == 1 {
          return n
        }
      }
      fatalError()
    case .recursiveNaive:
      let factor1 = with(value: 1 + modulus / value)
      let remainder = self * factor1
      if remainder.value == 1 {
        return factor1
      }
      assert(remainder.value < value)
      return factor1 * remainder.invert(algorithm: algorithm)
    case .recursive:
      let factor1 = with(value: 1 + modulus / value)
      let remainder = self * factor1
      if remainder.value == 1 {
        return factor1
      }
      assert(remainder.value < value)

      // Figure out an additional factor to drive down the argument
      // to the recursive call.
      let residual = value - remainder.value
      let factor2 = with(value: value / residual - (value % residual == 0 ? 1 : 0))
      let joI = factor1 * factor2 - (factor2 - self.with(value: 1))

      let lowerRemainder = self * joI
      assert(lowerRemainder.value <= remainder.value)

      return joI * lowerRemainder.invert(algorithm: algorithm)
    }
  }

  /// Find the multiplicative inverse for the number.
  ///
  /// This should only be used if the modulus is prime.
  public func maybeInvert(algorithm: InversionAlgorithm) -> ModInt? {
    switch algorithm {
    case .bruteForce:
      for i in 1..<modulus {
        let n = with(value: i)
        if (self * n).value == 1 {
          return n
        }
      }
      return nil
    case .extendedEuclid:
      // x is always the larger of the pair
      var x = modulus
      var y = value

      // xcoeff tells us (a, b) that gives x = a*x0 + b*y0
      // ycoeff tells us (a, b) that gives y = a*x0 + b*y0
      var xcoeff: (I, I) = (1, 0)
      var ycoeff: (I, I) = (0, 1)

      while y > 0 {
        let divided = x / y
        (x, y) = (y, x - y * divided)
        (xcoeff, ycoeff) = (ycoeff, (xcoeff.0 - ycoeff.0 * divided, xcoeff.1 - ycoeff.1 * divided))
      }
      if x != 1 {
        // there is a common factor
        return nil
      }
      return with(value: xcoeff.1)
    }
  }
}
