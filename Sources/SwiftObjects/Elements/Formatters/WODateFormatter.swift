//
//  WODateFormatter.swift
//  SwiftObjects
//
//  Created by Helge Hess on 13.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

import struct Foundation.TimeZone
import struct Foundation.Locale
import class  Foundation.Formatter
import class  Foundation.DateFormatter

/**
 * This formatter takes a String and returns a Foundation.Date object.
 *
 * The transformation can either use a predefined key, like 'SHORT' or
 * 'DATETIME.SHORT', or a custom format (eg 'dd-MMM-yy') as implemented by
 * the java.text.SimpleDateFormat parser.
 *
 * Custom Formats (of java.text.SimpleDateFormat):
 * ```
 * G       Era designator          Text    AD
 * y       Year                    Year    1996; 96
 * M       Month in year           Month   July; Jul; 07
 * w       Week in year            Number  27
 * W       Week in month           Number  2
 * D       Day in year             Number  189
 * d       Day in month            Number  10
 * F       Day of week in month    Number  2
 * E       Day in week             Text    Tuesday; Tue
 * a       Am/pm marker            Text    PM
 * H       Hour in day (0-23)      Number  0
 * k       Hour in day (1-24)      Number  24
 * K       Hour in am/pm (0-11)    Number  0
 * h       Hour in am/pm (1-12)    Number  12
 * m       Minute in hour          Number  30
 * s       Second in minute        Number  55
 * S       Millisecond             Number  978
 * Z       Time zone               RFC 822 time zone       -0800
 * z       Time zone               General time zone
 *                                   Pacific Standard Time; PST; GMT-08:00
 * ```
 */
open class WODateFormatter : WOFormatter {
  
  let format    : WOAssociation
  let isLenient : WOAssociation?
  let locale    : WOAssociation?
  let timeZone  : WOAssociation?

  public init(format    : WOAssociation,
              isLenient : WOAssociation? = nil,
              locale    : WOAssociation? = nil,
              timeZone  : WOAssociation? = nil)
  {
    self.format    = format
    self.isLenient = isLenient
    self.locale    = locale
    self.timeZone  = timeZone
    
    // TODO: process and cache constant associations for performance
  }

  open func formatter(in context: WOContext) -> Foundation.Formatter? {
    // TODO: cache, like in Go
    let nf     = Foundation.DateFormatter()
    let cursor = context.cursor
    
    if let format = format.stringValue(in: cursor) {
      nf.dateFormat = format
    }
    
    if let isLenient = isLenient {
      nf.isLenient = isLenient.boolValue(in: cursor)
    }
    
    if let locale = locale {
      nf.locale = locale.value(in: cursor) as? Locale
    }
    
    if let timeZone = timeZone, let v = timeZone.value(in: cursor) {
      if let tz = v as? TimeZone {
        nf.timeZone = tz
      }
      else if let tzName = v as? String {
        if let tz = TimeZone(identifier: tzName) {
          nf.timeZone = tz
        }
        else if let tz = TimeZone(abbreviation: tzName) {
          nf.timeZone = tz
        }
        else {
          context.log.error("Did not find timezone:", tzName)
        }
      }
      else {
        context.log.error("Cannot process timeZone value:", v)
      }
    }
    
    return nf
  }
  
  public func objectValue(for s: String, in context: WOContext) -> Any? {
    let formatter = self.formatter(in: context)
    if let fmt = formatter as? DateFormatter {
      return fmt.date(from: s)
    }
    return defaultObjectValue(for: s, in: context)
  }
}
