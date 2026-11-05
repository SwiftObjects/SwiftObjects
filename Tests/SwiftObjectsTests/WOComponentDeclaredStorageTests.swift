//
//  WOComponentDeclaredStorageTests.swift
//  SwiftObjectsTests
//
//  Created by Helge Hess on 04.11.26.
//  Copyright © 2026 ZeeZide. All rights reserved.
//

import XCTest
@testable import SwiftObjects

final class WOComponentDeclaredStorageTests : XCTestCase {

  @WOComponent open class MacroStatelessPage {

    public var isStateless : Bool { return true }
    var value : Any? = nil { didSet { changes += 1 } }
    var k       = "key"
    var changes = 0
    var resets  = 0

    public func reset() { resets += 1 }
  }

  @WOComponent public final class MacroPublicSubPage : MacroStatelessPage {

    var counter = 0

    public override func pageWithName(_ name: String) -> WOComponent? {
      counter += 1
      return super.pageWithName(name)
    }
  }


  func testDeclaredIsStatelessIsUsed() {
    let page : WOComponent = MacroPublicSubPage()
    XCTAssertTrue(page.isStateless)
  }

  func testObservedPropertyIsSettable() throws {
    let page = MacroStatelessPage()
    try page.takeValue("Hello", forKey: "value")
    XCTAssertEqual(page.value as? String, "Hello")
    XCTAssertEqual(page.changes, 1)
    XCTAssertEqual(page.value(forKey: "changes") as? Int, 1)
  }

  func testPropertiesNamedLikeParameters() throws {
    let page = MacroStatelessPage()
    XCTAssertEqual(page.value(forKey: "k") as? String, "key")
    try page.takeValue("other", forKey: "k")
    XCTAssertEqual(page.k, "other")
    XCTAssertEqual(page.value(forKey: "value") as? String, nil)
  }

  func testPageWithNameIsOverridable() {
    let page = MacroPublicSubPage()
    let base : WOComponent = page
    XCTAssertNil(base.pageWithName("Missing")) // no application assigned
    XCTAssertEqual(page.counter, 1)
  }

  func testPublicSubclassAccessors() throws {
    let page : WOComponent = MacroPublicSubPage()
    try page.takeValue("7", forKey: "counter")
    XCTAssertEqual(page.value(forKey: "counter") as? Int, 7)
    try page.takeValue("42", forKey: "changes")
    XCTAssertEqual(page.value(forKey: "changes") as? Int, 42)
  }
}
