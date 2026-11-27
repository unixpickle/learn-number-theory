/// Create an ordered list of primes up to and including the provided
/// upper-bound.
public func listPrimes(upTo: Int) -> [Int] {
  var compositeMap = BitVector(count: upTo + 1)
  var result = [Int]()
  for i in 2...upTo {
    if compositeMap[i] {
      continue
    }
    result.append(i)
    for x in stride(from: i, through: upTo, by: i) {
      compositeMap[x] = true
    }
  }
  return result
}
