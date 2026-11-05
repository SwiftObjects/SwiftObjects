//
//  WOActionMacroTests.swift
//  SwiftObjectsMacrosTests
//
//  Created by Helge Hess on 03.11.26.
//  Copyright © 2026 ZeeZide. All rights reserved.
//

import XCTest
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosTestSupport
@testable import SwiftObjectsMacros

final class WOActionMacroTests : XCTestCase {

  /**
   * The specs used for root classes. The compiler passes the conformances a
   * class is missing to the macro, which marks the class as a root.
   */
  let root : [ String : MacroSpec ] = [
    "WODirectAction" : MacroSpec(type: WODirectActionMacro.self,
                                 conformances: [ "WODirectAction" ]),
    "WOComponent"    : MacroSpec(type: WOComponentMacro.self,
                                 conformances: [ "WOComponent" ]),
    "WOAction"       : MacroSpec(type: WOActionMacro.self)
  ]

  /**
   * The specs used for subclasses. A class inheriting the conformance from
   * its superclass gets no conformances passed.
   */
  let sub : [ String : MacroSpec ] = [
    "WODirectAction" : MacroSpec(type: WODirectActionMacro.self),
    "WOComponent"    : MacroSpec(type: WOComponentMacro.self),
    "WOAction"       : MacroSpec(type: WOActionMacro.self)
  ]

  static let componentStorage = """
        public var log : WOLogger = WOPrintLogger.shared
        public var variableDictionary = [ String : Any ]()
        public var exposedActions = [ String : WOExposedAction ]()
        public var _wcName : String? = nil
        public weak var context : WOContext? = nil
        public weak var _session : WOSession? = nil
        public var subcomponents = [ String : WOComponent ]()
        public var wocBindings = [ String : WOAssociation ]()
        public weak var parentComponent : WOComponent? = nil
        public var isStateless = false
        public var isAwake = false
        public var _resourceManager : WOResourceManager? = nil
        public var _template : WOElement? = nil
        public var renderObject : Any? = nil
    """

  func testDirectActionRoot() {
    assertMacroExpansion(
      """
      @WODirectAction
      final class DirectAction {
        var age = 1337
        func showAction() -> Any? { return nil }
        func noteAction() { }
        @WOAction("bye") func goodbye() throws -> String { return "bye" }
        func helper() -> Int { return 42 }
        static func classAction() -> Any? { return nil }
      }
      """,
      expandedSource: """
      final class DirectAction {
        var age = 1337
        func showAction() -> Any? { return nil }
        func noteAction() { }
        func goodbye() throws -> String { return "bye" }
        func helper() -> Int { return 42 }
        static func classAction() -> Any? { return nil }

          public let log : WOLogger

          public let context : WOContext

          public var variableDictionary = [ String : Any ]()

          public var exposedActions = [ String : WOExposedAction ]()

          public init(context: WOContext) {
            self.context = context
            self.log = context.log
          }

          func lookupActionNamed(_ name: String) -> WOActionCallback? {
            switch name {
              case "show":
                return {
                    self.showAction()
                }
              case "note":
                return {
                    self.noteAction()
                    return nil
                }
              case "bye":
                return {
                    try self.goodbye()
                }
              default:
                return woLookupActionNamed(name)
            }
          }

          func value(forKey k: String) -> Any? {
            switch k {
              case "age":
                return self.age
              default:
                return woValue(forKey: k)
            }
          }

          func takeValue(_ value: Any?, forKey k: String) throws {
            switch k {
              case "age":
                self.age = try KeyValueCoding.coerce(value, forKey: k)
              default:
                try woTakeValue(value, forKey: k)
            }
          }
      }

      extension DirectAction : WODirectAction {
      }
      """,
      macroSpecs: root
    )
  }

