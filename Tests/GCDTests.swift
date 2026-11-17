import NumberTheory
import Testing

@Test func testGCDRandomSmall() {
  for _ in 0...100 {
    let a = (2..<30).randomElement()!
    let b = (2..<30).randomElement()!
    #expect(gcd(a, b) == gcdNaive(a, b))
  }
}

@Test func testGCDSelf() {
  for i in 1..<100 {
    #expect(gcd(i, i) == i)
  }
}

@Test func testGCDKnown() {
  #expect(gcd(199, 3) == 1)
  #expect(gcd(199 * 3, 3 * 3) == 3)
  #expect(gcd(2 * 5 * 5 * 7, 2 * 2 * 5 * 7 * 7) == 2 * 5 * 7)
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
