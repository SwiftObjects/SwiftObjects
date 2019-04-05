//
//  WOTemplateParser.swift
//  SwiftObjects
//
//  Created by Helge Hess on 19.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

import struct Foundation.URL

/**
 * Interface which represents a template parser.
 * The only class (and hence the only template syntax) implementing this in Go
 * is WOHtmlParser.
 *
 * The parser is only responsibly for parsing the syntax. It does not even do
 * the WOElement object construction - this is done by the handler of the
 * parser (via the dynamicElementWithName() method).
 *
 * Do not confuse this class with WOTemplate*Builder*. The builder also
 * deals with the on-disk structure (eg .wo directory vs .xml file) and returns
 * a WOTemplate element.
 *
 * P.S.: StaticCMS has additional parser for some specific XHTML syntax.
 */
public protocol WOTemplateParser : class {
  
  var handler : WOTemplateParserHandler? { get set }
  
  func parseHTMLData(_ url: URL) throws -> [ WOElement ]
  
}
