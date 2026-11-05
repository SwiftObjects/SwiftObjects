//
//  WOActionClass.swift
//  SwiftObjectsMacros
//
//  Created by Helge Hess on 03.11.26.
//  Copyright © 2026 ZeeZide. All rights reserved.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

/**
 * The analysis of a class marked with `@WODirectAction` or `@WOComponent`,
 * and the generator for the members added to it.
 *
 * A class is a root if it doesn't already conform to the protocol. The
 * compiler passes the missing conformances to the macro, a subclass of a
 * conforming class gets an empty list. Since explicitly declared
 * conformances are not passed either, the inheritance clause is checked for
 * the protocol name as well.
 */
struct WOActionClass {

  enum Kind {
    case directAction
    case component

    var protocolName : String {
      switch self {
        case .directAction: return "WODirectAction"
        case .component:    return "WOComponent"
      }
    }
  }

  let kind      : Kind
  let classDecl : ClassDeclSyntax
  let actions   : [ WOActionMethod ]
  let properties: [ WOProperty ]
  let isRoot    : Bool
  let isFinal   : Bool

  /// The access modifier for generated members, derived from the class.
  let access    : String

  /// The names of the members declared in the class body.
  let declared  : Set<String>

  /// The names of the methods declared in the class body.
  let declaredMethods : Set<String>

  init?(_ declaration: some DeclGroupSyntax, attribute: AttributeSyntax,
        kind: Kind, conformingTo protocols: [ TypeSyntax ],
        in context: some MacroExpansionContext)
  {
    let macroName = attribute.attributeName.trimmedDescription
    guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
      context.diagnose(Diagnostic(
        node: attribute,
        message: MacroExpansionErrorMessage(
          "'@\(macroName)' can only be applied to classes")))
      return nil
    }

    let inherited = classDecl.inheritanceClause?.inheritedTypes
      .map { $0.type.trimmedDescription } ?? []

    self.kind      = kind
    self.classDecl = classDecl
    self.isRoot    = !protocols.isEmpty
                  || inherited.contains(kind.protocolName)
    self.isFinal   = classDecl.modifiers.contains {
      $0.name.tokenKind == .keyword(.final)
    }
    self.access    = classDecl.modifiers.compactMap { modifier -> String? in
      switch modifier.name.tokenKind {
        case .keyword(.open):   return "open "
        case .keyword(.public): return "public "
        default:                return nil
      }
    }.first ?? ""

    self.actions    = WOActionMethod.actions(in: classDecl, in: context)
    self.properties = WOProperty.properties(in: classDecl)

