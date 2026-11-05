//
//  TestComponent.swift
//  SwiftObjectsTests
//

import Foundation
@testable import SwiftObjects

/**
 * A test component with various typed properties for binding tests.
 * Supports KVC for all properties.
 */
@WOComponent final class TestComponent {

  var stringValue  : String? = nil
  var intValue     : Int     = 0
  var boolValue    : Bool    = false
  var dateValue    : Date?   = nil
  var arrayValue   : [ Any ] = []
  var selection    : Any?    = nil
  var items        : [ Any ] = []
  var currentItem  : Any?    = nil
  var currentIndex : Int     = 0
  var isEven       : Bool    = false
  var isFirst      : Bool    = false
  var isLast       : Bool    = false

  var actionCalled      = false
  var actionCalledCount = 0

  func testAction() -> WOComponent? {
    actionCalled = true
    actionCalledCount += 1
    return self
  }
}
