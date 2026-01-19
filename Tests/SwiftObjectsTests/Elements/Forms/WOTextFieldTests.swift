//
//  WOTextFieldTests.swift
//  SwiftObjectsTests
//

import XCTest
@testable import SwiftObjects

class WOTextFieldTests: FormTestCase {

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

  func testInputTypeText() throws {
    var bindings : Bindings = [
      "value" : try keypath("stringValue"),
      "name"  : value("field1")
    ]

    let field = WOTextField(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try field.append(to: response, in: context)
    assertResponseContains("type=\"text\"")
  }

  func testNameBinding() throws {
    let field = WOTextField(bindings: [
      "value" : try keypath("stringValue"),
      "name"  : value("myField")
    ])

    try field.append(to: response, in: context)
    assertResponseContains("name=\"myField\"")
  }

  func testValueBinding() throws {
    testComponent.stringValue = "Hello World"

    let field = WOTextField(bindings: [
      "value" : try keypath("stringValue"),
      "name"  : value("field1")
    ])

    try field.append(to: response, in: context)
    assertResponseContains("value=\"Hello World\"")
  }

  func testSizeBinding() throws {
    var bindings : Bindings = [
      "value" : try keypath("stringValue"),
      "name"  : value("field1"),
      "size"  : value(20)
    ]

    let field = WOTextField(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try field.append(to: response, in: context)
    assertResponseContains("size=\"20\"")
  }

  func testDisabledBinding() throws {
    var bindings : Bindings = [
      "value"    : try keypath("stringValue"),
      "name"     : value("field1"),
      "disabled" : value(true)
    ]

    let field = WOTextField(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try field.append(to: response, in: context)
    assertResponseContains("disabled")
  }

  func testReadonlyBinding() throws {
    var bindings : Bindings = [
      "value"    : try keypath("stringValue"),
      "name"     : value("field1"),
      "readonly" : value(true)
    ]

    let field = WOTextField(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try field.append(to: response, in: context)
    assertResponseContains("readonly")
  }

  func testIdBinding() throws {
    var bindings : Bindings = [
      "value" : try keypath("stringValue"),
      "name"  : value("field1"),
      "id"    : value("my-field-id")
    ]

    let field = WOTextField(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try field.append(to: response, in: context)
    assertResponseContains("id=\"my-field-id\"")
  }

  func testIdNameShortcut() throws {
    // idname sets both id and name to the same value
    // The framework internally adds an "id" binding from idname
    var bindings : Bindings = [
      "value"  : try keypath("stringValue"),
      "idname" : value("combined")
    ]

    let field = WOTextField(bindings: &bindings)
    // idname creates an internal id binding which stays in bindings
    bindings.removeValue(forKey: "id")
    assertBindingsConsumed(bindings)

    try field.append(to: response, in: context)
    assertResponseContains("name=\"combined\"")
  }


  // MARK: - takeValues Tests

  func testTakeValueFromForm() throws {
    testComponent.stringValue = "original"

    let field = WOTextField(bindings: [
      "value" : try keypath("stringValue"),
      "name"  : value("field1")
    ])

    let req = makePostRequest(formValues: [ "field1" : "updated" ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try field.takeValues(from: req, in: ctx)

    XCTAssertEqual(testComponent.stringValue, "updated")
  }

  func testTrimBinding() throws {
    testComponent.stringValue = "original"

    let field = WOTextField(bindings: [
      "value" : try keypath("stringValue"),
      "name"  : value("field1"),
      "trim"  : value(true)
    ])

    let req = makePostRequest(formValues: [ "field1" : "  trimmed  " ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try field.takeValues(from: req, in: ctx)

    XCTAssertEqual(testComponent.stringValue, "trimmed")
  }

  func testSkipsWhenDisabled() throws {
    testComponent.stringValue = "original"

    let field = WOTextField(bindings: [
      "value"    : try keypath("stringValue"),
      "name"     : value("field1"),
      "disabled" : value(true)
    ])

    let req = makePostRequest(formValues: [ "field1" : "should-not-update" ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try field.takeValues(from: req, in: ctx)

    // Value should NOT be updated because field is disabled
    XCTAssertEqual(testComponent.stringValue, "original")
  }

  func testSkipsMissingFormValue() throws {
    testComponent.stringValue = "original"

    let field = WOTextField(bindings: [
      "value" : try keypath("stringValue"),
      "name"  : value("field1")
    ])

    // Request without the field value
    let req = makePostRequest(formValues: [ "otherField" : "value" ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try field.takeValues(from: req, in: ctx)

    // Value should NOT be updated because field was not in form
    XCTAssertEqual(testComponent.stringValue, "original")
  }

  func testReadWriteValueBindings() throws {
    testComponent.stringValue = "readValue"
    testComponent.selection   = nil

    let field = WOTextField(bindings: [
      "readValue"  : try keypath("stringValue"),
      "writeValue" : try keypath("selection"),
      "name"       : value("field1")
    ])

    // Render should use readValue
    try field.append(to: response, in: context)
    assertResponseContains("value=\"readValue\"")

    // Take values should use writeValue
    let req = makePostRequest(formValues: [ "field1" : "writeValue" ])
    let ctx = makeContext(for: req)
    ctx.enterComponent(testComponent)

    try field.takeValues(from: req, in: ctx)

    XCTAssertEqual(testComponent.stringValue, "readValue") // unchanged
    XCTAssertEqual(testComponent.selection as? String, "writeValue")
  }


  // MARK: - Linux

  static var allTests = [
    ( "testInputTypeText",         testInputTypeText         ),
    ( "testNameBinding",           testNameBinding           ),
    ( "testValueBinding",          testValueBinding          ),
    ( "testSizeBinding",           testSizeBinding           ),
    ( "testDisabledBinding",       testDisabledBinding       ),
    ( "testReadonlyBinding",       testReadonlyBinding       ),
    ( "testIdBinding",             testIdBinding             ),
    ( "testIdNameShortcut",        testIdNameShortcut        ),
    ( "testTakeValueFromForm",     testTakeValueFromForm     ),
    ( "testTrimBinding",           testTrimBinding           ),
    ( "testSkipsWhenDisabled",     testSkipsWhenDisabled     ),
    ( "testSkipsMissingFormValue", testSkipsMissingFormValue ),
    ( "testReadWriteValueBindings", testReadWriteValueBindings ),
  ]
}
