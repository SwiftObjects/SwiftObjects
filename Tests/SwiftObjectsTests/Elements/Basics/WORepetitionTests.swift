//
//  WORepetitionTests.swift
//  SwiftObjectsTests
//

import XCTest
@testable import SwiftObjects

class WORepetitionTests: FormTestCase {

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


  // MARK: - append() Tests

  func testEmptyList() throws {
    testComponent.items = []

    let content = WOString(bindings: [ "value" : value("X") ])

    var bindings : Bindings = [
      "list" : try keypath("items"),
      "item" : try keypath("currentItem")
    ]
    let rep = WORepetition(bindings: &bindings, template: content)
    assertBindingsConsumed(bindings)

    try rep.append(to: response, in: context)
    // When nothing is rendered, contentString is nil
    XCTAssert(response.contentString?.isEmpty ?? true)
  }

  func testSingleItemList() throws {
    testComponent.items = [ "Hello" ]

    let content = WOString(bindings: [ "value" : try keypath("currentItem") ])

    var bindings : Bindings = [
      "list" : try keypath("items"),
      "item" : try keypath("currentItem")
    ]
    let rep = WORepetition(bindings: &bindings, template: content)
    assertBindingsConsumed(bindings)

    try rep.append(to: response, in: context)
    XCTAssertEqual(response.contentString, "Hello")
  }

  func testMultipleItems() throws {
    testComponent.items = [ "A", "B", "C" ]

    let content = WOString(bindings: [ "value" : try keypath("currentItem") ])

    var bindings : Bindings = [
      "list" : try keypath("items"),
      "item" : try keypath("currentItem")
    ]
    let rep = WORepetition(bindings: &bindings, template: content)
    assertBindingsConsumed(bindings)

    try rep.append(to: response, in: context)
    XCTAssertEqual(response.contentString, "ABC")
  }

  func testItemBinding() throws {
    testComponent.items = [ "First", "Second", "Third" ]

    let content = WOString(bindings: [ "value" : try keypath("currentItem") ])
    let rep   = WORepetition(bindings: [
      "list" : try keypath("items"),
      "item" : try keypath("currentItem")
    ], template: content)

    try rep.append(to: response, in: context)

    // After iteration, currentItem should hold the last value
    // We verify the output which shows all items were processed
    XCTAssertEqual(response.contentString, "FirstSecondThird")
  }

  func testIndexBinding() throws {
    testComponent.items = [ "A", "B", "C" ]

    let content = WOString(bindings: [ "value" : try keypath("currentIndex") ])

    var bindings : Bindings = [
      "list"  : try keypath("items"),
      "item"  : try keypath("currentItem"),
      "index" : try keypath("currentIndex")
    ]
    let rep = WORepetition(bindings: &bindings, template: content)
    assertBindingsConsumed(bindings)

    try rep.append(to: response, in: context)
    XCTAssertEqual(response.contentString, "012")
  }

  func testIndex1Binding() throws {
    testComponent.items = [ "A", "B", "C" ]

    let content = WOString(bindings: [ "value" : try keypath("currentIndex") ])

    var bindings : Bindings = [
      "list"   : try keypath("items"),
      "item"   : try keypath("currentItem"),
      "index1" : try keypath("currentIndex")
    ]
    let rep = WORepetition(bindings: &bindings, template: content)
    assertBindingsConsumed(bindings)

    try rep.append(to: response, in: context)
    XCTAssertEqual(response.contentString, "123")
  }

  func testSeparator() throws {
    testComponent.items = [ "A", "B", "C" ]

    let content = WOString(bindings: [ "value" : try keypath("currentItem") ])

    var bindings : Bindings = [
      "list"      : try keypath("items"),
      "item"      : try keypath("currentItem"),
      "separator" : value(", ")
    ]
    let rep = WORepetition(bindings: &bindings, template: content)
    assertBindingsConsumed(bindings)

    try rep.append(to: response, in: context)
    XCTAssertEqual(response.contentString, "A, B, C")
  }

