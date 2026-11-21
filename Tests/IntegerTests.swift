import NumberTheory
import Testing

@Test func testIntModAdd() {
  testIntModAddType(Int8.self)
  testIntModAddType(Int16.self)
  testIntModAddType(Int32.self)
  testIntModAddType(Int64.self)
  testIntModAddType(Int.self)
}

@Test func testIntModMul() {
  testIntModMulType(Int8.self, Int16.self)
  testIntModMulType(Int16.self, Int32.self)
  testIntModMulType(Int32.self, Int64.self)
}

func testIntModAddType<I: FixedWidthInteger>(_ t: I.Type) where I: Integer {
  let value1: I = I.max - 1
  let value2: I = (I.max - 1) / 2
  let value3: I = (I.max / 2) + 1
  let value4: I = I.max / 2
  let value5: I = I.max / 3
  for modulus in [value1, value2, value3, value4, value5] {
    #expect(I.add(modulus - 1, modulus - 2, modulus: modulus) == modulus - 3)
    if modulus % 2 == 0 {
      #expect(I.add(modulus / 2, modulus / 2, modulus: modulus) == 0)
      #expect(I.add(modulus / 2 - 1, modulus / 2, modulus: modulus) == modulus - 1)
      #expect(I.add(modulus / 2 + 1, modulus / 2, modulus: modulus) == 1)
    } else {
      #expect(I.add(modulus / 2, modulus / 2, modulus: modulus) == modulus - 1)
      #expect(I.add(modulus / 2 - 1, modulus / 2, modulus: modulus) == modulus - 2)
      #expect(I.add(modulus / 2 + 1, modulus / 2, modulus: modulus) == 0)
    }
  }
}

func testIntModMulType<I: FixedWidthInteger, I2: FixedWidthInteger>(
  _ t: I.Type,
  _ t1: I2.Type
) where I: Integer {
  let value1: I = I.max - 1
  let value2: I = (I.max - 1) / 2
  let value3: I = (I.max / 2) + 1
  let value4: I = I.max / 2
  let value5: I = I.max / 3
  for modulus in [value1, value2, value3, value4, value5] {
    let arr: [I] = [modulus / 2, modulus / 2 - 1, modulus / 2 + 1, modulus - 1, modulus - 3, 3]
    for a in arr {
      for b in arr {
        let expected = I(exactly: (I2(exactly: a)! * I2(exactly: b)!) % I2(exactly: modulus)!)
        let actual = I.multiply(a, b, modulus: modulus)
        #expect(actual == expected)
      }
    }
  }
}
