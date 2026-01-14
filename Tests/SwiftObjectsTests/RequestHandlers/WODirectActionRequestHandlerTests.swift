//
//  WODirectActionRequestHandlerTests.swift
//  SwiftObjectsTests
//

import XCTest
@testable import SwiftObjects

class WODirectActionRequestHandlerTests: XCTestCase {

  // MARK: - Test Setup

  var application : WOApplication!
  var handler     : WODirectActionRequestHandler!

  override func setUp() {
    super.setUp()
    application = WOApplication()
    handler     = WODirectActionRequestHandler(application: application)
  }

  override func tearDown() {
    handler     = nil
    application = nil
    super.tearDown()
  }


  // MARK: - URL Parsing Tests
  //
  // URL format: /AppName/wa/ActionClass/ActionName
  // The request handler uses requestHandlerPathArray which contains parts
  // after the request handler key.

  func testDefaultActionName() {
    // /wa/ with no path should default to DirectAction/default
    let request = WORequest(method: "GET", uri: "/wa/")
    let ( clazz, action ) = handler.extractActionName(from: request)

    XCTAssertEqual(clazz,  "DirectAction")
    XCTAssertEqual(action, "default")
  }

  func testSinglePathComponent() {
    // /wa/Main/show - path array contains ["show"]
    // With single element, actionClassName defaults to DirectAction
    let request = WORequest(method: "GET", uri: "/wa/Main/show")
    let ( clazz, action ) = handler.extractActionName(from: request)

    XCTAssertEqual(clazz,  "DirectAction")
    XCTAssertEqual(action, "show")
  }

  func testTwoPathComponents() {
    // /App/wa/Main/show - path array contains ["Main", "show"]
    let request = WORequest(method: "GET", uri: "/App/wa/Main/show")
    let ( clazz, action ) = handler.extractActionName(from: request)

    XCTAssertEqual(clazz,  "Main")
    XCTAssertEqual(action, "show")
  }

  func testActionWithExtension() {
    // /App/wa/Main/export.csv should strip .csv extension
    let request = WORequest(method: "GET", uri: "/App/wa/Main/export.csv")
    let ( clazz, action ) = handler.extractActionName(from: request)

    XCTAssertEqual(clazz,  "Main")
    XCTAssertEqual(action, "export")
  }

  func testThreePathComponents() {
    // /App/wa/Main/show/extra - path array is ["Main", "show", "extra"]
    // Only first two used for action
    let request = WORequest(method: "GET", uri: "/App/wa/Main/show/extra")
    let ( clazz, action ) = handler.extractActionName(from: request)

    XCTAssertEqual(clazz,  "Main")
    XCTAssertEqual(action, "show")
  }


  // MARK: - Handler Behavior Tests

  func testHandlerHasApplication() {
    XCTAssertNotNil(handler.application)
    XCTAssert(handler.application === application)
  }

  func testMissingResourceManagerReturnsNil() throws {
    // Without a resource manager, handleRequest should return nil
    let request = WORequest(method: "GET", uri: "/wa/Main/default")
    let context = WOAppContext(application: application, request: request)

    // Remove resource manager (if any) by creating app without one
    application.resourceManager = nil

    let response = try handler.handleRequest(request, in: context, session: nil)
    XCTAssertNil(response)
  }


  // MARK: - RenderResults Tests

  func testRenderStringResult() throws {
    let request = WORequest(method: "GET", uri: "/wa/")
    let context = WOAppContext(application: application, request: request)

    let response = try handler.renderResults("Hello World", in: context)

    XCTAssertNotNil(response)
    XCTAssert(response?.contentString?.contains("Hello World") ?? false)
  }

  func testRenderNilResult() throws {
    let request = WORequest(method: "GET", uri: "/wa/")
    let context = WOAppContext(application: application, request: request)

    let response = try handler.renderResults(nil, in: context)

    XCTAssertNil(response)
  }


  // MARK: - Linux

  static var allTests = [
    ( "testDefaultActionName",           testDefaultActionName           ),
    ( "testSinglePathComponent",         testSinglePathComponent         ),
    ( "testTwoPathComponents",           testTwoPathComponents           ),
    ( "testActionWithExtension",         testActionWithExtension         ),
    ( "testThreePathComponents",         testThreePathComponents         ),
    ( "testHandlerHasApplication",       testHandlerHasApplication       ),
    ( "testMissingResourceManagerReturnsNil",
                                         testMissingResourceManagerReturnsNil ),
    ( "testRenderStringResult",          testRenderStringResult          ),
    ( "testRenderNilResult",             testRenderNilResult             ),
  ]
}
