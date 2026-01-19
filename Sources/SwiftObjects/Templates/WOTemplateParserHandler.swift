//
//  WOTemplateParserHandler.swift
//  SwiftObjects
//
//  Created by Helge Hess on 19.05.18.
//  Copyright © 2018-2021 ZeeZide. All rights reserved.
//

import struct Foundation.Data

public protocol WOTemplateParserHandler : AnyObject {
  
  typealias Data     = UnsafeBufferPointer<UInt8>
  
  func parser(_ parser: WOTemplateParser, willParseHTMLData: Data) -> Bool
  
  func parser(_ parser: WOTemplateParser, finishedParsingHTMLData: Data,
              with elements : [ WOElement ])
  
  func parser(_ parser: WOTemplateParser, failedParsingHTMLData: Data,
              with elements : [ WOElement ],
              error: Swift.Error?)

  func parser(_ parser: WOTemplateParser, dynamicElementFor name: String,
              attributes: [ String : String ], children: [ WOElement ]) throws
       -> WOElement?
}

public extension WOTemplateParserHandler { // default imp
  
  func parser(_ parser: WOTemplateParser, willParseHTMLData: Data) -> Bool {
    return true
  }
  
  func parser(_ parser: WOTemplateParser, finishedParsingHTMLData: Data,
              with elements : [ WOElement ]) {}
  
  func parser(_ parser: WOTemplateParser, failedParsingHTMLData: Data,
              with elements : [ WOElement ], error: Swift.Error?) {}
  
  func parser(_ parser: WOTemplateParser, dynamicElementFor name: String,
              attributes: [ String : String ], children: [ WOElement ]) throws
              -> WOElement?
  {
    return nil
  }
}