  func testDirectActionNonFinalRoot() {
    assertMacroExpansion(
      """
      @WODirectAction
      class Base {
        var x = 1
      }
      """,
      expandedSource: """
      class Base {
        var x = 1

          public let log : WOLogger

          public let context : WOContext

          public var variableDictionary = [ String : Any ]()

          public var exposedActions = [ String : WOExposedAction ]()

          required public init(context: WOContext) {
            self.context = context
            self.log = context.log
          }

          func lookupActionNamed(_ name: String) -> WOActionCallback? {
            return woLookupActionNamed(name)
          }

          func value(forKey k: String) -> Any? {
            switch k {
              case "x":
                return self.x
              default:
                return woValue(forKey: k)
            }
          }

          func takeValue(_ value: Any?, forKey k: String) throws {
            switch k {
              case "x":
                self.x = try KeyValueCoding.coerce(value, forKey: k)
              default:
                try woTakeValue(value, forKey: k)
            }
          }

          func defaultAction() -> WOActionResults? {
            return pageWithName("Main")
          }

          func performActionNamed(_ name: String) throws -> Any? {
            return try woPerformActionNamed(name)
          }

          func appendToDescription(_ ms: inout String) {
            woAppendToDescription(&ms)
          }
      }

      extension Base : WODirectAction {
      }
      """,
      macroSpecs: root
    )
  }

  func testComponentRoot() {
    assertMacroExpansion(
      """
      @WOComponent
      final class Main {
        let store = CowStore.shared
        var cow : Cow? = nil
        var isNew : Bool { return cow == nil }
        var title : String { get { "" } set { } }
        var _private = 0
        static let shared = Main()
        @WOAction func save() -> Any? { return nil }
        func showAction() -> Any? { return nil }
        @WOAction("hello", direct: true) func sayHello() -> String { "hi" }
        @WOAction(direct: false) func editAction() -> Any? { return nil }
      }
      """,
      expandedSource: """
      final class Main {
        let store = CowStore.shared
        var cow : Cow? = nil
        var isNew : Bool { return cow == nil }
        var title : String { get { "" } set { } }
        var _private = 0
        static let shared = Main()
        func save() -> Any? { return nil }
        func showAction() -> Any? { return nil }
        func sayHello() -> String { "hi" }
        func editAction() -> Any? { return nil }

      \(Self.componentStorage.split(separator: "\n").joined(separator: "\n\n"))

          public init() {
          }

          func lookupActionNamed(_ name: String) -> WOActionCallback? {
            switch name {
              case "save":
                return {
                    self.save()
                }
              case "show":
                return {
                    self.showAction()
                }
              case "hello":
                return {
                    self.sayHello()
                }
              case "edit":
                return {
                    self.editAction()
                }
              default:
                return woLookupActionNamed(name)
            }
          }

          func lookupDirectActionNamed(_ name: String) -> WOActionCallback? {
            switch name {
              case "show":
                return {
                    self.showAction()
                }
              case "hello":
                return {
                    self.sayHello()
                }
              default:
                return woLookupDirectActionNamed(name)
            }
          }

          func value(forKey k: String) -> Any? {
            switch k {
              case "store":
                return self.store
              case "cow":
                return self.cow
              case "isNew":
                return self.isNew
              case "title":
                return self.title
              default:
                return woValue(forKey: k)
            }
          }

          func takeValue(_ value: Any?, forKey k: String) throws {
            switch k {
              case "cow":
                self.cow = try KeyValueCoding.coerce(value, forKey: k)
              case "title":
                self.title = try KeyValueCoding.coerce(value, forKey: k)
              default:
                try woTakeValue(value, forKey: k)
            }
          }
      }

      extension Main : WOComponent {
      }
      """,
      macroSpecs: root
    )
  }

