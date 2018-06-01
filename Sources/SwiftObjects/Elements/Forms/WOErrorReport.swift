//
//  WOErrorReport.swift
//  SwiftObjects
//
//  Created by Helge Hess on 14.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

/**
 * This object is used to capture errors found during form processing. For
 * example if the user entered a number in a date field. The WODateFormatter
 * would raise an exception, which can then be handled by a WOErrorReport for
 * the whole page.
 *
 * Error reports are managed as a stack on the WOContext.
 */
open class WOErrorReport {
  
  // TODO: trampoline!
  
  open var subReports = [ WOErrorReport ]()
  open var errors     = [ WOErrorItem   ]()

  open var hasErrors : Bool { return !errors.isEmpty }
  open var isEmpty   : Bool { return !hasErrors }
  
  open func errorsForElementID(_ id: String) -> [ WOErrorItem ] {
    return errors.filter { $0.elementID == id }
  }
  open func errorForElementID(_ id: String) -> WOErrorItem? {
    return errors.first(where: { $0.elementID == id })
  }

  /**
   * Returns the WOErrorItems which match the given name. Note that
   * there can be multiple items per name. If you just want the first, use
   * errorForName().
   * Eg the 'name' is the name used in markField().
   *
   * @param _name - the name of the item (eg 'lastname')
   * @return the WOErrorItems for the form element with the name, or null
   */
  open func errorsForName(_ name: String) -> [ WOErrorItem ] {
    return errors.filter { $0.name == name }
  }
  
  /**
   * Returns the first WOErrorItem which matches the given name. Note that
   * there can be multiple items per name, to retrieve all, you can use
   * errorsForName().
   * Eg the 'name' is the name used in markField().
   *
   * @param _name - the name of the item (eg 'lastname')
   * @return the first WOErrorItem for the form element with the name, or null
   */
  open func errorForName(_ name: String) -> WOErrorItem? {
    return errors.first(where: { $0.name == name })
  }
  
  
  // MARK: - Adding Errors
  
  open func addErrorItem(_ item: WOErrorItem) {
    errors.append(item)
  }
  
  open func addError(elementID : String? = nil,
                     name      : String? = nil,
                     error     : Error,
                     value     : Any?    = nil)
  {
    let item = WOErrorItem(elementID: elementID, name: name, error: error,
                           value: value)
    addErrorItem(item)
  }
  
  /**
   * Marks a field with the given name as invalid. This only generates a new
   * erroritem if no error is registered for the field yet.
   *
   * @param _name  - name of the field, eg 'startdate'
   * @param _value - buggy value of the field, eg 'murks'
   */
  open func markField(_ name: String, value: Any? = nil) {
    guard errorForName(name) == nil else { return }
    addError(name: name, error: MarkError(name: name), value: value)
  }
  
  public struct MarkError : Swift.Error { // a little funny ;-)
    let name : String
  }

  
  // MARK: - Description
  
  public func appendToDescription(_ ms: inout String) {
    if errors.isEmpty {
      ms += " no-errors"
    }
    
    ms += " errors=["
    ms += self.errors.map { $0.description }.joined(separator: ", ")
    ms += "]"
  }
  

  // MARK: - Error Item
  
  public struct WOErrorItem : SmartDescription {
    
    let elementID : String?
    let name      : String?
    let error     : Error
    let value     : Any?
    
    public init(elementID : String? = nil,
                name      : String? = nil,
                error     : Error,
                value     : Any?    = nil)
    {
      self.elementID = elementID
      self.name      = name
      self.error     = error
      self.value     = value
    }

    public func appendToDescription(_ ms: inout String) {
      if let v = elementID { ms += " eid=\(v)"   }
      if let v = name      { ms += " name=\(v)"  }
      if let v = value     { ms += " value=\(v)" }
      ms += " error=\(error)"
    }
  }
  
  
  // MARK: - Trampoline
  
  /**
   * Used to navigate to errors using KeyValueCoding.
   *
   * Example which adds the `errors` class to the div when the `amount` field
   * has any:
   *
   *     <div .errors="$errors.on.amount">
   *
   */
  open var on : WOErrorReportTrampoline {
    return WOErrorReportTrampoline(self)
  }
  
  public struct WOErrorReportTrampoline : KeyValueCodingType, SmartDescription {
    
    let report : WOErrorReport
    
    init(_ report : WOErrorReport) {
      self.report = report
    }
    
    public func value(forKey k: String) -> Any? {
      return report.errorForElementID(k) ?? report.errorForName(k)
    }

    public func appendToDescription(_ ms: inout String) {
      ms += " report=\(report)"
    }
  }
}
