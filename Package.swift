// swift-tools-version:6.2
//
//  Package.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018-2026 ZeeZide. All rights reserved.
//
import PackageDescription
import Foundation

let fm = FileManager.default

let package = Package(
  name: "SwiftObjects",
  
  platforms: [ .macOS(.v15), .iOS(.v18), .visionOS(.v2) ],
  
  products: [
    .library(name: "SwiftObjects", targets: [ "SwiftObjects" ]),
  ],
  
  dependencies: [
    .package(url: "https://github.com/apple/swift-nio.git",
             from: "2.92.1"),
    .package(url: "https://github.com/wickwirew/Runtime.git",
             from: "2.2.7"),
    
    // just for the showcase
    .package(url: "https://github.com/SwiftWebResources/SemanticUI-Swift.git",
             from: "2.5.0"),
    .package(url: "https://github.com/SwiftWebResources/jQuery-Swift.git",
             from: "3.7.1"),
  ],
  
  targets: [
    .target(name: "SwiftObjects",
            dependencies: [
              .product(name: "NIO",                 package: "swift-nio"),
              .product(name: "NIOHTTP1",            package: "swift-nio"),
              .product(name: "NIOFoundationCompat", package: "swift-nio"),
              .product(name: "Runtime",             package: "Runtime"),
            ],
            exclude:
              fm.filesWithExtension("api", at: targetURL("SwiftObjects")),
            swiftSettings: [ .swiftLanguageMode(.v5) ]),
    
    .testTarget(name: "SwiftObjectsTests",
                dependencies: [ "SwiftObjects" ],
                swiftSettings: [ .swiftLanguageMode(.v5) ]),
    
    .executableTarget(name: "WOShowcaseApp",
                      dependencies: [
                        "SwiftObjects",
                        .product(name: "SemanticUI",
                                 package: "SemanticUI-Swift"),
                        .product(name: "jQuery", package: "jQuery-Swift")
                      ],
                      resources: [
                        .copy("favicon.ico")
                      ]
                      + fm.filesWithExtension("html",
                                              at: targetURL("WOShowcaseApp"))
                          .map { .copy($0) }
                      + fm.filesWithExtension("wod",
                                              at: targetURL("WOShowcaseApp"))
                          .map { .copy($0) })
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
