//
//  WORequestFormDecoderTests.swift
//  SwiftObjectsTests
//
//  Created by Helge Hess on 28.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

import XCTest
@testable import SwiftObjects

class WORequestFormDecoderTests: XCTestCase {
  
  func testQueryParameterDecoder() throws {
    let fixture = "/MyApp/wa/Main/default?title=Hello%20World"
    
    let request = WORequest(method: "GET", uri: fixture)
    let fv = request.formValue(for: "title")
    guard let s = fv as? String else {
      XCTAssert(fv is String, "form value is not a string: \(fv as Any)")
      return
    }
    
    XCTAssertEqual(s, "Hello World")
  }
  
  func testPostBodyDecoder() throws {
    let fixture = "5.1=My+First+Component"
    
    let request = WORequest(method: "POST", uri: "/MyApp/wa/Main/default")
    request.setHeader("application/x-www-form-urlencoded", for: "Content-Type")
    request.contentString = fixture

    let fv = request.formValue(for: "5.1")
    XCTAssertNotNil(fv, "got no formvalue: \(request)")
    guard let s = fv as? String else {
      XCTAssert(fv is String, "form value is not a string: \(fv as Any)")
      return
    }
    
    XCTAssertEqual(s, "My First Component")
  }
  
  // MARK: - Linux
  
  static var allTests = [
    ( "testQueryParameterDecoder", testQueryParameterDecoder ),
    ( "testPostBodyDecoder",       testPostBodyDecoder ),
  ]
}
