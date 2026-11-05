//
//  WOResourcePatternAssociation.swift
//  SwiftObjects
//
//  Created by Helge Hess on 19.05.18.
//  Copyright © 2018-2026 ZeeZide. All rights reserved.
//

open class WOResourcePatternAssociation: WOResourceURLAssociation,
                                         @unchecked Sendable
{
  override open func filenameValue(in cursor: Any?) -> String? {
    return KeyValueStringFormatter.format(filename, object: cursor)
  }
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    ms += " %'\(filename)'"
  }
}

