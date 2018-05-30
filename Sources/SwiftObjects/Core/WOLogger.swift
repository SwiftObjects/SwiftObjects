//
//  WOLogger.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * A logger object.
 *
 * A concrete implementation is the `WOPrintLogger`.
 */
public protocol WOLogger {
  
  typealias LogLevel = WOLogLevel

  func primaryLog(_ logLevel: LogLevel, _ msgfunc: () -> String,
                  _ values: [ Any? ] )
}

public extension WOLogger {
  
  public func error(_ msg: @autoclosure () -> String, _ values: Any?...) {
    primaryLog(.Error, msg, values)
  }
  public func warn (_ msg: @autoclosure () -> String, _ values: Any?...) {
    primaryLog(.Warn, msg, values)
  }
  public func log  (_ msg: @autoclosure () -> String, _ values: Any?...) {
    primaryLog(.Log, msg, values)
  }
  public func info (_ msg: @autoclosure () -> String, _ values: Any?...) {
    primaryLog(.Info, msg, values)
  }
  public func trace(_ msg: @autoclosure () -> String, _ values: Any?...) {
    primaryLog(.Trace, msg, values)
  }
  
}

/**
 * WO log levels.
 */
public enum WOLogLevel : Int8 {
  case Error
  case Warn
  case Log
  case Info
  case Trace
  
  var logPrefix : String {
    switch self {
      case .Error: return "ERROR: "
      case .Warn:  return "WARN:  "
      case .Info:  return "INFO:  "
      case .Trace: return "Trace: "
      case .Log:   return ""
    }
  }
}


// MARK: - Simple Default Logger

/**
 * Simple default logger which logs using, well, `print`. :-)
 */
public struct WOPrintLogger : WOLogger {
  
  public static let shared = WOPrintLogger() // FIXME: doesn't belong here
  
  public let logLevel : LogLevel
  
  public init(logLevel: LogLevel = .Log) {
    self.logLevel = logLevel
  }
  
  public func primaryLog(_ logLevel : LogLevel,
                         _ msgfunc  : () -> String,
                         _ values   : [ Any? ] )
  {
    guard logLevel.rawValue <= self.logLevel.rawValue else { return }
    
    let prefix = logLevel.logPrefix
    let s = msgfunc()
    
    if values.isEmpty {
      print("\(prefix)\(s)")
    }
    else {
      var ms = ""
      appendValues(values, to: &ms)
      print("\(prefix)\(s)\(ms)")
    }
  }
  
  func appendValues(_ values: [ Any? ], to ms: inout String) {
    for v in values {
      ms += " "
      
      if      let v = v as? CustomStringConvertible { ms += v.description }
      else if let v = v as? String                  { ms += v }
      else if let v = v                             { ms += "\(v)" }
      else                                          { ms += "<nil>" }
    }
  }
}

