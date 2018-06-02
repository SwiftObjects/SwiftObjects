//
//  WOLabelAssociation.swift
//  SwiftObjects
//
//  Created by Helge Hess on 19.05.18.
//

/**
 * String value syntax:
 *
 *     "next"       - lookup key 'next' in table 'nil'   with default 'next'
 *     "table/next" - lookup key 'next' in table 'table' with default 'next'
 *
 * This association performs a string lookup in the component's
 * WOResourceManager (or the app's manager if the component has none). It uses
 * the context's languages for the key lookup.
 *
 * Note that this also supports keypaths by prefixing the values with an
 * "$", eg: "$currentDay" will first evaluate "currentDay" in the component
 * and then pipe the result through the label processor.
 * We consider that a bit hackish, but given that it is often required in
 * practice, a pragmatic implementation.
 */
open class WOLabelAssocation : WOAssociation, SmartDescription {
  
  let key          : String
  let table        : String?
  let defaultValue : String?
  let isKeyKeyPath   = false
  let isTableKeyPath = false
  let isValueKeyPath = false

  public init(key: String, table: String?, defaultValue: String?) {
    self.key          = key
    self.table        = table
    self.defaultValue = defaultValue
  }
  
  public convenience init(key: String) {
    // TODO: parse `$` keypath markers
    
    if let idx = key.index(of: "/") {
      let table  = String(key[key.startIndex..<idx])
      let newKey = String(key[key.index(after: idx)..<key.endIndex])
      self.init(key: newKey, table: table, defaultValue: nil)
    }
    else {
      self.init(key: key, table: nil, defaultValue: nil)
    }
  }
  
  open var keyPath : String? { return key }

  open var isValueConstant : Bool { return false }
  open var isValueSettable : Bool { return false }
  
  open func value(in component: Any?) -> Any? {
    return stringValue(in: component)
  }
  
  open func stringValue(in cursor: Any?) -> String? {
    let resourceManager : WOResourceManager
    let context         : WOContext?
    
    if let component = cursor as? WOComponent {
      context = component.context
      guard let rm = component.resourceManager
                  ?? context?.application.resourceManager else {
        return defaultValue // FIXME: KVC?
      }
      resourceManager = rm
    }
    else if let lc = cursor as? WOContext {
      context = lc
      guard let rm = lc.application.resourceManager else {
        return defaultValue // FIXME: KVC?
      }
      resourceManager = rm
    }
    else if let app = cursor as? WOApplication {
      guard let rm = app.resourceManager else { return defaultValue }
      resourceManager = rm
      context = nil
    }
    else {
      return defaultValue
    }
    
    let lKey : String? = {
      if !isKeyKeyPath { return key }
      let v = KeyValueCoding.value(forKey: key, inObject: cursor)
      return UObject.stringValue(v)
    }()
    
    let lTable : String? = {
      guard let table = table else { return nil }
      if !isTableKeyPath { return table }
      let v = KeyValueCoding.value(forKey: table, inObject: cursor)
      return UObject.stringValue(v)
    }()
    
    let lValue : String? = {
      guard let value = defaultValue else { return nil }
      if !isValueKeyPath { return value }
      let v = KeyValueCoding.value(forKey: value, inObject: cursor)
      return UObject.stringValue(v)
    }()
    
    guard let rKey = lKey else {
      return lValue ?? defaultValue
    }
    
    return resourceManager.stringForKey(rKey, in: lTable, default: lValue,
                                        framework: nil,
                                        languages: context?.languages ?? [])
  }
  
  
  // MARK: - Description

  open func appendToDescription(_ ms: inout String) {
    ms += " "
    ms += key
    if let s = table        { ms += " table=\(s)" }
    if let s = defaultValue { ms += " default=\(s)" }
  }
}
