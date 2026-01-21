//
//  KeyValueCodingTests.swift
//  SwiftObjectsTests
//

import XCTest
@testable import SwiftObjects

class KeyValueCodingTests: XCTestCase {

  // MARK: - Test Helper Classes

  class KVCPerson: KeyValueCodingType, MutableKeyValueCodingType {

    var name    : String = ""
    var age     : Int = 0
    var active  : Bool = false
    var address : KVCAddress?
    var tags    : [ String ] = []

    func value(forKey k: String) -> Any? {
      switch k {
        case "name":    return name
        case "age":     return age
        case "active":  return active
        case "address": return address
        case "tags":    return tags
        default:        return handleQueryWithUnboundKey(k)
      }
    }

    func takeValue(_ value: Any?, forKey k: String) throws {
      switch k {
        case "name":    name    = value as? String ?? ""
        case "age":     age     = value as? Int ?? 0
        case "active":  active  = value as? Bool ?? false
        case "address": address = value as? KVCAddress
        case "tags":    tags    = value as? [ String ] ?? []
        default:        try handleTakeValue(value, forUnboundKey: k)
      }
    }
  }

  class KVCAddress: KeyValueCodingType, MutableKeyValueCodingType {

    var street : String = ""
    var city   : String = ""
    var zip    : String?
    var country : KVCCountry?

    func value(forKey k: String) -> Any? {
      switch k {
        case "street":  return street
        case "city":    return city
        case "zip":     return zip
        case "country": return country
        default:        return handleQueryWithUnboundKey(k)
      }
    }

    func takeValue(_ value: Any?, forKey k: String) throws {
      switch k {
        case "street":  street  = value as? String ?? ""
        case "city":    city    = value as? String ?? ""
        case "zip":     zip     = value as? String
        case "country": country = value as? KVCCountry
        default:        try handleTakeValue(value, forUnboundKey: k)
      }
    }
  }

  class KVCCountry: KeyValueCodingType, MutableKeyValueCodingType {

    var name : String = ""
    var code : String = ""

    func value(forKey k: String) -> Any? {
      switch k {
        case "name": return name
        case "code": return code
        default:     return handleQueryWithUnboundKey(k)
      }
    }

    func takeValue(_ value: Any?, forKey k: String) throws {
      switch k {
        case "name": name = value as? String ?? ""
        case "code": code = value as? String ?? ""
        default:     try handleTakeValue(value, forUnboundKey: k)
      }
    }
  }

  class KVCDynamicObject: KeyValueCodingType, MutableKeyValueCodingType {

    var storage : [ String : Any ] = [:]

    func value(forKey k: String) -> Any? {
      return storage[k]
    }

    func takeValue(_ value: Any?, forKey k: String) throws {
      if let v = value {
        storage[k] = v
      }
      else {
        storage.removeValue(forKey: k)
      }
    }

    func handleQueryWithUnboundKey(_ key: String) -> Any? {
      return storage[key]
    }

    func handleTakeValue(_ value: Any?, forUnboundKey k: String) throws {
      if let v = value {
        storage[k] = v
      }
      else {
        storage.removeValue(forKey: k)
      }
    }
  }


  // MARK: - Basic Key Access Tests

  func testValueForKeySimple() {
    let person = KVCPerson()
    person.name = "John"
    person.age  = 30

    let name = KeyValueCoding.value(forKey: "name", inObject: person)
    let age  = KeyValueCoding.value(forKey: "age", inObject: person)

    XCTAssertEqual(name as? String, "John")
    XCTAssertEqual(age as? Int, 30)
  }

  func testValueForKeyNilObject() {
    let result = KeyValueCoding.value(forKey: "name", inObject: nil)
    XCTAssertNil(result)
  }

  func testValueForKeyMissing() {
    let person = KVCPerson()
    let result = KeyValueCoding.value(forKey: "nonexistent", inObject: person)
    XCTAssertNil(result)
  }

  func testTakeValueForKey() throws {
    let person = KVCPerson()

    try KeyValueCoding.takeValue("Jane", forKey: "name", inObject: person)
    try KeyValueCoding.takeValue(25, forKey: "age", inObject: person)

    XCTAssertEqual(person.name, "Jane")
    XCTAssertEqual(person.age, 25)
  }

  func testTakeValueForKeyNilValue() throws {
    let person = KVCPerson()
    person.address = KVCAddress()

    try KeyValueCoding.takeValue(nil, forKey: "address", inObject: person)

    XCTAssertNil(person.address)
  }

