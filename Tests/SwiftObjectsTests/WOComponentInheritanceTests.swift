//
//  WOComponentInheritanceTests.swift
//  SwiftObjectsTests
//
//  Created by Helge Hess on 04.11.26.
//  Copyright © 2026 ZeeZide. All rights reserved.
//

import XCTest
@testable import SwiftObjects

final class WOComponentInheritanceTests : XCTestCase {

  @WOComponent class MacroBasePage {

    var title      = "base"
    var awakeCount = 0
    var sleepCount = 0

    var upperTitle : String { return title.uppercased() }

    func awake() { awakeCount += 1 }
    func sleep() { sleepCount += 1 }

    @WOAction func base() -> Any? { return "base" }
  }

  @WOComponent final class MacroSubPage : MacroBasePage {

    var counter = 0

    override func awake() {
      super.awake()
      counter += 10
    }

    @WOAction func sub() -> Any? { return "sub" }
    func showAction() -> Any? { return self }
  }

  var application : WOApplication! = nil
  var request     : WORequest!     = nil
  var context     : WOContext!     = nil
  
  override func setUp() {
    super.setUp()
    application = WOApplication()
    application.name = "MyApp"
    request = WORequest(method: "GET", uri: "/MyApp/wa/MacroSubPage/show")
    context = WOAppContext(application: application, request: request)
  }
  override func tearDown() {
    application = nil
    request     = nil
    context     = nil
    super.tearDown()
  }
  
  func testSubclassInheritsActions() throws {
    let page = MacroSubPage()
    XCTAssertEqual(try page.lookupActionNamed("base")?() as? String, "base")
    XCTAssertEqual(try page.lookupActionNamed("sub")?()  as? String, "sub")
    XCTAssertNil(page.lookupActionNamed("missing"))
  }
  
  func testSubclassDirectActions() throws {
    let page = MacroSubPage()
    XCTAssertNil(page.lookupDirectActionNamed("base"))
    XCTAssertNil(page.lookupDirectActionNamed("sub"))
    XCTAssertNotNil(page.lookupDirectActionNamed("show"))
    XCTAssertNotNil(page.lookupDirectActionNamed("default"))
  }
  
  func testActionsThroughExistential() throws {
    let page : WOComponent = MacroSubPage()
    XCTAssertEqual(try page.lookupActionNamed("base")?() as? String, "base")
    XCTAssertEqual(try page.lookupActionNamed("sub")?()  as? String, "sub")
  }
  
  func testKVCThroughInheritance() throws {
    let page : WOComponent = MacroSubPage()
    
    try page.takeValue("Hello", forKey: "title")
    try page.takeValue("42",    forKey: "counter") // coerced from String
    XCTAssertEqual(page.value(forKey: "title")      as? String, "Hello")
    XCTAssertEqual(page.value(forKey: "upperTitle") as? String, "HELLO")
    XCTAssertEqual(page.value(forKey: "counter")    as? Int,    42)
    
    // actions resolve as values, this is how `action="$sub"` binds
    XCTAssertEqual(page.value(forKey: "sub") as? String, "sub")
    
    // unknown keys land in the variable dictionary
    try page.takeValue("extra", forKey: "unknown")
    XCTAssertEqual(page.value(forKey: "unknown") as? String, "extra")
  }
  
  func testKVCRejectsUnconvertibleValues() {
    let page = MacroSubPage()
    XCTAssertThrowsError(try page.takeValue("abc", forKey: "counter"))
    XCTAssertEqual(page.counter, 0)
  }
  
  func testHooksDispatchToSubclass() {
    let page : WOComponent = MacroSubPage()
    page.ensureAwake(in: context)
    page._sleepWithContext(context)
    
    guard let sub = page as? MacroSubPage else { return XCTFail("type") }
    XCTAssertEqual(sub.awakeCount, 1)
    XCTAssertEqual(sub.counter,    10)
    XCTAssertEqual(sub.sleepCount, 1)
  }
  
  func testNameDefaultsToClassName() {
    XCTAssertEqual(MacroSubPage().name,  "MacroSubPage")
    XCTAssertEqual(MacroBasePage().name, "MacroBasePage")
  }
  
  func testMetatypeInstantiation() {
    let type : WOComponent.Type = MacroSubPage.self
    let page = type.init()
    XCTAssertTrue(page is MacroSubPage)
  }
  
  func testComponentClassLookup() {
    let rm = WODevResourceManager(sourceType: WOComponentInheritanceTests.self)
    XCTAssertNotNil(rm.lookupComponentClass("MacroSubPage"))
    XCTAssertNotNil(rm.lookupComponentClass("MacroBasePage"))
    XCTAssertNil(rm.lookupComponentClass("WOApplication"))
    XCTAssertNotNil(rm.lookupDirectActionClass("MacroDirectAction"))
    XCTAssertNil(rm.lookupDirectActionClass("MacroSubPage"))
  }
  
  func testTemplateComponent() throws {
    let page : WOComponent = WOTemplateComponent()
    try page.takeValue("Hello", forKey: "title")
    XCTAssertEqual(page.value(forKey: "title") as? String, "Hello")
    XCTAssertEqual(page.name, "WOTemplateComponent")
  }
  
  func testDefaultDirectAction() throws {
    let action : WODirectAction = WODefaultDirectAction(context: context)
    XCTAssertNotNil(action.lookupActionNamed("default"))
    XCTAssertNil(action.lookupActionNamed("missing"))
  }
}
