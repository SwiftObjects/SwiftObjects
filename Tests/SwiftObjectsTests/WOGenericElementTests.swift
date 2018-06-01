//
//  WOGenericElementTests.swift
//  SwiftObjectsTests
//
//  Created by Helge Hess on 01.06.18.
//

import XCTest
@testable import SwiftObjects

class WOGenericElementTests: DynamicElementTestCase {
  
  func testLIWithClass() throws {
    // Note: This is intentionally wrong! "isSelected" is a constant assoc
    //       here! (which happens to evaluate to "true" :-) )
    
    // <#li .selected="isSelected"><wo:str value="10" /></#li>
    var bindings : [ String : WOAssociation ] = [
      "elementName" : WOAssociationFactory.associationWithValue("li"),
      ".selected"   : WOAssociationFactory.associationWithValue("isSelected")
    ]
    let t = WOString(value: WOValueAssociation(10))
    let e = WOGenericContainer(name: "TestGC", bindings: &bindings, template: t)
    XCTAssert(bindings.isEmpty, "element did not consume all bindings")
    
    try e.append(to: response, in: context)
    XCTAssertEqual(response.contentString, "<li class=\"selected\">10</li>")
  }

  
  // MARK: - Linux
  
  static var allTests = [
    ( "testLIWithClass", testLIWithClass ),
  ]
}

