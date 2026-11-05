// swift-tools-version:6.3
//
//  Package.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018-2026 ZeeZide. All rights reserved.
//
import PackageDescription
import CompilerPluginSupport
import Foundation

let fm = FileManager.default

let showcaseResources : [ Resource ] =
  [ .copy("favicon.ico") ]
  + fm.filesWithExtension("html", at: targetURL("WOShowcaseApp"))
      .map { Resource.copy($0) }
  + fm.filesWithExtension("wod",  at: targetURL("WOShowcaseApp"))
      .map { Resource.copy($0) }

let package = Package(
  name: "SwiftObjects",
  
  platforms: [ .macOS(.v15), .iOS(.v18), .visionOS(.v2) ],
  
  products: [
    .library(name: "SwiftObjects", targets: [ "SwiftObjects" ]),
  ],
  
  dependencies: [
    .package(url: "https://github.com/apple/swift-nio.git",
             from: "2.92.1"),
    .package(url: "https://github.com/swiftlang/swift-syntax.git",
             from: "600.0.0"),

    // just for the showcase
    .package(url: "https://github.com/SwiftWebResources/SemanticUI-Swift.git",
             from: "2.5.0"),
    .package(url: "https://github.com/SwiftWebResources/jQuery-Swift.git",
             from: "3.7.1"),
  ],
  
  targets: [
    .macro(name: "SwiftObjectsMacros",
           dependencies: [
             .product(name: "SwiftSyntaxMacros",   package: "swift-syntax"),
             .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
           ]),
    
    .target(name: "SwiftObjects",
            dependencies: [
              "SwiftObjectsMacros",
              .product(name: "NIO",                 package: "swift-nio"),
              .product(name: "NIOHTTP1",            package: "swift-nio"),
              .product(name: "NIOFoundationCompat", package: "swift-nio"),
            ],
            exclude:
              fm.filesWithExtension("api", at: targetURL("SwiftObjects"))),
    
    .testTarget(name: "SwiftObjectsTests",
                dependencies: [ "SwiftObjects" ]),
    .testTarget(name: "SwiftObjectsMacrosTests",
                dependencies: [
                  "SwiftObjectsMacros",
                  .product(name: "SwiftSyntaxMacrosTestSupport",
                           package: "swift-syntax"),
                ]),
    
    .executableTarget(name: "WOShowcaseApp",
                      dependencies: [
                        "SwiftObjects",
                        .product(name: "SemanticUI",
                                 package: "SemanticUI-Swift"),
                        .product(name: "jQuery", package: "jQuery-Swift")
                      ],
                      resources: showcaseResources)
  ]
)

fileprivate func targetURL(_ target: String) -> URL {
  URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("Sources")
    .appendingPathComponent(target)
}

fileprivate extension FileManager {
  
  func filesWithExtension(_ extension: String, at url: URL) -> [ String ] {
    let url = url.standardizedFileURL
    guard let enumerator = FileManager.default
      .enumerator(at: url,
                  includingPropertiesForKeys: [ .isRegularFileKey ],
                  options: [ .skipsHiddenFiles ])
    else { return [] }
    
    let baseParts = url.pathComponents.count
    var files = [ String ]()
    for case let url as URL in enumerator
    where url.pathExtension == `extension`
    {
      let relative = url.pathComponents.dropFirst(baseParts)
        .joined(separator: "/")
      files.append(relative)
    }
    return files
  }
}
