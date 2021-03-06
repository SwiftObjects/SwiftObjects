//
//  DLSymRuntime.swift
//  testit
//
//  Created by Helge Hess on 25.05.18.
//  Copyright © 2018-2019 ZeeZide. All rights reserved.
//

import Foundation

func SOGetPointerToType<T>(_ type: T.Type) -> UnsafeRawPointer {
  return unsafeBitCast(type, to: UnsafeRawPointer.self)
}
func SOGetPointerToType(_ type: AnyClass) -> UnsafeRawPointer {
  return unsafeBitCast(type, to: UnsafeRawPointer.self)
}

fileprivate var didWarn = false

func SOGetPackageName<T>(_ type: T.Type, default: String = "") -> String {
  let ptr = SOGetPointerToType(type)
  
  var info = Dl_info()
  let rc   = dladdr(ptr, &info)
  assert(rc != 0, "Could not locate dlinfo for type: \(type)")
  guard rc != 0 else { return `default` }
  
  if info.dli_sname == nil {
    if !didWarn  {
      didWarn = true
      #if os(Linux)
        let exportFlags = "-Xlinker -export-dynamic"
      #else
        let exportFlags = "-Xlinker -export_dynamic"
      #endif
      print("WARN: could not locate type:", type,
            "did you link the package with `\(exportFlags)`?")
    }
  }
  
  guard info.dli_sname != nil else { return `default` }
  
  #if swift(>=4.2)
    // App Names examples:
    // - "WOShowcaseApp"  : $S13WOShowcaseAppAACN / $s13WOShowcaseAppAACN
    // - "WOShowcaseApp2" : $s13WOShowcaseApp0A4App2CN (compression?)
    // - "OTHER"          : $s13WOShowcaseApp5OTHERCN
    //
    // It is a string length 13, S13 WOShowcaseApp
    // Don't know what the 'AACN' is.
    //
    let symbolName = String(cString: info.dli_sname)
    #if swift(>=5)
      let prefix = "$s"
    #else
      let prefix = "$S"
    #endif
    if symbolName.hasPrefix(prefix) {
      let x = symbolName.dropFirst(prefix.count)
      if let endCountIdx = x.firstIndex(where: { !"0123456789".contains($0) }),
         endCountIdx > x.startIndex,
         let len = Int(x[..<endCountIdx]), len > 0
      {
        let stringEndIdx = x.index(endCountIdx, offsetBy: len)
        return String(x[endCountIdx..<stringEndIdx])
      }
    }
    
    print("Swift 4.2/5+ cannot lookup package name yet, symbol:",
          symbolName)
    return `default`
  #elseif swift(>=4.1.50)
    print("Swift 4.2 cannot lookup package name yet, symbol:",
          String(cString: info.dli_sname))
    return `default`
  #else
    assert(UnsafePointer(strstr(info.dli_sname, "_T")) == info.dli_sname,
           "package name does not begin with: " +
           "_T (\(String(cString: info.dli_sname))")
    var p = info.dli_sname!.advanced(by: 2) // skip _T
    
    let   len = Int(atoi(p))
    while isdigit(Int32(p.pointee)) != 0 { p += 1 }
    
    return p.withMemoryRebound(to: UInt8.self, capacity: len) { p in
      let data = UnsafeBufferPointer(start: p, count: len)
      return String(decoding: data, as: UTF8.self)
    }
  #endif
}

func SOGetClassByName(_ name: String, _ module: String) -> AnyClass? {
  let n = "_T0\(module.utf8.count)\(module)\(name.utf8.count)\(name)CN"
  
  guard let dlHandle = dlopen(nil, RTLD_NOW) else { return nil }
  defer { dlclose(dlHandle) }
  
  guard let ptr = dlsym(dlHandle, n) else {
    #if false
      print("\(#function) did not find:", n)
    #endif
    return nil
  }
  return unsafeBitCast(ptr, to: AnyClass.self)
}
