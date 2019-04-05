//
//  WOFormatter.swift
//  SwiftObjects
//
//  Created by Helge Hess on 13.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

import class Foundation.Formatter
import class Foundation.NSString

/**
 * Helper class which deals with formatting attributes of WODynamicElement's.
 * It is based upon Foundation.Formatter.
 *
 * THREAD: remember that Format objects are usually not thread-safe.
 *         TBD: Same in Swift Foundation?
 */
public protocol WOFormatter {
  
  func formatter(in context: WOContext) -> Foundation.Formatter?

  func objectValue  (for s: String, in context: WOContext) throws -> Any?
  func string       (for o: Any?,   in context: WOContext) -> String?
  func editingString(for o: Any?,   in context: WOContext) -> String?
}

public enum WOFormatterFactory { // can't have statics on Swift protocols

  public typealias Bindings = [ String : WOAssociation ]
  
  /**
   * Extracts a WOFormatter for the given associations. This checks the
   * following bindings:
   *
   * - dateformat, lenient, locale, timeZone/tz
   * - numberformat
   * - formatter
   * - formatterClass
   *
   * @param _assocs - the bindings of the element
   * @return a WOFormatter object used to handle the bindings
   */
  public static func formatter(for associations: inout Bindings)
                     -> WOFormatter?
  {
    // TODO: currencyformat, intformat, percentformat
    if let format = associations.removeValue(forKey: "numberformat") {
      return WONumberFormatter(format: format)
    }
    
    if let format = associations.removeValue(forKey: "dateformat") {
      return WODateFormatter(
        format    : format,
        isLenient : associations.removeValue(forKey: ""),
        locale    : associations.removeValue(forKey: "locale"),
        timeZone  : associations.removeValue(forKey: "timeZone")
                 ?? associations.removeValue(forKey: "tz")
      )
    }
    
    // TODO: formatterclass
    if let formatter = associations.removeValue(forKey: "formatter") {
      return WOObjectFormatter(formatter: formatter)
    }
    
    return nil
  }
}

public extension WOFormatter {

  func objectValue(for s: String, in context: WOContext) -> Any? {
    return defaultObjectValue(for: s, in: context)
  }
  func defaultObjectValue(for s: String, in context: WOContext) -> Any? {
    guard let formatter = self.formatter(in: context) else {
      return nil
    }
    
    #if os(Linux)
      do {
        return try formatter.objectValue(s)
      }
      catch {
        // TODO: throw
        return nil
      }
    #else
      var obj   : AnyObject?
      var error : NSString?

      guard formatter.getObjectValue(&obj, for: s, errorDescription: &error) else{
        // TODO: throw
        return nil
      }
      return obj
    #endif
  }
  
  func string(for o: Any?, in context: WOContext) -> String? {
    guard let formatter = self.formatter(in: context) else { return nil }

    #if os(Linux)
      // Hmmm
      if let o = o { return formatter.string(for: o)        }
      else         { return formatter.string(for: o as Any) }
    #else
      return formatter.string(for: o)
    #endif
  }
  
  public func editingString(for o: Any?, in context: WOContext) -> String? {
    return string(for: o, in: context)
  }

}
