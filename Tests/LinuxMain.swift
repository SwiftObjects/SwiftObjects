import XCTest

#if os(Linux) || os(FreeBSD)
@testable import SwiftObjectsTests

XCTMain([
     testCase(DynamicElementTestCase.allTests),
     testCase(HTMLParserTests.allTests),
     testCase(PListParserTests.allTests),
     testCase(WOContextURLTests.allTests),
     testCase(WODParserTests.allTests),
     testCase(WORequestFormDecoderTests.allTests),
     testCase(WOStringTests.allTests),
])
#endif