  func testTakeValueForKeyNilObject() throws {
    // Should be a no-op (nil messaging)
    try KeyValueCoding.takeValue("test", forKey: "name", inObject: nil)
    // No assertion - just verifying no crash
  }


  // MARK: - Keypath Access Tests

  func testValueForKeyPathSimple() {
    let person = KVCPerson()
    person.name = "Alice"

    let result = KeyValueCoding.value(forKeyPath: "name", inObject: person)
    XCTAssertEqual(result as? String, "Alice")
  }

  func testValueForKeyPathNested() {
    let person  = KVCPerson()
    let address = KVCAddress()
    address.city  = "Berlin"
    person.address = address

    let result = KeyValueCoding.value(forKeyPath: "address.city", inObject: person)
    XCTAssertEqual(result as? String, "Berlin")
  }

  func testValueForKeyPathDeep() {
    let person  = KVCPerson()
    let address = KVCAddress()
    let country = KVCCountry()
    country.name    = "Germany"
    country.code    = "DE"
    address.country = country
    person.address  = address

    let name = KeyValueCoding.value(forKeyPath: "address.country.name",
                                    inObject: person)
    let code = KeyValueCoding.value(forKeyPath: "address.country.code",
                                    inObject: person)

    XCTAssertEqual(name as? String, "Germany")
    XCTAssertEqual(code as? String, "DE")
  }

  func testValueForKeyPathNilIntermediate() {
    let person = KVCPerson()
    // address is nil

    let result = KeyValueCoding.value(forKeyPath: "address.city", inObject: person)
    XCTAssertNil(result)
  }

  func testValueForKeyPathArrayForm() {
    let person  = KVCPerson()
    let address = KVCAddress()
    address.city   = "Munich"
    person.address = address

    let result = KeyValueCoding.value(forKeyPath: [ "address", "city" ],
                                      inObject: person)
    XCTAssertEqual(result as? String, "Munich")
  }

  func testTakeValueForKeyPath() throws {
    let person  = KVCPerson()
    let address = KVCAddress()
    person.address = address

    try KeyValueCoding.takeValue("Hamburg", forKeyPath: "address.city",
                                 inObject: person)

    XCTAssertEqual(person.address?.city, "Hamburg")
  }

  func testTakeValueForKeyPathArrayForm() throws {
    let person  = KVCPerson()
    let address = KVCAddress()
    person.address = address

    try KeyValueCoding.takeValue("Frankfurt", forKeyPath: [ "address", "city" ],
                                 inObject: person)

    XCTAssertEqual(person.address?.city, "Frankfurt")
  }

  func testTakeValueForKeyPathNilIntermediate() throws {
    let person = KVCPerson()
    // address is nil - should be a no-op

    try KeyValueCoding.takeValue("Nowhere", forKeyPath: "address.city",
                                 inObject: person)

    // No crash, address still nil
    XCTAssertNil(person.address)
  }


  // MARK: - Batch Operations Tests

  func testValuesForKeys() {
    let person = KVCPerson()
    person.name   = "Bob"
    person.age    = 40
    person.active = true

    let values = KeyValueCoding.values(forKeys: [ "name", "age", "active" ],
                                       inObject: person)

    XCTAssertEqual(values["name"] as? String, "Bob")
    XCTAssertEqual(values["age"] as? Int, 40)
    XCTAssertEqual(values["active"] as? Bool, true)
  }

  func testValuesForKeysNilObject() {
    let values = KeyValueCoding.values(forKeys: [ "name", "age" ], inObject: nil)
    XCTAssert(values.isEmpty)
  }

  func testValuesForKeysMissingKeys() {
    let person = KVCPerson()
    person.name = "Charlie"

    let values = KeyValueCoding.values(forKeys: [ "name", "nonexistent" ],
                                       inObject: person)

    XCTAssertEqual(values["name"] as? String, "Charlie")
    XCTAssertNil(values["nonexistent"])
    XCTAssertEqual(values.count, 1)
  }

  func testTakeValuesForKeys() throws {
    let person = KVCPerson()

    try person.takeValuesForKeys([
      "name"   : "Diana",
      "age"    : 35,
      "active" : true
    ])

    XCTAssertEqual(person.name, "Diana")
    XCTAssertEqual(person.age, 35)
    XCTAssertEqual(person.active, true)
  }


  // MARK: - Error Handling Tests

  func testEmptyKeyPathError() {
    let person = KVCPerson()

    XCTAssertThrowsError(
      try KeyValueCoding.takeValue("test", forKeyPath: "", inObject: person)
    ) { error in
      guard case KeyValueCoding.Error.EmptyKeyPath = error else {
        XCTFail("Expected EmptyKeyPath error, got \(error)")
        return
      }
    }
  }

