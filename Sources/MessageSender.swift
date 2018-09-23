//
//  MessageSender.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/17.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

/// Represents a message sender.
public protocol MessageSender {
    associatedtype Peer: Tuka.Peer

    /// Sends the given message, to the given peers.
    ///
    /// - Parameters:
    ///   - message: A message to be sent.
    ///   - peers: A set of peers that should receive the message.
    /// - Throws: An `Error` if sending the message could not be completed.
    func send<Message: Tuka.Message>(_ message: Message, to peers: Set<Peer>) throws
}

extension MessageSender where Self: DataSender, Self: MessageEncoder {
    public func send<Message: Tuka.Message>(_ message: Message, to peers: Set<Peer>) throws {
        let data = try encodeMessage(message)
        try send(data, to: peers)
    }
}
