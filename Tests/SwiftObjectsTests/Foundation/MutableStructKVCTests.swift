//
//  MutableStructKVCTests.swift
//  SwiftObjectsTests
//

import XCTest
@testable import SwiftObjects

/**
 * Tests for mutable KVC on structs using `inout` parameters.
 *
 * These tests verify that value types can be mutated through KVC with proper
 * bubbling behavior for keypath access.
 */
class MutableStructKVCTests: XCTestCase {

  // MARK: - Test Helpers

  /// Simple struct for basic mutation tests
  struct Point {

    var x : Int = 0
    var y : Int = 0
  }

  /// Struct with nested struct
  struct Rectangle {

    var origin : Point = Point()
    var size   : Size = Size()
  }

  struct Size {

    var width  : Int = 0
    var height : Int = 0
  }

  /// Struct conforming to MutableKeyValueCodingType
  struct KVCPoint: KeyValueCodingType, MutableKeyValueCodingType {

    var x : Int = 0
    var y : Int = 0

    func value(forKey k: String) -> Any? {
      switch k {
        case "x": return x
        case "y": return y
        default:  return handleQueryWithUnboundKey(k)
      }
    }

    mutating func takeValue(_ value: Any?, forKey k: String) throws {
      switch k {
        case "x": x = value as? Int ?? 0
        case "y": y = value as? Int ?? 0
        default:  try handleTakeValue(value, forUnboundKey: k)
      }
    }
  }

  /// Size struct conforming to MutableKeyValueCodingType
  struct KVCSize: KeyValueCodingType, MutableKeyValueCodingType {

    var width  : Int = 0
    var height : Int = 0

    func value(forKey k: String) -> Any? {
      switch k {
        case "width":  return width
        case "height": return height
        default:       return handleQueryWithUnboundKey(k)
      }
    }

    mutating func takeValue(_ value: Any?, forKey k: String) throws {
      switch k {
        case "width":  width  = value as? Int ?? 0
        case "height": height = value as? Int ?? 0
        default:       try handleTakeValue(value, forUnboundKey: k)
      }
    }
  }

  /// Struct with nested KVC struct
  struct KVCRectangle: KeyValueCodingType, MutableKeyValueCodingType {

    var origin : KVCPoint = KVCPoint()
    var size   : KVCSize  = KVCSize()

    func value(forKey k: String) -> Any? {
      switch k {
        case "origin": return origin
        case "size":   return size
        default:       return handleQueryWithUnboundKey(k)
      }
    }

    mutating func takeValue(_ value: Any?, forKey k: String) throws {
      switch k {
        case "origin": origin = value as? KVCPoint ?? KVCPoint()
        case "size":   size   = value as? KVCSize ?? KVCSize()
        default:       try handleTakeValue(value, forUnboundKey: k)
      }
    }
  }

  /// Class containing a struct (for mixed hierarchy tests)
  class Canvas {

    var frame : Rectangle = Rectangle()
    var name  : String = ""
  }

  /// Class containing a KVC-conforming struct (for nested property tests)
  class KVCCanvas {

    var frame : KVCRectangle = KVCRectangle()
    var name  : String = ""
  }


  // MARK: - Single Key Mutation Tests

  func testSingleKeyMutationOnStruct() throws {
    var point = Point(x: 10, y: 20)

    try KeyValueCoding.takeValue(100, forKey: "x", inObject: &point)

    XCTAssertEqual(point.x, 100)
    XCTAssertEqual(point.y, 20) // unchanged
  }

  func testSingleKeyMutationMultipleKeys() throws {
    var point = Point()

    try KeyValueCoding.takeValue(5, forKey: "x", inObject: &point)
    try KeyValueCoding.takeValue(10, forKey: "y", inObject: &point)

    XCTAssertEqual(point.x, 5)
    XCTAssertEqual(point.y, 10)
  }

  func testSingleKeyMutationWithKVCProtocol() throws {
    var point = KVCPoint(x: 1, y: 2)

    try KeyValueCoding.takeValue(99, forKey: "x", inObject: &point)

    XCTAssertEqual(point.x, 99)
    XCTAssertEqual(point.y, 2)
  }

