//
//  WODParserTests.swift
//  SwiftObjectsTests
//
//  Created by Helge Hess on 18.05.18.
//

import XCTest
@testable import SwiftObjects

class WODParserTests: XCTestCase {
  
  func testSimpleWOD() throws {
    let wod = """
              Frame: MyFrame {
                title = "Hello World!"
              }
              """
    
    let result = try WODParser.parse(wod.data(using: .utf8)!)
    print("result:", result as Any)
    
    XCTAssertEqual(result.count, 1)
    XCTAssertNotNil(result["Frame"])
  }

  func testMultiWOD() throws {
    let wod = """
              Frame: MyFrame {
                title = "Hello World!"
              }
              Date : WOString {
                dateformat = "%Y-%m-%d";
                value      = context.startDate;
              }
              """
    
    let result = try WODParser.parse(wod.data(using: .utf8)!)
    print("result:", result as Any)
    
    XCTAssertEqual(result.count, 2)
    XCTAssertNotNil(result["Frame"])
    XCTAssertNotNil(result["Date"])
  }

  func testMultiWODWithComments() throws {
    let wod = """
              /* this is
               a nice multiline comment */
              Frame: MyFrame {
                title = "Hello World!"
              }
              // a date you know
              Date : WOString {
                dateformat = "%Y-%m-%d";
                value      = context.startDate;
              }
              """
    
    let result = try WODParser.parse(wod.data(using: .utf8)!)
    print("result:", result as Any)
    
    XCTAssertEqual(result.count, 2)
    XCTAssertNotNil(result["Frame"])
    XCTAssertNotNil(result["Date"])
  }

  func testEmtptWithComments() throws {
    let wod = """
              /* this is
               a nice multiline comment */
              // a date you know
              """
    
    let result = try WODParser.parse(wod.data(using: .utf8)!)
    print("result:", result as Any)
    
    XCTAssertEqual(result.count, 0)
  }

  // MARK: - Linux
  
  static var allTests = [
    ( "testSimpleWOD",            testSimpleWOD            ),
    ( "testMultiWOD",             testMultiWOD             ),
    ( "testMultiWODWithComments", testMultiWODWithComments ),
    ( "testEmtptWithComments",    testEmtptWithComments    ),
  ]
}

