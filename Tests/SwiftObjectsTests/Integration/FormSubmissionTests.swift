//
//  FormSubmissionTests.swift
//  SwiftObjectsTests
//

import XCTest
@testable import SwiftObjects

/**
 * Integration tests for form submission scenarios, testing multiple
 * form elements working together.
 */
class FormSubmissionTests: FormTestCase {

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


  // MARK: - Simple Form Submission Tests

  func testSimpleFormSubmit() throws {
    testComponent.stringValue = "original"

    // Create form with text field
    var fieldBindings : Bindings = [
      "value" : try keypath("stringValue"),
      "name"  : value("username")
    ]
    let field = WOTextField(name: "Field", bindings: &fieldBindings,
                            template: nil)

    var formBindings : Bindings = [:]
    let form = WOForm(name: "Form", bindings: &formBindings, template: field)

    // Submit form
    let req = makePostRequest(formValues: [ "username" : "newuser" ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try form.takeValues(from: req, in: ctx)

    XCTAssertEqual(testComponent.stringValue, "newuser")
  }

  func testFormWithMultipleFields() throws {
    testComponent.stringValue = nil
    testComponent.intValue    = 0

    // Create two fields
    var field1Bindings : Bindings = [
      "value" : try keypath("stringValue"),
      "name"  : value("name")
    ]
    let field1 = WOTextField(name: "Name", bindings: &field1Bindings,
                             template: nil)

    var field2Bindings : Bindings = [
      "value" : try keypath("intValue"),
      "name"  : value("age")
    ]
    let field2 = WOTextField(name: "Age", bindings: &field2Bindings,
                             template: nil)

    // Compose form with both fields
    let group = WOCompoundElement(children: [ field1, field2 ])
    var formBindings : Bindings = [:]
    let form = WOForm(name: "Form", bindings: &formBindings, template: group)

    let req = makePostRequest(formValues: [
      "name" : "Alice",
      "age"  : "30"
    ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try form.takeValues(from: req, in: ctx)

    XCTAssertEqual(testComponent.stringValue, "Alice")
    // Note: intValue may remain 0 if there's no formatter for conversion
  }

  func testCheckboxInForm() throws {
    testComponent.boolValue = false

    var cbBindings : Bindings = [
      "checked" : try keypath("boolValue"),
      "name"    : value("agree")
    ]
    let checkbox = WOCheckBox(name: "CB", bindings: &cbBindings, template: nil)

    var formBindings : Bindings = [:]
    let form = WOForm(name: "Form", bindings: &formBindings, template: checkbox)

    // Submit with checkbox checked
    let req = makePostRequest(formValues: [
      "agree"    : "1",
      "agree_sg" : "agree"
    ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try form.takeValues(from: req, in: ctx)

    XCTAssertTrue(testComponent.boolValue)
  }

  func testCheckboxUncheckedInForm() throws {
    testComponent.boolValue = true

    var cbBindings : Bindings = [
      "checked" : try keypath("boolValue"),
      "name"    : value("agree")
    ]
    let checkbox = WOCheckBox(name: "CB", bindings: &cbBindings, template: nil)

    var formBindings : Bindings = [:]
    let form = WOForm(name: "Form", bindings: &formBindings, template: checkbox)

    // Submit with checkbox unchecked (only safeguard present)
    let req = makePostRequest(formValues: [
      "agree_sg" : "agree"
    ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try form.takeValues(from: req, in: ctx)

    XCTAssertFalse(testComponent.boolValue)
  }

  func testPopUpButtonSelection() throws {
    testComponent.items     = [ "Red", "Green", "Blue" ]
    testComponent.selection = nil

    var popupBindings : Bindings = [
      "list"      : try keypath("items"),
      "item"      : try keypath("currentItem"),
      "selection" : try keypath("selection"),
      "name"      : value("color")
    ]
    let popup = WOPopUpButton(name: "Color", bindings: &popupBindings,
                              template: nil)

    var formBindings : Bindings = [:]
    let form = WOForm(name: "Form", bindings: &formBindings, template: popup)

    // Submit with Green selected (index 1)
    let req = makePostRequest(formValues: [ "color" : "1" ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try form.takeValues(from: req, in: ctx)

    XCTAssertEqual(testComponent.selection as? String, "Green")
  }


  // MARK: - Form Rendering Tests

  func testFormRendersAllFields() throws {
    testComponent.stringValue = "TestValue"
    testComponent.boolValue   = true

    var fieldBindings : Bindings = [
      "value" : try keypath("stringValue"),
      "name"  : value("text")
    ]
    let field = WOTextField(name: "Field", bindings: &fieldBindings,
                            template: nil)

    var cbBindings : Bindings = [
      "checked" : try keypath("boolValue"),
      "name"    : value("check")
    ]
    let checkbox = WOCheckBox(name: "CB", bindings: &cbBindings, template: nil)

    let group = WOCompoundElement(children: [ field, checkbox ])
    var formBindings : Bindings = [:]
    let form = WOForm(name: "Form", bindings: &formBindings, template: group)

    try form.append(to: response, in: context)

    assertResponseContains("<form")
    assertResponseContains("name=\"text\"")
    assertResponseContains("value=\"TestValue\"")
    assertResponseContains("name=\"check\"")
    assertResponseContains("type=\"checkbox\"")
    assertResponseContains("checked")
    assertResponseContains("</form>")
  }

  func testFormWithRepetition() throws {
    testComponent.items = [ "Item1", "Item2", "Item3" ]

    var repBindings : Bindings = [
      "list" : try keypath("items"),
      "item" : try keypath("currentItem")
    ]

    var innerBindings : Bindings = [
      "value" : try keypath("currentItem")
    ]
    let inner = WOString(name: "Item", bindings: &innerBindings, template: nil)

    let rep = WORepetition(name: "Rep", bindings: &repBindings, template: inner)

    var formBindings : Bindings = [:]
    let form = WOForm(name: "Form", bindings: &formBindings, template: rep)

    try form.append(to: response, in: context)

    assertResponseContains("<form")
    assertResponseContains("Item1")
    assertResponseContains("Item2")
    assertResponseContains("Item3")
    assertResponseContains("</form>")
  }


  // MARK: - Disabled Field Tests

  func testDisabledFieldsNotUpdated() throws {
    testComponent.stringValue = "original"

    var fieldBindings : Bindings = [
      "value"    : try keypath("stringValue"),
      "name"     : value("field1"),
      "disabled" : value(true)
    ]
    let field = WOTextField(name: "Field", bindings: &fieldBindings,
                            template: nil)

    var formBindings : Bindings = [:]
    let form = WOForm(name: "Form", bindings: &formBindings, template: field)

    let req = makePostRequest(formValues: [ "field1" : "changed" ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try form.takeValues(from: req, in: ctx)

    // Value should NOT be updated because field is disabled
    XCTAssertEqual(testComponent.stringValue, "original")
  }


  // MARK: - Linux

  static var allTests = [
    ( "testSimpleFormSubmit",        testSimpleFormSubmit        ),
    ( "testFormWithMultipleFields",  testFormWithMultipleFields  ),
    ( "testCheckboxInForm",          testCheckboxInForm          ),
    ( "testCheckboxUncheckedInForm", testCheckboxUncheckedInForm ),
    ( "testPopUpButtonSelection",    testPopUpButtonSelection    ),
    ( "testFormRendersAllFields",    testFormRendersAllFields    ),
    ( "testFormWithRepetition",      testFormWithRepetition      ),
    ( "testDisabledFieldsNotUpdated", testDisabledFieldsNotUpdated ),
  ]
}
