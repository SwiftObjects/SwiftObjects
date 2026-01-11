//
//  FormTestCase.swift
//  SwiftObjectsTests
//

import XCTest
@testable import SwiftObjects

/**
 * Base class for form element tests. Extends DynamicElementTestCase with
 * form-specific helpers for creating POST requests and form elements.
 */
class FormTestCase: DynamicElementTestCase {

  // MARK: - Request Helpers

  /**
   * Creates a POST request with the given form values.
   * Sets the appropriate Content-Type header.
   */
  func makePostRequest(formValues: [ String : Any ]) -> WORequest {
    let req = WORequest(method: "POST", uri: "/wa/Main/default")
    req.setHeader("application/x-www-form-urlencoded", for: "Content-Type")
    req._formValues = formValues.mapValues { value in
      if let array = value as? [ Any ] { return array }
      return [ value ]
    }
    return req
  }

  /**
   * Creates a new context from the given request, with the page entered.
   */
  func makeContext(for request: WORequest) -> WOContext {
    let ctx = WOAppContext(application: application, request: request)
    if let page = page {
      ctx.enterComponent(page)
    }
    return ctx
  }

  /**
   * Sets up a form context by setting isInForm = true on the current context.
   */
  func enterForm() {
    (context as? WOAppContext)?.isInForm = true
  }


  // MARK: - Association Helpers

  /**
   * Creates a value association wrapping the given constant value.
   */
  func value<T>(_ v: T) -> WOAssociation {
    return WOAssociationFactory.associationWithValue(v)
  }

  /**
   * Creates a keypath association for the given path.
   * Returns nil if the path is invalid.
   */
  func keypath(_ path: String) -> WOAssociation? {
    return WOAssociationFactory.associationWithKeyPath(path)
  }


  // MARK: - Element Creation Helpers

  typealias Bindings = [ String : WOAssociation ]

  /**
   * Creates an element of the given type and verifies all bindings were
   * consumed.
   */
  func makeElement<T: WODynamicElement>(_ type: T.Type,
                                        bindings: inout Bindings,
                                        template: WOElement? = nil) -> T
  {
    let element = T.init(name: "Test", bindings: &bindings,
                         template: template)
    XCTAssert(bindings.isEmpty,
              "Element did not consume bindings: \(bindings.keys)")
    return element
  }


  // MARK: - Assertion Helpers

  /**
   * Asserts that the response content contains the expected string.
   */
  func assertResponseContains(_ expected: String,
                              file: StaticString = #filePath,
                              line: UInt = #line)
  {
    let content = response.contentString ?? ""
    XCTAssert(content.contains(expected),
              "Response '\(content)' should contain '\(expected)'",
              file: file, line: line)
  }

  /**
   * Asserts that the response content equals the expected string exactly.
   */
  func assertResponseEquals(_ expected: String,
                            file: StaticString = #filePath,
                            line: UInt = #line)
  {
    XCTAssertEqual(response.contentString, expected, file: file, line: line)
  }

  /**
   * Asserts that all bindings were consumed (the dictionary is empty).
   */
  func assertBindingsConsumed(_ bindings: Bindings,
                              file: StaticString = #filePath,
                              line: UInt = #line)
  {
    XCTAssert(bindings.isEmpty,
              "Element did not consume bindings: \(bindings.keys)",
              file: file, line: line)
  }
}




