//
//  WOWrapperTemplateBuilder.swift
//  SwiftObjects
//
//  Created by Helge Hess on 19.05.18.
//

import Foundation

/**
 * This class implements a parser for so called 'wrapper templates', which
 * in turn are WebObjects style templates composed of an HTML template plus
 * a .wod file.
 *
 * ### Supported binding prefixes
 * ```
 *   const   - WOValueAssociation
 *   go(/jo) - GoPathAssociation
 *   label   - WOLabelAssociation
 *   ognl    - WOOgnlAssociation
 *   plist   - parse value as plist, then create a WOValueAssociation
 *   q       - WOQualifierAssociation (evaluate the given qualifier)
 *   regex   - WORegExAssociation
 *   rsrc    - WOResourceURLAssociation (lookup URL for a given resource name)
 *   var     - WOKeyPathAssociation
 *   varpat  - WOKeyPathPatternAssociation
 * ```
 *
 * ### Shortcuts
 * ```
 *   <wo:a>         - WOHyperlink
 *   <wo:for>       - WORepetition
 *   <wo:get>       - WOString
 *   <wo:if>        - WOConditional
 *   <wo:put>       - WOCopyValue
 *   <wo:submit>    - WOSubmitButton
 *   <wo:table-for> - WOTableRepetition
 * ```
 * .. and more. See WOShortNameAliases.plist file.
 *
 * ### Element Wrapper Attributes
 * ```
 *   <wo:tag ... if="condition">    - WOConditional
 *   <wo:tag ... ifnot="condition"> - WOConditional
 *   <wo:tag ... foreach="list">    - WORepetition
 * ```
 *
 * ### WOHTMLParser vs WOWrapperTemplateBuilder
 *
 * The WOHTMLParser just parses the HTML and asks the WOWrapperTemplateBuilder
 * to build the actual WOElements.
 *
 * THREAD: this class is not threadsafe and uses ivars for temporary storage.
 *
 * TODO: WOWrapperTemplateBuilder is not a good name for this class because it
 *       has nothing to do with wrappers. The actual resolution of the wrapper
 *       is done in the WOResourceManager / WOComponentDefinition.
 *       This class receives the already-looked-up URLs for the .wod and .html
 *       templates.
 *       Possibly we could also move this class into the WOTemplateBuilder?
 */
