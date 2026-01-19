//
//  WOSubmitButtonTests.swift
//  SwiftObjectsTests
//

import XCTest
@testable import SwiftObjects

class WOSubmitButtonTests: FormTestCase {

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

  func testInputTypeSubmit() throws {
    let button = WOSubmitButton(bindings: [ "name" : value("submit1") ])
    try button.append(to: response, in: context)
    assertResponseContains("type=\"submit\"")
  }

  func testNameBinding() throws {
    let button = WOSubmitButton(bindings: [ "name" : value("mySubmit") ])
    try button.append(to: response, in: context)
    assertResponseContains("name=\"mySubmit\"")
  }

  func testValueAsLabel() throws {
    let button = WOSubmitButton(bindings: [
      "name"  : value("submit1"),
      "value" : value("Save Changes")
    ])
    try button.append(to: response, in: context)
    assertResponseContains("value=\"Save Changes\"")
  }

  func testDisabledBinding() throws {
    let button = WOSubmitButton(bindings: [
      "name"     : value("submit1"),
      "disabled" : value(true)
    ])
    try button.append(to: response, in: context)
    assertResponseContains("disabled")
  }

  func testIdBinding() throws {
    let button = WOSubmitButton(bindings: [
      "name" : value("submit1"),
      "id"   : value("my-button-id")
    ])
    try button.append(to: response, in: context)
    assertResponseContains("id=\"my-button-id\"")
  }


  // MARK: - takeValues and activeFormElement Tests

  func testRegistersAsActiveFormElement() throws {
    let button = WOSubmitButton(bindings: [
      "name"   : value("submit1"),
      "action" : try keypath("testAction")
    ])

    // When submit button's name is in form values, it becomes active
    let req = makePostRequest(formValues: [ "submit1" : "OK" ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try button.takeValues(from: req, in: ctx)

    // The button should be registered as an active form element
    // We can check this indirectly by verifying context has active elements
    if let appCtx = ctx as? WOAppContext {
      XCTAssertNotNil(appCtx.activeFormElement)
    }
  }

  func testSkipsTakeValuesWhenDisabled() throws {
    let button = WOSubmitButton(bindings: [
      "name"     : value("submit1"),
      "action"   : try keypath("testAction"),
      "disabled" : value(true)
    ])

    let req = makePostRequest(formValues: [ "submit1" : "OK" ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try button.takeValues(from: req, in: ctx)

    // Should not register as active because it's disabled
    if let appCtx = ctx as? WOAppContext {
      XCTAssertNil(appCtx.activeFormElement)
    }
  }

  func testNotActiveWhenNotSubmitted() throws {
    let button = WOSubmitButton(bindings: [
      "name"   : value("submit1"),
      "action" : try keypath("testAction")
    ])

    // Different form value, not this button
    let req = makePostRequest(formValues: [ "other" : "value" ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try button.takeValues(from: req, in: ctx)

    // Should not register as active because it wasn't submitted
    if let appCtx = ctx as? WOAppContext {
      XCTAssertNil(appCtx.activeFormElement)
    }
  }


  // MARK: - invokeAction Tests

  func testNoActionWhenSenderIDDoesNotMatch() throws {
    let button = WOSubmitButton(bindings: [
      "name"   : value("submit1"),
      "action" : try keypath("testAction")
    ])

    // Don't set senderID to match
    _ = try button.invokeAction(for: request, in: context)

    XCTAssertFalse(testComponent.actionCalled)
  }


  // MARK: - Linux

  static var allTests = [
    ( "testInputTypeSubmit",             testInputTypeSubmit             ),
    ( "testNameBinding",                 testNameBinding                 ),
    ( "testValueAsLabel",                testValueAsLabel                ),
    ( "testDisabledBinding",             testDisabledBinding             ),
    ( "testIdBinding",                   testIdBinding                   ),
    ( "testRegistersAsActiveFormElement", testRegistersAsActiveFormElement ),
    ( "testSkipsTakeValuesWhenDisabled", testSkipsTakeValuesWhenDisabled ),
    ( "testNotActiveWhenNotSubmitted",   testNotActiveWhenNotSubmitted   ),
    ( "testNoActionWhenSenderIDDoesNotMatch",
                                         testNoActionWhenSenderIDDoesNotMatch ),
  ]
}