  func testEmptyKeyPathArrayError() {
    let person = KVCPerson()

    XCTAssertThrowsError(
      try KeyValueCoding.takeValue("test", forKeyPath: [ String ](),
                                   inObject: person)
    ) { error in
      guard case KeyValueCoding.Error.EmptyKeyPath = error else {
        XCTFail("Expected EmptyKeyPath error, got \(error)")
        return
      }
    }
  }

  func testCannotTakeValueForKeyError() {
    // Using a class that conforms to KVC but has an unknown key
    let person = KVCPerson()

    XCTAssertThrowsError(
      try KeyValueCoding.takeValue("new", forKey: "nonexistent", inObject: person)
    ) { error in
      guard case KeyValueCoding.Error.CannotTakeValueForKey(let key) = error
      else {
        XCTFail("Expected CannotTakeValueForKey error, got \(error)")
        return
      }
      XCTAssertEqual(key, "nonexistent")
    }
  }


  // MARK: - Unbound Key Handling Tests

  func testHandleQueryWithUnboundKey() {
    let dynamic = KVCDynamicObject()
    dynamic.storage["custom"] = "value"

    let result = KeyValueCoding.value(forKey: "custom", inObject: dynamic)
    XCTAssertEqual(result as? String, "value")
  }

  func testHandleTakeValueForUnboundKey() throws {
    let dynamic = KVCDynamicObject()

    try KeyValueCoding.takeValue("stored", forKey: "dynamic", inObject: dynamic)

    XCTAssertEqual(dynamic.storage["dynamic"] as? String, "stored")
  }

  func testDefaultUnboundKeyReturnsNil() {
    let person = KVCPerson()
    let result = person.handleQueryWithUnboundKey("unknown")
    XCTAssertNil(result)
  }

  func testDefaultUnboundKeyThrows() {
    let person = KVCPerson()

    XCTAssertThrowsError(
      try person.handleTakeValue("test", forUnboundKey: "unknown")
    ) { error in
      guard case KeyValueCoding.Error.CannotTakeValueForKey(let key) = error
      else {
        XCTFail("Expected CannotTakeValueForKey error, got \(error)")
        return
      }
      XCTAssertEqual(key, "unknown")
    }
  }


  // MARK: - Linux

  static var allTests = [
    ( "testValueForKeySimple",              testValueForKeySimple              ),
    ( "testValueForKeyNilObject",           testValueForKeyNilObject           ),
    ( "testValueForKeyMissing",             testValueForKeyMissing             ),
    ( "testTakeValueForKey",                testTakeValueForKey                ),
    ( "testTakeValueForKeyNilValue",        testTakeValueForKeyNilValue        ),
    ( "testTakeValueForKeyNilObject",       testTakeValueForKeyNilObject       ),
    ( "testValueForKeyPathSimple",          testValueForKeyPathSimple          ),
    ( "testValueForKeyPathNested",          testValueForKeyPathNested          ),
    ( "testValueForKeyPathDeep",            testValueForKeyPathDeep            ),
    ( "testValueForKeyPathNilIntermediate", testValueForKeyPathNilIntermediate ),
    ( "testValueForKeyPathArrayForm",       testValueForKeyPathArrayForm       ),
    ( "testTakeValueForKeyPath",            testTakeValueForKeyPath            ),
    ( "testTakeValueForKeyPathArrayForm",   testTakeValueForKeyPathArrayForm   ),
    ( "testTakeValueForKeyPathNilIntermediate",
                                         testTakeValueForKeyPathNilIntermediate ),
    ( "testValuesForKeys",                  testValuesForKeys                  ),
    ( "testValuesForKeysNilObject",         testValuesForKeysNilObject         ),
    ( "testValuesForKeysMissingKeys",       testValuesForKeysMissingKeys       ),
    ( "testTakeValuesForKeys",              testTakeValuesForKeys              ),
    ( "testEmptyKeyPathError",              testEmptyKeyPathError              ),
    ( "testEmptyKeyPathArrayError",         testEmptyKeyPathArrayError         ),
    ( "testCannotTakeValueForKeyError",     testCannotTakeValueForKeyError     ),
    ( "testHandleQueryWithUnboundKey",      testHandleQueryWithUnboundKey      ),
    ( "testHandleTakeValueForUnboundKey",   testHandleTakeValueForUnboundKey   ),
    ( "testDefaultUnboundKeyReturnsNil",    testDefaultUnboundKeyReturnsNil    ),
    ( "testDefaultUnboundKeyThrows",        testDefaultUnboundKeyThrows        ),
  ]
}
