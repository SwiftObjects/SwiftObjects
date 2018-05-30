//
//  PListParserTests.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import XCTest
@testable import SwiftObjects

class PListParserTests: XCTestCase {
  
  func testEmptyPList() throws {
    let parser = PropertyListParser()
    let result = try parser.parse("".data(using: .utf8)!)
    XCTAssertNil(result)
  }
  
  func testBasicPList() throws {
    let parser = PropertyListParser()
    
    let plist = """
                { lastname = "Duck"; firstname = "Donald"; age = 110 }
                """
    let result = try parser.parse(plist.data(using: .utf8)!)
    print("result:", result as Any)
    
    guard let dict = result as? Dictionary<String, Any> else {
      XCTAssert(result is Dictionary<String, Any>)
      return
    }
    
    XCTAssertNotNil(dict["lastname"])
    XCTAssertNotNil(dict["firstname"])
    XCTAssertNotNil(dict["age"])
    XCTAssertNil(dict["404 not found"])
  }
  
  func testArrayWithoutNilPList() throws {
    let parser = PropertyListParser(allowNilValues: false)
    
    let plist = """
                ( 42, YES, "hello" )
                """
    let result = try parser.parse(plist.data(using: .utf8)!)
    print("result:", result as Any)
    
    guard let array = result as? Array<Any> else {
      XCTAssert(result is Array<Any>)
      return
    }
    
    XCTAssertEqual(array.count, 3)
    if array.count >= 3 {
      XCTAssert(array[0] as? Int    == 42)
      XCTAssert(array[1] as? Bool   == true)
      XCTAssert(array[2] as? String == "hello")
    }
  }
  
  func testArrayWithNilErrorPList() throws {
    let parser = PropertyListParser(allowNilValues: false)
    
    let plist = """
                ( 42, nil, YES, "hello" )
                """
    XCTAssertThrowsError(try parser.parse(plist.data(using: .utf8)!))
  }
  
  func testArrayWithNilPList() throws {
    let parser = PropertyListParser(allowNilValues: true)
    
    let plist = """
                ( 42, nil, YES, "hello" )
                """
    let result = try parser.parse(plist.data(using: .utf8)!)
    print("result:", result as Any)
    
    guard let array = result as? Array<Any?> else {
      XCTAssert(result is Array<Any?>)
      return
    }
    
    XCTAssertEqual(array.count, 4)
    if array.count >= 4 {
      XCTAssert(array[0] as? Int    == 42)
      XCTAssert(array[1] == nil)
      XCTAssert(array[2] as? Bool   == true)
      XCTAssert(array[3] as? String == "hello")
    }
  }
  
  
  // MARK: - Linux

  static var allTests = [
    ( "testEmptyPList",             testEmptyPList             ),
    ( "testBasicPList",             testBasicPList             ),
    ( "testArrayWithoutNilPList",   testArrayWithoutNilPList   ),
    ( "testArrayWithNilErrorPList", testArrayWithNilErrorPList ),
    ( "testArrayWithNilPList",      testArrayWithNilPList      ),
  ]
}
