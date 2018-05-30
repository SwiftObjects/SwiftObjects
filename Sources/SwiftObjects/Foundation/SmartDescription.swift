//
//  SmartDescription.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

public protocol SmartDescription : CustomStringConvertible {
  
  var descriptionPrefix : String { get }
  func appendToDescription(_ ms: inout String)
}

public extension SmartDescription { // default-imp
  
  public var descriptionPrefix : String {
    return "\(type(of: self))"
  }
  
  public var description: String {
    var s = "<\(descriptionPrefix)"
    appendToDescription(&s)
    s += ">"
    return s
  }
  
}

