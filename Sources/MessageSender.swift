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

    /// Sends a message with data to peers.
    ///
    /// - Parameters:
    ///   - data: A data to be sent.
    ///   - name: A name of message type.
    ///   - peers: A set of peers that should receive the message.
    /// - Throws: An `Error` if sending the message could not be completed.
    func send(_ data: Data, withName name: MessageName, to peers: Set<Peer>) throws

    /// Sends a message to peers.
    ///
    /// - Parameters:
    ///   - message: A message to be sent.
    ///   - peers: A set of peers that should receive the message.
    /// - Throws: An `Error` if sending the message could not be completed.
    func send<Message: Tuka.Message>(_ message: Message, to peers: Set<Peer>) throws
}

extension MessageSender {
    /// Sends a message with data to peers.
    ///
    /// - Parameters:
    ///   - data: A data to be sent.
    ///   - name: A raw name of message type.
    ///   - peers: A set of peers that should receive the message.
    /// - Throws: An `Error` if sending the message could not be completed.
    public func send(_ data: Data, withName rawName: String, to peers: Set<Peer>) throws {
        return try send(data, withName: MessageName(rawValue: rawName), to: peers)
    }
}

extension MessageSender {
    public func send<Message: Tuka.Message>(_ message: Message, to peers: Set<Peer>) throws {
        let name = Message.messageName
        let data = try message.serializedData()
        return try send(data, withName: name, to: peers)
    }
}

extension MessageSender where Self: DataSender {
    public func send(_ data: Data, withName name: MessageName, to peers: Set<Peer>) throws {
        let packet = MessagePacket(name: name.rawValue, data: data)
        let packetData = NSKeyedArchiver.archivedData(withRootObject: packet)
        try send(packetData, to: peers)
    }
}
