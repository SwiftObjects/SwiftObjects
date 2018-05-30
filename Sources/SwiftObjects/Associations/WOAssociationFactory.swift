//
//  WOAssociationFactory.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

// MARK: - Factory

public enum WOAssociationFactory {
  // This should be `public extension WOAssociation {}`, but you can't
  // call static methods on a protocol type in Swift ...
  
  static let log = WOPrintLogger.shared
  
  public static func associationWithKeyPath(_ path: String) -> WOAssociation? {
    guard !path.isEmpty else { return nil }
    
    return path.contains(".")
               ? WOKeyAssociation(path)
               : WOKeyPathAssociation(path)
  }
  
  public static func associationWithValue<T>(_ v: T) -> WOAssociation {
    return WOValueAssociation(v)
  }
 
  /**
   * Create an WOAssociation object for the given namespace prefix. This is
   * called when the parser encounters element attributes in the HTML file,
   * its not called from the WOD parser.
   *
   * Prefixes:
   *
   * - const   - WOAssociation.associationWithValue
   * - go      - GoPathAssociation
   * - jo      - GoPathAssociation (legacy name, use 'go' instead)
   * - label   - WOLabelAssociation
   * - ognl    - WOOgnlAssociation
   * - plist   - WOAssociation.associationWithValue
   * - q       - WOQualifierAssociation
   * - regex   - WORegExAssociation
   * - role    - WOCheckRoleAssociation
   * - rsrc    - WOResourceURLAssociation
   * - rsrcpat - WOResourceURLAssociation
   * - var     - WOAssociation.associationWithKeyPath
   * - varpat  - WOKeyPathPatternAssociation
   * - not     - WONegateAssociation on WOKeyPathAssociation
   *
   * If no prefix matches, associationWithValue will be used.
   *
   * @param _prefix - the parsed prefix which denotes the association class
   * @param _name   - the name of the binding (not relevant in this imp)
   * @param _value  - the value which needs to be put into the context
   */
  public static func associationForPrefix(_ prefix: String, name: String,
                                          value: String) -> WOAssociation?
  {
    switch prefix {
      case "var":   return associationWithKeyPath(value)
      case "const": return associationWithValue(value)
      case "label": return WOLabelAssocation(key: value)
      
      case "not":
        // TBD: inspect value for common _static_ values, eg 'true'?
        guard let a = associationWithKeyPath(value) else { return nil }
        return WONegateAssocation(a)
      
      case "plist":
        /* Allow arrays like this: list="(a,b,c)",
         * required because we can't specify plists in .html
         * template attributes. (we might want to change that?)
         */
        let parser = PropertyListParser()
        guard let v = try? parser.parse(value) else {
          log.error("could not parse plist in argument:", name, value)
          return nil
        }
        return associationWithValue(v)
      
      case "varpat":  return WOKeyPathPatternAssociation(value)
      case "rsrc":    return WOResourceURLAssociation(value)
      case "rsrcpat": return WOResourcePatternAssociation(value)
      
      // TODO: q, regex, ognl, role, go
      
      default:
        // TODO: port/support registry the user can fill
        
        return associationWithValue(value)
    }
  }
}
