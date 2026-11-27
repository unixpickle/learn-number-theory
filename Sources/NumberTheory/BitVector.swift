public struct BitVector {
  var words: [UInt32]
  public let count: Int

  public init(words: [UInt32], count: Int) {
    precondition(words.count * 32 >= count, "word list isn't long enough for bit count")
    precondition(words.count * 32 - count < 32, "no spare words allowed")
    self.words = words
    self.count = count
  }

  public init(count: Int) {
    self.words = [UInt32](repeating: 0, count: (count + 31) / 32)
    self.count = count
  }

  subscript(idx: Int) -> Bool {
    get {
      assert(idx >= 0 && idx < count)
      return words[idx >> 5] & (1 << (idx & 31)) == 0 ? false : true
    }
    set {
      assert(idx >= 0 && idx < count)
      if newValue {
        words[idx >> 5] |= (1 << (idx & 31))
      } else {
        words[idx >> 5] &= ~(1 << (idx & 31))
      }
    }
  }

  public static func ^ (lhs: BitVector, rhs: BitVector) -> BitVector {
    bitOp(lhs, rhs) { $0 ^ $1 }
  }

  public static func & (lhs: BitVector, rhs: BitVector) -> BitVector {
    bitOp(lhs, rhs) { $0 & $1 }
  }

  public static func | (lhs: BitVector, rhs: BitVector) -> BitVector {
    bitOp(lhs, rhs) { $0 | $1 }
  }

  static func bitOp(_ a: BitVector, _ b: BitVector, op: (UInt32, UInt32) -> UInt32) -> BitVector {
    precondition(a.count == b.count)
    return BitVector(words: zip(a.words, b.words).map(op), count: a.count)
  }
}
