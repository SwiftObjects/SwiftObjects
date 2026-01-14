//
//  WOCheckBoxTests.swift
//  SwiftObjectsTests
//

import XCTest
@testable import SwiftObjects

class WOCheckBoxTests: FormTestCase {

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

  func testInputTypeCheckbox() throws {
    var bindings : Bindings = [
      "checked" : try keypath("boolValue"),
      "name"    : value("cb1")
    ]

    let checkbox = WOCheckBox(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try checkbox.append(to: response, in: context)
    assertResponseContains("type=\"checkbox\"")
  }

  func testNameBinding() throws {
    let checkbox = WOCheckBox(bindings: [
      "checked" : try keypath("boolValue"),
      "name"    : value("myCheckbox")
    ])

    try checkbox.append(to: response, in: context)
    assertResponseContains("name=\"myCheckbox\"")
  }

  func testCheckedAttributeWhenTrue() throws {
    testComponent.boolValue = true

    let checkbox = WOCheckBox(bindings: [
      "checked" : try keypath("boolValue"),
      "name"    : value("cb1")
    ])

    try checkbox.append(to: response, in: context)
    assertResponseContains("checked")
  }

  func testNotCheckedWhenFalse() throws {
    testComponent.boolValue = false

    let checkbox = WOCheckBox(bindings: [
      "checked" : try keypath("boolValue"),
      "name"    : value("cb1")
    ])

    try checkbox.append(to: response, in: context)
    let content = response.contentString ?? ""
    XCTAssertFalse(content.contains("checked"))
  }

  func testSafeguardField() throws {
    let checkbox = WOCheckBox(bindings: [
      "checked" : try keypath("boolValue"),
      "name"    : value("cb1")
    ])

    try checkbox.append(to: response, in: context)
    // Safeguard hidden field should be rendered
    assertResponseContains("type=\"hidden\"")
    assertResponseContains("name=\"cb1_sg\"")
  }

  func testValueBinding() throws {
    var bindings : Bindings = [
      "checked" : try keypath("boolValue"),
      "name"    : value("cb1"),
      "value"   : value("customValue")
    ]

    let checkbox = WOCheckBox(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try checkbox.append(to: response, in: context)
    assertResponseContains("value=\"customValue\"")
  }

  func testDefaultValue() throws {
    let checkbox = WOCheckBox(bindings: [
      "checked" : try keypath("boolValue"),
      "name"    : value("cb1")
    ])

    try checkbox.append(to: response, in: context)
    // Default value should be "1"
    assertResponseContains("value=\"1\"")
  }

  func testDisabledBinding() throws {
    var bindings : Bindings = [
      "checked"  : try keypath("boolValue"),
      "name"     : value("cb1"),
      "disabled" : value(true)
    ]

    let checkbox = WOCheckBox(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try checkbox.append(to: response, in: context)
    assertResponseContains("disabled")
  }

  func testIdBinding() throws {
    var bindings : Bindings = [
      "checked" : try keypath("boolValue"),
      "name"    : value("cb1"),
      "id"      : value("my-checkbox-id")
    ]

    let checkbox = WOCheckBox(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try checkbox.append(to: response, in: context)
    assertResponseContains("id=\"my-checkbox-id\"")
  }


  // MARK: - takeValues Tests

  func testCheckboxChecked() throws {
    testComponent.boolValue = false

    let checkbox = WOCheckBox(bindings: [
      "checked" : try keypath("boolValue"),
      "name"    : value("cb1")
    ])

    // When checkbox is submitted, its value is present along with safeguard
    let req = makePostRequest(formValues: [
      "cb1"    : "1",
      "cb1_sg" : "cb1"
    ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try checkbox.takeValues(from: req, in: ctx)

    XCTAssertTrue(testComponent.boolValue)
  }

  func testCheckboxUnchecked() throws {
    testComponent.boolValue = true

    let checkbox = WOCheckBox(bindings: [
      "checked" : try keypath("boolValue"),
      "name"    : value("cb1")
    ])

    // When checkbox is unchecked, only safeguard is submitted (no cb1 value)
    let req = makePostRequest(formValues: [
      "cb1_sg" : "cb1"
    ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try checkbox.takeValues(from: req, in: ctx)

    XCTAssertFalse(testComponent.boolValue)
  }

  func testNoUpdateWithoutSafeguard() throws {
    testComponent.boolValue = true

    let checkbox = WOCheckBox(bindings: [
      "checked" : try keypath("boolValue"),
      "name"    : value("cb1")
    ])

    // Neither checkbox nor safeguard submitted - value should not change
    let req = makePostRequest(formValues: [ "other" : "value" ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try checkbox.takeValues(from: req, in: ctx)

    // Value should remain unchanged since safeguard wasn't submitted
    XCTAssertTrue(testComponent.boolValue)
  }

  func testSkipsWhenDisabled() throws {
    testComponent.boolValue = false

    let checkbox = WOCheckBox(bindings: [
      "checked"  : try keypath("boolValue"),
      "name"     : value("cb1"),
      "disabled" : value(true)
    ])

    let req = makePostRequest(formValues: [
      "cb1"    : "1",
      "cb1_sg" : "cb1"
    ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try checkbox.takeValues(from: req, in: ctx)

    // Value should NOT be updated because checkbox is disabled
    XCTAssertFalse(testComponent.boolValue)
  }

  func testSelectionBinding() throws {
    testComponent.selection = nil

    var bindings : Bindings = [
      "selection" : try keypath("selection"),
      "name"      : value("cb1"),
      "value"     : value("selectedItem")
    ]

    let checkbox = WOCheckBox(bindings: &bindings)
    assertBindingsConsumed(bindings)

    let req = makePostRequest(formValues: [
      "cb1"    : "selectedItem",
      "cb1_sg" : "cb1"
    ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try checkbox.takeValues(from: req, in: ctx)

    XCTAssertEqual(testComponent.selection as? String, "selectedItem")
  }

  func testSelectionClearedWhenUnchecked() throws {
    testComponent.selection = "oldValue"

    let checkbox = WOCheckBox(bindings: [
      "selection" : try keypath("selection"),
      "name"      : value("cb1"),
      "value"     : value("selectedItem")
    ])

    // Submit without checkbox value (unchecked)
    let req = makePostRequest(formValues: [
      "cb1_sg" : "cb1"
    ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try checkbox.takeValues(from: req, in: ctx)

    XCTAssertNil(testComponent.selection)
  }


  // MARK: - Linux

  static var allTests = [
    ( "testInputTypeCheckbox",         testInputTypeCheckbox         ),
    ( "testNameBinding",               testNameBinding               ),
    ( "testCheckedAttributeWhenTrue",  testCheckedAttributeWhenTrue  ),
    ( "testNotCheckedWhenFalse",       testNotCheckedWhenFalse       ),
    ( "testSafeguardField",            testSafeguardField            ),
    ( "testValueBinding",              testValueBinding              ),
    ( "testDefaultValue",              testDefaultValue              ),
    ( "testDisabledBinding",           testDisabledBinding           ),
    ( "testIdBinding",                 testIdBinding                 ),
    ( "testCheckboxChecked",           testCheckboxChecked           ),
    ( "testCheckboxUnchecked",         testCheckboxUnchecked         ),
    ( "testNoUpdateWithoutSafeguard",  testNoUpdateWithoutSafeguard  ),
    ( "testSkipsWhenDisabled",         testSkipsWhenDisabled         ),
    ( "testSelectionBinding",          testSelectionBinding          ),
    ( "testSelectionClearedWhenUnchecked",
                                       testSelectionClearedWhenUnchecked ),
  ]
}
