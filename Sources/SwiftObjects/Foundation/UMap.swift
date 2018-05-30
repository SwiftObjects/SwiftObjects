//
//  UMap.swift
//  SwiftObjects
//
//  Created by Helge Hess on 13.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation

protocol QueryDictionaryStringValue { // sigh
  func stringForQueryDictionary() -> String?
}

extension Dictionary where Key == String {
  
  /**
   * Return a URL query string for the given key/value Map. We moved this into
   * Foundation because links are useful everywhere, not just in appserver.
   *
   * Example:
   *
   *     { city = Magdeburg;
   *       companies = [ Skyrix, SWM ]; }
   *
   * will be converted into:
   *
   *     city=Magdeburg&companiens=Skyrix&companies=SWM
   *
   * Each key and each value will be converted to URL encoding using the
   * URLEncoder class.
   *
   * The reverse function is UString.mapForQueryString().
   *
   * @param _qp      - Map containing the values to be generated
   * @param _charset - charset used for encoding (%20 like values) (def: UTF-8)
   * @return a query string, or null if _qp was null or empty
   */
  func stringForQueryDictionary() -> String {
    var sb = ""
    sb.reserveCapacity(count * 20)
    
    let cs = CharacterSet.urlQueryAllowed
    for ( key, value ) in self {
      if !sb.isEmpty { sb += "&" }
      
      // FIXME: Go also supports arrays of values etc
      let vs : String
      
      if let sv = value as? QueryDictionaryStringValue {
        if let s = sv.stringForQueryDictionary() {
          vs = s
        }
        else {
          vs = ""
        }
      }
      else {
        vs = String(describing: value) // TBD
      }
      
      if let k = key.addingPercentEncoding(withAllowedCharacters: cs),
         let v = vs .addingPercentEncoding(withAllowedCharacters: cs)
      {
        sb.append(k.replacingOccurrences(of: " ", with: "+"))
        sb.append("=")
        sb.append(v.replacingOccurrences(of: " ", with: "+"))
      }
      else {
        // else: do something, throw, log ;-)
        WOPrintLogger.shared.error("could not encode query parameter:", key, vs)
      }
    }
    
    return sb
  }
}


// I don't like that not

extension String : QueryDictionaryStringValue {
  func stringForQueryDictionary() -> String? {
    return self
  }
}

extension Array : QueryDictionaryStringValue {
  func stringForQueryDictionary() -> String? {
    var ms = ""
    for e in self {
      if !ms.isEmpty { ms += "," }
      if let o = e as? QueryDictionaryStringValue {
        if let s = o.stringForQueryDictionary() {
          ms += s
        }
      }
      else {
        ms += String(describing: e)
      }
    }
    return ms
  }
}

extension Optional : QueryDictionaryStringValue {
  func stringForQueryDictionary() -> String? {
    switch self {
      case .none: return nil
      case .some(let wrapped):
        if let o = wrapped as? QueryDictionaryStringValue {
          return o.stringForQueryDictionary()
        }
        else {
          return String(describing: wrapped)
        }
    }
  }  
}
