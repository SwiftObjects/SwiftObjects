//
//  WOListWalker.swift
//  SwiftObjects
//
//  Created by Helge Hess on 14.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

/**
 * This is a helper object used by WORepetition to walk over a list.
 *
 * A special feature is that the 'list' binding can contain DOM nodes, NodeList
 * and EODataSource's (fetchObjects will get called).
 *
 * Bindings:
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
 * ```
 */
public protocol WOListWalker {
  
  typealias Bindings              = [ String : WOAssociation ]
  typealias WOListWalkerOperation = ( Int, Any?, WOContext ) throws -> Void
  
  func walkList(in    context   : WOContext,
                using operation : WOListWalkerOperation) throws

  
  func invokeAction(for request  : WORequest,
                    on  template : WOElement,
                    in  context  : WOContext) throws -> Any?
    // this is a little specific, we should have a walk w/ a return value
}

// Cannot do this, at least in 4.0:
// public extension WOListWalker {
internal func listForValue(_ value: Any?) -> WOListWalkable? {
  // In Go we 'instanceof' this. Here we just use a protocol anyone can
  // theoretically adopt.
  return value as? WOListWalkable
}

public protocol WOListWalkable {
  
  typealias AnyCollectionIteratorInfo = ( count: Int, iterator: AnyIterator<Any> )
  
  func listIterate() -> AnyCollectionIteratorInfo
  
}

// Yes, yes, I know. All this is un-Swifty non-sense ;-)

func WOMakeListIterator<T: Collection>(_ list: T)
     -> WOListWalkable.AnyCollectionIteratorInfo
{
  var typedIterator  = list.makeIterator()
  let erasedIterator = AnyIterator<Any> {
    guard let v = typedIterator.next() else { return nil }
    return v as Any
  }
  #if swift(>=4.1)
    return ( count: list.count, iterator: erasedIterator )
  #else
    return ( count: list.count as! Int, iterator: erasedIterator )
  #endif
}

// TODO: what else would we want here?
// - NSXMLElement
// - EODataSource
// - Dictionary? (pairs?)

extension ContiguousArray : WOListWalkable {
  public func listIterate() -> AnyCollectionIteratorInfo {
    return WOMakeListIterator(self)
  }
}
extension Array : WOListWalkable {
  public func listIterate() -> AnyCollectionIteratorInfo {
    return WOMakeListIterator(self)
  }
}
extension Set : WOListWalkable {
  public func listIterate() -> AnyCollectionIteratorInfo {
    return WOMakeListIterator(self)
  }
}


// MARK: - Factory

public enum WOListWalkerFactory {
  
  /**
   * Creates a new WOListWalker instance for the given associations.
   * WOListWalker itself is an abstract class, this method returns the
   * appropriate (optimized) subclass.
   */
  public static func newListWalker(bindings: inout WOListWalker.Bindings)
                     -> WOListWalker
  {
    guard !bindings.isEmpty else {
      return WOSimpleListWalker(bindings: &bindings)
    }
    
    let list = bindings["list"]
    let item = bindings["item"]
    
    /* Here we hack constant associations. If the user forgets a 'var:' in
     * front of his variable bindings, we'll autoconvert it to keypathes.
     * This is hackish but seems reasonable given that constant list/item
     * bindings make no sense?
     *
     * Could also check isConstant(), but WOValueAssociation is closer to
     * our intention (missing 'var:' in the .wo template).
     */
    if let a = list, a.isValueConstant, let s = a.value(in: nil) as? String {
      // TODO: support Plists/json strings ( list="(a,b,c)" )
      bindings["list"] = WOAssociationFactory.associationWithKeyPath(s)
    }
    if let a = item, a.isValueConstant, let s = a.value(in: nil) as? String {
      bindings["item"] = WOAssociationFactory.associationWithKeyPath(s)
    }
    
    
    if bindings.count == 1 && list != nil {
      return WOSimpleListWalker(bindings: &bindings)
    }
    if bindings.count == 2 && list != nil && item != nil {
      return WOSimpleListWalker(bindings: &bindings)
    }
    
    return WOComplexListWalker(bindings: &bindings)
  }
  
}
