/// CRT stores a Chinese remainder theorem representation of numbers modulo a
/// product of coprimes.
public struct CRT<I: Integer>: Equatable {
  public let coprimes: [I]
  public let residuals: [I]

  public init(coprimes: [I], residuals: [I]) {
    self.coprimes = coprimes
    self.residuals = zip(residuals, coprimes).map { $0.positiveModulus($1) }
  }

  public init(coprimes: [I], representative: I) {
    self.coprimes = coprimes
    residuals = coprimes.map { representative % $0 }
  }

  public static func + (lhs: Self, rhs: Self) -> Self {
    assert(lhs.coprimes == rhs.coprimes)
    return CRT(
      coprimes: lhs.coprimes,
      residuals: zip(zip(lhs.residuals, rhs.residuals), lhs.coprimes).map {
        I.add($0.0, $0.1, modulus: $1)
      }
    )
  }

  public static prefix func - (value: Self) -> Self {
    return CRT(
      coprimes: value.coprimes,
      residuals: zip(value.residuals, value.coprimes).map { $1 - $0 }
    )
  }

  public static func - (lhs: Self, rhs: Self) -> Self {
    return lhs + (-rhs)
  }

  public static func * (lhs: Self, rhs: Self) -> Self {
    assert(lhs.coprimes == rhs.coprimes)
    return CRT(
      coprimes: lhs.coprimes,
      residuals: zip(zip(lhs.residuals, rhs.residuals), lhs.coprimes).map {
        I.multiply($0.0, $0.1, modulus: $1)
      }
    )
  }

  /// Compute the residual modulo the product of coprimes which has the
  /// correct residuals modulo each coprime.
  public func representative() -> I {
    var current: I = 0
    var curModulus: I = 1
    for (coprime, residual) in zip(coprimes, residuals) {
      // (x = current) mod curModulus
      // (x = residual) mod coprime
      // x = current + curModulus*k

      // We need to figure out k such that curModulus*k = (residual - current) mod coprime
      // We can always invert curModulus modulo coprime
      guard let inverse = ModInt<I>(value: curModulus, modulus: coprime).maybeInvert() else {
        fatalError("CRT basis isn't actually coprime: \(coprime) and \(curModulus) share a factor")
      }
      let newModulus = curModulus * coprime
      let k = I.multiply(inverse.value, residual - current, modulus: newModulus)
      current = I.add(current, I.multiply(k, curModulus, modulus: newModulus), modulus: newModulus)
      curModulus = newModulus
    }
    return current
  }
}
