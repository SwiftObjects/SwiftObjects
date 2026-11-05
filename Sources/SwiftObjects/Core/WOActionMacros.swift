//
//  WOActionMacros.swift
//  SwiftObjects
//
//  Created by Helge Hess on 03.11.26.
//  Copyright © 2026 ZeeZide. All rights reserved.
//

/**
 * Turns a class into a ``WODirectAction``.
 *
 * The macro adds the conformance to the ``WODirectAction`` protocol, the
 * storage the protocol requires and the ``WODirectAction/init(context:)``
 * initializer. It then scans the class body for action methods and generates
 * the ``WODirectAction/lookupActionNamed(_:)`` method mapping the action
 * names to the methods. Finally it generates `value(forKey:)` and
 * `takeValue(_:forKey:)` for the properties declared in the class, so that
 * KVC access to those doesn't need runtime reflection.
 *
 * A method named with an `Action` suffix is an action under the name without
 * the suffix. Other methods can be marked with the ``WOAction(_:direct:)``
 * attribute, which optionally specifies the action name.
 * ```swift
 * @WODirectAction
 * final class DirectAction {
 *
 *   func helloAction() -> Any? {        // /MyApp/wa/DirectAction/hello
 *     return "Hello World"
 *   }
 *
 *   @WOAction("bye")
 *   func sayGoodbye() -> WOResponse? { // /MyApp/wa/DirectAction/bye
 *     ...
 *   }
 * }
 * ```
 *
 * The macro also supports subclasses of direct actions, it has to be
 * applied to the subclass as well. In this case it only generates the
 * lookup and KVC methods for the members added by the subclass. If the
 * root class is not `final`, the macro generates overridable stubs for the
 * methods of the protocol, so that subclasses can override them.
 */
@attached(member, conformances: WODirectAction,
          names: named(log), named(context), named(variableDictionary),
                 named(exposedActions), named(init),
                 named(lookupActionNamed), named(lookupDirectActionNamed),
                 named(value(forKey:)), named(takeValue(_:forKey:)),
                 named(defaultAction), named(performActionNamed),
                 named(appendToDescription))
@attached(extension, conformances: WODirectAction)
public macro WODirectAction() =
  #externalMacro(module: "SwiftObjectsMacros", type: "WODirectActionMacro")

/**
 * Turns a class into a ``WOComponent``.
 *
 * The macro adds the conformance to the ``WOComponent`` protocol, the
 * storage the protocol requires and the `init()` initializer. It then scans
 * the class body for action methods and generates the
 * ``WOComponent/lookupActionNamed(_:)`` method, which covers all actions and
 * is used by template bindings like `action="$save"`, and the
 * ``WOComponent/lookupDirectActionNamed(_:)`` method, which only covers the
 * direct actions. Methods with the `Action` suffix are direct actions, which
 * can be invoked using a URL like `/MyApp/wa/CowEditor/show`. Methods only
 * marked with `@WOAction` are component actions, which can only be bound in
 * templates, unless the attribute passes `direct: true`.
 *
 * Finally it generates `value(forKey:)` and `takeValue(_:forKey:)` for the
 * properties declared in the class, so that KVC access to those doesn't
 * need runtime reflection. This includes computed properties.
 * ```swift
 * @WOComponent
 * final class CowEditor {
 *
 *   var cow : Cow? = nil               // <wo:textfield value="$cow.name" />
 *
 *   @WOAction
 *   func save() -> Any? {              // <wo:form action="$save">
 *     ...
 *   }
 *
 *   func showAction() -> Any? {        // /MyApp/wa/CowEditor/show
 *     ...
 *   }
 * }
 * ```
 *
 * The macro also supports subclasses of components, it has to be applied to
 * the subclass as well. In this case it only generates the lookup and KVC
 * methods for the members added by the subclass, which fall back to the
 * superclass. If the root class is not `final`, the macro generates
 * overridable stubs for the hooks of the protocol, like
 * ``WOComponent/awake()``, so that subclasses can override them.
 *
 * Only methods declared in the class body are considered, methods in
 * extensions are not visible to the macro. Actions exposed with
 * `expose(_:as:direct:)` keep working, they are consulted when the macro
 * doesn't know the name.
 */
@attached(member, conformances: WOComponent,
          names: named(log), named(variableDictionary), named(exposedActions),
                 named(_wcName), named(context), named(_session),
                 named(subcomponents), named(wocBindings),
                 named(parentComponent), named(isStateless), named(isAwake),
                 named(_resourceManager), named(_template),
                 named(renderObject), named(init),
                 named(lookupActionNamed), named(lookupDirectActionNamed),
                 named(value(forKey:)), named(takeValue(_:forKey:)),
                 named(initWithContext), named(name), named(awake),
                 named(sleep), named(reset), named(pageWithName),
                 named(defaultAction),
                 named(performActionNamed), named(shouldTakeValues),
                 named(takeValues), named(invokeAction), named(append),
                 named(walkTemplate),
                 named(synchronizesVariablesWithBindings),
                 named(validationFailed), named(canRenderObject),
                 named(appendToDescription))
@attached(extension, conformances: WOComponent)
public macro WOComponent() =
  #externalMacro(module: "SwiftObjectsMacros", type: "WOComponentMacro")

/**
 * Marks a method as an action, or changes the name of an action.
 *
 * The attribute is evaluated by the ``WODirectAction()`` and
 * ``WOComponent()`` macros, it generates no code on its own. The method must
 * be an instance method without parameters, it can throw and return a value.
 * ```swift
 * @WOAction                    func hello()       // component action 'hello'
 * @WOAction("bye")             func goodbye()     // component action 'bye'
 * @WOAction(direct: true)      func show()        // direct action 'show'
 * @WOAction(direct: false)     func editAction()  // component action 'edit'
 * ```
 *
 * In a ``WOComponent()`` class a method marked with the attribute is a
 * component action, which can only be bound in templates, the client cannot
 * invoke it by name. Pass `direct: true` to make it callable using a direct
 * action URL, like `/MyApp/wa/Main/show`. Methods with the `Action` suffix
 * are direct actions by default, pass `direct: false` to turn one into a
 * component action. All actions of a ``WODirectAction()`` class are direct
 * actions.
 *
 * - Parameters:
 *   - name:   the name of the action, defaults to the method name with a
 *             trailing `Action` removed
 *   - direct: whether a component action can be invoked using a URL,
 *             defaults to whether the method has the `Action` suffix
 */
@attached(peer)
public macro WOAction(_ name: String? = nil, direct: Bool? = nil) =
  #externalMacro(module: "SwiftObjectsMacros", type: "WOActionMacro")
