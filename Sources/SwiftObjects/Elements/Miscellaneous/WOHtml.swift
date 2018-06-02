//
//  WOHtml.swift
//  SwiftObjects
//
//  Created by Helge Hess on 02.06.18.
//

/**
 * Used to generate the `<html>` root element and to configure
 * and output a proper DOCTYPE declaration.
 *
 * Sample:
 * ```
 *   <#WOHtml>[template]</#WOHtml>
 * ```
 * Renders:
 * ```
 *   <html>
 *     [template]
 *   </html>
 * ```
 *
 * Constant doctypes:
 *
 * - strict
 * - strict-xhtml11
 * - strict-xhtml10
 * - strict-html
 * - trans
 * - trans-xhtml
 * - trans-html
 * - quirk
 * - html5
 *
 * Bindings:
 * ```
 *   doctype|type  [in] - string (empty string for no doctype, default: quirks)
 *   language|lang [in] - language
 *   namespace|ns  [in] - default XML namespace
 * ```
 */
public class WOHtml : WOHTMLDynamicElement {
  
  let doctype  : WOAssociation
  let lang     : WOAssociation?
  let ns       : WOAssociation?
  let template : WOElement?
  
  required
  public init(name: String, bindings: inout Bindings, template: WOElement?) {
    doctype = bindings.removeValue(forKey: "doctype")
           ?? bindings.removeValue(forKey: "type")
           ?? WOHtml.quirksTypeAssoc
    lang    = bindings.removeValue(forKey: "language")
           ?? bindings.removeValue(forKey: "lang")
    ns      = bindings.removeValue(forKey: "namespace")
           ?? bindings.removeValue(forKey: "ns")
           ?? bindings.removeValue(forKey: "xmlns")

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
  
  override open func walkTemplate(using walker : WOElementWalker,
                                  in   context : WOContext) throws
  {
    try template?.walkTemplate(using: walker, in: context)
  }

  /* response generation */
  
  override
  open func append(to response: WOResponse, in context: WOContext) throws {
    guard !context.isRenderingDisabled else {
      try template?.append(to: response, in: context)
      return
    }

    let cursor = context.cursor
    let log    = context.log
    
    // Note: IE6 will consider the doctype only if its on the first line, so
    //       we can't render an <?xml marker
 
    /* render doctype */
 
    var renderXmlLang = false
    var lDocType      = doctype.stringValue(in: cursor)
    var lXmlNS        : String? = nil

    if var llDocType = lDocType, !llDocType.isEmpty {
      // TBD: refactor this crap ;-)
 
      if llDocType.hasPrefix("http://") {
        /* select by URL */
        switch llDocType {
          case WOHtml.xhtml11DTD: lDocType = WOHtml.xhtml11Type
          case WOHtml.xhtml10DTD: lDocType = WOHtml.xhtml10Type
          case WOHtml.html401DTD: lDocType = WOHtml.html401Type
          case WOHtml.xhtml10TransitionalDTD:
            lDocType = WOHtml.xhtml10TransitionalType
          case WOHtml.html401TransitionalDTD:
            lDocType = WOHtml.html401TransitionalType
          default: log.warn("got unknown doctype-url:", lDocType)
        }
      }
      if let dt = lDocType { llDocType = dt }

      if (llDocType.hasPrefix("-//")) {
        /* select by type ID */
        switch llDocType {
          case WOHtml.xhtml11Type:
            try response.appendContentString("<!DOCTYPE html PUBLIC \"");
            try response.appendContentString(WOHtml.xhtml11Type);
            try response.appendContentString("\" \"");
            try response.appendContentString(WOHtml.xhtml11DTD);
            try response.appendContentString("\">\n");
            renderXmlLang = true;
            context.generateEmptyAttributes       = false
            context.generateXMLStyleEmptyElements = true
            context.closeAllElements              = true
            lXmlNS = WOHtml.xhtmlNS;

          case WOHtml.xhtml10Type:
            try response.appendContentString("<!DOCTYPE html PUBLIC \"");
            try response.appendContentString(WOHtml.xhtml10Type);
            try response.appendContentString("\" \"");
            try response.appendContentString(WOHtml.xhtml10DTD);
            try response.appendContentString("\">\n");
            renderXmlLang = true;
            context.generateEmptyAttributes       = false
            context.generateXMLStyleEmptyElements = true
            context.closeAllElements              = true
            lXmlNS = WOHtml.xhtmlNS;

          case WOHtml.html401Type:
            try response.appendContentString("<!DOCTYPE html PUBLIC \"");
            try response.appendContentString(WOHtml.html401Type);
            try response.appendContentString("\" \"");
            try response.appendContentString(WOHtml.html401DTD);
            try response.appendContentString("\">\n");
            context.generateEmptyAttributes       = true
            context.generateXMLStyleEmptyElements = false
            context.closeAllElements              = false

          case WOHtml.xhtml10TransitionalType:
            try response.appendContentString("<!DOCTYPE html PUBLIC \"");
            try response.appendContentString(WOHtml.xhtml10TransitionalType);
            try response.appendContentString("\" \"");
            try response.appendContentString(WOHtml.xhtml10TransitionalDTD);
            try response.appendContentString("\">\n");
            renderXmlLang = true;
            context.generateEmptyAttributes       = false
            context.generateXMLStyleEmptyElements = true
            context.closeAllElements              = true
            lXmlNS = WOHtml.xhtmlNS;

          case WOHtml.html401TransitionalType:
            try response.appendContentString("<!DOCTYPE html PUBLIC \"");
            try response.appendContentString(WOHtml.html401TransitionalType);
            try response.appendContentString("\" \"");
            try response.appendContentString(WOHtml.html401TransitionalDTD);
            try response.appendContentString("\">\n");
            context.generateEmptyAttributes       = true
            context.generateXMLStyleEmptyElements = false
            context.closeAllElements              = false
          
          default:
            // TBD: support custom doctypes
            log.warn("got unknown doctype-id:", lDocType)
        }
      }
      else {
        /* select by constant */
 
        if llDocType.hasPrefix("strict") {
          switch llDocType {
            case "strict":
              lDocType = "xhtml11"
              lXmlNS = WOHtml.xhtmlNS

            case "strict-xhtml11":
              lDocType = "xhtml11"
              lXmlNS = WOHtml.xhtmlNS

            case "strict-xhtml10":
              lDocType = "xhtml10"
              lXmlNS = WOHtml.xhtmlNS

            case "strict-xhtml":
              lDocType = "xhtml10"
              lXmlNS = WOHtml.xhtmlNS
            
            case "strict-html":
              lDocType = "html401"
            
            default: break
          }
        }
        else if llDocType.hasPrefix("trans") {
          switch llDocType {
            case "trans":
              lDocType = "html4"
            case "trans-xhtml":
              lDocType = "xhtml10-trans"
              lXmlNS = WOHtml.xhtmlNS
            case "trans-html":
              lDocType = "html4"
              default: break
          }
        }
        if let dt = lDocType { llDocType = dt }

        if llDocType.hasPrefix("quirk") {
          try response.appendContentString("<!DOCTYPE html PUBLIC \"");
          try response.appendContentString(WOHtml.html401TransitionalType);
          try response.appendContentString("\">\n");
          context.generateEmptyAttributes       = true
          context.generateXMLStyleEmptyElements = false
          context.closeAllElements              = false
        }
        else if llDocType.hasPrefix("xhtml") {
          context.generateEmptyAttributes       = false
          context.generateXMLStyleEmptyElements = true
          context.closeAllElements              = true
          renderXmlLang = true
          lXmlNS = WOHtml.xhtmlNS;
 
          switch llDocType {
            case "xhtml11":
              try response.appendContentString("<!DOCTYPE html PUBLIC \"");
              try response.appendContentString(WOHtml.xhtml11Type);
              try response.appendContentString("\" \"");
              try response.appendContentString(WOHtml.xhtml11DTD);
              try response.appendContentString("\">\n");

            case "xhtml10":
              try response.appendContentString("<!DOCTYPE html PUBLIC \"");
              try response.appendContentString(WOHtml.xhtml10Type);
              try response.appendContentString("\" \"");
              try response.appendContentString(WOHtml.xhtml10DTD);
              try response.appendContentString("\">\n");

            case "xhtml", "xhtml10-trans":
              try response.appendContentString("<!DOCTYPE html PUBLIC \"");
              try response.appendContentString(WOHtml.xhtml10TransitionalType);
              try response.appendContentString("\" \"");
              try response.appendContentString(WOHtml.xhtml10TransitionalDTD);
              try response.appendContentString("\">\n");
              renderXmlLang = true
              context.generateEmptyAttributes       = false
              context.generateXMLStyleEmptyElements = true
              context.closeAllElements              = true

            default:
              log.warn("got unknown XHTML doctype:", llDocType)
          }
        }
        else if llDocType.hasPrefix("html") {
          context.generateEmptyAttributes       = true
          context.generateXMLStyleEmptyElements = false
          context.closeAllElements              = false

          switch llDocType {
            case "html4", "html", "html-trans", "html4-trans":
              try response.appendContentString("<!DOCTYPE html PUBLIC \"");
              try response.appendContentString(WOHtml.html401TransitionalType);
              try response.appendContentString("\" \"");
              try response.appendContentString(WOHtml.html401TransitionalDTD);
              try response.appendContentString("\">\n");

            case "html401":
              try response.appendContentString("<!DOCTYPE html PUBLIC \"");
              try response.appendContentString(WOHtml.html401Type);
              try response.appendContentString("\" \"");
              try response.appendContentString(WOHtml.html401DTD);
              try response.appendContentString("\">\n");

            case "html5":
              try response.appendContentString("<!DOCTYPE html>\n");
 
            default: log.warn("got unknown HTML doctype:", lDocType)
          }
        }
        else {
          log.warn("got unknown doctype:", lDocType)
        }
      }
    }
 
    /* XML namespace */
 
    if let ns = ns {
      lXmlNS = ns.stringValue(in: cursor)
    }
 
    /* render HTML tag */
 
    try response.appendBeginTag("html")
    
    if let ns = lXmlNS, !ns.isEmpty {
      try response.appendAttribute("xmlns", lXmlNS)
    }
 
    if let l = lang?.stringValue(in: cursor), !l.isEmpty {
      try response.appendAttribute("lang", l)
      if renderXmlLang { try response.appendAttribute("xml:lang", l) }
    }
    
    try appendExtraAttributes(to: response, in: context)
    try response.appendBeginTagEnd()
    
    try template?.append(to: response, in: context)
    
    try response.appendEndTag("html")
  }


  // MARK: - Constants
  
  public static let quirksTypeAssoc =
                      WOAssociationFactory.associationWithValue("quirks")
  
  public static let xhtmlNS = "http://www.w3.org/1999/xhtml"
  
  public static let xhtml11Type = "-//W3C//DTD XHTML 1.1//EN"
  public static let xhtml10Type = "-//W3C//DTD XHTML 1.0 Strict//EN"
  public static let html401Type = "-//W3C//DTD HTML 4.01//EN"

  public static let xhtml10TransitionalType =
    "-//W3C//DTD XHTML 1.0 Transitional//EN"
  public static let html401TransitionalType =
    "-//W3C//DTD HTML 4.01 Transitional//EN"
  
  public static let xhtml11DTD =
    "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
  public static let xhtml10DTD =
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
  public static let html401DTD =
    "http://www.w3.org/TR/html4/strict.dtd"
  
  public static let xhtml10TransitionalDTD =
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
  public static let html401TransitionalDTD =
    "http://www.w3.org/TR/html4/loose.dtd"
}

