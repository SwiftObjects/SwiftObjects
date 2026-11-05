//
//  WOObjectFormatter.swift
//  SwiftObjects
//
//  Created by Helge Hess on 13.05.18.
//  Copyright © 2018-2026 ZeeZide. All rights reserved.
//

import class Foundation.Formatter

/**
 * This formatter formats using an arbitrary Foundation.Formatter object.
 *
 * Example:
 * ```wod
 * Text: WOString {
 *     value  = event.startDate;
 *     format = session.userDateFormatter;
 * }
 * ```
 */
open class WOObjectFormatter : WOFormatter, @unchecked Sendable {
  
  let formatter : WOAssociation
  
  public init(formatter: WOAssociation) {
    self.formatter = formatter
  }
  
  open func formatter(in context: WOContext) -> Foundation.Formatter? {
    return formatter.value(in: context.cursor) as? Foundation.Formatter
  }
}
