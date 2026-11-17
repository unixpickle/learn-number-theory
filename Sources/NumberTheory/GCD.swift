public func gcd(_ x: Int, _ y: Int) -> Int {
  assert(x > 0 && y > 0)
  // Euclid's algorithm
  var (x, y) = (min(x, y), max(x, y))
  while y != 0 {
    (x, y) = (y, x % y)
  }
  return x
}
