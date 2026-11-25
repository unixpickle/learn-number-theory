import NumberTheory
import Testing

@Test func testCRTRepresentative() {
  for basis in [[3, 5, 7], [9, 5, 4], [9, 5], [2, 3]] {
    let totalModulus = basis.reduce(1, *)
    for i in 0..<totalModulus {
      let rep = CRT(coprimes: basis, residuals: basis.map { i % $0 }).representative()
      #expect(rep == i)
    }
  }
}