  func testComponentNonFinalRoot() {
    assertMacroExpansion(
      """
      @WOComponent
      open class CommonPage {
        var title = ""
        func awake() {}
      }
      """,
      expandedSource: """
      open class CommonPage {
        var title = ""
        func awake() {}

      \(Self.componentStorage.split(separator: "\n").joined(separator: "\n\n"))

          required public init() {
          }

          open func lookupActionNamed(_ name: String) -> WOActionCallback? {
            return woLookupActionNamed(name)
          }

          open func lookupDirectActionNamed(_ name: String) -> WOActionCallback? {
            return woLookupDirectActionNamed(name)
          }

          open func value(forKey k: String) -> Any? {
            switch k {
              case "title":
                return self.title
              default:
                return woValue(forKey: k)
            }
          }

          open func takeValue(_ value: Any?, forKey k: String) throws {
            switch k {
              case "title":
                self.title = try KeyValueCoding.coerce(value, forKey: k)
              default:
                try woTakeValue(value, forKey: k)
            }
          }

          open func initWithContext(_ ctx: WOContext) -> WOComponent? {
            return woInitWithContext(ctx)
          }

          open var name : String {
            return woName
          }

          open func sleep() {
          }

          open func reset() {
          }

          open func pageWithName(_ name: String) -> WOComponent? {
            return woPageWithName(name)
          }

          open func defaultAction() -> WOComponent? {
            return self
          }

          open func performActionNamed(_ name: String) throws -> Any? {
            return try woPerformActionNamed(name)
          }

          open func shouldTakeValues(from request: WORequest, in context: WOContext) -> Bool {
            return woShouldTakeValues(from: request, in: context)
          }

          open func takeValues(from request: WORequest, in context: WOContext) throws {
            try woTakeValues(from: request, in: context)
          }

          open func invokeAction(for request: WORequest, in context: WOContext) throws -> Any? {
            return try woInvokeAction(for: request, in: context)
          }

          open func append(to response: WOResponse, in context: WOContext) throws {
            try woAppend(to: response, in: context)
          }

          open func walkTemplate(using walker: WOElementWalker, in context: WOContext) throws {
            try woWalkTemplate(using: walker, in: context)
          }

          open var synchronizesVariablesWithBindings : Bool {
            return true
          }

          open func validationFailed(with error: Swift.Error, value: Any?, keyPath: String?) {
          }

          open func canRenderObject(_ object: Any?, in context: WOContext) -> Bool {
            return false
          }

          open func appendToDescription(_ ms: inout String) {
            woAppendToDescription(&ms)
          }
      }

      extension CommonPage : WOComponent {
      }
      """,
      macroSpecs: root
    )
  }

  func testComponentSubclass() {
    assertMacroExpansion(
      """
      @WOComponent
      final class Main : CommonPage {
        var counter = 0
        @WOAction func save() -> Any? { return nil }
        func showAction() -> Any? { return nil }
      }
      """,
      expandedSource: """
      final class Main : CommonPage {
        var counter = 0
        func save() -> Any? { return nil }
        func showAction() -> Any? { return nil }

          override func lookupActionNamed(_ name: String) -> WOActionCallback? {
            switch name {
              case "save":
                return {
                    self.save()
                }
              case "show":
                return {
                    self.showAction()
                }
              default:
                return super.lookupActionNamed(name)
            }
          }

          override func lookupDirectActionNamed(_ name: String) -> WOActionCallback? {
            switch name {
              case "show":
                return {
                    self.showAction()
                }
              default:
                return super.lookupDirectActionNamed(name)
            }
          }

          override func value(forKey k: String) -> Any? {
            switch k {
              case "counter":
                return self.counter
              default:
                return super.value(forKey: k)
            }
          }

          override func takeValue(_ value: Any?, forKey k: String) throws {
            switch k {
              case "counter":
                self.counter = try KeyValueCoding.coerce(value, forKey: k)
              default:
                try super.takeValue(value, forKey: k)
            }
          }
      }
      """,
      macroSpecs: sub
    )
  }

  func testComponentExplicitConformanceIsRoot() {
    // The compiler doesn't report explicitly declared conformances as
    // missing, the inheritance clause marks the class as a root.
    assertMacroExpansion(
      """
      @WOComponent
      final class Empty : WOComponent {
      }
      """,
      expandedSource: """
      final class Empty : WOComponent {

      \(Self.componentStorage.split(separator: "\n").joined(separator: "\n\n"))

          public init() {
          }
      }
      """,
      macroSpecs: sub
    )
  }

