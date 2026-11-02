//
//  SwiftTypeIndexTests.swift
//  SwiftObjectsTests
//

import XCTest
@testable import SwiftObjects

// MARK: - Probe Classes

class TypeIndexProbeBase {}
final class TypeIndexProbeClass : TypeIndexProbeBase {}
final class TypeIndexProbeGeneric<T> : TypeIndexProbeBase {}
private final class TypeIndexProbePrivate : TypeIndexProbeBase {}

enum TypeIndexProbeScope {
  final class TypeIndexProbeNested : TypeIndexProbeBase {}
}

class TypeIndexProbeOtherBase {}

enum TypeIndexProbeScopeA {
  final class TypeIndexProbeDup : TypeIndexProbeBase {}
}
enum TypeIndexProbeScopeB {
  final class TypeIndexProbeDup : TypeIndexProbeOtherBase {}
}

final class TypeIndexProbeComponent : WOComponent {}


// MARK: - Tests

final class SwiftTypeIndexTests: XCTestCase {
  
  private typealias Nested = TypeIndexProbeScope.TypeIndexProbeNested
  private typealias DupA   = TypeIndexProbeScopeA.TypeIndexProbeDup
  private typealias DupB   = TypeIndexProbeScopeB.TypeIndexProbeDup
  
  /// Class objects are not `AnyObject` on Linux, so `===` can't be used.
  private func assertSameClass(_ cls: AnyClass?, _ expected: AnyClass,
                               file: StaticString = #filePath,
                               line: UInt = #line)
  {
    XCTAssertEqual(cls.map { ObjectIdentifier($0) },
                   ObjectIdentifier(expected),
                   "expected \(expected), got \(cls.map { "\($0)" } ?? "nil")",
                   file: file, line: line)
  }
  
  func testFindsTopLevelClass() {
    let entries = SwiftTypeIndex.classes(named: "TypeIndexProbeClass")
    XCTAssertEqual(entries.count, 1)
    guard let entry = entries.first else { return }
    
    XCTAssertEqual(entry.name,          "TypeIndexProbeClass")
    XCTAssertEqual(entry.module,        "SwiftObjectsTests")
    XCTAssertEqual(entry.typePath,      [ "TypeIndexProbeClass" ])
    XCTAssertEqual(entry.qualifiedName, "SwiftObjectsTests.TypeIndexProbeClass")
    XCTAssertEqual(entry.mangledName,
                   "17SwiftObjectsTests19TypeIndexProbeClassC")
    assertSameClass(entry.resolve(), TypeIndexProbeClass.self)
    
    assertSameClass(SwiftTypeIndex.lookupClass(named: "TypeIndexProbeClass"),
                    TypeIndexProbeClass.self)
  }
  
  func testFindsNestedClass() {
    let entries = SwiftTypeIndex.classes(named: "TypeIndexProbeNested")
    XCTAssertEqual(entries.count, 1)
    guard let entry = entries.first else { return }
    
    XCTAssertEqual(entry.typePath,
                   [ "TypeIndexProbeScope", "TypeIndexProbeNested" ])
    XCTAssertEqual(entry.qualifiedName,
                   "SwiftObjectsTests.TypeIndexProbeScope.TypeIndexProbeNested")
    assertSameClass(entry.resolve(), Nested.self)
  }
  
  func testFindsClassesInOtherModules() {
    let entries = SwiftTypeIndex.classes(named: "WOComponent")
    XCTAssertTrue(entries.contains { $0.module == "SwiftObjects" })
    let component = ObjectIdentifier(WOComponent.self)
    XCTAssertTrue(entries.contains {
      $0.resolve().map { ObjectIdentifier($0) } == component
    })
  }
  
  func testSkipsUnreachableClasses() {
    XCTAssertTrue(SwiftTypeIndex.classes(named: "TypeIndexProbeGeneric")
                    .isEmpty)
    XCTAssertTrue(SwiftTypeIndex.classes(named: "TypeIndexProbePrivate")
                    .isEmpty)
    XCTAssertTrue(SwiftTypeIndex.classes(named: "TypeIndexProbeMissing")
                    .isEmpty)
  }
  
  func testAmbiguousNamesAreSortedAndNotResolvedByLookup() {
    let entries = SwiftTypeIndex.classes(named: "TypeIndexProbeDup")
    XCTAssertEqual(entries.count, 2)
    XCTAssertEqual(entries.map { $0.qualifiedName }, [
      "SwiftObjectsTests.TypeIndexProbeScopeA.TypeIndexProbeDup",
      "SwiftObjectsTests.TypeIndexProbeScopeB.TypeIndexProbeDup"
    ])
    XCTAssertNil(SwiftTypeIndex.lookupClass(named: "TypeIndexProbeDup"))
  }
  
  func testResetRebuildsIndex() {
    SwiftTypeIndex.reset()
    XCTAssertEqual(SwiftTypeIndex.classes(named: "TypeIndexProbeClass").count,
                   1)
  }
  
  
  // MARK: - WODevResourceManager Integration
  
  func testResourceManagerFindsClassesWithoutRegistration() {
    let rm = WODevResourceManager(sourceType: SwiftTypeIndexTests.self)
    XCTAssertEqual(rm.lookupModules, [ "SwiftObjectsTests", "SwiftObjects" ])
    
    assertSameClass(rm.lookupClass("TypeIndexProbeClass"),
                    TypeIndexProbeClass.self)
    assertSameClass(rm.lookupClass("TypeIndexProbeNested"), Nested.self)
    assertSameClass(rm.lookupClass("WOComponent"), WOComponent.self)
    assertSameClass(rm.lookupComponentClass("TypeIndexProbeComponent"),
                    TypeIndexProbeComponent.self)
    XCTAssertNil(rm.lookupClass("TypeIndexProbeMissing"))
  }
  
  func testResourceManagerFindsClassesOutsideLookupModules() {
    let rm = WODevResourceManager(sourceType: SwiftTypeIndexTests.self)
    rm.lookupModules = [ "NoSuchModule" ]
    
    assertSameClass(rm.lookupClass("TypeIndexProbeClass"),
                    TypeIndexProbeClass.self)
    assertSameClass(rm.lookupClass("WOComponent"), WOComponent.self)
  }
  
  func testResourceManagerPrefersRegisteredClasses() {
    let rm = WODevResourceManager(sourceType: SwiftTypeIndexTests.self)
    rm.register(DupA.self)
    assertSameClass(rm.lookupClass("TypeIndexProbeDup"), DupA.self)
  }
  
  func testResourceManagerDisambiguatesByType() {
    let rm = WODevResourceManager(sourceType: SwiftTypeIndexTests.self)
    
    assertSameClass(rm.lookupClass("TypeIndexProbeDup",
                                   type: TypeIndexProbeOtherBase.self),
                    DupB.self)
    
    // the cache is keyed by name, so a second lookup returns the same class
    assertSameClass(rm.lookupClass("TypeIndexProbeDup"), DupB.self)
  }
  
  func testResourceManagerDoesNotCacheTypeMismatches() {
    let rm = WODevResourceManager(sourceType: SwiftTypeIndexTests.self)
    
    XCTAssertNil(rm.lookupComponentClass("TypeIndexProbeClass"))
    assertSameClass(rm.lookupClass("TypeIndexProbeClass"),
                    TypeIndexProbeClass.self)
  }
}
