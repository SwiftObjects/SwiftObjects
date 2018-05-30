//
//  WORepetition.swift
//  SwiftObjects
//
//  Created by Helge Hess on 15.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import Foundation

/**
 * This iterate over a subsection multiple times based on the given List. During
 * that the item/index/etc bindings are updated with the current value from the
 * list. This way the containing elements can refer to the current item.
 *
 * Sample:
 *
 *     Countries: WORepetition {
 *         list = countries;
 *         item = country;
 *     }
 *
 * Renders:
 *   This element does not render anything (well, a separator when available).
 *
 * WOListWalker Bindings:
 * ```
 *   list       [in]  - WOListWalkable
 *   count      [in]  - int
 *   item       [out] - object
 *   index      [out] - int
 *   index1     [out] - int (like index, but starts at 1, not 0)
 *   startIndex [in]  - int
 *   identifier [in]  - string (TODO: currently unescaped)
 *   sublist    [in]  - WOListWalkable
 *   isEven     [out] - boolean
 *   isFirst    [out] - boolean
 *   isLast     [out] - boolean
 *   filter     [in]  - EOQualifier/String
 *   sort       [in]  - EOSortOrdering/EOSortOrdering[]/Comparator/String/bool
 *   elementName[in]  - contents in the specified element (eg: 'div')
 * ```
 * Bindings:
 * ```
 *   separator  [in]  - string
 *   elementName[in]  - string (name of a wrapper element)
 * ```
 * Extra Bindings are used in combination with 'elementName'.
 */
open class WORepetition : WOHTMLDynamicElement {
  // TBD: document 'list' binding behaviour<br>
  // TBD: document 'sublist' for processing trees
  // TBD: add 'isEven'/'isOdd'/'isFirst'/'isLast' bindings
  // TBD: if 'count' is null, but the list is not empty, push a count?

  let separator : WOAssociation?
  let template  : WOElement?
  let walker    : WOListWalker
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    separator = bindings.removeValue(forKey: "separator")

    walker = WOListWalkerFactory.newListWalker(bindings: &bindings)

    /* check whether we should wrap the repetitive content in a container */
    if bindings["elementName"] != nil {
      let c = WOGenericContainer(name: name + "_wrap", bindings: &bindings,
                                 template: template)
      c.setExtraAttributes(&bindings)
      bindings.removeAll()
      
      self.template = c
    }
    else {
      self.template = template
    }

    super.init(name: name, bindings: &bindings, template: template)
  }

  
  override open func takeValues(from request: WORequest,
                                in context: WOContext) throws
  {
    guard let template = template else { return }
    
    try walker.walkList(in: context) { (_, _, context) in
      try template.takeValues(from: request, in: context)
    }
  }
  
  override open func invokeAction(for request: WORequest,
                                  in context: WOContext) throws -> Any?
  {
    guard let template = template else { return nil }
    return try walker.invokeAction(for: request, on: template, in: context)
  }
  
  override open func append(to response: WOResponse,
                            in context: WOContext) throws
  {
    // Note: we still walk if there is no template
    let template = self.template
    let op : WOListWalker.WOListWalkerOperation
    
    if separator == nil || context.isRenderingDisabled {
      op = { _, _, context in
        try template?.append(to: response, in: context)
      }
    }
    else {
      let s = separator?.stringValue(in: context.cursor)
      op = { idx, _, context in
        if idx > 0, let s = s { try response.appendContentString(s) }
        try template?.append(to: response, in: context)
      }
    }
    
    try walker.walkList(in: context, using: op)
  }

  override open func walkTemplate(using walker : WOElementWalker,
                                  in   context : WOContext) throws
  {
    // FIXME
    try template?.walkTemplate(using: walker, in: context)
  }
  
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    WODynamicElement.appendBindingsToDescription(&ms,
      "separator", separator
    )
  }
}