  func testSingleKeyMutationInvalidKey() {
    var point = Point()

    XCTAssertThrowsError(
      try KeyValueCoding.takeValue(42, forKey: "z", inObject: &point)
    ) { error in
      guard case KeyValueCoding.Error.CannotTakeValueForKey(let key) = error
      else {
        XCTFail("Expected CannotTakeValueForKey error, got \(error)")
        return
      }
      XCTAssertEqual(key, "z")
    }
  }


  // MARK: - Keypath Mutation Tests with Bubbling
  //
  // Note: Nested keypath mutation (e.g., "origin.x") requires intermediate
  // structs to conform to MutableKeyValueCodingType for reliable behavior.
  // This is because modifying values inside Any boxes requires type information
  // at runtime.

  func testKeypathMutationWithKVCStruct() throws {
    var rect = KVCRectangle(origin: KVCPoint(x: 5, y: 5),
                            size: KVCSize(width: 50, height: 50))

    try KeyValueCoding.takeValue(15, forKeyPath: "origin.x", inObject: &rect)

    XCTAssertEqual(rect.origin.x, 15)
    XCTAssertEqual(rect.origin.y, 5)
  }

  func testKeypathMutationSingleKey() throws {
    var point = Point(x: 1, y: 2)

    // Single-element keypath should work like single key
    try KeyValueCoding.takeValue(99, forKeyPath: "x", inObject: &point)

    XCTAssertEqual(point.x, 99)
  }

  func testKeypathMutationNestedKVCStructs() throws {
    var rect = KVCRectangle()

    try KeyValueCoding.takeValue(10, forKeyPath: "origin.x", inObject: &rect)
    try KeyValueCoding.takeValue(20, forKeyPath: "origin.y", inObject: &rect)

    XCTAssertEqual(rect.origin.x, 10)
    XCTAssertEqual(rect.origin.y, 20)
  }


  // MARK: - Mixed Class/Struct Hierarchy Tests

  func testClassContainingStruct() throws {
    let canvas = Canvas()
    canvas.frame = Rectangle(origin: Point(x: 0, y: 0),
                             size: Size(width: 800, height: 600))

    // Set via keypath on class (uses existing Any? overload)
    try KeyValueCoding.takeValue("MyCanvas", forKey: "name", inObject: canvas)
    XCTAssertEqual(canvas.name, "MyCanvas")

    // Access direct struct property
    let frame = KeyValueCoding.value(forKey: "frame", inObject: canvas)
    XCTAssertNotNil(frame)
  }

  func testNestedStructPropertyRead() {
    let canvas = KVCCanvas()
    canvas.frame = KVCRectangle(origin: KVCPoint(x: 10, y: 20),
                                size: KVCSize(width: 800, height: 600))

    // Read nested struct properties via keypath
    let originX = KeyValueCoding.value(forKeyPath: "frame.origin.x",
                                       inObject: canvas)
    let originY = KeyValueCoding.value(forKeyPath: "frame.origin.y",
                                       inObject: canvas)
    let width   = KeyValueCoding.value(forKeyPath: "frame.size.width",
                                       inObject: canvas)
    let height  = KeyValueCoding.value(forKeyPath: "frame.size.height",
                                       inObject: canvas)

    XCTAssertEqual(originX as? Int, 10)
    XCTAssertEqual(originY as? Int, 20)
    XCTAssertEqual(width as? Int, 800)
    XCTAssertEqual(height as? Int, 600)
  }

  func testNestedStructPropertyWrite() throws {
    let canvas = KVCCanvas()
    canvas.frame = KVCRectangle(origin: KVCPoint(x: 0, y: 0),
                                size: KVCSize(width: 100, height: 100))

    // Write nested struct properties via keypath
    try KeyValueCoding.takeValue(50, forKeyPath: "frame.origin.x",
                                 inObject: canvas)
    try KeyValueCoding.takeValue(75, forKeyPath: "frame.origin.y",
                                 inObject: canvas)
    try KeyValueCoding.takeValue(1920, forKeyPath: "frame.size.width",
                                 inObject: canvas)
    try KeyValueCoding.takeValue(1080, forKeyPath: "frame.size.height",
                                 inObject: canvas)

    XCTAssertEqual(canvas.frame.origin.x, 50)
    XCTAssertEqual(canvas.frame.origin.y, 75)
    XCTAssertEqual(canvas.frame.size.width, 1920)
    XCTAssertEqual(canvas.frame.size.height, 1080)
  }

