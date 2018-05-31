//
//  HTMLParserTests.swift
//  SwiftObjectsTests
//
//  Created by Helge Hess on 19.05.18.
//

import XCTest
@testable import SwiftObjects

class HTMLParserTests: XCTestCase {
  
  func testStaticHTML() throws {
    let parser = WOHTMLParser()
    
    let html = """
               <html><title>Hello</title><body>World</body></html>
               """
    let result = try parser.parse(html.data(using: .utf8)!)
    print("result:", result)
    
    XCTAssertEqual(result.count, 1)
    guard let element = result.first else { return }
    
    XCTAssert(element is WOStaticHTMLElement)
    guard let s = element as? WOStaticHTMLElement else { return }
    
    XCTAssertEqual(s.string, html)
  }
  
  func testEmptyHTML() throws {
    let parser = WOHTMLParser()
    
    let html = ""
    let result = try parser.parse(html.data(using: .utf8)!)
    print("result:", result)
    
    XCTAssertEqual(result.count, 0)
  }
  
  func testSimpleWOElement() throws {
    let parser = WOHTMLParser()
    parser.handler = StaticTestHandler()
    
    let html = """
               <title><WEBOBJECT NAME="Hello"></WEBOBJECT></title>
               """
    let result = try parser.parse(html.data(using: .utf8)!)
    print("result:", result)
    
    XCTAssertEqual(result.count, 3)
    guard result.count >= 3 else { return }
    
    let prefix = result[0]
    let wo     = result[1]
    let suffix = result[2]
    XCTAssert(prefix is WOStaticHTMLElement)
    XCTAssert(suffix is WOStaticHTMLElement)
    XCTAssert(wo     is StaticTestElement)
    
    if let s = prefix as? WOStaticHTMLElement {
      XCTAssertEqual(s.string, "<title>")
    }
    if let s = suffix as? WOStaticHTMLElement {
      XCTAssertEqual(s.string, "</title>")
    }
    
    if let wo = wo as? StaticTestElement {
      print("WO:", wo)
      XCTAssertEqual(wo.name, "Hello")
      XCTAssertEqual(wo.attributes.count, 1)
      XCTAssertNotNil(wo.attributes["NAME"])
      XCTAssertEqual(wo.children.count, 0)
    }
  }
  
  func testSimpleHashElement() throws {
    let parser = WOHTMLParser()
    parser.handler = StaticTestHandler()
    
    let html = """
               <title><#Hello>World</# ></title>
               """
    let result = try parser.parse(html.data(using: .utf8)!)
    print("result:", result)
    
    XCTAssertEqual(result.count, 3)
    guard result.count >= 3 else { return }
    
    let prefix = result[0]
    let wo     = result[1]
    let suffix = result[2]
    XCTAssert(prefix is WOStaticHTMLElement)
    XCTAssert(suffix is WOStaticHTMLElement)
    XCTAssert(wo     is StaticTestElement)
    
    if let s = prefix as? WOStaticHTMLElement {
      XCTAssertEqual(s.string, "<title>")
    }
    if let s = suffix as? WOStaticHTMLElement {
      XCTAssertEqual(s.string, "</title>")
    }
    
    if let wo = wo as? StaticTestElement {
      print("WO:", wo)
      XCTAssertEqual(wo.name, "Hello")
      XCTAssertEqual(wo.attributes.count, 1)
      XCTAssertNotNil(wo.attributes["NAME"])
      
      XCTAssertEqual(wo.children.count, 1)
      guard let element = wo.children.first else { return }
      XCTAssert(element is WOStaticHTMLElement)
      guard let s = element as? WOStaticHTMLElement else { return }
      XCTAssertEqual(s.string, "World")
    }
  }
  
