//
//  WOTemplateParserHandler.swift
//  SwiftObjects
//
//  Created by Helge Hess on 19.05.18.
//

import Foundation

public protocol WOTemplateParserHandler : class {
  
  typealias Data     = UnsafeBufferPointer<UInt8>
  
  func parser(_ parser: WOTemplateParser, willParseHTMLData: Data) -> Bool
  
  func parser(_ parser: WOTemplateParser, finishedParsingHTMLData: Data,
              with elements : [ WOElement ])
  
  func parser(_ parser: WOTemplateParser, failedParsingHTMLData: Data,
              with elements : [ WOElement ],
              error: Swift.Error?)

  func parser(_ parser: WOTemplateParser, dynamicElementFor name: String,
              attributes: [ String : String ], children: [ WOElement ])
       -> WOElement?
}

public extension WOTemplateParserHandler { // default imp
  
  public
  func parser(_ parser: WOTemplateParser, willParseHTMLData: Data) -> Bool
  {
    return true
  }
  
  public func parser(_ parser: WOTemplateParser, finishedParsingHTMLData: Data,
                     with elements : [ WOElement ]) {}
  
  public func parser(_ parser: WOTemplateParser, failedParsingHTMLData: Data,
                     with elements : [ WOElement ],
                     error: Swift.Error?) {}
  
  public func parser(_ parser: WOTemplateParser, dynamicElementFor name: String,
                     attributes: [ String : String ], children: [ WOElement ])
              -> WOElement?
  {
    return nil
  }
}