  func testNestedStructPropertyWritePreservesOtherValues() throws {
    let canvas = KVCCanvas()
    canvas.frame = KVCRectangle(origin: KVCPoint(x: 10, y: 20),
                                size: KVCSize(width: 800, height: 600))
    canvas.name = "TestCanvas"

    // Modify only origin.x
    try KeyValueCoding.takeValue(999, forKeyPath: "frame.origin.x",
                                 inObject: canvas)

    // Verify only origin.x changed
    XCTAssertEqual(canvas.frame.origin.x, 999)
    XCTAssertEqual(canvas.frame.origin.y, 20)   // unchanged
    XCTAssertEqual(canvas.frame.size.width, 800)  // unchanged
    XCTAssertEqual(canvas.frame.size.height, 600) // unchanged
    XCTAssertEqual(canvas.name, "TestCanvas")      // unchanged
  }


  // MARK: - Backwards Compatibility Tests

  func testClassOverloadStillWorks() throws {
    // This test ensures the existing AnyObject-based class mutation still works
    let person = TestPerson()

    try KeyValueCoding.takeValue("Alice", forKey: "name", inObject: person)
    try KeyValueCoding.takeValue(30, forKey: "age", inObject: person)

    XCTAssertEqual(person.name, "Alice")
    XCTAssertEqual(person.age, 30)
  }

  func testClassKeypathStillWorks() throws {
    let person  = TestPerson()
    let address = TestAddress()
    person.address = address

    try KeyValueCoding.takeValue("Berlin", forKeyPath: "address.city",
                                 inObject: person)

    XCTAssertEqual(person.address?.city, "Berlin")
  }


  // MARK: - Edge Cases

  func testEmptyKeypathError() {
    var point = Point()

    XCTAssertThrowsError(
      try KeyValueCoding.takeValue(1, forKeyPath: "", inObject: &point)
    ) { error in
      guard case KeyValueCoding.Error.EmptyKeyPath = error else {
        XCTFail("Expected EmptyKeyPath error, got \(error)")
        return
      }
    }
  }

  func testEmptyKeypathArrayError() {
    var point = Point()

    XCTAssertThrowsError(
      try KeyValueCoding.takeValue(1, forKeyPath: [ String ](),
                                   inObject: &point)
    ) { error in
      guard case KeyValueCoding.Error.EmptyKeyPath = error else {
        XCTFail("Expected EmptyKeyPath error, got \(error)")
        return
      }
    }
  }


  // MARK: - Large Plain Structs (heap-boxed in Any)

  /// 40 bytes, does not fit the 24 byte inline buffer of `Any`.
  struct Large {

    var a    = 1
    var b    = 2
    var c    = 3
    var d    = 4
    var name = "large"
  }

  struct Outer {

    var inner = Large()
    var tag   = 0
  }

  class LargeHolder {

    var large = Large()
    var outer = Outer()
  }

  func testLargePlainStructRead() {
    let holder = LargeHolder()
    XCTAssertEqual(KeyValueCoding.value(forKeyPath: "large.a",
                                        inObject: holder) as? Int, 1)
    XCTAssertEqual(KeyValueCoding.value(forKeyPath: "large.d",
                                        inObject: holder) as? Int, 4)
    XCTAssertEqual(KeyValueCoding.value(forKeyPath: "large.name",
                                        inObject: holder) as? String, "large")
    XCTAssertEqual(KeyValueCoding.value(forKeyPath: "outer.inner.d",
                                        inObject: holder) as? Int, 4)
    XCTAssertEqual(KeyValueCoding.value(forKey: "d", inObject: holder.large)
                   as? Int, 4)
  }

