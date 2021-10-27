//
//  ExtraVariables.swift
//  SwiftObjects
//
//  Created by Helge Hess on 26.05.18.
//  Copyright © 2018-2021 ZeeZide. All rights reserved.
//

/**
 * A marker interface which denotes objects which can store additional key/value
 * pairs in a HashMap via KVC (w/o declaring ivars).
 *
 * Examples are `WOComponent` and `WOSession`.
 */
public protocol ExtraVariables : AnyObject {
  
  /**
   * Attach an additional key/value pair to the object.
   *
   * The actual implementation may differ, but usually a 'null' value will
   * remove the key (use removeObjectForKey() if you explicitly want to remove
   * a key).
   *
   * Note: usually you want to access the slots using regular KVC.
   *
   * @param _value - the value to be attached
   * @param _key   - the key to store the value under
   */
  func setObject(_ o: Any?, for key: String)
  
  /**
   * Removes the given 'addon' key from the object. If the key is not an
   * additional object slot, nothing happens.
   *
   * Note: usually you want to access the slots using regular KVC.
   *
   * @param _key - the key to remove
   */
  func removeObject(for key: String)
  
  /**
   * Retrieves an extra slot from the object.
   * <p>
   * Note: usually you want to access the slots using regular KVC (valueForKey)
   *
   * @param _key - the key to retrieve
   * @return the value stored under the key, or null
   */
  func object(for key: String) -> Any?
  
  /**
   * Retrieves all extra slots from the object. This method is not always
   * implemented (or possible to implement). Use with care.
   *
   * @return a Map containing all extra values
   */
  var variableDictionary : [ String : Any ] { get set }

  
  // MARK: - Utility
  
  func appendExtraAttributesToDescription(_ ms: inout String)
}

public extension ExtraVariables { // Default Imp

  func setObject(_ o: Any?, for key: String) {
    if let o = o {
      variableDictionary[key] = o
    }
    else {
      removeObject(for: key)
    }
  }
  
  func removeObject(for key: String) {
    variableDictionary.removeValue(forKey: key)
  }
  
  func object(for key: String) -> Any? {
    return variableDictionary[key]
  }

  func appendExtraAttributesToDescription(_ ms: inout String) {
    guard !variableDictionary.isEmpty else { return }
    
    ms.append(" vars=")
    
    var isFirst = true
    for ( key, value ) in variableDictionary {
      if isFirst { isFirst = false }
      else { ms += "," }
      ms += key
      
      if let v = value as? Int {
        ms += "=\(v)"
      }
      else if let v = value as? String {
        ms += "=\""
        if v.count > 16 {
          ms += v[v.startIndex..<v.index(v.startIndex, offsetBy: 14)]
          ms += "\"..."
        }
        else {
          ms += v
          ms += "\""
        }
      }
      else {
        ms += "[\(type(of: value))]"
      }
    }
  }
}
