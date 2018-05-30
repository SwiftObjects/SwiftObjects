//
//  WOContextURLTests.swift
//  SwiftObjectsTests
//
//  Created by Helge Hess on 28.05.18.
//

import XCTest
@testable import SwiftObjects

class WOContextURLTests: XCTestCase {
  
  var application : WOApplication! = nil
  var request     : WORequest!     = nil
  var context     : WOContext!     = nil
  
  override func setUp() {
    super.setUp()
    
    application = WOApplication()
    application.name = "MyApp"
    request     = WORequest(method: "GET", uri: "/MyApp/wa/Main/default")
    context     = WOAppContext(application: application, request: request)
    
    request._formValues = [
      "title": [ "Hello Test World" ],
      "age":   [ 42 ]
    ]
  }
  override func tearDown() {
    application = nil
    request     = nil
    context     = nil
    super.tearDown()
  }
  
  
  func testComponentAction() throws {
    context.appendElementIDComponent(10)
    context.appendElementIDComponent("rep")
    context.appendElementIDComponent(0)
    context.incrementLastElementIDComponent()
    
    let url = context.componentActionURL()
    guard let rurl = url else {
      XCTAssertNotNil(url, "got no component action URL")
      return
    }
    
    // /MyApp/wo/F130AE8B83961FBACB77ED14A422D7C2/369517342x0/10.rep.1
    XCTAssert(rurl.hasPrefix("/MyApp/wo/"))
    XCTAssert(rurl.hasSuffix("10.rep.1"))
  }
  
  func testQueryDictRedirect() throws {
    let url = "Main/default"
    
    var qd = [ String : Any? ]()
    for ( name, values ) in context.request.formValues {
      qd[name] = values
    }
    if context.hasSession {
      qd[WORequest.SessionIDKey] = context.session.sessionID
    }
    else {
      qd.removeValue(forKey: WORequest.SessionIDKey)
    }
    
    let fullURL = context.directActionURLForActionNamed(url, with: qd)
    print("URL:", fullURL)
    XCTAssert(fullURL.hasPrefix("/MyApp/wa/Main/default?"))
    XCTAssertFalse(fullURL.contains("Optional"))
    XCTAssert(fullURL.contains("title=Hello%20Test%20World"))
    XCTAssert(fullURL.contains("age=42"))
    XCTAssert(fullURL.contains("&"))
  }
  
  func testRootComponentActionGen() throws {
    let request = WORequest(method: "GET", uri: "/")
    let context = WOAppContext(application: application, request: request)
    
    context.appendElementIDComponent(10)
    context.appendElementIDComponent("rep")
    context.appendElementIDComponent(0)
    context.incrementLastElementIDComponent()
    
    let url = context.componentActionURL()
    guard let rurl = url else {
      XCTAssertNotNil(url, "got no component action URL")
      return
    }
    print("URL:", rurl)
    
    // /MyApp/wo/F130AE8B83961FBACB77ED14A422D7C2/369517342x0/10.rep.1
    XCTAssert(rurl.hasPrefix("/MyApp/wo/"))
    XCTAssert(rurl.hasSuffix("10.rep.1"))
  }
  
  
  // MARK: - Linux
  
  static var allTests = [
    ( "testComponentAction",        testComponentAction   ),
    ( "testQueryDictRedirect",      testQueryDictRedirect ),
    ( "testRootComponentActionGen", testRootComponentActionGen ),
  ]
}