  func testLargePlainStructWriteViaKeyPath() throws {
    let holder = LargeHolder()
    try KeyValueCoding.takeValue(42,    forKeyPath: "large.d", inObject: holder)
    try KeyValueCoding.takeValue("new", forKeyPath: "large.name",
                                 inObject: holder)
    XCTAssertEqual(holder.large.a,    1)
    XCTAssertEqual(holder.large.c,    3)
    XCTAssertEqual(holder.large.d,    42)
    XCTAssertEqual(holder.large.name, "new")
  }

  func testLargePlainStructNestedWrite() throws {
    let holder = LargeHolder()
    try KeyValueCoding.takeValue(7, forKeyPath: "outer.inner.c",
                                 inObject: holder)
    try KeyValueCoding.takeValue(9, forKeyPath: "outer.tag", inObject: holder)
    XCTAssertEqual(holder.outer.inner.c, 7)
    XCTAssertEqual(holder.outer.inner.d, 4)
    XCTAssertEqual(holder.outer.tag,     9)
  }

  func testLargePlainStructInout() throws {
    var large = Large()
    try KeyValueCoding.takeValue(42, forKey: "d", inObject: &large)
    try KeyValueCoding.takeValue("x", forKeyPath: "name", inObject: &large)
    XCTAssertEqual(large.d,    42)
    XCTAssertEqual(large.name, "x")

    var outer = Outer()
    try KeyValueCoding.takeValue(5, forKeyPath: "inner.b", inObject: &outer)
    XCTAssertEqual(outer.inner.b, 5)
  }

  func testInoutThroughAny() throws {
    var any : Any = Large()
    try KeyValueCoding.takeValue(42, forKey: "d", inObject: &any)
    XCTAssertEqual((any as? Large)?.d, 42)
  }

  func testInoutThroughOptional() throws {
    var point : Point? = Point()
    try KeyValueCoding.takeValue(5, forKey: "x", inObject: &point)
    XCTAssertEqual(point?.x, 5)

    var any : Any? = Large()
    try KeyValueCoding.takeValue(42, forKeyPath: "d", inObject: &any)
    XCTAssertEqual((any as? Large)?.d, 42)

    var outer : Outer? = Outer()
    try KeyValueCoding.takeValue(5, forKeyPath: "inner.b", inObject: &outer)
    XCTAssertEqual(outer?.inner.b, 5)

    var kvcPoint : KVCPoint? = KVCPoint()
    try KeyValueCoding.takeValue(7, forKey: "x", inObject: &kvcPoint)
    XCTAssertEqual(kvcPoint?.x, 7)
  }

  func testInoutThroughNilOptionalIsNoOp() throws {
    var point : Point? = nil
    try KeyValueCoding.takeValue(5, forKey: "x", inObject: &point)
    XCTAssertNil(point)
  }


  // MARK: - Value Types Through the Any API

  func testValueTypeThroughAnyAPIThrows() {
    var point = KVCPoint()
    point.x = 1
    XCTAssertThrowsError(
      try KeyValueCoding.takeValue(5, forKey: "x", inObject: point)
    ) { error in
      guard case KeyValueCoding.Error.CannotTakeValueOnValueType(_, let key)
              = error
      else { return XCTFail("Expected CannotTakeValueOnValueType: \(error)") }
      XCTAssertEqual(key, "x")
    }
    XCTAssertEqual(point.x, 1)
  }


  // MARK: - Coercion

  class Coerced {

    var int      = 0
    var optInt   : Int? = nil
    var double   = 0.0
    var optFloat : Float? = nil
    var string   = ""
  }

  func testCoercionFromStrings() throws {
    let o = Coerced()
    try KeyValueCoding.takeValue("7",   forKey: "int",      inObject: o)
    try KeyValueCoding.takeValue("8",   forKey: "optInt",   inObject: o)
    try KeyValueCoding.takeValue("2.5", forKey: "double",   inObject: o)
    try KeyValueCoding.takeValue("1.5", forKey: "optFloat", inObject: o)
    try KeyValueCoding.takeValue(42,    forKey: "string",   inObject: o)
    XCTAssertEqual(o.int,      7)
    XCTAssertEqual(o.optInt,   8)
    XCTAssertEqual(o.double,   2.5)
    XCTAssertEqual(o.optFloat, 1.5)
    XCTAssertEqual(o.string,   "42")
  }

