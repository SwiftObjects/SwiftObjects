//
//  WODParser.swift
//  SwiftObjects
//
//  Created by Helge Hess on 18.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

import struct Foundation.Data

/**
 * Parse .wod files (WebObject definitions).
 */
open class WODParser : PropertyListParser {
  // Note: A port of the Java version which is a straight port of the ObjC
  //       parser and therefore somewhat clumsy.
  // Actually I think that this inherits from PL was changed in Java.
  
  public typealias Bindings = WOElement.Bindings
  public typealias Result   = [ String : Entry ]
  
  let log = WOPrintLogger.shared
  
  open weak var handler : WODParserHandler? = nil
  var entries = Result()
  
  public init() {
    super.init(useValueKeys: true, allowNilValues: true)
  }
  
  static func parse(_ data: Data, handler: WODParserHandler? = nil) throws
                -> Result
  {
    let parser = WODParser()
    parser.handler = handler
    
    guard let value = try parser.parse(data) else {
      throw WODParserError.unexpectedNilValue
    }
    guard let entries = value as? [ String : Entry ] else {
      throw WODParserError.invalidParseResult
    }
    
    return entries
  }

  override open func parse() -> Any? {
    guard handler?.parser(self, willParseDeclarationData: buffer) ?? true else {
      return nil
    }
    
    while parseEntry() { // just loop
    }
    
    let result = entries
    entries.removeAll()
    
    handler?.parser(self, finishedParsingDeclarationData: buffer, with: result)
    return result
  }
  
  /**
   * This function parses a single WOD entry from the source, that is a
   * construct like:
   *
   *     Frame: MyFrame {
   *         title = "Welcome to Hola";
   *     }
   *
   * The entry contains:
   *
   * - The element name ("Frame") which is used to refer to
   *   the entry from the html template file (eg <#Frame> or
   *   <WEBOBJECT NAME="Frame">).
   * - The component name ("MyFrame"). This refers to either a WOComponent
   *   or to a WODynamicElement. Its usually the name of the class
   *   implementing the component.
   * - The bindings Map. The key is the name of the binding
   *   (`title`), the value is the `WOAssociation`
   *   object representing the binding.
   *
   * Note that the parser tracks all entries in the `entries`
   * property.
   * It will detect and log duplicate entries (currently the last one in the
   * file will win, but this isn't guaranteed, duplicate entries are considered
   * a bug).
   *
   * The parser itself does not create the Object representing the WOD entry,
   * it calls the `handler`'s
   * `parser(:definitionForComponentNamed:className:bindings:)`
   * method to produce it.
   */
  func parseEntry() -> Bool {
    guard skipComments() else { return false } // EOF
    
    guard let elementName = parseIdentifier() else {
      return reportError(.missingElementName(idx))
    }
    guard skipComments() else { _ = reportError(.earlyEOF); return false }
    
    let colon : UInt8 = 58
    if buffer[idx] != colon {
      if !reportError(.missingElementNameSeparator(idx)) { return false }
    }
    idx += 1
    guard skipComments() else { _ = reportError(.earlyEOF); return false }

    guard let className = parseIdentifier() else {
      return reportError(.missingClassName(idx))
    }
    guard skipComments() else { _ = reportError(.earlyEOF); return false }

    /* configuration (a property list with binding semantics) */
    
    let bindings : Bindings
    
    if let v = parseWODConfig() {
      bindings = v
    }
    else {
      if !reportError(.missingBindings(idx, elementName: elementName)) {
        return false
      }
      bindings = [:]
    }
    
    /* read trailing ';' if available */
    if skipComments() {
      let semicolon : UInt8 = 59
      if idx < buffer.count && buffer[idx] == semicolon {
        idx += 1
      }
    }
    
    /* create entry */
    
    if entries[elementName] != nil {
      log.error("duplicate element in WOD file:", elementName)
    }
    
    let entry : WODParser.Entry?
    
    if let handler = handler {
      entry = handler.parser(self, definitionForComponentNamed: elementName,
                             className: className, bindings: bindings)
    }
    else {
      entry = WODParser.Entry(componentName: elementName,
                              componentClassName: className,
                              bindings: bindings)

    }
    if let entry = entry {
      entries[elementName] = entry
    }
    
    return true
  }
  
