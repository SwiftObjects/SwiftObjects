//
//  WONIOAdaptor.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import NIO
import NIOHTTP1

open class WONIOAdaptor {
  // TODO: you create WOApplication objects, and *those* have the adaptors.
  // though in Go, the Servlet maintains the app object.
  
  open class Configuration {
    open var logger         : WOLogger        = WOPrintLogger(logLevel: .Log)
    open var host           : String?         = nil
    open var port           : Int             = 1337
    open var backlog        : Int             = 256
    open var eventLoopGroup : EventLoopGroup? = nil
    open var workerGroup    : EventLoopGroup? = nil
    
    public init() {}
  }

  let application    : WOApplication
  let configuration  : Configuration
  let eventLoopGroup : EventLoopGroup
  let workerGroup    : EventLoopGroup
  var serverChannel  : Channel?
  public let logger  : WOLogger

  public init(configuration: Configuration = Configuration(),
              application: WOApplication)
  {
    let numCores = System.coreCount
    
    self.application    = application
    self.configuration  = configuration
    
    self.eventLoopGroup = configuration.eventLoopGroup
                       ?? MultiThreadedEventLoopGroup(numThreads: numCores / 2)
    self.workerGroup    = configuration.eventLoopGroup
                       ?? MultiThreadedEventLoopGroup(numThreads: numCores / 2)
    self.logger         = configuration.logger
  }
  
  
  // MARK: - Dispatch

  func dispatchRequest(_ request: WONIORequest, in ctx: ChannelHandlerContext,
                       whenDone cb: @escaping ( WOResponse ) -> Void)
  {
    let requestLoop = ctx.eventLoop
    let workerLoop  = workerGroup.next()
    
    workerLoop.execute {
      let response = self.application.dispatchRequest(request)
      requestLoop.execute {
        cb(response)
      }
    }
  }

  
  // MARK: - Server
  
    open func listenAndWait() {
        listen()
      
        do    { try serverChannel?.closeFuture.wait() }
        catch { print("ERROR: Failed to wait on server:", error) }
    }

    open func listen() {
        let bootstrap = makeBootstrap()
      
        do {
            let address : SocketAddress
          
            if let host = configuration.host {
                address = try SocketAddress
                  .newAddressResolving(host: host, port: configuration.port)
            }
            else {
                var addr = sockaddr_in()
                addr.sin_port = in_port_t(configuration.port).bigEndian
                address = SocketAddress(addr, host: "*")
            }
          
            serverChannel = try bootstrap.bind(to: address).wait()
          
            if let addr = serverChannel?.localAddress {
                print("Server running on:", addr)
            }
            else {
                print("ERROR: server reported no local address?")
            }
        }
        catch let error as NIO.IOError {
            print("ERROR: failed to start server, errno:", error.errnoCode, "\n",
                  error.localizedDescription)
        }
        catch {
            print("ERROR: failed to start server:", type(of:error), error)
        }
    }
  

    // MARK: - Bootstrap
  
    func makeBootstrap() -> ServerBootstrap {
      let reuseAddrOpt = ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET),
                                               SO_REUSEADDR)
      let bootstrap = ServerBootstrap(group: eventLoopGroup)
          // Specify backlog and enable SO_REUSEADDR for the server itself
          .serverChannelOption(ChannelOptions.backlog,
                               value: Int32(configuration.backlog))
          .serverChannelOption(reuseAddrOpt, value: 1)
        
          // Set the handlers that are applied to the accepted Channels
          .childChannelInitializer { channel in
              channel.pipeline
                  .configureHTTPServerPipeline(withErrorHandling: true)
                  .then {
                      channel.pipeline
                          .add(name: "WONIOHandler",
                               handler: WONIOHandler(adaptor: self))
                  }
          }
        
          // Enable TCP_NODELAY and SO_REUSEADDR for the accepted Channels
          .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY),
                              value: 1)
          .childChannelOption(reuseAddrOpt, value: 1)
          .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
    
      return bootstrap
    }
}
