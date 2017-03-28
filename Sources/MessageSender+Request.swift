//
//  MessageSender+Request.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/18.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

extension MessageSender {
    /// Send a request message to peers.
    ///
    /// - Parameters:
    ///   - request: A request message to be sent.
    ///   - peers: An array of peers that should receive the request.
    /// - Returns: A receipt of the submission.
    /// - Throws: An `Error` if sending the request could not be completed.
    /// - Note: Pass returned receipt to MessageReceiverProtocol.addObserver()
    ///         to observe responses of the request.
    @discardableResult
    public func submit<Request: Tuka.Request>(_ request: Request, to peers: Set<Peer>) throws -> RequestReceipt<Request, Self> {
        try send(request, to: peers)
        return RequestReceipt(request: request, peers: peers, sender: self)
    }
}
