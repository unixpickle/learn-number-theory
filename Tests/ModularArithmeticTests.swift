import NumberTheory
import Testing

@Test func additionWrapsAtModulus() {
  let result = ModInt(value: 5, modulus: 7) + ModInt(value: 4, modulus: 7)
  #expect(result == .init(value: 2, modulus: 7))
}

@Test func multiplicationWrapsAtModulus() {
  let result = ModInt(value: 5, modulus: 7) * ModInt(value: 4, modulus: 7)
  #expect(result == .init(value: 6, modulus: 7))
}

@Test func modularInverseBruteForce() {
  testModularInverseFn(ModPrime.self, modulus: 23, fn: { $0.invert(algorithm: .bruteForce) })
  testModularInverseFn(ModInt.self, modulus: 25, fn: { $0.maybeInvert(algorithm: .bruteForce) })
  testModularInverseFn(ModInt.self, modulus: 10, fn: { $0.maybeInvert(algorithm: .bruteForce) })
}

@Test func modularInverseRecursiveNaive() {
  testModularInverseFn(ModPrime.self, modulus: 23, fn: { $0.invert(algorithm: .recursiveNaive) })
  testModularInverseFn(ModPrime.self, modulus: 89, fn: { $0.invert(algorithm: .recursiveNaive) })
}

@Test func modularInverseRecursive() {
  testModularInverseFn(ModPrime.self, modulus: 23, fn: { $0.invert(algorithm: .recursive) })
  testModularInverseFn(ModPrime.self, modulus: 89, fn: { $0.invert(algorithm: .recursive) })
}

@Test func modularInverseExtendedEuclid() {
  testModularInverseFn(
    ModPrime.self, modulus: 23, fn: { $0.maybeInvert(algorithm: .extendedEuclid) }
  )
  testModularInverseFn(
    ModPrime.self, modulus: 89, fn: { $0.maybeInvert(algorithm: .extendedEuclid) }
  )
  testModularInverseFn(
    ModPrime.self, modulus: 199, fn: { $0.maybeInvert(algorithm: .extendedEuclid) }
  )
  testModularInverseFn(
    ModInt.self, modulus: 199 * 3, fn: { $0.maybeInvert(algorithm: .extendedEuclid) }
  )
  testModularInverseFn(
    ModInt.self, modulus: 3 * 3 * 5 * 7, fn: { $0.maybeInvert(algorithm: .extendedEuclid) }
  )
}

func testModularInverseFn<T: ModIntImpl>(
  _ t: T.Type,
  modulus: Int,
  fn: (T) -> T?
) where T.I == Int {
  for i in 1..<modulus {
    let n = T(value: i, modulus: modulus)
    let maybeInverse = fn(n)
    if gcd(modulus, i) == 1 {
      #expect(maybeInverse != nil, "expected inverse of \(i) mod \(modulus)")
      guard let inverse = maybeInverse else {
        continue
      }
      #expect(inverse.modulus == modulus && inverse.value >= 0 && inverse.value < modulus)
      #expect((n * inverse).value == 1)
    } else {
      #expect(maybeInverse == nil)
    }
  }
}

@Test func testModularExponent() {
  #expect(ModInt<Int>(value: 13, modulus: 1337).pow(10).value == 694)
  #expect(ModInt<Int>(value: 13, modulus: 1337).pow(1111).value == 706)
  #expect(ModInt<Int>(value: 13, modulus: 1337).pow((7 - 1) * (191 - 1)).value == 1)
  #expect(ModInt<Int>(value: 1234, modulus: 1337).pow((7 - 1) * (191 - 1)).value == 1)
  #expect(ModInt<Int>(value: -1, modulus: 1337).pow(1).value == 1336)
  #expect(ModInt<Int>(value: -1, modulus: 1337).pow(2).value == 1)
}
