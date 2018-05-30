//
//  WONIOHandler.swift
//  SwiftObjects
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2018 ZeeZide. All rights reserved.
//

import NIO
import NIOHTTP1
import NIOFoundationCompat

final class WONIOHandler : ChannelInboundHandler {
  
  // TODO: this needs to create WORequest's, WOResponse's, and WOContext's,
  //       and dispatch those back to the application

  typealias InboundIn   = HTTPServerRequestPart
  typealias OutboundOut = HTTPServerResponsePart
  
  let adaptor       : WONIOAdaptor
  var activeRequest : WONIORequest? = nil
  
  public init(adaptor: WONIOAdaptor) {
    self.adaptor = adaptor
  }
  
  func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
    let requestPart = unwrapInboundIn(data)
    
    switch requestPart {
      
      case .head(let requestHead):
        let request = WONIORequest(channel     : ctx.channel,
                                   method      : requestHead.method.woMethod,
                                   uri         : requestHead.uri,
                                   httpVersion : requestHead.version,
                                   headers     : requestHead.headers)
        activeRequest = request
      
      case .body(let bb):
        // We just spool up the data in the request.
        // TODO: have limits, and streaming support, etc.
        guard let request = activeRequest else { break }
        
        let data = bb.getData(at: bb.readerIndex, length: bb.readableBytes)
        if request.contents != nil, let data = data {
          request.contents!.append(data)
        }
        else {
          request.contents = data
        }
      
      case .end:
        guard let request = activeRequest else { break }
        dispatchRequest(request, in: ctx)
    }
  }
  
  func dispatchRequest(_ request: WONIORequest, in ctx: ChannelHandlerContext) {
    adaptor.dispatchRequest(request, in: ctx) { response in
      let contentLength = response.contents?.count ?? 0
      response.setHeader("\(contentLength)", for: "Content-Length")
      
      let responseHead = HTTPResponseHead(
        version : response.httpVersion,
        status  : HTTPResponseStatus(statusCode: response.status),
        headers : response.headers
      )

      let wrap = self.wrapOutboundOut
      
      ctx.write(wrap(.head(responseHead)), promise: nil)
      
      if contentLength > 0, let data = response.contents {
        var buf = ctx.channel.allocator.buffer(capacity: contentLength)
        buf.write(bytes: data)
        ctx.write(wrap(.body(.byteBuffer(buf))), promise: nil)
      }
      
      ctx.writeAndFlush(wrap(.end(nil)), promise: nil)
      
      assert(request === self.activeRequest)
      self.activeRequest = nil
    }
  }
  
  
  func channelActive(ctx: ChannelHandlerContext) {
  }
  
  func channelInactive(ctx: ChannelHandlerContext) {
    activeRequest = nil
  }
  
  /// Called if an error happens. We just close the socket here.
  func errorCaught(ctx: ChannelHandlerContext, error: Error) {
    adaptor.application.log.error("adaptor error:", error)
    ctx.close(promise: nil)
    activeRequest = nil
  }
}
