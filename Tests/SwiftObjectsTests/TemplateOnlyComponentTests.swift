//
//  TemplateOnlyComponentTests.swift
//  SwiftObjectsTests
//
//  Created by Helge Hess on 04.11.26.
//  Copyright © 2026 ZeeZide. All rights reserved.
//

import XCTest
import Foundation
@testable import SwiftObjects

/**
 * Templates without a Swift class, e.g. a `HelloPage.html` without a
 * `HelloPage` class, are instantiated using ``WOTemplateComponent``.
 */
final class TemplateOnlyComponentTests : XCTestCase {
  
  /// Looks up resources in a temporary directory instead of the source dir.
  final class TempResourceManager : WODevResourceManager {
    
    let directory : URL
    
    init(directory: URL) {
      self.directory = directory
      super.init(sourceType: TemplateOnlyComponentTests.self)
    }
    
    override func urlForResourceNamed(_ name: String,
                                      languages: [ String ] = []) -> URL?
    {
      let url = directory.appendingPathComponent(name)
      return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
  }
  
  var directory   : URL!           = nil
  var application : WOApplication! = nil
  var context     : WOContext!     = nil
  
  override func setUpWithError() throws {
    try super.setUpWithError()
    directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("SwiftObjectsTests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory,
                                            withIntermediateDirectories: true)
    try "<h1><wo:str value=\"$title\" /></h1>"
      .write(to: directory.appendingPathComponent("HelloPage.html"),
             atomically: true, encoding: .utf8)
    
    application = WOApplication()
    application.name = "MyApp"
    application.resourceManager = TempResourceManager(directory: directory)
    let request = WORequest(method: "GET", uri: "/MyApp/wa/HelloPage/default")
    context = WOAppContext(application: application, request: request)
  }
  override func tearDownWithError() throws {
    try? FileManager.default.removeItem(at: directory)
    context     = nil
    application = nil
    try super.tearDownWithError()
  }
  
  func testTemplateWithoutClassUsesStandin() throws {
    let page = try XCTUnwrap(application.pageWithName("HelloPage",
                                                      in: context))
    XCTAssertTrue(page is WOTemplateComponent)
    XCTAssertEqual(page.name, "HelloPage")
    XCTAssertNotNil(page.template)
  }
  
  func testTemplateWithoutClassRenders() throws {
    let page = try XCTUnwrap(application.pageWithName("HelloPage",
                                                      in: context))
    try page.takeValue("Hello World", forKey: "title")
    XCTAssertEqual(page.value(forKey: "title") as? String, "Hello World")
    
    let response = try page.generateResponse()
    XCTAssertEqual(response.contentString, "<h1>Hello World</h1>")
  }
}