  func testIsEvenBinding() throws {
    testComponent.items = [ "A", "B", "C", "D" ]

    // Render "E" for even
    let evenStr = WOString(bindings: [ "value" : value("E") ])
    let cond    = WOConditional(bindings: [ "condition" : try keypath("isEven") ],
                                template: evenStr)

    var bindings : Bindings = [
      "list"   : try keypath("items"),
      "item"   : try keypath("currentItem"),
      "isEven" : try keypath("isEven")
    ]
    let rep = WORepetition(bindings: &bindings, template: cond)
    assertBindingsConsumed(bindings)

    try rep.append(to: response, in: context)
    // isEven: idx 0 = false (1st), 1 = true (2nd), 2 = false, 3 = true
    XCTAssertEqual(response.contentString, "EE")
  }

  func testIsFirstBinding() throws {
    testComponent.items = [ "A", "B", "C" ]

    let firstStr = WOString(bindings: [ "value" : value("[FIRST]") ])
    let cond     = WOConditional(bindings: [ "condition" : try keypath("isFirst") ],
                                 template: firstStr)

    var bindings : Bindings = [
      "list"    : try keypath("items"),
      "item"    : try keypath("currentItem"),
      "isFirst" : try keypath("isFirst")
    ]
    let rep = WORepetition(bindings: &bindings, template: cond)
    assertBindingsConsumed(bindings)

    try rep.append(to: response, in: context)
    XCTAssertEqual(response.contentString, "[FIRST]")
  }

  func testIsLastBinding() throws {
    testComponent.items = [ "A", "B", "C" ]

    let lastStr = WOString(bindings: [ "value" : value("[LAST]") ])
    let cond    = WOConditional(bindings: [ "condition" : try keypath("isLast") ],
                                template: lastStr)

    var bindings : Bindings = [
      "list"   : try keypath("items"),
      "item"   : try keypath("currentItem"),
      "isLast" : try keypath("isLast")
    ]
    let rep = WORepetition(bindings: &bindings, template: cond)
    assertBindingsConsumed(bindings)

    try rep.append(to: response, in: context)
    XCTAssertEqual(response.contentString, "[LAST]")
  }

  func testElementNameWrapper() throws {
    testComponent.items = [ "A", "B" ]

    let content = WOString(bindings: [ "value" : try keypath("currentItem") ])

    var bindings : Bindings = [
      "list"        : try keypath("items"),
      "item"        : try keypath("currentItem"),
      "elementName" : value("li")
    ]
    let rep = WORepetition(bindings: &bindings, template: content)
    assertBindingsConsumed(bindings)

    try rep.append(to: response, in: context)
    XCTAssertEqual(response.contentString, "<li>A</li><li>B</li>")
  }


  // MARK: - takeValues() Tests

  func testTakeValuesIteratesItems() throws {
    testComponent.items = [ "A", "B", "C" ]

    let content = WOString(bindings: [ "value" : try keypath("currentItem") ])
    let rep   = WORepetition(bindings: [
      "list"  : try keypath("items"),
      "item"  : try keypath("currentItem"),
      "index" : try keypath("currentIndex")
    ], template: content)

    // takeValues should iterate all items
    try rep.takeValues(from: request, in: context)

    // After iteration, index should be at the last item (2)
    // This verifies the walker executed for all items
    XCTAssertEqual(testComponent.currentIndex, 2)
  }


  // MARK: - Linux

  static var allTests = [
    ( "testEmptyList",              testEmptyList              ),
    ( "testSingleItemList",         testSingleItemList         ),
    ( "testMultipleItems",          testMultipleItems          ),
    ( "testItemBinding",            testItemBinding            ),
    ( "testIndexBinding",           testIndexBinding           ),
    ( "testIndex1Binding",          testIndex1Binding          ),
    ( "testSeparator",              testSeparator              ),
    ( "testIsEvenBinding",          testIsEvenBinding          ),
    ( "testIsFirstBinding",         testIsFirstBinding         ),
    ( "testIsLastBinding",          testIsLastBinding          ),
    ( "testElementNameWrapper",     testElementNameWrapper     ),
    ( "testTakeValuesIteratesItems", testTakeValuesIteratesItems ),
  ]
}
