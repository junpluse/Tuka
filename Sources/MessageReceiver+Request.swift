//
//  MessageReceiver+Request.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/18.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import ReactiveSwift
import Result

extension MessageReceiver {
    /// Returns a stream of responses to the request from the given peers.
    ///
    /// - Parameters:
    ///   - request: A request which the peers should be responded to.
    ///   - peers: A set of peers who should respond to the request.
    /// - Returns: A `Signal` sends incoming responses with sender peers.
    public func responses<Request: Tuka.Request>(to request: Request, from peers: Set<Peer>) -> Signal<(Request.Response, Peer), NoError> {
        return incomingMessages(of: Request.Response.self)
            .filter { response, peer -> Bool in
                return response.requestID == request.requestID && peers.contains(peer)
            }
            .take(first: peers.count)
    }
}