open class WOWrapperTemplateBuilder : WOTemplateBuilder,
                                      WODParserHandler, WOTemplateParserHandler
{
  
  // A map which maps short tag names like `<wo:for>` to their full name,
  // like `WORepetition`. Also: HTML tags to `WOGenericElement`/`Container`.
  let elementNameAliasMap = WOTagAliases
  
  var wodEntries      : [ String : WODParser.Entry ]? = nil
  var resourceManager : WOResourceManager?            = nil
  var iTemplate       : WOTemplate?

  open func buildTemplate(for url: URL, bindingsURL: URL?,
                          using resourceManager: WOResourceManager) throws
            -> WOTemplate
  {
    defer { self.resourceManager = nil; wodEntries = nil; iTemplate = nil }
    self.resourceManager = resourceManager
    
    if let url = bindingsURL {
      let data   = try Foundation.Data(contentsOf: url)
      wodEntries = try WODParser.parse(data, handler: self)
    }
    
    let template = WOTemplate(url: url, log: resourceManager.log)
    iTemplate = template // used to register child components
    
    let parser = instantiateTemplateParser(for: url)
    parser.handler = self
    
    let elements = try parser.parseHTMLData(url)
    
    template.rootElement = {
      if elements.isEmpty { return WOStaticHTMLElement("") }
      if elements.count == 1 { return elements[0] }
      return WOCompoundElement(children: elements)
    }()

    return template
  }
  
  func instantiateTemplateParser(for url: URL) -> WOTemplateParser {
    return WOHTMLParser()
  }
  
  
  // MARK: - HTML Parser Callback
  
  /**
   * This method builds a `Dictionary<String, WOAssociation>`
   * from a `Dictionary<String, String>`.
   *
   * It scans the key for a colon (`:`). If it does not find one,
   * it creates a value-association, if not, it calls the
   *   `WOAssociation.associationForPrefix()`
   * to determine an appropriate WOAssociation for the prefix.
   *
   * Example:
   *
   *     {
   *         var:list = "persons";
   *         var:item = "person";
   *         count = 5;
   *     }
   *
   * is mapped to:
   *
   *     {
   *         list  = [WOKeyPathAssociation keypath="persons"];
   *         item  = [WOKeyPathAssociation keypath="person"];
   *         count = [WOValueAssociation value=5];
   *     }
   *
   * We also support Project Wonder style value prefixes (~ and $). Those are
   * only processed if the attribute has NO prefix. Eg if you want to have a
   * regular, constant value, you can use the `const:` prefix.
   *
   * @param _attrs - a `Dictionary<String, String>` as parsed from HTML
   * @return a `Dictionary<String, WOAssociation>`
   */
  func buildBindings(for attributes: [ String : String ]) -> Bindings {
    var bindings = Bindings()
    bindings.reserveCapacity(attributes.count)
    
    for ( k, value ) in attributes {
      if let pm = k.index(of: ":") {
        let prefix = String(k[k.startIndex..<pm])
        let newKey = String(k[k.index(after: pm)..<k.endIndex])
        
        bindings[newKey] = WOAssociationFactory
                       .associationForPrefix(prefix, name: newKey, value: value)
      }
      else {
        /* No prefix like 'var:', we still want to support Wonder value
         * prefixes, eg '$' for KVC and '~' for OGNL.
         *
         * This implies that we need to escape the String value, we'll use
         * backslashes.
         */
        // TODO: support escaping, e.g.: `\$hello` to get a plain `$hello`
        // TODO: OGNL
        
        /* well, we do not convert '$(', because this is usually some
         * prototype const attribute, eg:
         *    before="$('progress').show()"
         * kinda hackish, but we wanted this AND Wonder style bindings ...
         */
        if value.hasPrefix("$") && !value.hasPrefix("$(") {
          let idx  = value.index(after: value.startIndex)
          let path = String(value[idx..<value.endIndex])
          bindings[k] = WOAssociationFactory.associationWithKeyPath(path)
        }
        else {
          bindings[k] = WOAssociationFactory.associationWithValue(value)
        }
      }
    }
    
    return bindings
  }
  
  /**
   * This method constructs a WODynamicElement for the given name. It will first
   * check for an entry with the name in the wod mapping table and otherwise
   * attempt to lookup the name as a class. If that also fails some fallbacks
   * kick in, that is element name aliases (<wo:if>) and automatic generic
   * elements (<wo:li>).
   *
   * If the name represents a component, a WOChildComponentReference object
   * will get constructed (not the component itself, components are allocated
   * on demand).
   */
  open func parser(_ parser: WOTemplateParser, dynamicElementFor name: String,
                   attributes: [ String : String ], children: [ WOElement ])
            -> WOElement?
  {
    // TODO: split up
    guard !name.isEmpty else {
      return WOStaticHTMLElement("[ERROR: unnamed dynamic element]")
    }
    
    var cls      : WODynamicElement.Type?
    var bindings : Bindings
    let cname    : String?

    func lookupDynamicElementClass(_ name: String) -> WODynamicElement.Type? {
      if let rm = resourceManager {
        return rm.lookupDynamicElementClass(name)
      }
      return WOElementNames[name]
    }

    if let entry = wodEntries?[name] {
      // if nil, most likely a WOComponent
      cls = lookupDynamicElementClass(entry.componentClassName)
      cname = cls != nil ? nil : entry.componentClassName
      
      if entry.bindings.isEmpty {
        bindings = buildBindings(for: attributes)
      }
      else {
        let tagAttrs = buildBindings(for: attributes)
        bindings = entry.bindings.merging(tagAttrs, uniquingKeysWith: { $1 })
      }
    }
    else {
      /*
       * Derive element from tag name, eg:
       *
       *   <wo:WOString var:value="abc" const:escapeHTML="1"/>
       *
       * This will attempt to find the class 'WOString'. If it can't find the
       * class, it checks for aliases and HTML tags (generic elements).
       */
      bindings = buildBindings(for: attributes)
      cls      = lookupDynamicElementClass(name)
      cname    = nil
      
      var addElementName = false
      if cls == nil {
        /* Could not resolve tagname as a WODynamicElement class, check for
         * aliases and dynamic HTML tags, like
         *
         *     <wo:li var:style="current" var:+style="isCurrent" />
         *
         * Note: we only check for dynamic element classes! The _name could
         *       still be the name of a WOComponent class!
         */
        if name == "a" {
          if bindings["action"]   != nil || bindings["actionClass"] != nil ||
             bindings["@action"]  != nil || bindings["pageName"]    != nil ||
             bindings["disabled"] != nil
          {
            cls = WOHyperlink.self
          }
          else {
            cls = WOGenericContainer.self
            addElementName = true
          }
        }
        else if let nname = elementNameAliasMap[name] {
          cls = lookupDynamicElementClass(nname)
          if let cls = cls {
            addElementName = cls is WOGenericElement.Type
          }
          else {
            resourceManager?.log.error("could not resolve name alias class",
                                       name, nname)
            return WOStaticHTMLElement("[Missing element: \(name) => \(nname)]")
          }
        }
        // else: probably a WOComponent,.
      }
      
      if addElementName {
        bindings["elementName"] =
          WOAssociationFactory.associationWithValue(name)
      }
    }
    
    bindings.removeValue(forKey: "NAME")
    
    let content : WOElement? = {
      if children.isEmpty    { return nil }
      if children.count == 1 { return children.first }
      return WOCompoundElement(children: children)
    }()
    
    let element : WOElement
    
    if let cls = cls {
      let e = cls.init(name: name, bindings: &bindings, template: content)
      
      element = hackNewElement(e, with: &bindings)
      
      if !bindings.isEmpty, let de = element as? WODynamicElement {
        de.setExtraAttributes(&bindings)
      }
    }
    else { // a component
      let lcname = iTemplate?.addSubcomponent(with: cname ?? name,
                                              bindings: bindings)
      element = WOChildComponentReference(name: lcname ?? name,
                                          template: content)
    }
    
    return element
  }
  
  /**
   * Add `WOConditional` and `WORepetition` support to all elements, eg:
   *
   *     <wo:get var:value="label" if="label.isNotEmpty" />
   *
   * @param _element - the element to hack
   * @param _assocs  - the associations
   * @return a hacked element (or the original, if no hack was necessary)
   */
  func hackNewElement(_ original: WODynamicElement,
                      with bindings: inout Bindings)
       -> WOElement
  {
    var element : WOElement = original
    
    if let a = bindings.removeValue(forKey: "if") {
      var b : Bindings = [ "condition" : a ]
      element = WOConditional(name: "if-attr", bindings: &b, template: element)
    }
    
    if let a = bindings.removeValue(forKey: "ifnot") {
      var b : Bindings = [
        "condition" : a,
        "negate"    : WOAssociationFactory.associationWithValue(true)
      ]
      element = WOConditional(name: "ifnot-attr", bindings: &b,
                              template: element)
    }
    
    if let a = bindings.removeValue(forKey: "foreach") {
      var b : Bindings = [
        "list" : a,
        "item" : WOAssociationFactory.associationWithKeyPath("item")!
      ]
      element = WOConditional(name: "foreach-attr", bindings: &b,
                              template: element)
    }
    
    if original !== element, !bindings.isEmpty {
      original.setExtraAttributes(&bindings)
      assert(bindings.isEmpty)
    }

    return element
  }

}