  func parseWODConfig() -> Bindings? {
    /* This is very similiar to a dictionary, but only allows identifiers for
     * keys and it does allow associations as values.
     */
    guard skipComments() else {
      _ = reportError(.expectedDictionary(idx))
      return nil
    }
    
    guard buffer[idx] == tokens.openDict else {
      _ = reportError(.expectedData(idx))
      return nil
    }
    idx += 1 // skip {
    
    var result = Bindings()
    
    while idx < buffer.count {
      guard skipComments() else {
        if reportError(.dictionaryNotClosed(idx)) { return nil }
        break
      }
      
      if buffer[idx] == tokens.closeDict {
        idx += 1
        break
      }

      guard let key = parseIdentifier() else {
        if reportError(.invalidDictionaryKey(idx)) { return nil }
        break
      }

      /* The following parses:  (comment|space)* '=' (comment|space)* */
      guard skipComments() else {
        if reportError(.dictionaryAssignmentMissing(idx)) { return nil }
        break
      }
      if buffer[idx] != tokens.dictAssignment {
        if reportError(.dictionaryAssignmentMissing(idx)) { return nil }
      }
      else {
        idx += 1 // skip =
      }
      guard skipComments() else {
        if reportError(.dictionaryValueMissing(idx)) { return nil }
        break
      }
      
      /* read value property */
      
      guard let value = parseAssociationProperty(for: key) else {
        if reportError(.dictionaryValueMissing(idx)) { return nil }
        break
      }
      
      result[key] = value
      
      /* read trailing ';' if available */
      guard skipComments() else {
        if reportError(.dictionaryNotClosed(idx)) { return nil }
        break
      }
      
      if buffer[idx] == tokens.dictPairSeparator {
        idx += 1 // skip ;
      }
      else { /* no ; at end of pair, only allowed at end of dictionary */
        if buffer[idx] != tokens.closeDict {
          if reportError(.dictionaryAssignmentNotTerminated(idx)) {
            return nil
          }
        }
      }
    }
    
    return result
  }
  
  func parseAssociationProperty(for key: String) -> WOAssociation? {
    guard skipComments() else { return nil } // EOF
    
    func makeValue<T>(_ value: T) -> WOAssociation? {
      guard let handler = self.handler else {
        return WOAssociationFactory.associationWithValue(value)
      }
      return handler.parser(self, associationFor: value)
    }
    
    switch buffer[idx] {
      case tokens.stringQuote, tokens.stringQuote2:
        guard let s = parseQuotedString() else {
          _ = reportError(.unexpectedNilValue)
          return nil
        }
        return makeValue(s)
      
      case tokens.openDict:
        if useValueKeys {
          let dict : Dictionary<AnyHashable, Any?>? = parseDictionary()
          guard let vdict = dict else {
            _ = reportError(.unexpectedNilValue)
            return nil
          }
          return makeValue(vdict.compactMapValues { $0 })
        }
        else {
          let dict : Dictionary<String, Any?>? = parseDictionary()
          guard let vdict = dict else {
            _ = reportError(.unexpectedNilValue)
            return nil
          }
          return makeValue(vdict.compactMapValues { $0 })
        }
      
      case tokens.openArray:
        let optArray : Array<Any?>? = parseArray()
        guard let array = optArray else {
          _ = reportError(.unexpectedNilValue)
          return nil
        }
        if allowNilValues { return makeValue(array) }
        #if swift(>=4.1)
          return makeValue(array.compactMap { $0 })
        #else
          return makeValue(array.flatMap { $0 })
        #endif
      
      case tokens.openData:
        guard let s = parseData() else {
          _ = reportError(.unexpectedNilValue)
          return nil
        }
        return makeValue(s)
      
      // TODO: support OGNL association: ` ~ 1 + 2`
      // TODO: support script association: backtick script backtick
      
      case 48...57, 45:
        guard let s = parseDigit() else {
          _ = reportError(.unexpectedNilValue)
          return nil
        }
        if      let i = s as? Int { return makeValue(i) }
        else if let d = s as? Int { return makeValue(d) }
        else                      { return makeValue(s) }
      
      default:
        if let b = parseBool() { return makeValue(b)   }
        else if parseNil()     { return nil }
        else                   {
          guard let value = parseKeyPath() else {
            _ = reportError(.unexpectedNilValue)
            return nil
          }
          guard let handler = self.handler else {
            return WOAssociationFactory.associationWithKeyPath(value)
          }
          return handler.parser(self, associationForKeyPath: value)
        }
    }
  }
  
  func reportError(_ error: WODParserError) -> Bool {
    errors.append(error)
    return true
  }

  public enum WODParserError : Swift.Error {
    case earlyEOF
    case missingElementName(Int)
    case missingElementNameSeparator(Int)
    case missingClassName(Int)
    case missingBindings(Int, elementName: String)
    case duplicateElement(Int, name: String)
    case unexpectedNilValue
    case invalidParseResult
  }
  
  /**
   * This represents an entry in a WOD file, eg:
   *
   *     A: WOString {
   *         value = abc;
   *     }
   *
   * Notably the class-name (`WOString`) is a relative name which needs to be
   * resolved against the component lookup path.
   *
   * Further, the class can be either a WOComponent or a WODynamicElement (and
   * its not really a class, eg pageWithName might return a scripted component).
   *
   * WOWrapperBuilder is a class which creates WODFileEntry objects (as part of
   * implementing WODParserHandler.makeDefinitionForComponentNamed()).
   */
  public class Entry : SmartDescription {
    
    let componentName      : String
    let componentClassName : String
    let bindings           : Bindings
    
    public init(componentName      : String,
                componentClassName : String,
                bindings           : Bindings = [:])
    {
      self.componentName      = componentName
      self.componentClassName = componentClassName
      self.bindings           = bindings
    }
    
    // MARK: - Description
    
    open func appendToDescription(_ ms: inout String) {
      ms += " '\(componentName)'"
      if componentName != componentClassName {
        ms += "<\(componentClassName)>"
      }
      if !bindings.isEmpty { ms += " \(bindings)" }
    }
  }
}

