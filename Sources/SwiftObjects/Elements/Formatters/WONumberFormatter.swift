//
//  WONumberFormatter.swift
//  SwiftObjects
//
//  Created by Helge Hess on 13.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

import class  Foundation.Formatter
import class Foundation.NumberFormatter

/**
 * This formatter formats a NumberFormatter pattern. Check the
 * NumberFormatter documentation for the possible patterns.
 *
 * Examples:
 *
 *     Text: WOString {
 *         value        = product.price;
 *         numberformat = "#,##0.00 ; (#,##0.00)"; // you need the ';' spaces
 *     }
 *
 *     <wo:str value="$product.price" numberformat="#,##0.00" />
 */
open class WONumberFormatter : WOFormatter {
  
  let format : WOAssociation
  
  public init(format: WOAssociation) {
    self.format = format
  }

  open func formatter(in context: WOContext) -> Foundation.Formatter? {
    let nf = Foundation.NumberFormatter()
    
    if let format = format.stringValue(in: context.cursor) {
      nf.format = format
    }
    
    return nf
  }
  
  public func objectValue(for s: String, in context: WOContext) -> Any? {
    let formatter = self.formatter(in: context)
    if let fmt = formatter as? NumberFormatter {
      return fmt.number(from: s)
    }
    return defaultObjectValue(for: s, in: context)
  }
}
