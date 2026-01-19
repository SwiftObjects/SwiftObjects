//
//  WOAssociationFactoryTests.swift
//  SwiftObjectsTests
//

import XCTest
@testable import SwiftObjects

class WOAssociationFactoryTests: XCTestCase {

  // MARK: - associationWithKeyPath Tests

  func testKeyPathWithDot() throws {
    let assoc = try WOAssociationFactory.associationWithKeyPath("person.name")

    XCTAssert(assoc is WOKeyPathAssociation)
    XCTAssertEqual(assoc.keyPath, "person.name")
  }

  func testKeyPathWithoutDot() throws {
    let assoc = try WOAssociationFactory.associationWithKeyPath("name")

    XCTAssert(assoc is WOKeyAssociation)
    XCTAssertEqual(assoc.keyPath, "name")
  }

  func testEmptyKeyPath() {
    XCTAssertThrowsError(
      try WOAssociationFactory.associationWithKeyPath("")
    ) { error in
      guard case WOAssociationFactory.AssociationError.emptyKeyPath = error
      else {
        XCTFail("Expected emptyKeyPath error, got \(error)")
        return
      }
    }
  }


  // MARK: - associationWithValue Tests

  func testValueAssociationWithString() {
    let assoc = WOAssociationFactory.associationWithValue("Hello")

    XCTAssertNotNil(assoc)
    XCTAssert(assoc.isValueConstant)
    XCTAssertEqual(assoc.stringValue(in: nil), "Hello")
  }

  func testValueAssociationWithInt() {
    let assoc = WOAssociationFactory.associationWithValue(42)

    XCTAssertNotNil(assoc)
    XCTAssert(assoc.isValueConstant)
    XCTAssertEqual(assoc.intValue(in: nil), 42)
  }

  func testValueAssociationWithBool() {
    let assocTrue = WOAssociationFactory.associationWithValue(true)
    let assocFalse = WOAssociationFactory.associationWithValue(false)

    XCTAssert(assocTrue.boolValue(in: nil))
    XCTAssertFalse(assocFalse.boolValue(in: nil))
  }


  // MARK: - associationForPrefix Tests

  func testVarPrefix() throws {
    let assoc = try WOAssociationFactory.associationForPrefix(
      "var", name: "test", value: "person.name"
    )

    XCTAssertNotNil(assoc)
    XCTAssert(assoc is WOKeyPathAssociation)
  }

  func testVarPrefixSimpleKey() throws {
    let assoc = try WOAssociationFactory.associationForPrefix(
      "var", name: "test", value: "name"
    )

    XCTAssertNotNil(assoc)
    XCTAssert(assoc is WOKeyAssociation)
  }

  func testConstPrefix() throws {
    let assoc = try WOAssociationFactory.associationForPrefix(
      "const", name: "test", value: "Hello World"
    )

    XCTAssertNotNil(assoc)
    XCTAssert(assoc?.isValueConstant ?? false)
    XCTAssertEqual(assoc?.stringValue(in: nil), "Hello World")
  }

  func testLabelPrefix() throws {
    let assoc = try WOAssociationFactory.associationForPrefix(
      "label", name: "test", value: "greeting.hello"
    )

    XCTAssertNotNil(assoc)
    XCTAssert(assoc is WOLabelAssocation)
  }

  func testNotPrefix() throws {
    let assoc = try WOAssociationFactory.associationForPrefix(
      "not", name: "test", value: "isEnabled"
    )

    XCTAssertNotNil(assoc)
    XCTAssert(assoc is WONegateAssocation)
  }

  func testPlistPrefixArray() throws {
    let assoc = try WOAssociationFactory.associationForPrefix(
      "plist", name: "test", value: "(a, b, c)"
    )

    XCTAssertNotNil(assoc)
    XCTAssert(assoc?.isValueConstant ?? false)

    if let array = assoc?.value(in: nil) as? [ Any ] {
      XCTAssertEqual(array.count, 3)
    }
    else {
      XCTFail("Expected array result")
    }
  }

  func testPlistPrefixDictionary() throws {
    let assoc = try WOAssociationFactory.associationForPrefix(
      "plist", name: "test", value: "{ key = value }"
    )

    XCTAssertNotNil(assoc)
    if let dict = assoc?.value(in: nil) as? [ String : Any ] {
      XCTAssertEqual(dict["key"] as? String, "value")
    }
    else {
      XCTFail("Expected dictionary result")
    }
  }

  func testVarpatPrefix() throws {
    let assoc = try WOAssociationFactory.associationForPrefix(
      "varpat", name: "test", value: "Hello %(name)s"
    )

    XCTAssertNotNil(assoc)
    XCTAssert(assoc is WOKeyPathPatternAssociation)
  }

  func testRsrcPrefix() throws {
    let assoc = try WOAssociationFactory.associationForPrefix(
      "rsrc", name: "test", value: "images/logo.png"
    )

    XCTAssertNotNil(assoc)
    XCTAssert(assoc is WOResourceURLAssociation)
  }

  func testRsrcpatPrefix() throws {
    let assoc = try WOAssociationFactory.associationForPrefix(
      "rsrcpat", name: "test", value: "images/%(name)s.png"
    )

    XCTAssertNotNil(assoc)
    XCTAssert(assoc is WOResourcePatternAssociation)
  }

  func testUnknownPrefixDefault() throws {
    // Unknown prefix should create a value association with the string
    let assoc = try WOAssociationFactory.associationForPrefix(
      "unknown", name: "test", value: "some value"
    )

    XCTAssertNotNil(assoc)
    XCTAssert(assoc?.isValueConstant ?? false)
    XCTAssertEqual(assoc?.stringValue(in: nil), "some value")
  }


  // MARK: - Linux

  static var allTests = [
    ( "testKeyPathWithDot",       testKeyPathWithDot       ),
    ( "testKeyPathWithoutDot",    testKeyPathWithoutDot    ),
    ( "testEmptyKeyPath",         testEmptyKeyPath         ),
    ( "testValueAssociationWithString", testValueAssociationWithString ),
    ( "testValueAssociationWithInt",    testValueAssociationWithInt    ),
    ( "testValueAssociationWithBool",   testValueAssociationWithBool   ),
    ( "testVarPrefix",            testVarPrefix            ),
    ( "testVarPrefixSimpleKey",   testVarPrefixSimpleKey   ),
    ( "testConstPrefix",          testConstPrefix          ),
    ( "testLabelPrefix",          testLabelPrefix          ),
    ( "testNotPrefix",            testNotPrefix            ),
    ( "testPlistPrefixArray",     testPlistPrefixArray     ),
    ( "testPlistPrefixDictionary", testPlistPrefixDictionary ),
    ( "testVarpatPrefix",         testVarpatPrefix         ),
    ( "testRsrcPrefix",           testRsrcPrefix           ),
    ( "testRsrcpatPrefix",        testRsrcpatPrefix        ),
    ( "testUnknownPrefixDefault", testUnknownPrefixDefault ),
  ]
}
