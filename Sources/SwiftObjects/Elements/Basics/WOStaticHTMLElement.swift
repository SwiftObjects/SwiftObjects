//
//  WOStaticHTMLElement.swift
//  SwiftObjects
//
//  Created by Helge Hess on 15.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation

/**
 * Renders a string as-is to the output. Basically the same like a WOString with
 * escapeHTML=NO.
 *
 * This object is used by the WOHTMLParser for raw template content.
 */
open class WOStaticHTMLElement : WOElement, SmartDescription {
  
  let string : String
  
  public init(_ s: String) {
    self.string = s
  }
  convenience init(_ data: Data) {
    self.init(String(data: data, encoding: .utf8) ?? "??")
  }
  
  open func append(to response: WOResponse, in context: WOContext) throws {
    try response.appendContentString(string)
  }
  
  // MARK: - Description
  
  open func appendToDescription(_ ms: inout String) {
    if string.isEmpty {
      ms += " no-string"
    }
    else {
      ms += " \""
      if string.count > 80 {
        let from = string.startIndex
        ms += string[from..<string.index(from, offsetBy: 76)]
              .replacingOccurrences(of: "\"", with: "\\\"")
        ms += "\"..."
      }
      else {
        ms += string.replacingOccurrences(of: "\"", with: "\\\"")
        ms += "\""
      }
    }
  }
}

