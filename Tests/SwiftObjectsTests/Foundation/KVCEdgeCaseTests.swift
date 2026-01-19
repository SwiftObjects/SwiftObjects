//
//  KVCEdgeCaseTests.swift
//  SwiftObjectsTests
//
//  Tests for edge cases in KVC that previously caused crashes.
//

import XCTest
@testable import SwiftObjects

/**
 * Tests for KVC edge cases that previously caused crashes.
 *
 * These tests ensure that:
 * - Double-boxed Any values (Any containing Any) are handled gracefully
 * - Existential types don't cause crashes
 * - Weak references are handled safely
 * - Null/nil values don't cause crashes
 */
class KVCEdgeCaseTests: XCTestCase {

  // MARK: - Test Helpers

  /// Simple class with optional properties (similar to Cow model)
  class TestModel {

    var name  : String?
    var image : String?
    var count : Int = 0

    init(name: String? = nil, image: String? = nil, count: Int = 0) {
      self.name  = name
      self.image = image
      self.count = count
    }
  }

  /// Class with weak reference (like WOComponent.context)
  class TestContainer {

    weak var weakRef : TestModel?
    var strongRef    : TestModel?

    init(weakRef: TestModel? = nil, strongRef: TestModel? = nil) {
      self.weakRef  = weakRef
      self.strongRef = strongRef
    }
  }

  /// Class that holds an Any value
  class AnyHolder {

    var anyValue : Any?

    init(anyValue: Any? = nil) {
      self.anyValue = anyValue
    }
  }


  // MARK: - Double-Boxing Tests

  func testDoubleBoxedAnyDoesNotCrash() {
    // Simulate double-boxing: Any containing Any containing a value
    let model = TestModel(name: "Test", image: "test.jpg")
    let inner : Any = model
    let outer : Any = inner

    // This should not crash - should return nil for double-boxed Any
    let result = KeyValueCoding.value(forKey: "name", inObject: outer)

    // The result might be nil (if double-boxing detected) or the actual value
    // Either is acceptable as long as it doesn't crash
    if let name = result as? String {
      XCTAssertEqual(name, "Test")
    }
    // If nil, that's also acceptable - main thing is no crash
  }

  func testKeyPathThroughAnyDoesNotCrash() {
    // Create a scenario similar to WOPopUpButton crash
    let model = TestModel(name: "Test", image: "photo.jpg")
    let holder = AnyHolder(anyValue: model)

    // Access through keypath: anyValue.image
    // This exercises the path where intermediate value is boxed in Any
    let result = KeyValueCoding.value(forKeyPath: "anyValue.image",
                                      inObject: holder)

    // Main assertion: this should not crash
    // The result might be the image value, nil, or some other safe result
    // depending on how the Any boxing is handled
    _ = result  // Just verify no crash
  }

  func testArrayOfAnyDoesNotCrash() {
    // Array containing Any values - common in popup scenarios
    let items : [Any] = [
      TestModel(name: "A", image: "a.jpg"),
      TestModel(name: "B", image: "b.jpg"),
      "plain string",
      42
    ]

    // Access property on array elements
    let names = KeyValueCoding.value(forKey: "name", inObject: items)

    // Should return array of results without crashing
    XCTAssertNotNil(names)
    if let namesArray = names as? [Any?] {
      XCTAssertEqual(namesArray.count, 4)
    }
  }


  // MARK: - Existential Type Tests

  func testExistentialTypeReturnsNil() {
    // Direct Any value should not crash
    let anyValue : Any = "test"

    // When the dynamic type IS Any (rare but possible), should return nil
    let result = KeyValueCoding.value(forKey: "count", inObject: anyValue)

    // String doesn't have a "count" property accessible via KVC
    // Should return nil without crashing
    XCTAssertNil(result)
  }

  func testProtocolExistentialDoesNotCrash() {
    // Protocol existential
    let items : [CustomStringConvertible] = ["hello", "world"]

    // Accessing description should work
    let descriptions = KeyValueCoding.value(forKey: "description", inObject: items)

    // Should not crash
    XCTAssertNotNil(descriptions)
  }


  // MARK: - Weak Reference Tests

  func testWeakReferenceReturnsNilNotCrash() {
    let container = TestContainer()
    // weakRef is nil

    // Accessing weak reference property should return nil, not crash
    let result = KeyValueCoding.value(forKey: "weakRef", inObject: container)

    XCTAssertNil(result)
  }

