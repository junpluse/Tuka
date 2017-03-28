//
//  MessageSender.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/17.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

/// Represents a message sender.
public protocol MessageSender {
    associatedtype Peer: Tuka.Peer

    /// Sends a message to peers.
    ///
    /// - Parameters:
    ///   - message: A message to be sent.
    ///   - peers: A set of peers that should receive the message.
    /// - Throws: An `Error` if sending the message could not be completed.
    func send<Message: Tuka.Message>(_ message: Message, to peers: Set<Peer>) throws
}

extension MessageSender where Self: DataSender {
    /// Sends a message to peers.
    ///
    /// - Parameters:
    ///   - message: A message to be sent.
    ///   - peers: An array of peers that should receive the message.
    /// - Throws: An `Error` if sending the message could not be completed.
    public func send<Message: Tuka.Message>(_ message: Message, to peers: Set<Peer>) throws {
        let context = MessageSerializationContext()
        let data = try message.serializedData(with: context)
        try send(data, to: peers)
    }
}
