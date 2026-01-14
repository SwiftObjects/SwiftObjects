//
//  UObjectTests.swift
//  SwiftObjectsTests
//

import XCTest
@testable import SwiftObjects

/**
 * Tests for UObject utility functions used for type coercion.
 */
class UObjectTests: XCTestCase {

  // MARK: - boolValue Tests

  func testBoolValueFromBoolTrue() {
    XCTAssertTrue(UObject.boolValue(true))
  }

  func testBoolValueFromBoolFalse() {
    XCTAssertFalse(UObject.boolValue(false))
  }

  func testBoolValueFromIntZero() {
    XCTAssertFalse(UObject.boolValue(0))
  }

  func testBoolValueFromIntNonZero() {
    XCTAssertTrue(UObject.boolValue(1))
    XCTAssertTrue(UObject.boolValue(42))
    XCTAssertTrue(UObject.boolValue(-1))
  }

  func testBoolValueFromStringFalsy() {
    // These strings should be false
    XCTAssertFalse(UObject.boolValue(""))
    XCTAssertFalse(UObject.boolValue("0"))
    XCTAssertFalse(UObject.boolValue(" "))
    XCTAssertFalse(UObject.boolValue("NO"))
    XCTAssertFalse(UObject.boolValue("false"))
    XCTAssertFalse(UObject.boolValue("undefined"))
  }

  func testBoolValueFromStringTruthy() {
    // Other strings should be true
    XCTAssertTrue(UObject.boolValue("true"))
    XCTAssertTrue(UObject.boolValue("YES"))
    XCTAssertTrue(UObject.boolValue("1"))
    XCTAssertTrue(UObject.boolValue("hello"))
    XCTAssertTrue(UObject.boolValue("anything"))
  }

  func testBoolValueFromArrayEmpty() {
    let empty = [ Int ]()
    XCTAssertFalse(UObject.boolValue(empty))
  }

  func testBoolValueFromArrayNonEmpty() {
    let array = [ 1, 2, 3 ]
    XCTAssertTrue(UObject.boolValue(array))
  }

  func testBoolValueFromSetEmpty() {
    let empty = Set<Int>()
    XCTAssertFalse(UObject.boolValue(empty))
  }

  func testBoolValueFromSetNonEmpty() {
    let set : Set<Int> = [ 1, 2, 3 ]
    XCTAssertTrue(UObject.boolValue(set))
  }

  func testBoolValueFromOptionalNone() {
    let none : String? = nil
    XCTAssertFalse(UObject.boolValue(none))
  }

  func testBoolValueFromOptionalSome() {
    let some : String? = "value"
    XCTAssertTrue(UObject.boolValue(some))
  }

  func testBoolValueFromOptionalSomeFalsy() {
    // An optional containing a falsy value
    let some : String? = ""
    XCTAssertFalse(UObject.boolValue(some))
  }

  func testBoolValueFromNil() {
    XCTAssertFalse(UObject.boolValue(nil))
  }

  func testBoolValueFromAnyObject() {
    // Any object that doesn't implement UObjectBoolValue is truthy
    class PlainObject {}
    let obj = PlainObject()
    XCTAssertTrue(UObject.boolValue(obj))
  }


  // MARK: - stringValue Tests

  func testStringValueFromString() {
    XCTAssertEqual(UObject.stringValue("hello"), "hello")
    XCTAssertEqual(UObject.stringValue(""), "")
  }

  func testStringValueFromBoolTrue() {
    XCTAssertEqual(UObject.stringValue(true), "true")
  }

  func testStringValueFromBoolFalse() {
    XCTAssertEqual(UObject.stringValue(false), "false")
  }

  func testStringValueFromInt() {
    XCTAssertEqual(UObject.stringValue(42), "42")
    XCTAssertEqual(UObject.stringValue(0), "0")
    XCTAssertEqual(UObject.stringValue(-1), "-1")
  }

  func testStringValueFromNil() {
    XCTAssertEqual(UObject.stringValue(nil), "<nil>")
  }

  func testStringValueFromOther() {
    // Uses String(describing:) for other types
    let array = [ 1, 2, 3 ]
    let result = UObject.stringValue(array)
    XCTAssert(result.contains("1"))
    XCTAssert(result.contains("2"))
    XCTAssert(result.contains("3"))
  }


  // MARK: - intValue Tests

  func testIntValueFromInt() {
    XCTAssertEqual(UObject.intValue(42), 42)
    XCTAssertEqual(UObject.intValue(0), 0)
    XCTAssertEqual(UObject.intValue(-100), -100)
  }

  func testIntValueFromBoolTrue() {
    XCTAssertEqual(UObject.intValue(true), 1)
  }

  func testIntValueFromBoolFalse() {
    XCTAssertEqual(UObject.intValue(false), 0)
  }

  func testIntValueFromStringValid() {
    XCTAssertEqual(UObject.intValue("42"), 42)
    XCTAssertEqual(UObject.intValue("0"), 0)
    XCTAssertEqual(UObject.intValue("-10"), -10)
  }

  func testIntValueFromStringInvalid() {
    XCTAssertEqual(UObject.intValue("not a number"), 0)
    XCTAssertEqual(UObject.intValue(""), 0)
    XCTAssertEqual(UObject.intValue("12.5"), 0) // Doesn't parse floats
  }

