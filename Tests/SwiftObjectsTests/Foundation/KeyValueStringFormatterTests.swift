//
//  KeyValueStringFormatterTests.swift
//  SwiftObjectsTests
//

import XCTest
@testable import SwiftObjects

/**
 * Tests for KeyValueStringFormatter, a printf-style formatter that uses
 * KVC keypaths for value substitution.
 *
 * Format syntax:
 * - `%(key)s` - String format with KVC keypath
 * - `%(key)@` - Alternative string format
 * - `%(key)i` - Integer format
 * - `%(key)U` - URL encoded format
 * - `%%` - Escaped percent
 */
class KeyValueStringFormatterTests: XCTestCase {

  // MARK: - Test Helper

  class Person: KeyValueCodingType {

    var firstName : String
    var lastName  : String
    var age       : Int
    var address   : Address?

    init(firstName: String, lastName: String, age: Int,
         address: Address? = nil)
    {
      self.firstName = firstName
      self.lastName  = lastName
      self.age       = age
      self.address   = address
    }

    func value(forKey k: String) -> Any? {
      switch k {
        case "firstName": return firstName
        case "lastName":  return lastName
        case "age":       return age
        case "address":   return address
        default:          return nil
      }
    }
  }

  class Address: KeyValueCodingType {

    var city    : String
    var country : String

    init(city: String, country: String) {
      self.city    = city
      self.country = country
    }

    func value(forKey k: String) -> Any? {
      switch k {
        case "city":    return city
        case "country": return country
        default:        return nil
      }
    }
  }


  // MARK: - String Format Tests

  func testSimpleStringFormat() {
    let person = Person(firstName: "Alice", lastName: "Smith", age: 30)

    let result = KeyValueStringFormatter.format("%(firstName)s", object: person)

    XCTAssertEqual(result, "Alice")
  }

  func testStringFormatAlternate() {
    let person = Person(firstName: "Bob", lastName: "Jones", age: 25)

    let result = KeyValueStringFormatter.format("%(lastName)@", object: person)

    XCTAssertEqual(result, "Jones")
  }

  func testMultipleStringFormats() {
    let person = Person(firstName: "Charlie", lastName: "Brown", age: 35)

    let result = KeyValueStringFormatter.format(
      "%(firstName)s %(lastName)s",
      object: person
    )

    XCTAssertEqual(result, "Charlie Brown")
  }

  func testStringFormatNilValue() {
    let person = Person(firstName: "Diana", lastName: "Ross", age: 40)
    // address is nil

    let result = KeyValueStringFormatter.format("%(address)s", object: person)

    XCTAssertEqual(result, "<nil>")
  }


  // MARK: - Integer Format Tests

  func testIntegerFormat() {
    let person = Person(firstName: "Eve", lastName: "Adams", age: 28)

    let result = KeyValueStringFormatter.format("Age: %(age)i", object: person)

    XCTAssertEqual(result, "Age: 28")
  }

  func testIntegerFormatNilValue() {
    let person = Person(firstName: "Frank", lastName: "Miller", age: 45)

    // Using a nil value (address) with integer format
    let result = KeyValueStringFormatter.format("%(address)i", object: person)

    XCTAssertEqual(result, "0")
  }


  // MARK: - URL Encoded Format Tests

  func testURLEncodedFormat() {
    let dict : [ String : Any ] = [ "query" : "hello world" ]

    let result = KeyValueStringFormatter.format("q=%(query)U", object: dict)

    XCTAssertEqual(result, "q=hello%20world")
  }

  func testURLEncodedFormatNonString() {
    let dict : [ String : Any ] = [ "count" : 42 ]

    let result = KeyValueStringFormatter.format("n=%(count)U", object: dict)

    // Non-string values are converted to string first
    XCTAssertEqual(result, "n=42")
  }

  func testURLEncodedFormatNilValue() {
    let dict : [ String : Any ] = [:]

    let result = KeyValueStringFormatter.format("q=%(missing)U", object: dict)

    XCTAssertEqual(result, "q=<nil>")
  }


  // MARK: - Nested Keypath Tests

  func testNestedKeypath() {
    let address = Address(city: "Berlin", country: "Germany")
    let person  = Person(firstName: "Greta", lastName: "Muller", age: 30,
                         address: address)

    let result = KeyValueStringFormatter.format(
      "%(address.city)s, %(address.country)s",
      object: person
    )

    XCTAssertEqual(result, "Berlin, Germany")
  }

