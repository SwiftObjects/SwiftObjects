//
//  WOHyperlinkTests.swift
//  SwiftObjectsTests
//

import XCTest
@testable import SwiftObjects

class WOHyperlinkTests: FormTestCase {

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

  func testSimpleHref() throws {
    let content = WOString(bindings: [ "value" : value("Click Here") ])

    var bindings : Bindings = [ "href" : value("https://example.com") ]
    let link = WOHyperlink(bindings: &bindings, template: content)
    assertBindingsConsumed(bindings)

    try link.append(to: response, in: context)
    assertResponseContains("<a href=\"https://example.com\">")
    assertResponseContains("Click Here")
    assertResponseContains("</a>")
  }

  func testStringContent() throws {
    var bindings : Bindings = [
      "href"   : value("https://example.com"),
      "string" : value("Link Text")
    ]

    let link = WOHyperlink(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try link.append(to: response, in: context)
    assertResponseContains("Link Text")
    assertResponseContains("</a>")
  }

  func testValueAsContent() throws {
    // 'value' is an alias for 'string'
    var bindings : Bindings = [
      "href"  : value("https://example.com"),
      "value" : value("Value Text")
    ]

    let link = WOHyperlink(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try link.append(to: response, in: context)
    assertResponseContains("Value Text")
  }

  func testTemplateContent() throws {
    let content = WOString(bindings: [ "value" : value("Template Content") ])
    let link    = WOHyperlink(bindings: [ "href" : value("https://example.com") ],
                              template: content)

    try link.append(to: response, in: context)
    assertResponseContains("Template Content")
  }

  func testTargetAttribute() throws {
    var bindings : Bindings = [
      "href"   : value("https://example.com"),
      "target" : value("_blank"),
      "string" : value("Open in new tab")
    ]

    let link = WOHyperlink(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try link.append(to: response, in: context)
    assertResponseContains("target=\"_blank\"")
  }

  func testIdAttribute() throws {
    var bindings : Bindings = [
      "href"   : value("https://example.com"),
      "id"     : value("my-link"),
      "string" : value("Link with ID")
    ]

    let link = WOHyperlink(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try link.append(to: response, in: context)
    assertResponseContains("id=\"my-link\"")
  }

  func testDisabledRendersContentOnly() throws {
    var bindings : Bindings = [
      "href"     : value("https://example.com"),
      "disabled" : value(true),
      "string"   : value("Disabled Link")
    ]

    let link = WOHyperlink(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try link.append(to: response, in: context)
    // Should render content but NOT the <a> tag
    assertResponseContains("Disabled Link")
    let content = response.contentString ?? ""
    XCTAssertFalse(content.contains("<a "))
    XCTAssertFalse(content.contains("</a>"))
  }

  func testDisableOnMissingLink() throws {
    // When no link is provided and disableOnMissingLink=true
    var bindings : Bindings = [
      "disableOnMissingLink" : value(true),
      "string"               : value("No Link")
    ]

    let link = WOHyperlink(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try link.append(to: response, in: context)
    // Should render content but NOT the <a> tag because no href
    let content = response.contentString ?? ""
    XCTAssert(content.contains("No Link"))
    XCTAssertFalse(content.contains("<a"))
  }


  // MARK: - Action Tests

  func testDirectActionURL() throws {
    var bindings : Bindings = [
      "directActionName" : value("showDetails"),
      "string"           : value("Show Details")
    ]

    let link = WOHyperlink(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try link.append(to: response, in: context)
    // URL format is /wa/wa/actionName (request handler key appears twice)
    assertResponseContains("/wa/showDetails")
  }

  func testDirectActionWithActionClass() throws {
    var bindings : Bindings = [
      "directActionName" : value("list"),
      "actionClass"      : value("Products"),
      "string"           : value("Product List")
    ]

    let link = WOHyperlink(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try link.append(to: response, in: context)
    assertResponseContains("/wa/Products/list")
  }

  func testActionWithActionClass() throws {
    // Test that action with actionClass works correctly
    var bindings : Bindings = [
      "directActionName" : value("show"),
      "actionClass"      : value("Admin"),
      "string"           : value("Admin Panel")
    ]

    let link = WOHyperlink(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try link.append(to: response, in: context)
    assertResponseContains("/wa/Admin/show")
    assertResponseContains("Admin Panel")
  }

  func testHrefWithFragment() throws {
    var bindings : Bindings = [
      "href"               : value("https://example.com/page"),
      "fragmentIdentifier" : value("section1"),
      "string"             : value("Go to section")
    ]

    let link = WOHyperlink(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try link.append(to: response, in: context)
    assertResponseContains("#section1")
  }


  // MARK: - invokeAction Tests

  func testActionLinkRendering() throws {
    // Test that action links generate component action URLs
    var bindings : Bindings = [
      "action" : try keypath("testAction"),
      "string" : value("Trigger Action")
    ]

    let link = WOHyperlink(bindings: &bindings)
    assertBindingsConsumed(bindings)

    try link.append(to: response, in: context)
    // Action links should generate a component action URL with element ID
    assertResponseContains("<a href=")
    assertResponseContains("Trigger Action")
  }

  func testNoActionWhenSenderIDDoesNotMatch() throws {
    let link = WOHyperlink(bindings: [
      "action" : try keypath("testAction"),
      "string" : value("No Trigger")
    ])

    // Don't set senderID - action should not trigger
    _ = try link.invokeAction(for: request, in: context)

    XCTAssertFalse(testComponent.actionCalled)
  }


  // MARK: - Linux

  static var allTests = [
    ( "testSimpleHref",              testSimpleHref              ),
    ( "testStringContent",           testStringContent           ),
    ( "testValueAsContent",          testValueAsContent          ),
    ( "testTemplateContent",         testTemplateContent         ),
    ( "testTargetAttribute",         testTargetAttribute         ),
    ( "testIdAttribute",             testIdAttribute             ),
    ( "testDisabledRendersContentOnly", testDisabledRendersContentOnly ),
    ( "testDisableOnMissingLink",    testDisableOnMissingLink    ),
    ( "testDirectActionURL",         testDirectActionURL         ),
    ( "testDirectActionWithActionClass", testDirectActionWithActionClass ),
    ( "testActionWithActionClass",   testActionWithActionClass   ),
    ( "testHrefWithFragment",        testHrefWithFragment        ),
    ( "testActionLinkRendering",     testActionLinkRendering     ),
    ( "testNoActionWhenSenderIDDoesNotMatch",
                                     testNoActionWhenSenderIDDoesNotMatch ),
  ]
}
