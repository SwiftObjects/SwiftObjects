//
//  WOComponentContent.swift
//  SwiftObjects
//
//  Created by Helge Hess on 28.05.18.
//

/**
 * This element renders/processes a section of the parent component inside the
 * subcomponent. The element is useful for pagewide frames and such. The child
 * would render the frame HTML and the actual content can stay in the page.
 *
 * Parent Sample (HTML):
 *
 *     <wo:Child>renders this text</wo:Child>
 *
 * Child Sample (HTML):
 *
 *     <b>Content: <#Content/></b>
 *
 * Child Sample (WOD):
 *
 *     Content: WOComponentContent {}
 *
 * Renders:
 *
 *     <b>Content: renders this text</b>
 *
 *
 * Copy bindings:
 *
 *     <div id="leftmenu">
 *         <#WOComponentContent section="menu" />
 *     </div>
 *     <div id="content">
 *         <#WOComponentContent section="content" />
 *     </div>
 *
 * This will set the 'section' key in the parent component to 'a' prior entering
 * the template. You can then check in the parent template:
 *
 *     <wo:if var:condition="section" value="menu">a b c</wo:if>
 *
 * Fragments
 *
 *     <wo:WOComponentContent fragmentID="menu" />
 *     <wo:WOComponentContent fragmentID="content" />
 *
 * And in the parent template:<pre>
 *
 *     <wo:WOFragment name="menu"> ... </wo:WOFragment>
 *
 * But be careful, this can interact with AJAX fragment processing.
 *
 * Bindings:
 * ```
 *   - fragmentID [in] - string   disable rendering and set fragment-id
 *   [extra]      [in] - object   copied into the parent component
 * ```
 */
open class WOComponentContent : WODynamicElement {
  
  let fragmentID : WOAssociation?
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    fragmentID = bindings.removeValue(forKey: "fragmentID")
    super.init(name: name, bindings: &bindings, template: template)
  }

  override open func takeValues(from request: WORequest,
                                in context: WOContext) throws
  {
    guard let content   = context.componentContent else { return }
    guard let component = context.component        else { return }
    
    context.leaveComponent(component)
    defer { context.enterComponent(component) }
    
    try content.takeValues(from: request, in: context)
  }
  
  override open func invokeAction(for request : WORequest,
                                  in  context : WOContext) throws -> Any?
  {
    guard let content   = context.componentContent else { return nil }
    guard let component = context.component        else { return nil }
    
    context.leaveComponent(component)
    defer { context.enterComponent(component) }
    
    return try content.invokeAction(for: request, in: context)
  }
  
  override open func append(to response: WOResponse,
                            in context: WOContext) throws
  {
    guard let content   = context.componentContent else { return }
    guard let component = context.component        else { return }
    
    let cursor = context.cursor
    let wofid  = fragmentID?.stringValue(in: cursor)
    
    /* copy other values (from WOComponentContent bindings) */
    var extraValues = [ String : Any? ]()
    if let extra = extra {
      for ( key, assoc ) in extra {
        extraValues[key] = assoc.value(in: cursor)
      }
    }
    
    context.leaveComponent(component)
    defer { context.enterComponent(component) }
    
    /* apply copied values */
    if !extraValues.isEmpty {
      if let setCursor = context.cursor as? MutableKeyValueCodingType {
        try setCursor.takeValuesForKeys(extraValues) // Go can also do pathes
      }
    }
    extraValues.removeAll()
    
    if let wofid = wofid {
      let wasRenderingDisabled = context.isRenderingDisabled
      let oldFragmentID        = context.fragmentID
      
      if         !wasRenderingDisabled { context.disableRendering() }
      defer { if !wasRenderingDisabled { context.enableRendering()  } }
      
      context.fragmentID = wofid
      defer { context.fragmentID = oldFragmentID }
      
      try content.append(to: response, in: context)
    }
    else {
      try content.append(to: response, in: context)
    }
  }

  override open func walkTemplate(using walker : WOElementWalker,
                                  in   context : WOContext) throws
  {
    guard let content   = context.componentContent else { return }
    guard let component = context.component        else { return }
    
    context.leaveComponent(component)
    defer { context.enterComponent(component) }
    
    try content.walkTemplate(using: walker, in: context)
  }
  
  
  // MARK: - Description
  
  override open func appendToDescription(_ ms: inout String) {
    super.appendToDescription(&ms)
    
    WODynamicElement.appendBindingsToDescription(&ms,
      "fragmentID", fragmentID
    )
  }
}