  func testSimpleHashAttributedElement() throws {
    let parser = WOHTMLParser()
    parser.handler = StaticTestHandler()
    
    let html = """
               <title><#Hello style="nice" disabled /></title>
               """
    let result = try parser.parse(html.data(using: .utf8)!)
    print("result:", result)
    
    XCTAssertEqual(result.count, 3)
    guard result.count >= 3 else { return }
    
    let prefix = result[0]
    let wo     = result[1]
    let suffix = result[2]
    XCTAssert(prefix is WOStaticHTMLElement)
    XCTAssert(suffix is WOStaticHTMLElement)
    XCTAssert(wo     is StaticTestElement)
    
    if let s = prefix as? WOStaticHTMLElement {
      XCTAssertEqual(s.string, "<title>")
    }
    if let s = suffix as? WOStaticHTMLElement {
      XCTAssertEqual(s.string, "</title>")
    }
    
    if let wo = wo as? StaticTestElement {
      print("WO:", wo)
      XCTAssertEqual(wo.name, "Hello")
      XCTAssertEqual(wo.attributes.count, 3)
      XCTAssertNotNil(wo.attributes["NAME"])
      XCTAssertNotNil(wo.attributes["style"])
      XCTAssertNotNil(wo.attributes["disabled"])
      XCTAssertEqual(wo.attributes["style"], "nice")
      XCTAssertEqual(wo.attributes["disabled"], "disabled")

      XCTAssertEqual(wo.children.count, 0)
    }
  }
  
  func testHomePage() throws {
    let html =
      """
      <!-- Our "Homepage"
           It wraps itself into a reusable Frame component, which does all the
           top level HTML rendering (html, body tag, stylesheets etc).

           Your can find the definitions of the WEBOBJECT tags in the Main.wod
           file.
        -->
      <WEBOBJECT NAME="Frame">
        <h1>SwiftObjects is not WebObjects</h1>
        <p>
          <WEBOBJECT NAME="Body"></WEBOBJECT>
        </p>
        
        <WEBOBJECT NAME="Form" class="ui form segment">
          <div class="field">
            <label>Title:</label>
            <WEBOBJECT NAME="TitleField" class="ui input"></WEBOBJECT>
          </div>

          <WEBOBJECT NAME="Submit" class="ui blue submit button"></WEBOBJECT>
        </WEBOBJECT>
        
      </WEBOBJECT>
      """
    
    let parser = WOHTMLParser()
    parser.handler = StaticTestHandler()
    
    let result = try parser.parse(html.data(using: .utf8)!)
    print("result:", result)
  }

  
  func testHomePageWithUnclosedTag() throws { // FIXME
    let html =
      """
      Some prefix
      <WEBOBJECT NAME="Frame">
        Counter: <wo:str value="$counter" />
        <wo:a action="incrementCounter">++</a> <!-- bug is here -->
        
        <h1>SwiftObjects is not WebObjects</h1>
      </WEBOBJECT>
      """
    
    let parser = WOHTMLParser()
    parser.handler = StaticTestHandler()
    
    let result = try parser.parse(html.data(using: .utf8)!)
    print("result:", result)
  }
  
  // MARK: - Support
  
  class StaticTestElement : WOHTMLDynamicElement {
    let name       : String
    let attributes : [ String : String ]
    let children   : [ WOElement ]
    
    init(name: String, attributes: [ String : String ],
         children: [ WOElement ])
    {
      self.name       = name
      self.attributes = attributes
      self.children   = children
      
      var bindings = Bindings()
      super.init(name: name, bindings: &bindings, template: nil)
    }
    
    required init(name: String, bindings: inout WOElement.Bindings,
                  template: WOElement?)
    {
      fatalError("\(#function) has not been implemented")
    }
    
    override func appendToDescription(_ ms: inout String) {
      super.appendToDescription(&ms)
      ms += " '\(name)'"
      if !attributes.isEmpty {
        ms += " "
        ms += attributes.description
      }
      if !children.isEmpty {
        ms += " "
        ms += children.description
      }
    }
  }
  
  class StaticTestHandler : WOTemplateParserHandler {
    public func parser(_ parser: WOTemplateParser, dynamicElementFor name: String,
                       attributes: [ String : String ], children: [ WOElement ])
                -> WOElement?
    {
      return StaticTestElement(name: name, attributes: attributes,
                               children: children)
    }
  }
  

  // MARK: - Linux
  
  static var allTests = [
    ( "testStaticHTML",                  testStaticHTML                  ),
    ( "testEmptyHTML",                   testEmptyHTML                   ),
    ( "testSimpleWOElement",             testSimpleWOElement             ),
    ( "testSimpleHashElement",           testSimpleHashElement           ),
    ( "testSimpleHashAttributedElement", testSimpleHashAttributedElement ),
    ( "testHomePage",                    testHomePage                    ),
    ( "testHomePageWithUnclosedTag",     testHomePageWithUnclosedTag     ),
  ]
}
