import NumberTheory
import Testing

@Test func testListPrimesUpTo() {
  #expect(listPrimes(upTo: 7) == [2, 3, 5, 7])
  #expect(listPrimes(upTo: 10) == [2, 3, 5, 7])
  #expect(listPrimes(upTo: 11) == [2, 3, 5, 7, 11])
  #expect(listPrimes(upTo: 19) == [2, 3, 5, 7, 11, 13, 17, 19])
  #expect(listPrimes(upTo: 21) == [2, 3, 5, 7, 11, 13, 17, 19])
  #expect(listPrimes(upTo: 23) == [2, 3, 5, 7, 11, 13, 17, 19, 23])
}
