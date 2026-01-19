//
//  WOKeyPathAssociationTests.swift
//  SwiftObjectsTests
//

import XCTest
@testable import SwiftObjects

class WOKeyPathAssociationTests: XCTestCase {

  // MARK: - Test Objects

  class Address: KeyValueCodingType {

    var city    : String = ""
    var country : String = ""

    func value(forKey key: String) -> Any? {
      switch key {
        case "city":    return city
        case "country": return country
        default:        return nil
      }
    }

    func takeValue(_ value: Any?, forKey key: String) throws {
      switch key {
        case "city":    city    = (value as? String) ?? ""
        case "country": country = (value as? String) ?? ""
        default: break
      }
    }
  }

  class Person: KeyValueCodingType {

    var name    : String  = ""
    var age     : Int     = 0
    var address : Address = Address()

    func value(forKey key: String) -> Any? {
      switch key {
        case "name":    return name
        case "age":     return age
        case "address": return address
        default:        return nil
      }
    }

    func takeValue(_ value: Any?, forKey key: String) throws {
      switch key {
        case "name":    name = (value as? String) ?? ""
        case "age":     age  = (value as? Int) ?? 0
        case "address":
          if let a = value as? Address { address = a }
        default: break
      }
    }
  }


  // MARK: - WOKeyPathAssociation Tests

  func testSimpleKeyPath() {
    let person = Person()
    person.name = "Alice"

    let assoc = WOKeyPathAssociation("name")

    let result = assoc.value(in: person)
    XCTAssertEqual(result as? String, "Alice")
  }

  func testNestedKeyPath() {
    let person = Person()
    person.address.city = "Berlin"

    let assoc = WOKeyPathAssociation("address.city")

    let result = assoc.value(in: person)
    XCTAssertEqual(result as? String, "Berlin")
  }

  func testDeepNestedKeyPath() {
    let person = Person()
    person.address.country = "Germany"

    let assoc = WOKeyPathAssociation("address.country")

    let result = assoc.value(in: person)
    XCTAssertEqual(result as? String, "Germany")
  }

  func testSetValue() throws {
    let person = Person()
    person.name = "Bob"

    let assoc = WOKeyPathAssociation("name")

    try assoc.setValue("Charlie", in: person)

    XCTAssertEqual(person.name, "Charlie")
  }

  func testSetNestedValue() throws {
    let person = Person()
    person.address.city = "Munich"

    let assoc = WOKeyPathAssociation("address.city")

    try assoc.setValue("Hamburg", in: person)

    XCTAssertEqual(person.address.city, "Hamburg")
  }

  func testIsValueConstant() {
    let assoc = WOKeyPathAssociation("some.path")

    XCTAssertFalse(assoc.isValueConstant)
  }

  func testIsValueSettable() {
    let assoc = WOKeyPathAssociation("some.path")

    XCTAssertTrue(assoc.isValueSettable)
  }

  func testKeyPathProperty() {
    let assoc = WOKeyPathAssociation("person.address.city")

    XCTAssertEqual(assoc.keyPath, "person.address.city")
  }

  func testPathComponents() {
    let assoc = WOKeyPathAssociation("a.b.c")

    XCTAssertEqual(assoc.path, [ "a", "b", "c" ])
  }

  func testNilComponent() {
    // When intermediate value is nil, should return nil
    let assoc = WOKeyPathAssociation("address.city")

    let result = assoc.value(in: nil)
    XCTAssertNil(result)
  }


  // MARK: - WOKeyAssociation Tests

  func testSimpleKeyValue() {
    let person = Person()
    person.name = "Dana"

    let assoc = WOKeyAssociation("name")

    let result = assoc.value(in: person)
    XCTAssertEqual(result as? String, "Dana")
  }

  func testSimpleKeySetValue() throws {
    let person = Person()

    let assoc = WOKeyAssociation("name")

    try assoc.setValue("Eve", in: person)

    XCTAssertEqual(person.name, "Eve")
  }

  func testKeyAssociationIsNotConstant() {
    let assoc = WOKeyAssociation("key")

    XCTAssertFalse(assoc.isValueConstant)
  }

  func testKeyAssociationIsSettable() {
    let assoc = WOKeyAssociation("key")

    XCTAssertTrue(assoc.isValueSettable)
  }

  func testKeyAssociationKeyPath() {
    let assoc = WOKeyAssociation("someKey")

    XCTAssertEqual(assoc.keyPath, "someKey")
  }


  // MARK: - Linux

  static var allTests = [
    ( "testSimpleKeyPath",            testSimpleKeyPath            ),
    ( "testNestedKeyPath",            testNestedKeyPath            ),
    ( "testDeepNestedKeyPath",        testDeepNestedKeyPath        ),
    ( "testSetValue",                 testSetValue                 ),
    ( "testSetNestedValue",           testSetNestedValue           ),
    ( "testIsValueConstant",          testIsValueConstant          ),
    ( "testIsValueSettable",          testIsValueSettable          ),
    ( "testKeyPathProperty",          testKeyPathProperty          ),
    ( "testPathComponents",           testPathComponents           ),
    ( "testNilComponent",             testNilComponent             ),
    ( "testSimpleKeyValue",           testSimpleKeyValue           ),
    ( "testSimpleKeySetValue",        testSimpleKeySetValue        ),
    ( "testKeyAssociationIsNotConstant", testKeyAssociationIsNotConstant ),
    ( "testKeyAssociationIsSettable", testKeyAssociationIsSettable ),
    ( "testKeyAssociationKeyPath",    testKeyAssociationKeyPath    ),
  ]
}