  func testNestedKeypathNilIntermediate() {
    let person = Person(firstName: "Hans", lastName: "Schmidt", age: 40)
    // address is nil

    let result = KeyValueStringFormatter.format("%(address.city)s",
                                                object: person)

    XCTAssertEqual(result, "<nil>")
  }


  // MARK: - Escaped Percent Tests

  func testEscapedPercent() {
    let person = Person(firstName: "Ivy", lastName: "Green", age: 25)

    let result = KeyValueStringFormatter.format("100%% complete",
                                                object: person)

    XCTAssertEqual(result, "100% complete")
  }

  func testEscapedPercentWithFormat() {
    let person = Person(firstName: "Jack", lastName: "Black", age: 50)

    let result = KeyValueStringFormatter.format(
      "%(firstName)s scored 100%%!",
      object: person
    )

    XCTAssertEqual(result, "Jack scored 100%!")
  }


  // MARK: - No Patterns Tests

  func testNoPatterns() {
    let person = Person(firstName: "Karen", lastName: "White", age: 35)

    let result = KeyValueStringFormatter.format("Hello World", object: person)

    XCTAssertEqual(result, "Hello World")
  }

  func testEmptyFormat() {
    let person = Person(firstName: "Leo", lastName: "King", age: 45)

    let result = KeyValueStringFormatter.format("", object: person)

    XCTAssertEqual(result, "")
  }


  // MARK: - requiresAll Tests
  //
  // Note: The KeyValueHandler has `lastKeyWasMiss = false` hardcoded,
  // so requiresAll only works for array-based formatting, not object-based.

  func testRequiresAllObjectBased() {
    // For object-based formatting, requiresAll doesn't work
    // (KeyValueHandler.lastKeyWasMiss is always false)
    let person = Person(firstName: "Mike", lastName: "Stone", age: 30)

    let fmt = KeyValueStringFormatter(format: "%(nonexistent)s",
                                      requiresAll: true)
    let result = fmt.string(for: person)

    // Returns "<nil>" instead of nil due to implementation
    XCTAssertEqual(result, "<nil>")
  }

  func testRequiresAllPresent() {
    let person = Person(firstName: "Nancy", lastName: "Drew", age: 25)

    let fmt = KeyValueStringFormatter(format: "%(firstName)s",
                                      requiresAll: true)
    let result = fmt.string(for: person)

    XCTAssertEqual(result, "Nancy")
  }

  func testRequiresAllArrayMissing() {
    // requiresAll works for array-based formatting
    let fmt = KeyValueStringFormatter(format: "%s %s %s", requiresAll: true)
    let result = fmt.string(for: [ "a", "b" ] as [ Any? ])

    // Only 2 values provided, but 3 expected - returns nil
    XCTAssertNil(result)
  }

  func testRequiresAllArrayPresent() {
    let fmt = KeyValueStringFormatter(format: "%s %s", requiresAll: true)
    let result = fmt.string(for: [ "Hello", "World" ] as [ Any? ])

    XCTAssertEqual(result, "Hello World")
  }


  // MARK: - Array Positional Format Tests

  func testArrayPositional() {
    let result = KeyValueStringFormatter.format("%s %s", "Hello", "World")

    XCTAssertEqual(result, "Hello World")
  }

  func testArrayPositionalMultiple() {
    let result = KeyValueStringFormatter.format(
      "%s, %s, and %s",
      "Alice", "Bob", "Charlie"
    )

    XCTAssertEqual(result, "Alice, Bob, and Charlie")
  }

  func testArrayPositionalInteger() {
    let result = KeyValueStringFormatter.format(
      "Count: %i items",
      42
    )

    XCTAssertEqual(result, "Count: 42 items")
  }

  func testArrayPositionalMixed() {
    let result = KeyValueStringFormatter.format(
      "%s has %i apples",
      "Alice", 5
    )

    XCTAssertEqual(result, "Alice has 5 apples")
  }


  // MARK: - Array Key Access Tests

  func testArrayCountKey() {
    let result = KeyValueStringFormatter.format(
      "Total: %(count)i",
      "a", "b", "c"
    )

    XCTAssertEqual(result, "Total: 3")
  }

  func testArrayLengthKey() {
    let result = KeyValueStringFormatter.format(
      "Length: %(length)i",
      "x", "y"
    )

    XCTAssertEqual(result, "Length: 2")
  }

  func testArraySizeKey() {
    let result = KeyValueStringFormatter.format(
      "Size: %(size)i",
      1, 2, 3, 4
    )

    XCTAssertEqual(result, "Size: 4")
  }

