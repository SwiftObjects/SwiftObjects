//
//  LinuxDLAddr.swift
//  testit
//
//  Created by Helge Hess on 25.05.18.
//

#if os(Linux)
import Glibc

public struct Dl_info { // pure luck that this works ;-)
  var dli_fname : UnsafePointer<Int8>!
  var dli_fbase : UnsafeMutableRawPointer!
  var dli_sname : UnsafePointer<Int8>!
  var dli_saddr : UnsafeMutableRawPointer!
}

fileprivate typealias dladdrType  =
  @convention(c) ( UnsafeRawPointer?,
                   UnsafeMutableRawPointer? ) -> Int32

fileprivate let dladdrBase : dladdrType = {
  guard let dlHandle = dlopen(nil, RTLD_NOW) else {
    fatalError("dlopen failed?!")
  }
  defer { dlclose(dlHandle) }
  
  guard let ptr = dlsym(dlHandle, "dladdr") else {
    fatalError("did not find dladdr??")
  }
  return unsafeBitCast(ptr, to: dladdrType.self)
}()

public func dladdr(_ ptr: UnsafeRawPointer!,
            _ info: UnsafeMutablePointer<Dl_info>!) -> Int32
{
  return dladdrBase(ptr, info)
}
#endif