    var declared = Set<String>()
    var methods  = Set<String>()
    for member in classDecl.memberBlock.members {
      if let function = member.decl.as(FunctionDeclSyntax.self) {
        declared.insert(function.name.text)
        methods .insert(function.name.text)
      }
      else if member.decl.is(InitializerDeclSyntax.self) {
        declared.insert("init")
      }
      else if let variable = member.decl.as(VariableDeclSyntax.self) {
        for binding in variable.bindings {
          if let name = binding.pattern.as(IdentifierPatternSyntax.self) {
            declared.insert(name.identifier.text)
          }
        }
      }
    }
    self.declared        = declared
    self.declaredMethods = methods
  }

  /**
   * Generates the extension adding the protocol conformance. Nothing is
   * generated for non-classes, the member expansion reports the error.
   */
  static func conformance(of type: some TypeSyntaxProtocol,
                          attachedTo declaration: some DeclGroupSyntax,
                          to protocols: [ TypeSyntax ]) throws
              -> [ ExtensionDeclSyntax ]
  {
    guard !protocols.isEmpty, declaration.is(ClassDeclSyntax.self) else {
      return []
    }
    let names = protocols.map { $0.trimmedDescription }
                         .joined(separator: ", ")
    let decl : DeclSyntax = "extension \(type.trimmed) : \(raw: names) {}"
    guard let ext = decl.as(ExtensionDeclSyntax.self) else { return [] }
    return [ ext ]
  }

  /// Generates the members added to the class.
  func members() -> [ DeclSyntax ] {
    var decls = [ DeclSyntax ]()

    if isRoot {
      decls += storage()
      if !declared.contains("init") { decls.append(initializer()) }
    }

    decls += actionLookups()
    decls += kvcAccessors()

    if isRoot && !isFinal {
      decls += hookStubs()
    }
    return decls
  }

  /// The modifier for generated methods which replace protocol defaults.
  private var overrideOrAccess : String {
    return isRoot ? access : "\(access)override "
  }


  // MARK: - Storage

  /**
   * The storage properties required by the protocol. Properties declared in
   * the class body are skipped, e.g. a component can declare its own
   * `isStateless`.
   */
  private func storage() -> [ DeclSyntax ] {
    let properties : [ ( name: String, decl: String ) ]
    switch kind {
      case .directAction:
        properties = [
          ( "log",     "public let log : WOLogger" ),
          ( "context", "public let context : WOContext" ),
          ( "variableDictionary",
            "public var variableDictionary = [ String : Any ]()" ),
          ( "exposedActions",
            "public var exposedActions = [ String : WOExposedAction ]()" )
        ]
      case .component:
        properties = [
          ( "log",     "public var log : WOLogger = WOPrintLogger.shared" ),
          ( "variableDictionary",
            "public var variableDictionary = [ String : Any ]()" ),
          ( "exposedActions",
            "public var exposedActions = [ String : WOExposedAction ]()" ),
          ( "_wcName",  "public var _wcName : String? = nil" ),
          ( "context",  "public weak var context : WOContext? = nil" ),
          ( "_session", "public weak var _session : WOSession? = nil" ),
          ( "subcomponents",
            "public var subcomponents = [ String : WOComponent ]()" ),
          ( "wocBindings",
            "public var wocBindings = [ String : WOAssociation ]()" ),
          ( "parentComponent",
            "public weak var parentComponent : WOComponent? = nil" ),
          ( "isStateless",  "public var isStateless = false" ),
          ( "isAwake",      "public var isAwake = false" ),
          ( "_resourceManager",
            "public var _resourceManager : WOResourceManager? = nil" ),
          ( "_template",    "public var _template : WOElement? = nil" ),
          ( "renderObject", "public var renderObject : Any? = nil" )
        ]
    }
    return properties.filter { !declared.contains($0.name) }
                     .map { "\(raw: $0.decl)" }
  }

  private func initializer() -> DeclSyntax {
    let required = isFinal ? "" : "required "
    switch kind {
      case .directAction:
        return """
          \(raw: required)public init(context: WOContext) {
            self.context = context
            self.log = context.log
          }
          """
      case .component:
        return "\(raw: required)public init() {}"
    }
  }


  // MARK: - Actions

  private func actionLookups() -> [ DeclSyntax ] {
    var decls = [ DeclSyntax ]()

    // The lookup is always generated for a non-final root, so that
    // subclasses can override it.
    let generateEmpty = isRoot && !isFinal

    if !declaredMethods.contains("lookupActionNamed"),
       !actions.isEmpty || generateEmpty
    {
      decls.append(lookup("lookupActionNamed", for: actions))
    }

    if kind == .component,
       !declaredMethods.contains("lookupDirectActionNamed")
    {
      let direct = actions.filter { $0.isDirect }
      if !direct.isEmpty || generateEmpty {
        decls.append(lookup("lookupDirectActionNamed", for: direct))
      }
    }
    return decls
  }

  /// Generates the given lookup method for the actions.
  private func lookup(_ method: String, for actions: [ WOActionMethod ])
               -> DeclSyntax
  {
    let cases = actions
      .map { "    case \"\($0.name)\": return \($0.closure)" }
      .joined(separator: "\n")
    let fallback = isRoot
      ? "wo\(method.prefix(1).uppercased())\(method.dropFirst())(name)"
      : "super.\(method)(name)"
    let signature = "\(overrideOrAccess)func \(method)(_ name: String)"
                  + " -> WOActionCallback?"
    guard !cases.isEmpty else {
      return """
        \(raw: signature) {
          return \(raw: fallback)
        }
        """
    }
    return """
      \(raw: signature) {
        switch name {
      \(raw: cases)
          default: return \(raw: fallback)
        }
      }
      """
  }


  // MARK: - KVC

  private func kvcAccessors() -> [ DeclSyntax ] {
    var decls = [ DeclSyntax ]()
    let generateEmpty = isRoot && !isFinal

    if !declaredMethods.contains("value"),
       !properties.isEmpty || generateEmpty
    {
      let cases = properties
        .map { "    case \"\($0.name)\": return self.\($0.name)" }
        .joined(separator: "\n")
      let fallback = isRoot ? "woValue(forKey: k)" : "super.value(forKey: k)"
      let signature = "\(overrideOrAccess)func value(forKey k: String) -> Any?"
      if cases.isEmpty {
        decls.append("""
          \(raw: signature) {
            return \(raw: fallback)
          }
          """)
      }
      else {
        decls.append("""
          \(raw: signature) {
            switch k {
          \(raw: cases)
              default: return \(raw: fallback)
            }
          }
          """)
      }
    }

    let settable = properties.filter { $0.isSettable }
    if !declaredMethods.contains("takeValue"),
       !settable.isEmpty || generateEmpty
    {
      let cases = settable
        .map {
          "    case \"\($0.name)\": " +
          "self.\($0.name) = try KeyValueCoding.coerce(value, forKey: k)"
        }
        .joined(separator: "\n")
      let fallback = isRoot
        ? "try woTakeValue(value, forKey: k)"
        : "try super.takeValue(value, forKey: k)"
      let signature = "\(overrideOrAccess)func takeValue(_ value: Any?,"
                    + " forKey k: String) throws"
      if cases.isEmpty {
        decls.append("""
          \(raw: signature) {
            \(raw: fallback)
          }
          """)
      }
      else {
        decls.append("""
          \(raw: signature) {
            switch k {
          \(raw: cases)
              default: \(raw: fallback)
            }
          }
          """)
      }
    }
    return decls
  }


  // MARK: - Hook Stubs
  
  /**
   * The overridable stubs generated in a non-final root class. Protocol
   * extension defaults are not overridable by subclasses, the stubs forward
   * to them as class members, which are.
   */
  private func hookStubs() -> [ DeclSyntax ] {
    let stubs : [ ( name: String, signature: String, body: String ) ]
    switch kind {
      case .directAction:
        stubs = [
          ( "defaultAction",
            "func defaultAction() -> WOActionResults?",
            "return pageWithName(\"Main\")" ),
          ( "performActionNamed",
            "func performActionNamed(_ name: String) throws -> Any?",
            "return try woPerformActionNamed(name)" ),
          ( "appendToDescription",
            "func appendToDescription(_ ms: inout String)",
            "woAppendToDescription(&ms)" )
        ]
      case .component:
        stubs = [
          ( "initWithContext",
            "func initWithContext(_ ctx: WOContext) -> WOComponent?",
            "return woInitWithContext(ctx)" ),
          ( "name",
            "var name : String",
            "return woName" ),
          ( "awake", "func awake()", "" ),
          ( "sleep", "func sleep()", "" ),
          ( "reset", "func reset()", "" ),
          ( "pageWithName",
            "func pageWithName(_ name: String) -> WOComponent?",
            "return woPageWithName(name)" ),
          ( "defaultAction",
            "func defaultAction() -> WOComponent?",
            "return self" ),
          ( "performActionNamed",
            "func performActionNamed(_ name: String) throws -> Any?",
            "return try woPerformActionNamed(name)" ),
          ( "shouldTakeValues",
            "func shouldTakeValues(from request: WORequest,"
            + " in context: WOContext) -> Bool",
            "return woShouldTakeValues(from: request, in: context)" ),
          ( "takeValues",
            "func takeValues(from request: WORequest,"
            + " in context: WOContext) throws",
            "try woTakeValues(from: request, in: context)" ),
          ( "invokeAction",
            "func invokeAction(for request: WORequest,"
            + " in context: WOContext) throws -> Any?",
            "return try woInvokeAction(for: request, in: context)" ),
          ( "append",
            "func append(to response: WOResponse,"
            + " in context: WOContext) throws",
            "try woAppend(to: response, in: context)" ),
          ( "walkTemplate",
            "func walkTemplate(using walker: WOElementWalker,"
            + " in context: WOContext) throws",
            "try woWalkTemplate(using: walker, in: context)" ),
          ( "synchronizesVariablesWithBindings",
            "var synchronizesVariablesWithBindings : Bool",
            "return true" ),
          ( "validationFailed",
            "func validationFailed(with error: Swift.Error, value: Any?,"
            + " keyPath: String?)",
            "" ),
          ( "canRenderObject",
            "func canRenderObject(_ object: Any?, in context: WOContext)"
            + " -> Bool",
            "return false" ),
          ( "appendToDescription",
            "func appendToDescription(_ ms: inout String)",
            "woAppendToDescription(&ms)" )
        ]
    }
    return stubs.filter { !declared.contains($0.name) }.map { stub in
      let body = stub.body.isEmpty ? "{}" : "{\n  \(stub.body)\n}"
      return "\(raw: access)\(raw: stub.signature) \(raw: body)"
    }
  }
}
