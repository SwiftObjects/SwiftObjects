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
class TestComponent: WOComponent {

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

  override open func takeValue(_ value: Any?, forKey key: String) throws {
    switch key {
      case "stringValue":  stringValue  = value as? String
      case "intValue":     intValue     = (value as? Int) ?? 0
      case "boolValue":    boolValue    = (value as? Bool) ?? false
      case "dateValue":    dateValue    = value as? Date
      case "arrayValue":   arrayValue   = (value as? [ Any ]) ?? []
      case "selection":    selection    = value
      case "items":        items        = (value as? [ Any ]) ?? []
      case "currentItem":  currentItem  = value
      case "currentIndex": currentIndex = (value as? Int) ?? 0
      case "isEven":       isEven       = (value as? Bool) ?? false
      case "isFirst":      isFirst      = (value as? Bool) ?? false
      case "isLast":       isLast       = (value as? Bool) ?? false
      default: try super.takeValue(value, forKey: key)
    }
  }

  override open func value(forKey key: String) -> Any? {
    switch key {
      case "stringValue":  return stringValue
      case "intValue":     return intValue
      case "boolValue":    return boolValue
      case "dateValue":    return dateValue
      case "arrayValue":   return arrayValue
      case "selection":    return selection
      case "items":        return items
      case "currentItem":  return currentItem
      case "currentIndex": return currentIndex
      case "isEven":       return isEven
      case "isFirst":      return isFirst
      case "isLast":       return isLast
      case "testAction":   return testAction
      default: return super.value(forKey: key)
    }
  }
}
