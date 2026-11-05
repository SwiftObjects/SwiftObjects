//
//  WOActionMethod.swift
//  SwiftObjectsMacros
//
//  Created by Helge Hess on 03.11.26.
//  Copyright © 2026 ZeeZide. All rights reserved.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

/// Describes a method which is exposed as an action.
struct WOActionMethod {

  /// The name of the action, as used in templates and URLs.
  let name     : String

  /**
   * Whether the action can be invoked using a direct action URL. Methods
   * with the `Action` suffix are direct actions, other methods marked with
   * `@WOAction` are not, unless the attribute passes `direct:` explicitly.
   */
  let isDirect : Bool

  /// The closure expression calling the method.
  let closure  : String

  /**
   * Analyzes the given function and returns `nil` if it is not an action.
   *
   * Placement errors of an explicit `@WOAction` attribute are diagnosed in
   * the given context.
   */
  init?(_ function: FunctionDeclSyntax, in context: some MacroExpansionContext)
  {
    let attribute  = function.attributes.first(named: "WOAction")
    let methodName = function.name.text
    let explicit   = attribute != nil

    var explicitName : String? = nil
    var isDirect     : Bool?   = nil
    for argument in attribute?.argumentList ?? [] {
      if argument.label?.text == "direct" {
        guard let literal = argument.expression.booleanLiteral else {
          context.diagnose(Diagnostic(
            node: argument.expression,
            message: MacroExpansionErrorMessage(
              "the 'direct' flag must be a boolean literal")))
          return nil
        }
        isDirect = literal
      }
      else {
        guard let literal = argument.expression.stringLiteral else {
          context.diagnose(Diagnostic(
            node: argument.expression,
            message: MacroExpansionErrorMessage(
              "the action name must be a string literal")))
          return nil
        }
        explicitName = literal
      }
    }

    let isSuffixed = methodName.hasSuffix("Action") && methodName != "Action"
    let name : String
    if let explicitName {
      name = explicitName
    }
    else if isSuffixed {
      name = String(methodName.dropLast("Action".count))
    }
    else if explicit {
      name = methodName
    }
    else {
      return nil
    }

    func reject(_ message: String) {
      guard explicit else { return }
      context.diagnose(Diagnostic(
        node: function.name, message: MacroExpansionErrorMessage(message)))
    }

    let isTypeMethod = function.modifiers.contains {
      $0.name.tokenKind == .keyword(.static) ||
      $0.name.tokenKind == .keyword(.class)
    }
    guard !isTypeMethod else {
      reject("action methods must be instance methods")
      return nil
    }
    guard function.signature.parameterClause.parameters.isEmpty else {
      reject("action methods take no parameters")
      return nil
    }
    guard function.signature.effectSpecifiers?.asyncSpecifier == nil else {
      reject("action methods cannot be async")
      return nil
    }
    guard !name.isEmpty else {
      reject("the action name must not be empty")
      return nil
    }
    guard !name.contains("\""), !name.contains("\\"),
          !name.contains(where: \.isNewline)
    else {
      reject("the action name must not contain quotes or backslashes")
      return nil
    }

    let isThrowing = function.signature.effectSpecifiers?.throwsClause != nil
    let returnType = function.signature.returnClause?.type
                       .trimmedDescription ?? "Void"
    let returnsVoid = returnType == "Void" || returnType == "()"
    let call = (isThrowing ? "try " : "") + "self.\(methodName)()"

    self.name     = name
    self.isDirect = isDirect ?? isSuffixed
    self.closure  = returnsVoid ? "{ \(call)\nreturn nil }" : "{ \(call) }"
  }

  /**
   * Collects the actions declared in the body of the given class. Duplicate
   * action names are diagnosed.
   */
  static func actions(in classDecl: ClassDeclSyntax,
                      in context: some MacroExpansionContext)
              -> [ WOActionMethod ]
  {
    var actions = [ WOActionMethod ]()
    var seen    = [ String : FunctionDeclSyntax ]()

    for member in classDecl.memberBlock.members {
      guard let function = member.decl.as(FunctionDeclSyntax.self),
            let action = WOActionMethod(function, in: context)
      else { continue }

      if let other = seen[action.name] {
        context.diagnose(Diagnostic(
          node: function.name,
          message: MacroExpansionErrorMessage(
            "action '\(action.name)' is already provided by " +
            "'\(other.name.text)'")))
        continue
      }
      seen[action.name] = function
      actions.append(action)
    }
    return actions
  }
}
