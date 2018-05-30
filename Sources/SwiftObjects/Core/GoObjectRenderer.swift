//
//  GoObjectRenderer.swift
//  SwiftObjects
//
//  Created by Helge Hess on 21.05.18.
//

/**
 * After a Go method associated with a request got run and returned a result,
 * Go will trigger a renderer to turn the result into a HTTP response.
 *
 * For regular WO like applications the result is usually a `WOComponent` which
 * itself does the actual rendering (the `GoDefaultRenderer` calls the
 * `append(to:in:)` method of WOComponent).
 *
 * Note that the render directly renders into the `WOResponse` which is
 * contained in the `WOContext`.
 *
 * Renderers are triggered by the `WOApplication` object
 * (renderObject(_:in:) method).
 *
 * @see GoDefaultRenderer
 * @see WOApplication
 * @see GoObjectRendererFactory
 */
public protocol GoObjectRenderer {
  
  /**
   * Render the given _object into the _response of the _ctx.
   */
  func renderObject(_ object: Any?, in context: WOContext) throws
  
  /**
   * Checks whether the renderer can render the given object in the given
   * context. Eg a PDF renderer could return false if the `WORequest` of the
   * _ctx does not contain an 'accept' handler which misses `application/pdf`.
   *
   * If a renderer returns 'false', Go will continue looking for other
   * renderers or fallback to the GoDefaultRenderer.
   *
   * @param _object - the object to be rendered
   * @param _ctx    - the context to render the object in
   * @return true if the renderer can render the object, false otherwise
   */
  func canRenderObject(_ object: Any?, in context: WOContext) -> Bool
  
}

/**
 * Instances returned by the factory should be GoObjectRenderer objects.
 *
 * Unlike `GoObjectRenderer` objects `GoObjectRendererFactory` objects are
 * usually part of the object traversal path. Eg they could be folder objects
 * which can contain special "master templates" (the actual root renderers).
 *
 * If the `WOApplication` cannot find a factory in the traversal path, it will
 * first resort to the product registry and then return the `GoDefaultRenderer`
 * (which is just fine for plenty of situations).
 *
 * @see GoObjectRenderer
 * @see GoDefaultRenderer
 * @see WOApplication
 */
public protocol GoObjectRendererFactory {
  
  /**
   * Returns a renderer which should be used to render the given _result object
   * in the given context.
   *
   * @param _result - the object which shall be rendered
   * @param _ctx    - the context in which the object lookup happened
   * @return a renderer or null if the factory could not return one
   */
  func rendererForObject(_ object: Any?, in context: WOContext)
       -> GoObjectRenderer?
  
}

open class GoDefaultRenderer : GoObjectRenderer {
  
  enum RenderError : WOHttpAwareError {
    case cannotRenderObject(Any?)
    case responseResultIsUnsuppored
    case notFound
    
    var httpStatus: Int {
      switch self {
        case .notFound: return 404
        default:        return 500
      }
    }
  }
  
  static let shared = GoDefaultRenderer()

  open func canRenderObject(_ object: Any?, in context: WOContext) -> Bool {
    return object is WOComponent     || object is WOResponse  ||
           object is WOActionResults || object is WOElement   ||
           object is String          || object is Swift.Error ||
           object is WOApplication
  }

  open func renderObject(_ object: Any?, in context: WOContext) throws {
    // TODO: AnyCodable for JSON? ;-)
    
    switch object {
      case let object as WOComponent: try renderComponent(object, in: context)
      case let object as WOResponse:  try renderResponse (object, in: context)
      
      case let object as WOActionResults:
        try renderActionResults(object, in: context)
      
      case let object as Swift.Error: try renderError  (object, in: context)
      case let object as WOElement:   try renderElement(object, in: context)
      case let object as String:      try renderString (object, in: context)
      
      case let object as WOApplication:
        /* This is if someone enters the root URL, per default we either redirect
         * to the DirectAction or to the Main page.
         */
        guard let r = object.redirectToApplicationEntry(in: context) else {
          throw RenderError.notFound
        }
        try renderResponse(r, in: context)
      
      default:
        throw RenderError.cannotRenderObject(object)
    }
  }

  open func renderResponse(_ object: WOResponse, in context: WOContext) throws {
    guard object !== context.response else { return } // already active
    // TODO: copy status, headers, content
    throw RenderError.responseResultIsUnsuppored
  }

  open func renderElement(_ object: WOElement, in context: WOContext) throws {
    try object.append(to: context.response, in: context)
  }

  open func renderActionResults(_ object: WOActionResults,
                                in context: WOContext) throws
  {
    let r = try object.generateResponse()
    try renderResponse(r, in: context)
  }

  open func renderComponent(_ page: WOComponent, in context: WOContext) throws {
    context.page = page
    page.ensureAwake(in: context)
    
    context.enterComponent(page)
    defer { context.leaveComponent(page) }
    
    // TBD: shouldn't we call WOApplication appendToResponse?!
    try page.append(to: context.response, in: context)
  }
  
  open func renderString(_ object: String, in context: WOContext) throws {
    let r = context.response
    r.status = 200
    r.setHeader("text/html", for: "Content-Type")
    try r.appendContentHTMLString(object)
  }
  
  open func renderError(_ error: Swift.Error, in context: WOContext) throws {
    let status = (error as? WOHttpAwareError)?.httpStatus ?? 500
    
    let r = context.response
    r.status = status
    
    guard !(error is RenderError) else { // avoid loops
      return
    }
    
    r.setHeader("text/html", for: "Content-Type")
    try r.appendContentHTMLString("Error: \(error)")
    try r.appendContentString("<br />")
  }
}

public protocol WOHttpAwareError : Swift.Error {
  var httpStatus : Int { get }
}