  func testArrayIndexedAccess() {
    let result = KeyValueStringFormatter.format(
      "Second: %(1)s, First: %(0)s",
      "Alpha", "Beta", "Gamma"
    )

    XCTAssertEqual(result, "Second: Beta, First: Alpha")
  }

  func testArrayIndexedAccessOutOfBounds() {
    let result = KeyValueStringFormatter.format(
      "Item: %(10)s",
      "only", "two"
    )

    XCTAssertEqual(result, "Item: <nil>")
  }


  // MARK: - Dictionary Object Tests

  func testDictionaryObject() {
    let dict : [ String : Any ] = [
      "name" : "Test",
      "value" : 123
    ]

    let result = KeyValueStringFormatter.format(
      "%(name)s: %(value)i",
      object: dict
    )

    XCTAssertEqual(result, "Test: 123")
  }


  // MARK: - Edge Cases

  func testTrailingPercent() {
    let person = Person(firstName: "Pat", lastName: "Quinn", age: 30)

    let result = KeyValueStringFormatter.format("Value%", object: person)

    XCTAssertEqual(result, "Value%")
  }

  func testUnknownFormatSpecifier() {
    let dict : [ String : Any ] = [ "value" : "test" ]

    // Unknown format specifier 'x' should be passed through
    let result = KeyValueStringFormatter.format("%(value)x", object: dict)

    XCTAssertEqual(result, "%(value)x")
  }

  func testIncompletePattern() {
    let person = Person(firstName: "Quinn", lastName: "Ross", age: 35)

    // Incomplete pattern - missing closing paren
    let result = KeyValueStringFormatter.format("%(firstName", object: person)

    XCTAssertEqual(result, "%(firstName")
  }

  func testNilObject() {
    let result = KeyValueStringFormatter.format("%(name)s", object: nil)

    XCTAssertEqual(result, "<nil>")
  }


  // MARK: - Linux

  static var allTests = [
    ( "testSimpleStringFormat",             testSimpleStringFormat             ),
    ( "testStringFormatAlternate",          testStringFormatAlternate          ),
    ( "testMultipleStringFormats",          testMultipleStringFormats          ),
    ( "testStringFormatNilValue",           testStringFormatNilValue           ),
    ( "testIntegerFormat",                  testIntegerFormat                  ),
    ( "testIntegerFormatNilValue",          testIntegerFormatNilValue          ),
    ( "testURLEncodedFormat",               testURLEncodedFormat               ),
    ( "testURLEncodedFormatNonString",      testURLEncodedFormatNonString      ),
    ( "testURLEncodedFormatNilValue",       testURLEncodedFormatNilValue       ),
    ( "testNestedKeypath",                  testNestedKeypath                  ),
    ( "testNestedKeypathNilIntermediate",   testNestedKeypathNilIntermediate   ),
    ( "testEscapedPercent",                 testEscapedPercent                 ),
    ( "testEscapedPercentWithFormat",       testEscapedPercentWithFormat       ),
    ( "testNoPatterns",                     testNoPatterns                     ),
    ( "testEmptyFormat",                    testEmptyFormat                    ),
    ( "testRequiresAllObjectBased",         testRequiresAllObjectBased         ),
    ( "testRequiresAllPresent",             testRequiresAllPresent             ),
    ( "testRequiresAllArrayMissing",        testRequiresAllArrayMissing        ),
    ( "testRequiresAllArrayPresent",        testRequiresAllArrayPresent        ),
    ( "testArrayPositional",                testArrayPositional                ),
    ( "testArrayPositionalMultiple",        testArrayPositionalMultiple        ),
    ( "testArrayPositionalInteger",         testArrayPositionalInteger         ),
    ( "testArrayPositionalMixed",           testArrayPositionalMixed           ),
    ( "testArrayCountKey",                  testArrayCountKey                  ),
    ( "testArrayLengthKey",                 testArrayLengthKey                 ),
    ( "testArraySizeKey",                   testArraySizeKey                   ),
    ( "testArrayIndexedAccess",             testArrayIndexedAccess             ),
    ( "testArrayIndexedAccessOutOfBounds",  testArrayIndexedAccessOutOfBounds  ),
    ( "testDictionaryObject",               testDictionaryObject               ),
    ( "testTrailingPercent",                testTrailingPercent                ),
    ( "testUnknownFormatSpecifier",         testUnknownFormatSpecifier         ),
    ( "testIncompletePattern",              testIncompletePattern              ),
    ( "testNilObject",                      testNilObject                      ),
  ]
}
