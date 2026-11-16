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
  testModularInverseFn(modulus: 23, fn: { $0.invert(algorithm: .bruteForce) })
  testModularInverseFn(modulus: 25, fn: { $0.maybeInvert(algorithm: .bruteForce) })
  testModularInverseFn(modulus: 10, fn: { $0.maybeInvert(algorithm: .bruteForce) })
}

@Test func modularInverseRecursiveNaive() {
  testModularInverseFn(modulus: 23, fn: { $0.invert(algorithm: .recursiveNaive) })
  testModularInverseFn(modulus: 89, fn: { $0.invert(algorithm: .recursiveNaive) })
}

@Test func modularInverseRecursive() {
  testModularInverseFn(modulus: 23, fn: { $0.invert(algorithm: .recursive) })
  testModularInverseFn(modulus: 89, fn: { $0.invert(algorithm: .recursive) })
}

func testModularInverseFn(modulus: Int, fn: (ModInt) -> ModInt?) {
  for i in 1..<modulus {
    let n = ModInt(value: i, modulus: modulus)
    let maybeInverse = fn(n)
    if gcdNaive(modulus, i) == 1 {
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

func gcdNaive(_ a: Int, _ b: Int) -> Int {
  var result = 1
  for i in 1...min(a, b) {
    if a % i == 0 && b % i == 0 {
      result = i
    }
  }
  return result
}
