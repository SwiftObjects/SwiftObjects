//
//  WOPopUpButtonTests.swift
//  SwiftObjectsTests
//

import XCTest
@testable import SwiftObjects

class WOPopUpButtonTests: FormTestCase {

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

  func testSelectTagRendering() throws {
    testComponent.items = [ "A", "B", "C" ]

    var bindings : Bindings = [
      "list" : try keypath("items"),
      "name" : value("popup1")
    ]

    let popup = WOPopUpButton(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try popup.append(to: response, in: context)
    assertResponseContains("<select")
    assertResponseContains("name=\"popup1\"")
    assertResponseContains("</select>")
  }

  func testOptionRendering() throws {
    testComponent.items = [ "One", "Two", "Three" ]

    var bindings : Bindings = [
      "list" : try keypath("items"),
      "item" : try keypath("currentItem"),
      "name" : value("popup1")
    ]

    let popup = WOPopUpButton(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try popup.append(to: response, in: context)
    assertResponseContains("<option")
    assertResponseContains(">One</option>")
    assertResponseContains(">Two</option>")
    assertResponseContains(">Three</option>")
  }

  func testSelectedOption() throws {
    testComponent.items     = [ "A", "B", "C" ]
    testComponent.selection = "B"

    var bindings : Bindings = [
      "list"      : try keypath("items"),
      "item"      : try keypath("currentItem"),
      "selection" : try keypath("selection"),
      "name"      : value("popup1")
    ]

    let popup = WOPopUpButton(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try popup.append(to: response, in: context)
    // The option for "B" should have selected attribute
    assertResponseContains("selected")
  }

  func testNoSelectionString() throws {
    testComponent.items = [ "X", "Y" ]

    var bindings : Bindings = [
      "list"              : try keypath("items"),
      "item"              : try keypath("currentItem"),
      "noSelectionString" : value("-- Select --"),
      "name"              : value("popup1")
    ]

    let popup = WOPopUpButton(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try popup.append(to: response, in: context)
    assertResponseContains("-- Select --")
    assertResponseContains("WONoSelectionString")
  }

  func testEscapeHTML() throws {
    testComponent.items = [ "<script>alert(1)</script>" ]

    var bindings : Bindings = [
      "list"       : try keypath("items"),
      "item"       : try keypath("currentItem"),
      "escapeHTML" : value(true),
      "name"       : value("popup1")
    ]

    let popup = WOPopUpButton(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try popup.append(to: response, in: context)
    // Should be escaped
    assertResponseContains("&lt;script&gt;")
  }

  func testNoEscapeHTML() throws {
    testComponent.items = [ "<b>Bold</b>" ]

    var bindings : Bindings = [
      "list"       : try keypath("items"),
      "item"       : try keypath("currentItem"),
      "escapeHTML" : value(false),
      "name"       : value("popup1")
    ]

    let popup = WOPopUpButton(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try popup.append(to: response, in: context)
    // Should NOT be escaped
    assertResponseContains("<b>Bold</b>")
  }

  func testDisabledBinding() throws {
    testComponent.items = [ "A" ]

    var bindings : Bindings = [
      "list"     : try keypath("items"),
      "name"     : value("popup1"),
      "disabled" : value(true)
    ]

    let popup = WOPopUpButton(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try popup.append(to: response, in: context)
    assertResponseContains("disabled")
  }

  func testIdBinding() throws {
    testComponent.items = [ "A" ]

    var bindings : Bindings = [
      "list" : try keypath("items"),
      "name" : value("popup1"),
      "id"   : value("my-popup-id")
    ]

    let popup = WOPopUpButton(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try popup.append(to: response, in: context)
    assertResponseContains("id=\"my-popup-id\"")
  }

  func testStringBinding() throws {
    testComponent.items       = [ "A", "B" ]
    testComponent.stringValue = "DisplayA"

    var bindings : Bindings = [
      "list"   : try keypath("items"),
      "item"   : try keypath("currentItem"),
      "string" : try keypath("stringValue"),
      "name"   : value("popup1")
    ]

    let popup = WOPopUpButton(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try popup.append(to: response, in: context)
    // The display string should be from stringValue binding
    assertResponseContains(">DisplayA</option>")
  }


  // MARK: - takeValues Tests

  func testSelectionByIndex() throws {
    testComponent.items     = [ "First", "Second", "Third" ]
    testComponent.selection = nil

    let popup = WOPopUpButton(bindings: [
      "list"      : try keypath("items"),
      "item"      : try keypath("currentItem"),
      "selection" : try keypath("selection"),
      "name"      : value("popup1")
    ])

    // Submit index 1 (Second)
    let req = makePostRequest(formValues: [ "popup1" : "1" ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try popup.takeValues(from: req, in: ctx)

    XCTAssertEqual(testComponent.selection as? String, "Second")
  }

  func testNoSelectionSubmit() throws {
    testComponent.items     = [ "A", "B" ]
    testComponent.selection = "A"

    let popup = WOPopUpButton(bindings: [
      "list"              : try keypath("items"),
      "item"              : try keypath("currentItem"),
      "selection"         : try keypath("selection"),
      "noSelectionString" : value("None"),
      "name"              : value("popup1")
    ])

    // Submit the no-selection value
    let req = makePostRequest(formValues: [
      "popup1" : WOPopUpButton.WONoSelectionString
    ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try popup.takeValues(from: req, in: ctx)

    XCTAssertNil(testComponent.selection)
  }

  func testSelectedValueBinding() throws {
    testComponent.items       = [ "A", "B", "C" ]
    testComponent.stringValue = nil

    var bindings : Bindings = [
      "list"          : try keypath("items"),
      "item"          : try keypath("currentItem"),
      "selectedValue" : try keypath("stringValue"),
      "name"          : value("popup1")
    ]

    let popup = WOPopUpButton(bindings: &bindings)
    assertBindingsConsumed(bindings)

    // Submit index 2 (C)
    let req = makePostRequest(formValues: [ "popup1" : "2" ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try popup.takeValues(from: req, in: ctx)

    // selectedValue should be set to the form value
    XCTAssertEqual(testComponent.stringValue, "2")
  }

  func testSkipsWhenDisabled() throws {
    testComponent.items     = [ "A", "B" ]
    testComponent.selection = "A"

    let popup = WOPopUpButton(bindings: [
      "list"      : try keypath("items"),
      "item"      : try keypath("currentItem"),
      "selection" : try keypath("selection"),
      "name"      : value("popup1"),
      "disabled"  : value(true)
    ])

    let req = makePostRequest(formValues: [ "popup1" : "1" ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try popup.takeValues(from: req, in: ctx)

    // Selection should NOT be updated because popup is disabled
    XCTAssertEqual(testComponent.selection as? String, "A")
  }

  func testSkipsMissingFormValue() throws {
    testComponent.items     = [ "A", "B" ]
    testComponent.selection = "A"

    let popup = WOPopUpButton(bindings: [
      "list"      : try keypath("items"),
      "item"      : try keypath("currentItem"),
      "selection" : try keypath("selection"),
      "name"      : value("popup1")
    ])

    // Request without the popup value
    let req = makePostRequest(formValues: [ "other" : "value" ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try popup.takeValues(from: req, in: ctx)

    // Selection should NOT be updated
    XCTAssertEqual(testComponent.selection as? String, "A")
  }


  // MARK: - Linux

  static var allTests = [
    ( "testSelectTagRendering",   testSelectTagRendering   ),
    ( "testOptionRendering",      testOptionRendering      ),
    ( "testSelectedOption",       testSelectedOption       ),
    ( "testNoSelectionString",    testNoSelectionString    ),
    ( "testEscapeHTML",           testEscapeHTML           ),
    ( "testNoEscapeHTML",         testNoEscapeHTML         ),
    ( "testDisabledBinding",      testDisabledBinding      ),
    ( "testIdBinding",            testIdBinding            ),
    ( "testStringBinding",        testStringBinding        ),
    ( "testSelectionByIndex",     testSelectionByIndex     ),
    ( "testNoSelectionSubmit",    testNoSelectionSubmit    ),
    ( "testSelectedValueBinding", testSelectedValueBinding ),
    ( "testSkipsWhenDisabled",    testSkipsWhenDisabled    ),
    ( "testSkipsMissingFormValue", testSkipsMissingFormValue ),
  ]
}
