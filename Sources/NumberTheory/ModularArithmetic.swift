public enum ModInverseAlgorithm {
  case bruteForce
  case extendedEuclid
}

public protocol ModIntImpl<I>: Equatable {
  associatedtype I: Integer

  var value: I { get }
  var modulus: I { get }

  init(value: I, modulus: I)
}

extension ModIntImpl {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.value == rhs.value && lhs.modulus == rhs.modulus
  }

  public static func + (lhs: Self, rhs: Self) -> Self {
    precondition(lhs.modulus == rhs.modulus)
    return lhs.with(value: I.add(lhs.value, rhs.value, modulus: lhs.modulus))
  }

  public static prefix func - (value: Self) -> Self {
    return value.with(value: value.modulus - value.value)
  }

  public static func - (lhs: Self, rhs: Self) -> Self {
    return lhs + (-rhs)
  }

  public static func * (lhs: Self, rhs: Self) -> Self {
    precondition(lhs.modulus == rhs.modulus)
    return lhs.with(value: I.multiply(lhs.value, rhs.value, modulus: lhs.modulus))
  }

  public func with(value: I) -> Self {
    var value = value % modulus
    if value < 0 {
      value = (value + modulus) % modulus
    }
    return Self(value: value, modulus: modulus)
  }

  public func with(modulus: I) -> Self {
    return Self(value: value, modulus: modulus)
  }

  /// Find the multiplicative inverse for the number.
  ///
  /// This should only be used if the modulus is prime.
  public func maybeInvert(algorithm: ModInverseAlgorithm = .extendedEuclid) -> Self? {
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

  /// Raise the number to a non-negative power.
  public func pow(_ x: I) -> Self {
    precondition(x >= 0)
    var result = with(value: 1)
    var remaining = x
    var currentSquare = self
    while remaining != 0 {
      if remaining & 1 == 1 {
        result = result * currentSquare
      }
      currentSquare = currentSquare * currentSquare
      remaining >>= 1
    }
    return result
  }
}

public struct ModInt<I: Integer>: ModIntImpl {
  public let value: I
  public let modulus: I

  public init(value: I, modulus: I) {
    self.value = value
    self.modulus = modulus
  }
}

public struct ModPrime<I: Integer>: ModIntImpl {
  public enum PrimeModInverseAlgorithm {
    case general(ModInverseAlgorithm)
    case recursiveNaive
    case recursive

    public static var bruteForce: Self { .general(.bruteForce) }
    public static var extendedEuclid: Self { .general(.extendedEuclid) }
  }

  public let value: I
  public let modulus: I

  public init(value: I, modulus: I) {
    precondition(modulus > 1)
    self.value = value
    self.modulus = modulus
  }

  /// Find the multiplicative inverse for the number.
  public func invert(algorithm: PrimeModInverseAlgorithm) -> Self {
    switch algorithm {
    case .general(let baseAlg):
      guard let result = maybeInvert(algorithm: baseAlg) else {
        fatalError("mod inverse must succeed for prime modulus")
      }
      return result
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

  /// Use Euler's criterion to check if the number is square.
  public func isSquare() -> Bool {
    // Fermat's little theorem says x^(p-1) == 1
    // So x^((p-1)/2) in {-1, +1}
    // And squares fill up the available roots of x^((p-1)/2)-1=0.
    pow((modulus - 1) / 2).value == 1
  }

  /// sqrt() computes the lower of the two square roots of the number using
  /// Tonelli-Shanks.
  public func sqrt() -> Self? {
    if modulus == 2 {
      return self
    }

    var oddComponent = modulus - 1
    var evenPowers: I = 0
    while oddComponent % 2 == 0 {
      evenPowers += 1
      oddComponent /= 2
    }
    assert(evenPowers > 0)

    // We have that p-1 = oddComponent * 2^(evenPowers)
    var r = pow((oddComponent + 1) / 2)
    var t = pow(oddComponent)
    assert(r.pow(2) == self * t, "initial relation of r and t failed")

    // This is only true if a is square, otherwise it would be negative one.
    let tTest = t.pow(1 << (evenPowers - 1))
    if tTest.value != 1 {
      assert(tTest.value == modulus - 1, "non-square should give -1 for Euler criterion")
      return nil
    }

    // We want to find a deep square root of -1, i.e. a number such that when
    // raised to 2^(evenPowers-1) is equal to -1.
    var correction = with(value: findNonSquare()).pow(oddComponent)

    // Repeatedly correct so that t requires fewer squarings to reach one.
    for i in stride(from: evenPowers - 2, through: 0, by: -1) {
      if t.pow(1 << i).value == modulus - 1 {
        t = t * correction.pow(2)
        r = r * correction
        assert(t.pow(1 << i).value == 1, "correction did not work")
      }
      correction = correction.pow(2)
    }

    assert(t.value == 1)
    return with(value: min(r.value, (-r).value))
  }

  private func findNonSquare() -> I {
    while true {
      let n = modulus.randomBelow()
      if with(value: n).pow((modulus - 1) / 2).value == modulus - 1 {
        return n
      }
    }
  }
}