  func testCoercionOfEmptyAndNil() throws {
    let o = Coerced()
    o.optInt = 3
    try KeyValueCoding.takeValue("",  forKey: "int",    inObject: o)
    try KeyValueCoding.takeValue("",  forKey: "optInt", inObject: o)
    XCTAssertEqual(o.int, 0)
    XCTAssertNil(o.optInt)
    o.optInt = 3
    try KeyValueCoding.takeValue(nil, forKey: "optInt", inObject: o)
    XCTAssertNil(o.optInt)
  }

  func testCoercionFailuresThrow() {
    let o = Coerced()
    o.int = 1
    XCTAssertThrowsError(
      try KeyValueCoding.takeValue("abc", forKey: "int", inObject: o)
    ) { error in
      guard case KeyValueCoding.Error.CannotCoerceValueForKey(_, _, let key)
              = error
      else { return XCTFail("Expected CannotCoerceValueForKey: \(error)") }
      XCTAssertEqual(key, "int")
    }
    XCTAssertEqual(o.int, 1) // unchanged
    XCTAssertThrowsError(
      try KeyValueCoding.takeValue("abc", forKey: "double", inObject: o)
    )

    // optionals are lenient, unparsable strings become nil
    o.optInt = 3
    XCTAssertNoThrow(
      try KeyValueCoding.takeValue("abc", forKey: "optInt", inObject: o)
    )
    XCTAssertNil(o.optInt)
  }


  // MARK: - Test Helper Classes (for backwards compatibility tests)

  class TestPerson {

    var name    : String = ""
    var age     : Int = 0
    var address : TestAddress?
  }

  class TestAddress {

    var city : String = ""
  }


  // MARK: - Linux

  static var allTests = [
    ( "testSingleKeyMutationOnStruct",
                                              testSingleKeyMutationOnStruct ),
    ( "testSingleKeyMutationMultipleKeys",
                                          testSingleKeyMutationMultipleKeys ),
    ( "testSingleKeyMutationWithKVCProtocol",
                                       testSingleKeyMutationWithKVCProtocol ),
    ( "testSingleKeyMutationInvalidKey",
                                            testSingleKeyMutationInvalidKey ),
    ( "testKeypathMutationWithKVCStruct",
                                           testKeypathMutationWithKVCStruct ),
    ( "testKeypathMutationSingleKey",
                                               testKeypathMutationSingleKey ),
    ( "testKeypathMutationNestedKVCStructs",
                                        testKeypathMutationNestedKVCStructs ),
    ( "testClassContainingStruct",
                                                  testClassContainingStruct ),
    ( "testNestedStructPropertyRead",
                                               testNestedStructPropertyRead ),
    ( "testNestedStructPropertyWrite",
                                              testNestedStructPropertyWrite ),
    ( "testNestedStructPropertyWritePreservesOtherValues",
                          testNestedStructPropertyWritePreservesOtherValues ),
    ( "testClassOverloadStillWorks",
                                                testClassOverloadStillWorks ),
    ( "testClassKeypathStillWorks",
                                                 testClassKeypathStillWorks ),
    ( "testEmptyKeypathError",
                                                      testEmptyKeypathError ),
    ( "testEmptyKeypathArrayError",
                                                 testEmptyKeypathArrayError ),
    ( "testLargePlainStructRead",
                                                   testLargePlainStructRead ),
    ( "testLargePlainStructWriteViaKeyPath",
                                        testLargePlainStructWriteViaKeyPath ),
    ( "testLargePlainStructNestedWrite",
                                            testLargePlainStructNestedWrite ),
    ( "testLargePlainStructInout",
                                                  testLargePlainStructInout ),
    ( "testInoutThroughAny",
                                                        testInoutThroughAny ),
    ( "testValueTypeThroughAnyAPIThrows",
                                           testValueTypeThroughAnyAPIThrows ),
    ( "testCoercionFromStrings",
                                                    testCoercionFromStrings ),
    ( "testCoercionOfEmptyAndNil",
                                                  testCoercionOfEmptyAndNil ),
    ( "testCoercionFailuresThrow",
                                                  testCoercionFailuresThrow ),
  ]
}