  func testDeclaredMembersAndObservers() {
    // Storage declared in the class is not generated again, properties with
    // observers are settable, and properties named like the parameters of
    // the accessors are qualified with `self`.
    assertMacroExpansion(
      """
      @WOComponent
      final class Stateless {
        var isStateless : Bool { return true }
        var value : Any? = nil { didSet { changes += 1 } }
        var changes = 0
      }
      """,
      expandedSource: """
      final class Stateless {
        var isStateless : Bool { return true }
        var value : Any? = nil { didSet { changes += 1 } }
        var changes = 0

      \(Self.componentStorage
           .split(separator: "\n")
           .filter { !$0.contains("isStateless") }
           .joined(separator: "\n\n"))

          public init() {
          }

          func value(forKey k: String) -> Any? {
            switch k {
              case "isStateless":
                return self.isStateless
              case "value":
                return self.value
              case "changes":
                return self.changes
              default:
                return woValue(forKey: k)
            }
          }

          func takeValue(_ value: Any?, forKey k: String) throws {
            switch k {
              case "value":
                self.value = try KeyValueCoding.coerce(value, forKey: k)
              case "changes":
                self.changes = try KeyValueCoding.coerce(value, forKey: k)
              default:
                try woTakeValue(value, forKey: k)
            }
          }
      }

      extension Stateless : WOComponent {
      }
      """,
      macroSpecs: root
    )
  }

  func testPublicSubclass() {
    // Overrides in a public subclass need the access modifier, otherwise
    // they are less accessible than the enclosing type.
    assertMacroExpansion(
      """
      @WOComponent
      public final class Main : CommonPage {
        var counter = 0
      }
      """,
      expandedSource: """
      public final class Main : CommonPage {
        var counter = 0

          public override func value(forKey k: String) -> Any? {
            switch k {
              case "counter":
                return self.counter
              default:
                return super.value(forKey: k)
            }
          }

          public override func takeValue(_ value: Any?, forKey k: String) throws {
            switch k {
              case "counter":
                self.counter = try KeyValueCoding.coerce(value, forKey: k)
              default:
                try super.takeValue(value, forKey: k)
            }
          }
      }
      """,
      macroSpecs: sub
    )
  }

  func testNotAClass() {
    assertMacroExpansion(
      """
      @WODirectAction
      struct Main {
        func showAction() -> Any? { return nil }
      }
      """,
      expandedSource: """
      struct Main {
        func showAction() -> Any? { return nil }
      }
      """,
      diagnostics: [
        DiagnosticSpec(
          message: "'@WODirectAction' can only be applied to classes",
          line: 1, column: 1)
      ],
      macroSpecs: root
    )
  }

  func testDuplicateAction() {
    assertMacroExpansion(
      """
      @WOComponent
      final class Main : CommonPage {
        func showAction() -> Any? { return nil }
        @WOAction("show") func display() -> Any? { return nil }
      }
      """,
      expandedSource: """
      final class Main : CommonPage {
        func showAction() -> Any? { return nil }
        func display() -> Any? { return nil }

          override func lookupActionNamed(_ name: String) -> WOActionCallback? {
            switch name {
              case "show":
                return {
                    self.showAction()
                }
              default:
                return super.lookupActionNamed(name)
            }
          }

          override func lookupDirectActionNamed(_ name: String) -> WOActionCallback? {
            switch name {
              case "show":
                return {
                    self.showAction()
                }
              default:
                return super.lookupDirectActionNamed(name)
            }
          }
      }
      """,
      diagnostics: [
        DiagnosticSpec(
          message: "action 'show' is already provided by 'showAction'",
          line: 4, column: 26)
      ],
      macroSpecs: sub
    )
  }

  func testInvalidExplicitAction() {
    assertMacroExpansion(
      """
      @WOComponent
      final class Main : CommonPage {
        @WOAction func show(_ id: Int) -> Any? { return nil }
      }
      """,
      expandedSource: """
      final class Main : CommonPage {
        func show(_ id: Int) -> Any? { return nil }
      }
      """,
      diagnostics: [
        DiagnosticSpec(
          message: "action methods take no parameters", line: 3, column: 18),
        DiagnosticSpec(
          message: "action methods take no parameters", line: 3, column: 18)
      ],
      macroSpecs: sub
    )
  }

  func testInvalidActionName() {
    assertMacroExpansion(
      """
      @WOComponent
      final class Main : CommonPage {
        @WOAction("sh\\"ow") func show() -> Any? { return nil }
      }
      """,
      expandedSource: """
      final class Main : CommonPage {
        func show() -> Any? { return nil }
      }
      """,
      diagnostics: [
        DiagnosticSpec(
          message: "the action name must not contain quotes or backslashes",
          line: 3, column: 28),
        DiagnosticSpec(
          message: "the action name must not contain quotes or backslashes",
          line: 3, column: 28)
      ],
      macroSpecs: sub
    )
  }
}
