//
//  WOActionMacroRuntimeTests.swift
//  SwiftObjectsTests
//
//  Created by Helge Hess on 03.11.26.
//  Copyright © 2026 ZeeZide. All rights reserved.
//

import XCTest
@testable import SwiftObjects

final class WOActionMacroRuntimeTests : XCTestCase {

  @WODirectAction final class MacroDirectAction {

    var notes = [ String ]()


    @WOAction("bye") func goodbye() throws -> String { return "bye" }

    func helloAction()       -> Any? { return "hello" }
    func noteAction()                { notes.append("noted") }
    func failAction() throws -> Any? { throw TestError.failed }

    func helper(_ value: Int) -> Int { return value }

    enum TestError : Swift.Error {
      case failed
    }
  }

  @WOComponent final class MacroComponent {

    var saved   = false
    var touched = 0

    func touch() { touched += 1 }
    func describeIt() -> String { return "touched \(touched)" }

    @WOAction func save() -> Any? {
      saved = true
      return nil
    }

    func showAction() -> WOComponent? { return self }

    @WOAction(direct: false) func editAction() -> Any? { return nil }
  }

  var application : WOApplication! = nil
  var request     : WORequest!     = nil
  var context     : WOContext!     = nil
  
  override func setUp() {
    super.setUp()
    application = WOApplication()
    application.name = "MyApp"
    request = WORequest(method: "GET", uri: "/MyApp/wa/MacroDirectAction/hello")
    context = WOAppContext(application: application, request: request)
  }
  override func tearDown() {
    application = nil
    request     = nil
    context     = nil
    super.tearDown()
  }
  
  // MARK: - Direct Actions
  
  func testSuffixedAction() throws {
    let action = MacroDirectAction(context: context)
    let result = try action.performActionNamed("hello")
    XCTAssertEqual(result as? String, "hello")
  }
  
  func testExplicitlyNamedAction() throws {
    let action = MacroDirectAction(context: context)
    let result = try action.performActionNamed("bye")
    XCTAssertEqual(result as? String, "bye")
  }
  
  func testVoidAction() throws {
    let action = MacroDirectAction(context: context)
    let result = try action.performActionNamed("note")
    XCTAssertNil(result)
    XCTAssertEqual(action.notes, [ "noted" ])
  }
  
  func testThrowingAction() {
    let action = MacroDirectAction(context: context)
    XCTAssertThrowsError(try action.performActionNamed("fail"))
  }
  
  func testUnknownAction() {
    let action = MacroDirectAction(context: context)
    XCTAssertNil(action.lookupActionNamed("helper"))
    XCTAssertNil(action.lookupActionNamed("nope"))
    XCTAssertNil(action.lookupDirectActionNamed("nope"))
  }
  
  func testExposedActionStillWorks() throws {
    let action = MacroDirectAction(context: context)
    action.expose({ "exposed" }, as: "manual")
    XCTAssertNotNil(action.lookupActionNamed("default"))
    XCTAssertNotNil(action.lookupDirectActionNamed("default"))
    XCTAssertEqual(try action.performActionNamed("manual") as? String,
                   "exposed")
  }
  
  func testExposedComponentActionIsNotDirectByDefault() throws {
    let page = MacroComponent()
    page.expose({ "hidden" },  as: "hidden")
    page.expose({ "visible" }, as: "visible", direct: true)
    XCTAssertNotNil(page.lookupActionNamed("hidden"))
    XCTAssertNil   (page.lookupDirectActionNamed("hidden"))
    XCTAssertEqual (try page.lookupDirectActionNamed("visible")?() as? String,
                    "visible")
  }
  
  func testExposedMethodReferences() throws {
    let page = MacroComponent()
    page.expose(MacroComponent.touch,      as: "touch")
    page.expose(MacroComponent.describeIt, as: "describe", direct: true)
    XCTAssertNil(try page.lookupActionNamed("touch")?())
    XCTAssertEqual(page.touched, 1)
    XCTAssertEqual(try page.lookupDirectActionNamed("describe")?() as? String,
                   "touched 1")
  }
  
  func testExposedMethodReferencesDoNotRetain() {
    weak var weakPage : MacroComponent? = nil
    do {
      let page = MacroComponent()
      page.expose(MacroComponent.touch, as: "touch")
      weakPage = page
      XCTAssertNotNil(weakPage)
    }
    XCTAssertNil(weakPage, "exposed method retains the component")
  }
  
  func testExposedActionsSurviveSleep() throws {
    let page = MacroComponent()
    page.expose(MacroComponent.touch, as: "touch")
    page.ensureAwake(in: context)
    page._sleepWithContext(context)
    XCTAssertNotNil(page.lookupActionNamed("touch"))
  }
  
  func testKVCResolvesActions() {
    let action = MacroDirectAction(context: context)
    XCTAssertEqual(action.value(forKey: "hello") as? String, "hello")
  }
  
  // MARK: - Component Actions
  
  func testComponentActionIsBindable() {
    let component = MacroComponent()
    XCTAssertNotNil(component.lookupActionNamed("save"))
    XCTAssertNil(component.value(forKey: "save")) // invokes the action
    XCTAssertTrue(component.saved)
  }
  
  func testComponentActionIsNotADirectAction() throws {
    let component = MacroComponent()
    XCTAssertNil(component.lookupDirectActionNamed("save"))
    XCTAssertNotNil(component.lookupActionNamed("edit"))
    XCTAssertNil(component.lookupDirectActionNamed("edit"))
    let result = try WODirectActionRequestHandler
      .performActionNamed("save", on: component, in: context)
    XCTAssertNil(result)
    XCTAssertFalse(component.saved)
  }
  
  func testSuffixedComponentActionIsADirectAction() throws {
    let component = MacroComponent()
    XCTAssertNotNil(component.lookupActionNamed("show"))
    XCTAssertNotNil(component.lookupDirectActionNamed("show"))
    let result = try WODirectActionRequestHandler
      .performActionNamed("show", on: component, in: context)
    XCTAssertTrue(result as? MacroComponent === component)
  }
}
