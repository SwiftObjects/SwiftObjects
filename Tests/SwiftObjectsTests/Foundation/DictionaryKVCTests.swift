//
//  DictionaryKVCTests.swift
//  SwiftObjectsTests
//

import XCTest
@testable import SwiftObjects

class DictionaryKVCTests: XCTestCase {

  // MARK: - value(forKey:) Tests

  func testDictionaryValueForStringKey() {
    let dict : [ String : Any ] = [
      "name" : "Alice",
      "age"  : 30
    ]

    let name = dict.value(forKey: "name")
    let age  = dict.value(forKey: "age")

    XCTAssertEqual(name as? String, "Alice")
    XCTAssertEqual(age as? Int, 30)
  }

  func testDictionaryValueForMissingKey() {
    let dict : [ String : Any ] = [ "name" : "Bob" ]

    let result = dict.value(forKey: "nonexistent")
    XCTAssertNil(result)
  }

  func testDictionaryValueForIntKey() {
    let dict : [ Int : String ] = [
      1 : "one",
      2 : "two",
      3 : "three"
    ]

    // Access Int-keyed dictionary using string key
    let one = dict.value(forKey: "1")
    let two = dict.value(forKey: "2")

    XCTAssertEqual(one as? String, "one")
    XCTAssertEqual(two as? String, "two")
  }

  func testDictionaryValueForIntKeyInvalid() {
    let dict : [ Int : String ] = [ 1 : "one" ]

    // Non-numeric string key should return nil for Int-keyed dict
    let result = dict.value(forKey: "notanumber")
    XCTAssertNil(result)
  }

  func testDictionaryValueForIntKeyMissing() {
    let dict : [ Int : String ] = [ 1 : "one" ]

    // Valid numeric key but not in dictionary
    let result = dict.value(forKey: "99")
    XCTAssertNil(result)
  }

  func testDictionaryOptionalValue() {
    // Note: In Swift, a Dictionary<String, String?> with a nil value still
    // has the key present. The KVC returns the Optional.none as-is.
    let dict : [ String : String? ] = [
      "present" : "value",
      "absent"  : nil
    ]

    let present = dict.value(forKey: "present")
    let absent  = dict.value(forKey: "absent")
    let missing = dict.value(forKey: "notakey")

    XCTAssertEqual(present as? String, "value")
    // absent key exists with nil value - KVC returns the wrapped nil
    XCTAssertNotNil(absent) // The Optional.none is wrapped in Any
    // truly missing key returns nil
    XCTAssertNil(missing)
  }


  // MARK: - takeValue(_:forKey:) Tests

  func testDictionaryTakeValueForKey() throws {
    var dict : [ String : Any ] = [ "name" : "Charlie" ]

    try dict.takeValue("David", forKey: "name")

    XCTAssertEqual(dict["name"] as? String, "David")
  }

  func testDictionaryTakeValueNewKey() throws {
    var dict : [ String : Any ] = [:]

    try dict.takeValue("Eva", forKey: "name")

    XCTAssertEqual(dict["name"] as? String, "Eva")
  }

  func testDictionaryTakeValueDifferentTypes() throws {
    var dict : [ String : Any ] = [:]

    try dict.takeValue("string", forKey: "str")
    try dict.takeValue(42, forKey: "int")
    try dict.takeValue(true, forKey: "bool")

    XCTAssertEqual(dict["str"] as? String, "string")
    XCTAssertEqual(dict["int"] as? Int, 42)
    XCTAssertEqual(dict["bool"] as? Bool, true)
  }


  // MARK: - Error Tests

  func testDictionaryUnsupportedKeyType() {
    // Dictionary with Double keys - not String or Int
    var dict : [ Double : String ] = [ 1.5 : "value" ]

    XCTAssertThrowsError(try dict.takeValue("new", forKey: "1.5")) { error in
      guard case KeyValueCoding.Error.UnsupportedDictionaryKeyType = error else {
        XCTFail("Expected UnsupportedDictionaryKeyType error, got \(error)")
        return
      }
    }
  }

  func testDictionaryCannotCoerceValue() {
    // Typed dictionary that can't accept the value type
    var dict : [ String : Int ] = [ "count" : 1 ]

    XCTAssertThrowsError(try dict.takeValue("not an int", forKey: "count"))
    { error in
      guard case KeyValueCoding.Error.CannotCoerceValueForKey(_, _, let key)
              = error
      else {
        XCTFail("Expected CannotCoerceValueForKey error, got \(error)")
        return
      }
      XCTAssertEqual(key, "count")
    }
  }


  // MARK: - KVC Integration Tests

  func testDictionaryViaKeyValueCoding() {
    let dict : [ String : Any ] = [
      "first"  : "one",
      "second" : 2
    ]

    let first  = KeyValueCoding.value(forKey: "first", inObject: dict)
    let second = KeyValueCoding.value(forKey: "second", inObject: dict)

    XCTAssertEqual(first as? String, "one")
    XCTAssertEqual(second as? Int, 2)
  }

  func testNestedDictionaryKeypath() {
    let dict : [ String : Any ] = [
      "person" : [
        "name" : "Frank",
        "age"  : 40
      ] as [ String : Any ]
    ]

    let name = KeyValueCoding.value(forKeyPath: "person.name", inObject: dict)
    let age  = KeyValueCoding.value(forKeyPath: "person.age", inObject: dict)

    XCTAssertEqual(name as? String, "Frank")
    XCTAssertEqual(age as? Int, 40)
  }


  // MARK: - Linux

  static var allTests = [
    ( "testDictionaryValueForStringKey",    testDictionaryValueForStringKey    ),
    ( "testDictionaryValueForMissingKey",   testDictionaryValueForMissingKey   ),
    ( "testDictionaryValueForIntKey",       testDictionaryValueForIntKey       ),
    ( "testDictionaryValueForIntKeyInvalid", testDictionaryValueForIntKeyInvalid ),
    ( "testDictionaryValueForIntKeyMissing", testDictionaryValueForIntKeyMissing ),
    ( "testDictionaryOptionalValue",        testDictionaryOptionalValue        ),
    ( "testDictionaryTakeValueForKey",      testDictionaryTakeValueForKey      ),
    ( "testDictionaryTakeValueNewKey",      testDictionaryTakeValueNewKey      ),
    ( "testDictionaryTakeValueDifferentTypes",
                                          testDictionaryTakeValueDifferentTypes ),
    ( "testDictionaryUnsupportedKeyType",   testDictionaryUnsupportedKeyType   ),
    ( "testDictionaryCannotCoerceValue",    testDictionaryCannotCoerceValue    ),
    ( "testDictionaryViaKeyValueCoding",    testDictionaryViaKeyValueCoding    ),
    ( "testNestedDictionaryKeypath",        testNestedDictionaryKeypath        ),
  ]
}
