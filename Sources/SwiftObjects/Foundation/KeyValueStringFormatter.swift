//
//  KeyValueStringFormatter.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation

/**
 * Sample formats:
 *
 *     "%(firstname)s %(lastname)s"
 *
 * Usage:
 *
 *     let s = KeyValueStringFormatter.format(
                 "%(firstname)s %(lastname)s", person)
 *     print(s)
 *
 * Inefficient, crappy implementation, but worx ;-)
 */
final class KeyValueStringFormatter : Formatter, SmartDescription {
  
  let format      : String
  let requiresAll : Bool

  init(format: String, requiresAll: Bool = false) {
    self.format      = format
    self.requiresAll = requiresAll
    super.init()
  }
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  // MARK: - Static Helper
  
  static func format(_ format: String, requiresAll: Bool = false, object: Any?)
              -> String
  {
    let fmt = KeyValueStringFormatter(format: format, requiresAll: requiresAll)
    return fmt.string(for: object) ?? ""
  }
  
  static func format(_ format: String, requiresAll: Bool = false,
                     _ args: Any?...) -> String
  {
    let fmt = KeyValueStringFormatter(format: format, requiresAll: requiresAll)
    return fmt.string(for: args) ?? ""
  }
  
  
  // MARK: - Implementation

  override
  public func string(for obj: Any?) -> String? {
    guard format.contains("%") else { return format }
    
    let valuesHandler : KeyValueStringFormatterValueHandler
    if let array = obj as? [ Any? ] {
      valuesHandler = ArrayValueHandler(array: array)
    }
    else {
      valuesHandler = KeyValueHandler(object: obj)
    }
    
    // TODO: pre-parse this into an array structure (RawValue/PatternPart)
    var s = ""
    var idx = format.startIndex
    while idx < format.endIndex {
      var c = format[idx]
      idx = format.index(after: idx)
      
      if c != "%" {
        s += String(c) // TODO: speedz
        continue
      }
      
      /* found a marker */
      
      guard idx != format.endIndex else {
        s += "%" // last char. Technically a syntax error ...
        break
      }
      
      c = format[idx]
      guard c != "%" else {
        // a quoted per-cent, %%
        s += "%"
        idx = format.index(after: idx)
        continue
      }

      /* check for a keypath, eg %(lastname)s */
      
      var key : String? = nil
      if c == "(" && format.canLA(4, startIndex: idx) { /* %(n)i */
        idx = format.index(after: idx)
        let keyStart = idx
        while idx < format.endIndex, format[idx] != ")" {
          
          idx = format.index(after: idx)
        }
        if idx == format.endIndex {
          // early close
          s += "%("
          s += format[keyStart..<format.endIndex]
          break
        }
        
        key = String(format[keyStart..<idx])
        idx = format.index(after: idx) // consume ')'
        if idx == format.endIndex {
          // early close
          s += "%("
          s += format[keyStart..<format.endIndex]
          s += ")"
          break
        }
        
        c = format[idx]
      }
      
      /* determine value */

      let value   = valuesHandler.value(forKey: key ?? "")
      let keyMiss = valuesHandler.lastKeyWasMiss
      
      if keyMiss && requiresAll {
        return nil
      }

      /* format */
      
      idx = format.index(after: idx) // consume format char

      switch c {
        case "i":
          guard let v = value else {
            s += "0" // null as 0
            continue
          }
          s += "\(v)" // TBD: right? first parse as Int?
        
        case "@", "s":
          guard let v = value else {
            s += "<nil>"
            continue
          }
          if let vs = v as? String { s += vs }
          else { s += "\(v)" }

        case "U":
          guard let v = value else {
            s += "<nil>"
            continue
          }
          let vvs : String
          if let vs = v as? String { vvs = vs }
          else                     { vvs = "\(v)" }
          if let vs =
            vvs.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
          {
            s += vs
          }

        default:
          s += "%"
          if let key = key {
            s += "(" + key + ")"
          }
          s += String(c)
      }
    }
    
    return s
  }

  func appendToDescription(_ ms: inout String) {
    ms += " format=\(format)"
    if requiresAll { ms += " requires-all" }
  }


  // MARK: - Value Handlers
  
  final class KeyValueHandler : KeyValueStringFormatterValueHandler {
    let lastKeyWasMiss = false
    let object : Any?
    
    init(object: Any?) {
      self.object = object
    }
    
    func value(forKey key: String) -> Any? {
      return KeyValueCoding.value(forKeyPath: key, inObject: object)
    }
  }
  
  final class ArrayValueHandler : KeyValueStringFormatterValueHandler {
    var lastKeyWasMiss = false
    let array  : [ Any? ]
    var cursor : Int = 0
    
    init(array: [ Any? ]) {
      self.array = array
    }
    
    /**
     * In the array implementation this usually is invoked without a key. When
     * its called, it consumes a position in the value array as a sideeffect.
     * Hence, you may not call it multiple times!!!
     *
     * However, it does support some keys which do *not* advance the position:
     *
     * - 'length', 'size', 'count'
     * - an Integer is parsed as an index, eg %(2)s => array[2]
     */
    func value(forKey key: String) -> Any? {
      if key.isEmpty {
        guard cursor < array.count else {
          lastKeyWasMiss = true
          return nil
        }
        let value = array[cursor]
        cursor += 1
        return value
      }
      
      if key == "length" || key == "count" || key == "size" {
        return array.count
      }
      
      if let idx = Int(key) {
        guard idx < array.count else {
          lastKeyWasMiss = true
          return nil
        }
        return array[idx]
      }
      
      // some other key
      lastKeyWasMiss = true
      return nil
    }
  }
}

fileprivate protocol KeyValueStringFormatterValueHandler: class {
  // Swift 3: Cannot nest protocols in classes, hence outside of the class
  // - if that isn't a class protocol, swiftc 3.1.1 crashes on Linux
  
  var lastKeyWasMiss : Bool { get }

  /**
   * Retrieve the next value for the given key. Note that this method may
   * only be called ONCE per pattern binding as some implementation have
   * sideeffects (eg advancing the array position cursor).
   *
   * @param _key - the key to resolve, or null
   * @return the value stored under the key, or the next value from an array
   */
  func value(forKey: String) -> Any?
}

fileprivate extension String {
  
  func canLA(_ count: Int, startIndex: Index) -> Bool {
    if startIndex == endIndex { return false }
    
    guard count != 0 else { return true } // can always not lookahead
    // this asserts on overflow: string.index(idx, offsetBy: count), so it is
    // no good for range-checks.
    
    // TBD: is there a betta way?
    var toGo   = count
    var cursor = startIndex
    while cursor != endIndex {
      toGo -= 1
      if toGo == 0 { return true }
      cursor = index(after: cursor)
    }
    return toGo == 0
  }
  
}
