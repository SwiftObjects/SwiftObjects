//
//  ArrayKVCTests.swift
//  SwiftObjectsTests
//

import XCTest
@testable import SwiftObjects

class ArrayKVCTests: XCTestCase {

  // MARK: - Test Helper

  class Person: KeyValueCodingType {

    var name : String
    var age  : Int

    init(name: String, age: Int) {
      self.name = name
      self.age  = age
    }

    func value(forKey k: String) -> Any? {
      switch k {
        case "name": return name
        case "age":  return age
        default:     return nil
      }
    }
  }


  // MARK: - @count Operator Tests

  func testArrayCountOperator() {
    let array = [ 1, 2, 3, 4, 5 ]

    let count = array.value(forKey: "@count")

    XCTAssertEqual(count as? Int, 5)
  }

  func testArrayCountOperatorEmpty() {
    let array = [ Int ]()

    let count = array.value(forKey: "@count")

    XCTAssertEqual(count as? Int, 0)
  }

  func testArrayCountOperatorStrings() {
    let array = [ "a", "b", "c" ]

    let count = array.value(forKey: "@count")

    XCTAssertEqual(count as? Int, 3)
  }


  // MARK: - Element Mapping Tests

  func testArrayMapsKeyToElements() {
    let people = [
      Person(name: "Alice", age: 30),
      Person(name: "Bob", age: 25),
      Person(name: "Charlie", age: 35)
    ]

    let names = people.value(forKey: "name") as? [ String ]
    let ages  = people.value(forKey: "age") as? [ Int ]

    XCTAssertEqual(names, [ "Alice", "Bob", "Charlie" ])
    XCTAssertEqual(ages, [ 30, 25, 35 ])
  }

  func testArrayMapsKeyToElementsEmpty() {
    let people = [ Person ]()

    let names = people.value(forKey: "name")

    XCTAssertNotNil(names)
    XCTAssert((names as? [ Any ])?.isEmpty ?? false)
  }

  func testArrayMapsKeyMissingProperty() {
    let people = [
      Person(name: "Alice", age: 30),
      Person(name: "Bob", age: 25)
    ]

    let result = people.value(forKey: "nonexistent") as? [ Any? ]

    // Should return array of nils
    XCTAssertNotNil(result)
    XCTAssertEqual(result?.count, 2)
    XCTAssertNil(result?[0])
    XCTAssertNil(result?[1])
  }


  // MARK: - KVC Integration Tests

  func testArrayViaKeyValueCoding() {
    let array = [ "one", "two", "three" ]

    let count = KeyValueCoding.value(forKey: "@count", inObject: array)

    XCTAssertEqual(count as? Int, 3)
  }

  func testNestedArrayKeypath() {
    let data : [ String : Any ] = [
      "items" : [ 1, 2, 3, 4 ]
    ]

    let count = KeyValueCoding.value(forKeyPath: "items.@count", inObject: data)

    XCTAssertEqual(count as? Int, 4)
  }

  func testArrayOfDictionariesKeypath() {
    let items : [ [ String : Any ] ] = [
      [ "name" : "Item1", "price" : 10 ],
      [ "name" : "Item2", "price" : 20 ],
      [ "name" : "Item3", "price" : 30 ]
    ]

    let names  = items.value(forKey: "name") as? [ String ]
    let prices = items.value(forKey: "price") as? [ Int ]

    XCTAssertEqual(names, [ "Item1", "Item2", "Item3" ])
    XCTAssertEqual(prices, [ 10, 20, 30 ])
  }

  func testDeepNestedArrayAccess() {
    let data : [ String : Any ] = [
      "company" : [
        "employees" : [
          Person(name: "Alice", age: 30),
          Person(name: "Bob", age: 25)
        ]
      ] as [ String : Any ]
    ]

    let employees = KeyValueCoding.value(forKeyPath: "company.employees",
                                         inObject: data) as? [ Person ]

    XCTAssertEqual(employees?.count, 2)
  }


  // MARK: - Unknown @ Operators

  func testArrayUnknownAtOperator() {
    let array = [ 1, 2, 3 ]

    // Unknown @ operators should be treated as regular keys
    // which will map over elements, returning array of nils
    let result = array.value(forKey: "@unknown") as? [ Any? ]

    XCTAssertNotNil(result)
    XCTAssertEqual(result?.count, 3)
  }


  // MARK: - Linux

  static var allTests = [
    ( "testArrayCountOperator",           testArrayCountOperator           ),
    ( "testArrayCountOperatorEmpty",      testArrayCountOperatorEmpty      ),
    ( "testArrayCountOperatorStrings",    testArrayCountOperatorStrings    ),
    ( "testArrayMapsKeyToElements",       testArrayMapsKeyToElements       ),
    ( "testArrayMapsKeyToElementsEmpty",  testArrayMapsKeyToElementsEmpty  ),
    ( "testArrayMapsKeyMissingProperty",  testArrayMapsKeyMissingProperty  ),
    ( "testArrayViaKeyValueCoding",       testArrayViaKeyValueCoding       ),
    ( "testNestedArrayKeypath",           testNestedArrayKeypath           ),
    ( "testArrayOfDictionariesKeypath",   testArrayOfDictionariesKeypath   ),
    ( "testDeepNestedArrayAccess",        testDeepNestedArrayAccess        ),
    ( "testArrayUnknownAtOperator",       testArrayUnknownAtOperator       ),
  ]
}
