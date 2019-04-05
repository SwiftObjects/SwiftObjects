//
//  WOHTMLDynamicElement.swift
//  SwiftObjects
//
//  Created by Helge Hess on 14.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

/**
 * Superclass for WODynamicElement's which render actual HTML tags. For example
 * WOTextField is a WOHTMLDynamicElement, but WOConditional is not (its just
 * flow control which renders nothing).
 *
 * Currently this has no additional behaviour, it just annotates the rendering
 * contract.
 */
open class WOHTMLDynamicElement : WODynamicElement {
}
