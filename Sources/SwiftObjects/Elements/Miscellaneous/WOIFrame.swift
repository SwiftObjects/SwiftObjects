//
//  WOIFrame.swift
//  SwiftObjects
//
//  Created by Helge Hess on 02.06.18.
//

/**
 * Can be used to generate a `<iframe>` tag with a dynamic content URL.
 *
 * Sample:
 * ```
 *   Frame: WOIFrame {
 *     actionClass      = "LeftMenu";
 *     directActionName = "default";
 *   }</pre>
 * ```
 *
 * Renders:<pre>
 * ```
 *   <iframe src="/App/x/LeftMenu/default">
 *     [sub-template]
 *   </iframe>
 * ```
 *
 * Bindings:
 * ```
 *   name             [in] - string
 *   href             [in] - string
 *   directActionName [in] - string
 *   actionClass      [in] - string
 *   pageName         [in] - string
 *   action           [in] - action
 * ```
 */
open class WOIFrame : WOFrame {
  
  override open var frameTag: String { return "iframe" }
  
}
