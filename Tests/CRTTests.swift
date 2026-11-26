import NumberTheory
import Testing

@Test func testCRTRepresentative() {
  for basis in [[3, 5, 7], [9, 5, 4], [9, 5], [2, 3]] {
    let totalModulus = basis.reduce(1, *)
    for i in 0..<totalModulus {
      let cNum = CRT(coprimes: basis, representative: i)
      #expect(cNum.residuals == basis.map { i % $0 })
      let rep = cNum.representative()
      #expect(rep == i)
    }
  }
}

@Test func testCRTExpression() {
  for basis in [[3, 5, 7], [9, 5, 4], [9, 5], [2, 3]] {
    let totalModulus = basis.reduce(1, *)
    for _ in 0...50 {
      let a = (0..<totalModulus).randomElement()!
      let b = (0..<totalModulus).randomElement()!
      let c = (0..<totalModulus).randomElement()!
      let aCRT = CRT(coprimes: basis, representative: a)
      let bCRT = CRT(coprimes: basis, representative: b)
      let cCRT = CRT(coprimes: basis, representative: c)
      #expect((aCRT * bCRT + cCRT).representative() == (a * b + c) % totalModulus)
      #expect((aCRT * bCRT - cCRT).representative() == (a * b - c).positiveModulus(totalModulus))
      #expect((-aCRT * bCRT - cCRT).representative() == (-a * b - c).positiveModulus(totalModulus))
    }
  }
}
