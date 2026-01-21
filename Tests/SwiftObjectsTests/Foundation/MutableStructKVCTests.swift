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
    ( "testSingleKeyMutationOnStruct",      testSingleKeyMutationOnStruct      ),
    ( "testSingleKeyMutationMultipleKeys",  testSingleKeyMutationMultipleKeys  ),
    ( "testSingleKeyMutationWithKVCProtocol",
                                          testSingleKeyMutationWithKVCProtocol ),
    ( "testSingleKeyMutationInvalidKey",    testSingleKeyMutationInvalidKey    ),
    ( "testKeypathMutationWithKVCStruct",   testKeypathMutationWithKVCStruct   ),
    ( "testKeypathMutationSingleKey",       testKeypathMutationSingleKey       ),
    ( "testKeypathMutationNestedKVCStructs",
                                          testKeypathMutationNestedKVCStructs ),
    ( "testClassContainingStruct",          testClassContainingStruct          ),
    ( "testNestedStructPropertyRead",       testNestedStructPropertyRead       ),
    ( "testNestedStructPropertyWrite",      testNestedStructPropertyWrite      ),
    ( "testNestedStructPropertyWritePreservesOtherValues",
                              testNestedStructPropertyWritePreservesOtherValues ),
    ( "testClassOverloadStillWorks",        testClassOverloadStillWorks        ),
    ( "testClassKeypathStillWorks",         testClassKeypathStillWorks         ),
    ( "testEmptyKeypathError",              testEmptyKeypathError              ),
    ( "testEmptyKeypathArrayError",         testEmptyKeypathArrayError         ),
  ]
}