  func testIntValueFromNil() {
    XCTAssertEqual(UObject.intValue(nil), 0)
  }

  func testIntValueFromStringOptional() {
    let s : String? = "42"
    XCTAssertEqual(UObject.intValue(s), 42)

    let n : String? = nil
    XCTAssertEqual(UObject.intValue(n), 0)
  }


  // MARK: - eq() Tests

  func testEqBothNil() {
    XCTAssertTrue(eq(nil as Any?, nil as Any?))
  }

  func testEqLeftNilRightValue() {
    XCTAssertFalse(eq(nil as Any?, "value"))
  }

  func testEqLeftValueRightNil() {
    XCTAssertFalse(eq("value", nil as Any?))
  }

  func testEqInts() {
    XCTAssertTrue(eq(42 as Any?, 42 as Any?))
    XCTAssertFalse(eq(42 as Any?, 43 as Any?))
  }

  func testEqStrings() {
    XCTAssertTrue(eq("hello" as Any?, "hello" as Any?))
    XCTAssertFalse(eq("hello" as Any?, "world" as Any?))
  }

  func testEqMixedTypes() {
    XCTAssertFalse(eq(42 as Any?, "42" as Any?))
  }

  func testEqOptionals() {
    let a: String? = "hello"
    let b: String? = "hello"
    let c: String? = nil
    XCTAssertTrue(eq(a, b))
    XCTAssertFalse(eq(a, c))
    XCTAssertTrue(eq(c, nil))
  }


  // MARK: - getSimpleName Tests

  func testGetSimpleName() {
    class MyClass {}
    let obj = MyClass()

    let name = UObject.getSimpleName(obj)

    XCTAssertEqual(name, "MyClass")
  }

  func testGetSimpleNameInt() {
    let value = 42

    let name = UObject.getSimpleName(value)

    XCTAssertEqual(name, "Int")
  }

  func testGetSimpleNameString() {
    let value = "hello"

    let name = UObject.getSimpleName(value)

    XCTAssertEqual(name, "String")
  }


  // MARK: - Linux

  static var allTests = [
    ( "testBoolValueFromBoolTrue",         testBoolValueFromBoolTrue         ),
    ( "testBoolValueFromBoolFalse",        testBoolValueFromBoolFalse        ),
    ( "testBoolValueFromIntZero",          testBoolValueFromIntZero          ),
    ( "testBoolValueFromIntNonZero",       testBoolValueFromIntNonZero       ),
    ( "testBoolValueFromStringFalsy",      testBoolValueFromStringFalsy      ),
    ( "testBoolValueFromStringTruthy",     testBoolValueFromStringTruthy     ),
    ( "testBoolValueFromArrayEmpty",       testBoolValueFromArrayEmpty       ),
    ( "testBoolValueFromArrayNonEmpty",    testBoolValueFromArrayNonEmpty    ),
    ( "testBoolValueFromSetEmpty",         testBoolValueFromSetEmpty         ),
    ( "testBoolValueFromSetNonEmpty",      testBoolValueFromSetNonEmpty      ),
    ( "testBoolValueFromOptionalNone",     testBoolValueFromOptionalNone     ),
    ( "testBoolValueFromOptionalSome",     testBoolValueFromOptionalSome     ),
    ( "testBoolValueFromOptionalSomeFalsy", testBoolValueFromOptionalSomeFalsy ),
    ( "testBoolValueFromNil",              testBoolValueFromNil              ),
    ( "testBoolValueFromAnyObject",        testBoolValueFromAnyObject        ),
    ( "testStringValueFromString",         testStringValueFromString         ),
    ( "testStringValueFromBoolTrue",       testStringValueFromBoolTrue       ),
    ( "testStringValueFromBoolFalse",      testStringValueFromBoolFalse      ),
    ( "testStringValueFromInt",            testStringValueFromInt            ),
    ( "testStringValueFromNil",            testStringValueFromNil            ),
    ( "testStringValueFromOther",          testStringValueFromOther          ),
    ( "testIntValueFromInt",               testIntValueFromInt               ),
    ( "testIntValueFromBoolTrue",          testIntValueFromBoolTrue          ),
    ( "testIntValueFromBoolFalse",         testIntValueFromBoolFalse         ),
    ( "testIntValueFromStringValid",       testIntValueFromStringValid       ),
    ( "testIntValueFromStringInvalid",     testIntValueFromStringInvalid     ),
    ( "testIntValueFromNil",               testIntValueFromNil               ),
    ( "testIntValueFromStringOptional",    testIntValueFromStringOptional    ),
    ( "testEqBothNil",             testEqBothNil             ),
    ( "testEqLeftNilRightValue",   testEqLeftNilRightValue   ),
    ( "testEqLeftValueRightNil",   testEqLeftValueRightNil   ),
    ( "testEqInts",                testEqInts                ),
    ( "testEqStrings",             testEqStrings             ),
    ( "testEqMixedTypes",          testEqMixedTypes          ),
    ( "testEqOptionals",           testEqOptionals           ),
    ( "testGetSimpleName",                 testGetSimpleName                 ),
    ( "testGetSimpleNameInt",              testGetSimpleNameInt              ),
    ( "testGetSimpleNameString",           testGetSimpleNameString           ),
  ]
}
