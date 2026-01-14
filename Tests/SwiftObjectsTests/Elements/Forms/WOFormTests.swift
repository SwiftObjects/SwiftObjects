//
//  WOFormTests.swift
//  SwiftObjectsTests
//

import XCTest
@testable import SwiftObjects

class WOFormTests: FormTestCase {

  // MARK: - Test Setup

  var testComponent : TestComponent!

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


  // MARK: - Rendering Tests

  func testFormTagRendering() throws {
    let content = WOString(bindings: [ "value" : value("Content") ])

    var bindings : Bindings = [:]
    let form = WOForm(bindings: &bindings, template: content)
    assertBindingsConsumed(bindings)

    try form.append(to: response, in: context)
    assertResponseContains("<form")
    assertResponseContains("method=\"POST\"")
    assertResponseContains("</form>")
    assertResponseContains("Content")
  }

  func testMethodBinding() throws {
    let content = WOString(bindings: [ "value" : value("Content") ])

    var bindings : Bindings = [ "method" : value("GET") ]
    let form = WOForm(bindings: &bindings, template: content)
    assertBindingsConsumed(bindings)

    try form.append(to: response, in: context)
    assertResponseContains("method=\"GET\"")
  }

  func testIdBinding() throws {
    let content = WOString(bindings: [ "value" : value("Content") ])

    var bindings : Bindings = [ "id" : value("my-form") ]
    let form = WOForm(bindings: &bindings, template: content)
    assertBindingsConsumed(bindings)

    try form.append(to: response, in: context)
    assertResponseContains("id=\"my-form\"")
  }

  func testTargetBinding() throws {
    let content = WOString(bindings: [ "value" : value("Content") ])

    var bindings : Bindings = [ "target" : value("_blank") ]
    let form = WOForm(bindings: &bindings, template: content)
    assertBindingsConsumed(bindings)

    try form.append(to: response, in: context)
    assertResponseContains("target=\"_blank\"")
  }

  func testActionAttribute() throws {
    let form = WOForm(bindings: [:])

    try form.append(to: response, in: context)
    // Form should have an action URL
    assertResponseContains("action=")
  }

  func testDirectActionURL() throws {
    var bindings : Bindings = [
      "directActionName" : value("submit"),
      "actionClass"      : value("Contact")
    ]

    let form = WOForm(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try form.append(to: response, in: context)
    assertResponseContains("/wa/Contact/submit")
  }


  // MARK: - takeValues Tests

  func testTakeValuesFromPOST() throws {
    testComponent.stringValue = "original"

    let field = WOTextField(bindings: [
      "value" : try keypath("stringValue"),
      "name"  : value("field1")
    ])
    let form = WOForm(bindings: [:], template: field)

    // Simulate POST request
    let req = makePostRequest(formValues: [ "field1" : "updated" ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try form.takeValues(from: req, in: ctx)

    XCTAssertEqual(testComponent.stringValue, "updated")
  }

  func testSkipsTakeValuesOnGET() throws {
    testComponent.stringValue = "original"

    let field = WOTextField(bindings: [
      "value" : try keypath("stringValue"),
      "name"  : value("field1")
    ])
    let form = WOForm(bindings: [:], template: field)

    // GET request - form should not take values
    let req = WORequest(method: "GET", uri: "/wa/Main/default?field1=updated")
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try form.takeValues(from: req, in: ctx)

    // Value should NOT be updated because it's a GET request
    XCTAssertEqual(testComponent.stringValue, "original")
  }

  func testForceTakeValues() throws {
    testComponent.stringValue = "original"

    let field = WOTextField(bindings: [
      "value" : try keypath("stringValue"),
      "name"  : value("field1")
    ])
    let form = WOForm(bindings: [ "forceTakeValues" : value(true) ],
                      template: field)

    // GET request with forceTakeValues=true should still take values
    let req = WORequest(method: "GET", uri: "/wa/Main/default?field1=forced")
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try form.takeValues(from: req, in: ctx)

    XCTAssertEqual(testComponent.stringValue, "forced")
  }

  func testIsInFormFlag() throws {
    // We can verify this indirectly by checking context after append
    let content = WOString(bindings: [ "value" : value("X") ])
    let form    = WOForm(bindings: [:], template: content)

    // Before form, isInForm should be false
    XCTAssertFalse((context as? WOAppContext)?.isInForm ?? true)

    try form.append(to: response, in: context)

    // After form, isInForm should be false again
    XCTAssertFalse((context as? WOAppContext)?.isInForm ?? true)
  }


  // MARK: - Error Report Tests

  func testErrorReportBinding() throws {
    testComponent.selection = nil

    var bindings : Bindings = [ "errorReport" : try keypath("selection") ]

    let form = WOForm(bindings: &bindings)
    assertBindingsConsumed(bindings)

    let req = makePostRequest(formValues: [:])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try form.takeValues(from: req, in: ctx)

    // Error report should have been created and pushed to selection
    XCTAssertNotNil(testComponent.selection)
    XCTAssert(testComponent.selection is WOErrorReport)
  }


  // MARK: - Linux

  static var allTests = [
    ( "testFormTagRendering",     testFormTagRendering     ),
    ( "testMethodBinding",        testMethodBinding        ),
    ( "testIdBinding",            testIdBinding            ),
    ( "testTargetBinding",        testTargetBinding        ),
    ( "testActionAttribute",      testActionAttribute      ),
    ( "testDirectActionURL",      testDirectActionURL      ),
    ( "testTakeValuesFromPOST",   testTakeValuesFromPOST   ),
    ( "testSkipsTakeValuesOnGET", testSkipsTakeValuesOnGET ),
    ( "testForceTakeValues",      testForceTakeValues      ),
    ( "testIsInFormFlag",         testIsInFormFlag         ),
    ( "testErrorReportBinding",   testErrorReportBinding   ),
  ]
}
