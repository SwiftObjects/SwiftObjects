//
//  WOTemplateBuilder.swift
//  SwiftObjects
//
//  Created by Helge Hess on 19.05.18.
//

import Foundation

/**
 * Protocol for objects which take a template file and build a
 * WOElement hierarchy from that (plus component instantiation info).
 *
 * The prominent implementation is `WOWrapperTemplateBuilder` which
 * handles various template setups (eg wrappers or straight .html Go
 * templates).
 */
public protocol WOTemplateBuilder {
  
  /**
   * Returns a WOTemplate dynamic element representing the template as
   * specified by the _templateDate and _bindData URL (.html file and .wod
   * file).
   */
  func buildTemplate(for url: URL, bindingsURL: URL?,
                     using resourceManager: WOResourceManager) throws
       -> WOTemplate
  
}
