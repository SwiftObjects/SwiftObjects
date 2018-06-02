//
//  WOBody.swift
//  SwiftObjects
//
//  Created by Helge Hess on 02.06.18.
//

/**
 * Can be used to generate a `<body>` tag with a dynamic background image.
 *
 * Sample:
 * ```
 *   Body: WOBody {
 *     src = "/images/mybackground.gif";
 *   }
 * ```
 *
 * Renders:
 * ```
 *   <body background="/images/mybackground.gif">
 *     [sub-template]
 *   </body>
 * ```
 *
 * Bindings:
 * ```
 *   filename  [in] - string
 *   framework [in] - string
 *   src       [in] - string
 *   value     [in] - byte array?
 * ```
 */
open class WOBody : WOHTMLDynamicElement {
  
  let link     : WOLinkGenerator?
  let template : WOElement?
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    link = WOLinkGenerator.resourceLinkGenerator(keyedOn: "src", for: &bindings)
    self.template = template
    super.init(name: name, bindings: &bindings, template: template)
  }
  
  override open func takeValues(from request: WORequest,
                                in context: WOContext) throws
  {
    try template?.takeValues(from: request, in: context)
  }
  
  override open func invokeAction(for request : WORequest,
                                  in  context : WOContext) throws -> Any?
  {
    return try template?.invokeAction(for: request, in: context)
  }

  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    guard !context.isRenderingDisabled else { return }
    
    try response.appendBeginTag("body")
    if let url = link?.fullHref(in: context) {
      try response.appendAttribute("background", url)
    }
    try appendExtraAttributes(to: response, in: context)
    try response.appendBeginTagEnd()
    
    try template?.append(to: response, in: context)
    
    try response.appendEndTag("body")
  }
  
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    if let link = link { ms += " src=\(link)" }
  }
}
