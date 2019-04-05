//
//  SmartDescription.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

public protocol SmartDescription : CustomStringConvertible {
  
  var descriptionPrefix : String { get }
  func appendToDescription(_ ms: inout String)
}

public extension SmartDescription { // default-imp
  
  var descriptionPrefix : String { return "\(type(of: self))" }
  
  var description: String {
    var s = "<\(descriptionPrefix)"
    appendToDescription(&s)
    s += ">"
    return s
  }
  
}

