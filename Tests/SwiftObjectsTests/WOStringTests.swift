//
//  WOStringTests.swift
//  SwiftObjectsTests
//
//  Created by Helge Hess on 19.05.18.
//

import XCTest
@testable import SwiftObjects

class WOStringTests: DynamicElementTestCase {
  
  func testSimpleRendering() throws {
    let e = WOString(bindings: [
      "value" : WOAssociationFactory.associationWithValue("Hello World")
    ])

    try e.append(to: response, in: context)
    XCTAssertEqual(response.contentString, "Hello World")
  }
  
  func testEscaping() throws {
    let e = WOString(bindings: [
      "value" : WOAssociationFactory.associationWithValue("\"Hello\" <World>")
    ])

    try e.append(to: response, in: context)
    XCTAssertEqual(response.contentString ?? "",
                   "&quot;Hello&quot; &lt;World&gt;")
  }
  
  func testEscapingOff() throws {
    let string = "\"Hello\" <World>"
    let e = WOString(bindings: [
      "value"      : WOAssociationFactory.associationWithValue(string),
      "escapeHTML" : WOAssociationFactory.associationWithValue(false)
    ])

    try e.append(to: response, in: context)
    XCTAssertEqual(response.contentString, string)
  }
  
  func testInsertBR() throws {
    let string = "Hello\nWorld\n"
    let e = WOString(bindings: [
      "value"    : WOAssociationFactory.associationWithValue(string),
      "insertBR" : WOAssociationFactory.associationWithValue(true)
    ])

    try e.append(to: response, in: context)
    XCTAssertEqual(response.contentString, "Hello<br />World<br />")
  }

  func testPatternValue() throws {
    let string = "%(hello)s %(world)s"
    let e = WOString(bindings: [
      "%value" : WOAssociationFactory.associationWithValue(string)
    ])

    try e.append(to: response, in: context)
    XCTAssertEqual(response.contentString, "Hello World")
  }
  
  // MARK: - Linux
  
  static var allTests = [
    ( "testSimpleRendering", testSimpleRendering ),
    ( "testEscaping",        testEscaping        ),
    ( "testEscapingOff",     testEscapingOff     ),
    ( "testInsertBR",        testInsertBR        ),
  ]
}