  func testWeakReferenceWithValueDoesNotCrash() {
    var model : TestModel? = TestModel(name: "Weak", image: "weak.jpg")
    let container = TestContainer(weakRef: model, strongRef: model)

    // Weak reference is set, should be accessible
    // Note: In our implementation, weak refs return nil via KVC for safety
    let weakResult = KeyValueCoding.value(forKey: "weakRef", inObject: container)
    _ = weakResult  // Either nil (skipped for safety) or the value

    // Strong reference should work
    let strongResult = KeyValueCoding.value(forKey: "strongRef", inObject: container)
    XCTAssertNotNil(strongResult)

    // Clear the reference to test dangling weak ref scenario
    model = nil

    // Access after deallocation should not crash
    let afterDealloc = KeyValueCoding.value(forKey: "weakRef", inObject: container)
    // Should be nil now
    _ = afterDealloc
  }


  // MARK: - Nil and Empty Tests

  func testNilObjectReturnsNil() {
    let result = KeyValueCoding.value(forKey: "anything", inObject: nil)
    XCTAssertNil(result)
  }

  func testEmptyKeyPathDoesNotCrash() {
    let model = TestModel(name: "Test")

    // Empty keypath - behavior may vary but should not crash
    let result = KeyValueCoding.value(forKeyPath: "", inObject: model)

    // Main assertion: no crash. Result could be nil or the object itself
    _ = result
  }

  func testKeyPathWithNilIntermediateReturnsNil() {
    let holder = AnyHolder(anyValue: nil)

    // anyValue is nil, so anyValue.name should return nil
    let result = KeyValueCoding.value(forKeyPath: "anyValue.name", inObject: holder)

    XCTAssertNil(result)
  }


  // MARK: - Optional Property Tests

  func testOptionalPropertyNilValue() {
    let model = TestModel()  // image is nil

    let result = KeyValueCoding.value(forKey: "image", inObject: model)

    XCTAssertNil(result)
  }

  func testOptionalPropertyWithValue() {
    let model = TestModel(image: "photo.jpg")

    let result = KeyValueCoding.value(forKey: "image", inObject: model)

    XCTAssertEqual(result as? String, "photo.jpg")
  }


  // MARK: - TypeInfo Edge Cases

  func testTypeInfoForBasicTypes() {
    // Basic types should not crash when accessed
    let intValue = 42
    let stringValue = "hello"
    let boolValue = true

    // These should return nil (no properties) but not crash
    let intResult = KeyValueCoding.value(forKey: "x", inObject: intValue)
    let strResult = KeyValueCoding.value(forKey: "x", inObject: stringValue)
    let boolResult = KeyValueCoding.value(forKey: "x", inObject: boolValue)

    XCTAssertNil(intResult)
    XCTAssertNil(strResult)
    XCTAssertNil(boolResult)
  }

  func testTypeInfoForTuple() {
    // Tuples should not crash
    let tuple = (name: "Test", value: 42)

    let result = KeyValueCoding.value(forKey: "name", inObject: tuple)

    // Should return nil (tuples not supported) but not crash
    XCTAssertNil(result)
  }

  func testTypeInfoForClosure() {
    // Closures should not crash
    let closure = { (x: Int) -> Int in x * 2 }

    let result = KeyValueCoding.value(forKey: "x", inObject: closure)

    // Should return nil but not crash
    XCTAssertNil(result)
  }


  // MARK: - Popup Scenario Regression Test

  func testPopupSelectionScenario() {
    // Simulates the exact WOPopUpButton crash scenario
    class FormComponent {
      var cow   = TestModel(name: "Bessie", image: "cow.jpg")
      var store = ["a.jpg", "b.jpg", "c.jpg"]
    }

    let component = FormComponent()

    // This is what WOPopUpButton does: evaluate $cow.image keypath
    let selection = KeyValueCoding.value(forKeyPath: "cow.image",
                                         inObject: component)

    XCTAssertEqual(selection as? String, "cow.jpg")

    // Also test accessing through intermediate Any
    let cowAsAny : Any = component.cow
    let imageFromAny = KeyValueCoding.value(forKey: "image", inObject: cowAsAny)

    XCTAssertEqual(imageFromAny as? String, "cow.jpg")
  }

