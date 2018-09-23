//
//  MessageSender+Request.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/18.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import ReactiveSwift
import Result

extension MessageSender {
    /// Submits the given request message, to the given peers.
    ///
    /// - Parameters:
    ///   - request: A request message to be sent.
    ///   - peers: An array of peers that should receive the request.
    /// - Returns: A receipt of the submission.
    /// - Throws: An `Error` if sending the request could not be completed.
    @discardableResult
    public func submit<Request: Tuka.Request>(_ request: Request, to peers: Set<Peer>) throws -> RequestReceipt<Request, Self> {
        try send(request, to: peers)
        return RequestReceipt(request: request, peers: peers, sender: self)
    }
}

/// Represents a receipt of request submission.
public struct RequestReceipt<Request: Tuka.Request, Sender: Tuka.MessageSender> {
    /// The submitted request.
    public let request: Request

    /// A set of peers that should receive the request.
    public let peers: Set<Sender.Peer>

    /// The sender who sent the request.
    public let sender: Sender

    /// Initializes a receipt with a request and an array of peers.
    ///
    /// - Parameters:
    ///   - request: A request to be sent.
    ///   - peers: An array of peers that should receive the request.
    public init(request: Request, peers: Set<Sender.Peer>, sender: Sender) {
        self.request = request
        self.peers = peers
        self.sender = sender
    }
}

extension RequestReceipt where Sender: MessageReceiver {
    /// Returns a stream of responses.
    ///
    /// - Returns: A `Signal` sends incoming responses with sender peers.
    public func responses() -> Signal<(Request.Response, Sender.Peer), NoError> {
        return sender.responses(to: request, from: peers)
    }
}
