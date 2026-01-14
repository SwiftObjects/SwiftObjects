//
//  MirrorKVCTests.swift
//  SwiftObjectsTests
//

import XCTest
@testable import SwiftObjects

/**
 * Tests for Mirror-based reflection fallback in KVC.
 *
 * When an object doesn't conform to KeyValueCodingType, the KVC system
 * falls back to using Swift's Mirror API for property access.
 */
class MirrorKVCTests: XCTestCase {

  // MARK: - Test Helpers (Non-KVC Classes)

  /// Plain class without KVC conformance - uses Mirror fallback
  class PlainPerson {

    var name : String
    var age  : Int
    var email : String?

    init(name: String, age: Int, email: String? = nil) {
      self.name  = name
      self.age   = age
      self.email = email
    }
  }

  /// Subclass to test superclass property access
  class Employee: PlainPerson {

    var department : String
    var salary     : Int

    init(name: String, age: Int, department: String, salary: Int) {
      self.department = department
      self.salary     = salary
      super.init(name: name, age: age)
    }
  }

  /// Class with nested plain objects
  class Company {

    var name : String
    var ceo  : PlainPerson?

    init(name: String, ceo: PlainPerson? = nil) {
      self.name = name
      self.ceo  = ceo
    }
  }


  // MARK: - Basic Mirror Access Tests

  func testMirrorBasedAccessString() {
    let person = PlainPerson(name: "Alice", age: 30)

    let name = KeyValueCoding.value(forKey: "name", inObject: person)

    XCTAssertEqual(name as? String, "Alice")
  }

  func testMirrorBasedAccessInt() {
    let person = PlainPerson(name: "Bob", age: 25)

    let age = KeyValueCoding.value(forKey: "age", inObject: person)

    XCTAssertEqual(age as? Int, 25)
  }

  func testMirrorBasedAccessMissingKey() {
    let person = PlainPerson(name: "Charlie", age: 35)

    let result = KeyValueCoding.value(forKey: "nonexistent", inObject: person)

    XCTAssertNil(result)
  }


  // MARK: - Optional Unwrapping Tests

  func testMirrorOptionalPresent() {
    let person = PlainPerson(name: "Diana", age: 28, email: "diana@example.com")

    let email = KeyValueCoding.value(forKey: "email", inObject: person)

    XCTAssertEqual(email as? String, "diana@example.com")
  }

  func testMirrorOptionalNil() {
    let person = PlainPerson(name: "Eva", age: 22)
    // email is nil

    let email = KeyValueCoding.value(forKey: "email", inObject: person)

    XCTAssertNil(email)
  }


  // MARK: - Superclass Property Access Tests

  func testMirrorSuperclassProperty() {
    let employee = Employee(name: "Frank", age: 40,
                            department: "Engineering", salary: 100000)

    // Access subclass properties
    let dept   = KeyValueCoding.value(forKey: "department", inObject: employee)
    let salary = KeyValueCoding.value(forKey: "salary", inObject: employee)

    XCTAssertEqual(dept as? String, "Engineering")
    XCTAssertEqual(salary as? Int, 100000)

    // Access superclass properties
    let name = KeyValueCoding.value(forKey: "name", inObject: employee)
    let age  = KeyValueCoding.value(forKey: "age", inObject: employee)

    XCTAssertEqual(name as? String, "Frank")
    XCTAssertEqual(age as? Int, 40)
  }


  // MARK: - Nested Object Access Tests

  func testMirrorNestedObjectAccess() {
    let ceo     = PlainPerson(name: "Grace", age: 50)
    let company = Company(name: "TechCorp", ceo: ceo)

    // Access nested object via keypath
    let ceoName = KeyValueCoding.value(forKeyPath: "ceo.name", inObject: company)
    let ceoAge  = KeyValueCoding.value(forKeyPath: "ceo.age", inObject: company)

    XCTAssertEqual(ceoName as? String, "Grace")
    XCTAssertEqual(ceoAge as? Int, 50)
  }

  func testMirrorNestedObjectNil() {
    let company = Company(name: "StartupCo")
    // ceo is nil

    let ceoName = KeyValueCoding.value(forKeyPath: "ceo.name", inObject: company)

    XCTAssertNil(ceoName)
  }


  // MARK: - defaultValue Function Tests

  func testDefaultValueDirect() {
    let person = PlainPerson(name: "Henry", age: 45)

    let name = KeyValueCoding.defaultValue(forKey: "name", inObject: person)

    XCTAssertEqual(name as? String, "Henry")
  }

  func testDefaultValueNilObject() {
    let result = KeyValueCoding.defaultValue(forKey: "name", inObject: nil)

    XCTAssertNil(result)
  }


  // MARK: - Dictionary via Mirror Tests

  func testMirrorDictionaryAccess() {
    // Dictionaries also use Mirror-based access when not going through
    // the Dictionary extension
    let dict : [ String : Any ] = [ "key" : "value" ]

    // This goes through Mirror-based dictionary lookup
    let result = KeyValueCoding.defaultValue(forKey: "key", inObject: dict)

    XCTAssertEqual(result as? String, "value")
  }


  // MARK: - Linux

  static var allTests = [
    ( "testMirrorBasedAccessString",     testMirrorBasedAccessString     ),
    ( "testMirrorBasedAccessInt",        testMirrorBasedAccessInt        ),
    ( "testMirrorBasedAccessMissingKey", testMirrorBasedAccessMissingKey ),
    ( "testMirrorOptionalPresent",       testMirrorOptionalPresent       ),
    ( "testMirrorOptionalNil",           testMirrorOptionalNil           ),
    ( "testMirrorSuperclassProperty",    testMirrorSuperclassProperty    ),
    ( "testMirrorNestedObjectAccess",    testMirrorNestedObjectAccess    ),
    ( "testMirrorNestedObjectNil",       testMirrorNestedObjectNil       ),
    ( "testDefaultValueDirect",          testDefaultValueDirect          ),
    ( "testDefaultValueNilObject",       testDefaultValueNilObject       ),
    ( "testMirrorDictionaryAccess",      testMirrorDictionaryAccess      ),
  ]
}