  func testSharedSingletonPropertyAccess() {
    // Simulates the CowStore.shared scenario
    final class SharedStore {
      static let shared = SharedStore()
      let urlPrefix = "https://example.com/"
      let availableImages = ["a.jpg", "b.jpg", "c.jpg"]
      var mutableList = ["x", "y", "z"]
    }

    class ComponentWithStore {
      let store = SharedStore.shared
      var selectedImage : String?
    }

    let component = ComponentWithStore()

    // Access store property
    let storeResult = KeyValueCoding.value(forKey: "store", inObject: component)
    XCTAssertNotNil(storeResult)
    XCTAssertTrue(storeResult is SharedStore)

    // Access nested constant array via keypath
    let images = KeyValueCoding.value(forKeyPath: "store.availableImages",
                                      inObject: component)
    XCTAssertNotNil(images)
    if let imageArray = images as? [String] {
      XCTAssertEqual(imageArray.count, 3)
      XCTAssertEqual(imageArray[0], "a.jpg")
    }
    else {
      XCTFail("Expected [String] array")
    }

    // Access nested mutable array
    let mutableImages = KeyValueCoding.value(forKeyPath: "store.mutableList",
                                             inObject: component)
    XCTAssertNotNil(mutableImages)
    if let array = mutableImages as? [String] {
      XCTAssertEqual(array.count, 3)
    }

    // Access constant string property
    let prefix = KeyValueCoding.value(forKeyPath: "store.urlPrefix",
                                      inObject: component)
    XCTAssertEqual(prefix as? String, "https://example.com/")
  }

  func testArrayPropertyIteration() {
    // Test that arrays returned from KVC can be iterated
    class ListHolder {
      let items = ["one", "two", "three"]
    }

    let holder = ListHolder()
    let items = KeyValueCoding.value(forKey: "items", inObject: holder)

    XCTAssertNotNil(items)

    // Verify we can iterate the array (this is what crashed before)
    if let array = items as? [String] {
      var count = 0
      for item in array {
        XCTAssertFalse(item.isEmpty)
        count += 1
      }
      XCTAssertEqual(count, 3)
    }
    else {
      XCTFail("Expected [String] array")
    }
  }

  func testTakeValueViaKeypath() {
    // Test setting a value through a keypath on a non-KVC-protocol class
    // This exercises the setOnClass code path that previously crashed
    class Cow {
      var name  : String  = "Bessie"
      var image : String? = nil
    }

    class FormComponent {
      var cow = Cow()
    }

    let component = FormComponent()

    // This should not crash - sets cow.name via keypath
    try? KeyValueCoding.takeValue("Daisy", forKeyPath: "cow.name",
                                  inObject: component)
    XCTAssertEqual(component.cow.name, "Daisy")

    // Also test setting optional property
    try? KeyValueCoding.takeValue("cow.jpg", forKeyPath: "cow.image",
                                  inObject: component)
    XCTAssertEqual(component.cow.image, "cow.jpg")

    // Test setting to nil
    try? KeyValueCoding.takeValue(nil, forKeyPath: "cow.image",
                                  inObject: component)
    // Note: Our implementation may not support setting nil, so just verify
    // no crash occurred
  }


  // MARK: - Linux

  static var allTests = [
    ( "testDoubleBoxedAnyDoesNotCrash",         testDoubleBoxedAnyDoesNotCrash ),
    ( "testKeyPathThroughAnyDoesNotCrash",      testKeyPathThroughAnyDoesNotCrash ),
    ( "testArrayOfAnyDoesNotCrash",             testArrayOfAnyDoesNotCrash ),
    ( "testExistentialTypeReturnsNil",          testExistentialTypeReturnsNil ),
    ( "testProtocolExistentialDoesNotCrash",    testProtocolExistentialDoesNotCrash ),
    ( "testWeakReferenceReturnsNilNotCrash",    testWeakReferenceReturnsNilNotCrash ),
    ( "testWeakReferenceWithValueDoesNotCrash", testWeakReferenceWithValueDoesNotCrash ),
    ( "testNilObjectReturnsNil",                testNilObjectReturnsNil ),
    ( "testEmptyKeyPathDoesNotCrash",           testEmptyKeyPathDoesNotCrash ),
    ( "testKeyPathWithNilIntermediateReturnsNil",
                                         testKeyPathWithNilIntermediateReturnsNil ),
    ( "testOptionalPropertyNilValue",           testOptionalPropertyNilValue ),
    ( "testOptionalPropertyWithValue",          testOptionalPropertyWithValue ),
    ( "testTypeInfoForBasicTypes",              testTypeInfoForBasicTypes ),
    ( "testTypeInfoForTuple",                   testTypeInfoForTuple ),
    ( "testTypeInfoForClosure",                 testTypeInfoForClosure ),
    ( "testPopupSelectionScenario",             testPopupSelectionScenario ),
    ( "testSharedSingletonPropertyAccess",      testSharedSingletonPropertyAccess ),
    ( "testArrayPropertyIteration",             testArrayPropertyIteration ),
    ( "testTakeValueViaKeypath",                testTakeValueViaKeypath ),
  ]
}
