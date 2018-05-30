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
    var bindings : [ String : WOAssociation ] = [
      "value" : WOAssociationFactory.associationWithValue("Hello World")
    ]
    let e = WOString(name: "MyString", bindings: &bindings, template: nil)
    XCTAssert(bindings.isEmpty, "element did not consume all bindings")
    
    try e.append(to: response, in: context)
    XCTAssertEqual(response.contentString, "Hello World")
  }
  
  func testEscaping() throws {
    var bindings : [ String : WOAssociation ] = [
      "value" : WOAssociationFactory.associationWithValue("\"Hello\" <World>")
    ]
    let e = WOString(name: "MyString", bindings: &bindings, template: nil)
    XCTAssert(bindings.isEmpty, "element did not consume all bindings")
    
    try e.append(to: response, in: context)
    XCTAssertEqual(response.contentString ?? "",
                   "&quot;Hello&quot; &lt;World&gt;")
  }
  
  func testEscapingOff() throws {
    let string = "\"Hello\" <World>"
    var bindings : [ String : WOAssociation ] = [
      "value" : WOAssociationFactory.associationWithValue(string),
      "escapeHTML" : WOAssociationFactory.associationWithValue(false)
    ]
    let e = WOString(name: "MyString", bindings: &bindings, template: nil)
    XCTAssert(bindings.isEmpty, "element did not consume all bindings")
    
    try e.append(to: response, in: context)
    XCTAssertEqual(response.contentString, string)
  }
  
  func testInsertBR() throws {
    let string = "Hello\nWorld\n"
    var bindings : [ String : WOAssociation ] = [
      "value" : WOAssociationFactory.associationWithValue(string),
      "insertBR" : WOAssociationFactory.associationWithValue(true)
    ]
    let e = WOString(name: "MyString", bindings: &bindings, template: nil)
    XCTAssert(bindings.isEmpty, "element did not consume all bindings")
    
    try e.append(to: response, in: context)
    XCTAssertEqual(response.contentString, "Hello<br />World<br />")
  }

  // MARK: - Linux
  
  static var allTests = [
    ( "testSimpleRendering", testSimpleRendering ),
    ( "testEscaping",        testEscaping        ),
    ( "testEscapingOff",     testEscapingOff     ),
    ( "testInsertBR",        testInsertBR        ),
  ]
}
