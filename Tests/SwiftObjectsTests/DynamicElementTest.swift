//
//  DynamicElementTest.swift
//  SwiftObjectsTests
//
//  Created by Helge Hess on 19.05.18.
//

import XCTest
@testable import SwiftObjects

class DynamicElementTestCase: XCTestCase {
  
  var application : WOApplication! = nil
  var request     : WORequest!     = nil
  var response    : WOResponse!    = nil
  var context     : WOContext!     = nil
  var page        : WOComponent!   = nil
  
  override func setUp() {
    super.setUp()
    
    application = WOApplication()
    request     = WORequest(method: "GET", uri: "/wa/Main/default")
    context     = WOAppContext(application: application, request: request)
    response    = context.response
    
    let page = WOComponent()
    try? page.takeValue("Hello", forKey: "hello")
    try? page.takeValue("World", forKey: "world")
    try? page.takeValue(Date(), forKey: "now")
    
    context.enterComponent(page)
  }
  override func tearDown() {
    if let page = page { context.leaveComponent(page) }
    page        = nil
    application = nil
    request     = nil
    response    = nil
    context     = nil
    super.tearDown()
  }
  
}
