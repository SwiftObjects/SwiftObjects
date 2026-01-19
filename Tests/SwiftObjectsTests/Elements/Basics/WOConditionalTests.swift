//
//  WOConditionalTests.swift
//  SwiftObjectsTests
//

import XCTest
@testable import SwiftObjects

class WOConditionalTests: FormTestCase {

  // MARK: - Test Setup

  var testComponent : TestComponent!
  let content = WOString(bindings: [
    "value" : WOAssociationFactory.associationWithValue("cond-content")
  ])

  override func setUp() {
    super.setUp()
    testComponent = TestComponent()
    context.enterComponent(testComponent)
  }

  override func tearDown() {
    if let testComponent { context.leaveComponent(testComponent) }
    testComponent = nil
    super.tearDown()
  }


  // MARK: - Basic Condition Tests

  func testConditionTrue() throws {
    testComponent.boolValue = true

    var bindings : Bindings = [ "condition" : try keypath("boolValue") ]
    let cond = WOConditional(bindings: &bindings, template: content)
    assertBindingsConsumed(bindings)

    try cond.append(to: response, in: context)
    XCTAssertEqual(response.contentString, "cond-content")
  }

  func testConditionFalse() throws {
    testComponent.boolValue = false

    var bindings : Bindings = [ "condition" : try keypath("boolValue") ]
    let cond = WOConditional(bindings: &bindings, template: content)
    assertBindingsConsumed(bindings)

    try cond.append(to: response, in: context)
    XCTAssert(response.contentString?.isEmpty ?? true)
  }

  func testNegateTrue() throws {
    testComponent.boolValue = true

    var bindings : Bindings = [
      "condition" : try keypath("boolValue"),
      "negate"    : value(true)
    ]
    let cond = WOConditional(bindings: &bindings, template: content)
    assertBindingsConsumed(bindings)

    try cond.append(to: response, in: context)
    // negate=true with condition=true should NOT show
    XCTAssert(response.contentString?.isEmpty ?? true)
  }

  func testNegateFalse() throws {
    testComponent.boolValue = false

    var bindings : Bindings = [
      "condition" : try keypath("boolValue"),
      "negate"    : value(true)
    ]
    let cond = WOConditional(bindings: &bindings, template: content)
    assertBindingsConsumed(bindings)

    try cond.append(to: response, in: context)
    // negate=true with condition=false should show
    XCTAssertEqual(response.contentString, "cond-content")
  }


  // MARK: - Value Comparison Tests

  func testValueMatchEqual() throws {
    testComponent.stringValue = "red"

    var bindings : Bindings = [
      "condition" : try keypath("stringValue"),
      "value"     : value("red")
    ]
    let cond = WOConditional(bindings: &bindings, template: content)
    assertBindingsConsumed(bindings)

    try cond.append(to: response, in: context)
    XCTAssertEqual(response.contentString, "cond-content")
  }

  func testValueMatchNotEqual() throws {
    testComponent.stringValue = "blue"

    var bindings : Bindings = [
      "condition" : try keypath("stringValue"),
      "value"     : value("red")
    ]
    let cond = WOConditional(bindings: &bindings, template: content)
    assertBindingsConsumed(bindings)

    try cond.append(to: response, in: context)
    // Values don't match, should not render
    XCTAssert(response.contentString?.isEmpty ?? true)
  }

  func testNilHandling() throws {
    // Both condition and value are nil - should match (both nil = true)
    testComponent.stringValue = nil

    var bindings : Bindings = [
      "condition" : try keypath("stringValue"),
      "value"     : try keypath("dateValue") // also nil
    ]
    let cond = WOConditional(bindings: &bindings, template: content)
    assertBindingsConsumed(bindings)

    try cond.append(to: response, in: context)
    XCTAssertEqual(response.contentString, "cond-content")
  }


  // MARK: - Shortcut Bindings

  func testNotBinding() throws {
    // <wo:if not="condition"> is a shortcut for condition + negate=true
    testComponent.boolValue = false

    var bindings : Bindings = [ "not" : try keypath("boolValue") ]
    let cond = WOConditional(bindings: &bindings, template: content)
    assertBindingsConsumed(bindings)

    try cond.append(to: response, in: context)
    // not + false condition = should show (negated)
    XCTAssertEqual(response.contentString, "cond-content")
  }


  // MARK: - takeValues / invokeAction Tests

  func testTakeValuesOnlyWhenShown() throws {
    testComponent.boolValue   = false
    testComponent.stringValue = "original"

    // Create a WOTextField that would update stringValue
    let field = WOTextField(bindings: [
      "value" : try keypath("stringValue"),
      "name"  : value("field1")
    ])
    let cond = WOConditional(bindings: [ "condition" : try keypath("boolValue") ],
                             template: field)

    // Simulate form submission with new value
    let req = makePostRequest(formValues: [ "field1" : "updated" ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try cond.takeValues(from: req, in: ctx)

    // Since condition is false, takeValues should have been skipped
    XCTAssertEqual(testComponent.stringValue, "original")
  }

  func testTakeValuesWhenShown() throws {
    testComponent.boolValue   = true
    testComponent.stringValue = "original"

    let field = WOTextField(bindings: [
      "value" : try keypath("stringValue"),
      "name"  : value("field1")
    ])
    let cond = WOConditional(bindings: [ "condition" : try keypath("boolValue") ],
                             template: field)

    let req = makePostRequest(formValues: [ "field1" : "updated" ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try cond.takeValues(from: req, in: ctx)

    // Since condition is true, takeValues should have updated the value
    XCTAssertEqual(testComponent.stringValue, "updated")
  }


  // MARK: - Constant Optimization Tests

  func testConstantTrueCondition() throws {
    var bindings : Bindings = [ "condition" : value(true) ]
    let cond = WOConditional(bindings: &bindings, template: content)
    assertBindingsConsumed(bindings)

    try cond.append(to: response, in: context)
    XCTAssertEqual(response.contentString, "cond-content")
  }

  func testConstantFalseCondition() throws {
    var bindings : Bindings = [ "condition" : value(false) ]
    let cond = WOConditional(bindings: &bindings, template: content)
    assertBindingsConsumed(bindings)

    try cond.append(to: response, in: context)
    XCTAssert(response.contentString?.isEmpty ?? true)
  }


  // MARK: - Linux

  static var allTests = [
    ( "testConditionTrue",            testConditionTrue            ),
    ( "testConditionFalse",           testConditionFalse           ),
    ( "testNegateTrue",               testNegateTrue               ),
    ( "testNegateFalse",              testNegateFalse              ),
    ( "testValueMatchEqual",          testValueMatchEqual          ),
    ( "testValueMatchNotEqual",       testValueMatchNotEqual       ),
    ( "testNilHandling",              testNilHandling              ),
    ( "testNotBinding",               testNotBinding               ),
    ( "testTakeValuesOnlyWhenShown",  testTakeValuesOnlyWhenShown  ),
    ( "testTakeValuesWhenShown",      testTakeValuesWhenShown      ),
    ( "testConstantTrueCondition",    testConstantTrueCondition    ),
    ( "testConstantFalseCondition",   testConstantFalseCondition   ),
  ]
}
