//
//  WODParserHandler.swift
//  SwiftObjects
//
//  Created by Helge Hess on 18.05.18.
//  Copyright © 2018-2021 ZeeZide. All rights reserved.
//

/**
 * This is the callback interface provided by the WODParser class.
 * The most prominent implementation is WOWrapperTemplateBuilder.
 */
public protocol WODParserHandler : AnyObject {
  
  typealias Bindings = WODParser.Bindings
  typealias Data     = UnsafeBufferPointer<UInt8>

  /**
   * Called by the WODParser if it starts parsing a given string.
   *
   * @param _p    - the parser instance
   * @param _data - the data which shall be parsed
   * @return true if the parsing should be done, false to abort
   */
  func parser(_ parser: WODParser, willParseDeclarationData: Data) -> Bool
  
  func parser(_ parser: WODParser, finishedParsingDeclarationData: Data,
              with entries : [ String : WODParser.Entry ])
  
  func parser(_ parser: WODParser, failedParsingDeclarationData: Data,
              with entries : [ String : WODParser.Entry ],
              error: Swift.Error?)
  
  /**
   * This is called by the WODParser to create an association for a constant
   * value.
   *
   * The value can be a String, a Number, a property list object, or some
   * other basic stuff ;-)
   *
   * @param _p     - a reference to the WOD parser
   * @param _value - the value which has been parsed
   * @return a WOAssociation (most likely a WOValueAssocation)
   */
  func parser(_ parser: WODParser, associationFor value: Any?) -> WOAssociation?
  
  /**
   * This is called by the WODParser to create an association for a dynamic
   * value (a keypath binding).
   *
   * The value is the string containing the keypath.
   *
   * @param _p  - a reference to the WOD parser
   * @param _kp - the String containing the keypath (eg person.lastname)
   * @return a WOAssociation (most likely a WOKeyPathAssocation)
   */
  func parser(_ parser: WODParser, associationForKeyPath path: String)
       -> WOAssociation?

  /**
   * Called by the WODParser once it has parsed the data of a WOD entry
   * like:
   *
   *     Frame: MyFrame {
   *         title = "Welcome to Hola";
   *     }
   *
   * The parser stores the result of this method in a Map under the _cname
   * (`Frame`). This Map is queried after the .wod has been
   * parsed. The parser does not care about the type of the object being
   * returned, it just stores it.
   *
   * WOWrapperTemplateBuilder returns a WODParser.Entry object.
   *
   * @param _p       - the parser
   * @param _cname   - the name of the element (`Frame`)
   * @param _entry   - the Map containing the bindings (String-WOAssociation)
   * @param _clsname - the name of the component (`MyFrame`)
   * @return an object representing the WOD entry
   */
  func parser(_ parser: WODParser, definitionForComponentNamed name: String,
              className: String, bindings: Bindings) -> WODParser.Entry?
  
}

public extension WODParserHandler { // default imp
  
  func parser(_ parser: WODParser, willParseDeclarationData: Data) -> Bool {
    return true
  }
  
  func parser(_ parser: WODParser, finishedParsingDeclarationData: Data,
              with entries : [ String : WODParser.Entry ]) {}
  
  func parser(_ parser: WODParser, failedParsingDeclarationData: Data,
              with entries : [ String : WODParser.Entry ],
              error: Swift.Error?) {}
  
  func parser(_ parser: WODParser, associationFor v: Any?) -> WOAssociation? {
    return WOAssociationFactory.associationWithValue(v)
  }
  
  func parser(_ parser: WODParser, associationForKeyPath path: String)
       -> WOAssociation?
  {
    return WOAssociationFactory.associationWithKeyPath(path)
  }

  func parser(_ parser: WODParser,
              definitionForComponentNamed name: String,
              className: String, bindings: Bindings) -> WODParser.Entry?
  {
    return WODParser.Entry(componentName: name, componentClassName: className,
                           bindings: bindings)
  }
}
