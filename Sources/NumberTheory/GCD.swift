public func gcd<I: Integer>(_ x: I, _ y: I) -> I {
  assert(x > 0 && y > 0)
  // Euclid's algorithm
  var (x, y) = (min(x, y), max(x, y))
  while y != 0 {
    (x, y) = (y, x % y)
  }
  return x
}
