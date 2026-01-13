//
//  RequestFlowTests.swift
//  SwiftObjectsTests
//

import XCTest
@testable import SwiftObjects

/**
 * Tests for the request/response lifecycle, verifying that the three-phase
 * processing (takeValues → invokeAction → append) works correctly.
 */
class RequestFlowTests: FormTestCase {

  // MARK: - Test Setup

  var testComponent : TestComponent!

  override func setUp() {
    super.setUp()
    testComponent = TestComponent()
    context.enterComponent(testComponent)
  }

  override func tearDown() {
    if testComponent != nil {
      context.leaveComponent(testComponent)
    }
    testComponent = nil
    super.tearDown()
  }


  // MARK: - Three-Phase Request Cycle Tests

  func testTakeValuesPhase() throws {
    testComponent.stringValue = "original"

    var fieldBindings : Bindings = [
      "value" : try keypath("stringValue"),
      "name"  : value("field1")
    ]
    let field = WOTextField(name: "Field", bindings: &fieldBindings,
                            template: nil)

    var formBindings : Bindings = [:]
    let form = WOForm(name: "Form", bindings: &formBindings, template: field)

    let req = makePostRequest(formValues: [ "field1" : "updated" ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    // Phase 1: takeValues
    try form.takeValues(from: req, in: ctx)

    XCTAssertEqual(testComponent.stringValue, "updated")
  }

  func testAppendPhase() throws {
    testComponent.stringValue = "Hello World"

    var fieldBindings : Bindings = [
      "value" : try keypath("stringValue"),
      "name"  : value("field1")
    ]
    let field = WOTextField(name: "Field", bindings: &fieldBindings,
                            template: nil)

    var formBindings : Bindings = [:]
    let form = WOForm(name: "Form", bindings: &formBindings, template: field)

    // Phase 3: append
    try form.append(to: response, in: context)

    assertResponseContains("<form")
    assertResponseContains("value=\"Hello World\"")
    assertResponseContains("</form>")
  }

  func testFullRequestCycle() throws {
    testComponent.stringValue = "initial"

    // Build form with text field
    var fieldBindings : Bindings = [
      "value" : try keypath("stringValue"),
      "name"  : value("myField")
    ]
    let field = WOTextField(name: "Field", bindings: &fieldBindings,
                            template: nil)

    var formBindings : Bindings = [:]
    let form = WOForm(name: "Form", bindings: &formBindings, template: field)

    // Phase 1: takeValues from POST
    let req = makePostRequest(formValues: [ "myField" : "processed" ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try form.takeValues(from: req, in: ctx)
    XCTAssertEqual(testComponent.stringValue, "processed")

    // Phase 3: append response
    let resp = WOResponse()
    try form.append(to: resp, in: ctx)

    let content = resp.contentString ?? ""
    XCTAssert(content.contains("value=\"processed\""))
  }


  // MARK: - Element ID Tests

  func testElementIDGeneration() throws {
    // When rendering, element IDs should be generated
    var fieldBindings : Bindings = [
      "value" : try keypath("stringValue"),
      "name"  : value("field1")
    ]
    let field = WOTextField(name: "Field", bindings: &fieldBindings,
                            template: nil)

    // Get initial element ID
    let initialID = context.elementID
    XCTAssertNotNil(initialID)

    try field.append(to: response, in: context)

    // Element ID should have been used/incremented
    XCTAssertNotNil(context.elementID)
  }

  func testNestedElementIDs() throws {
    testComponent.items = [ "A", "B", "C" ]

    // Create a repetition with items
    var repBindings : Bindings = [
      "list" : try keypath("items"),
      "item" : try keypath("currentItem")
    ]

    var innerBindings : Bindings = [
      "value" : try keypath("currentItem")
    ]
    let inner = WOString(name: "Item", bindings: &innerBindings, template: nil)

    let rep = WORepetition(name: "Rep", bindings: &repBindings, template: inner)

    try rep.append(to: response, in: context)

    // All items should be rendered
    assertResponseContains("A")
    assertResponseContains("B")
    assertResponseContains("C")
  }


  // MARK: - Component Lifecycle Tests

  func testContextSetup() {
    XCTAssertNotNil(context.request)
    XCTAssertNotNil(context.response)
    XCTAssertNotNil(context.application)
  }

  func testComponentCursor() {
    // The cursor should return the active component
    let cursor = context.cursor
    XCTAssertNotNil(cursor)
  }


  // MARK: - Conditional Processing Tests

  func testConditionalSkipsTakeValues() throws {
    testComponent.boolValue   = false
    testComponent.stringValue = "original"

    var condBindings : Bindings = [
      "condition" : try keypath("boolValue")
    ]

    var fieldBindings : Bindings = [
      "value" : try keypath("stringValue"),
      "name"  : value("field1")
    ]
    let field = WOTextField(name: "Field", bindings: &fieldBindings,
                            template: nil)

    let cond = WOConditional(name: "Cond", bindings: &condBindings,
                             template: field)

    let req = makePostRequest(formValues: [ "field1" : "updated" ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try cond.takeValues(from: req, in: ctx)

    // Value should NOT be updated because condition is false
    XCTAssertEqual(testComponent.stringValue, "original")
  }

  func testConditionalProcessesTakeValues() throws {
    testComponent.boolValue   = true
    testComponent.stringValue = "original"

    var condBindings : Bindings = [
      "condition" : try keypath("boolValue")
    ]

    var fieldBindings : Bindings = [
      "value" : try keypath("stringValue"),
      "name"  : value("field1")
    ]
    let field = WOTextField(name: "Field", bindings: &fieldBindings,
                            template: nil)

    let cond = WOConditional(name: "Cond", bindings: &condBindings,
                             template: field)

    let req = makePostRequest(formValues: [ "field1" : "updated" ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try cond.takeValues(from: req, in: ctx)

    // Value should be updated because condition is true
    XCTAssertEqual(testComponent.stringValue, "updated")
  }


  // MARK: - Linux

  static var allTests = [
    ( "testTakeValuesPhase",             testTakeValuesPhase             ),
    ( "testAppendPhase",                 testAppendPhase                 ),
    ( "testFullRequestCycle",            testFullRequestCycle            ),
    ( "testElementIDGeneration",         testElementIDGeneration         ),
    ( "testNestedElementIDs",            testNestedElementIDs            ),
    ( "testContextSetup",                testContextSetup                ),
    ( "testComponentCursor",             testComponentCursor             ),
    ( "testConditionalSkipsTakeValues",  testConditionalSkipsTakeValues  ),
    ( "testConditionalProcessesTakeValues",
                                         testConditionalProcessesTakeValues ),
  ]
}
