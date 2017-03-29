//
//  MessageReceiver.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/17.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result

/// Represents a message receiver.
public protocol MessageReceiver {
    associatedtype Peer: Tuka.Peer

    /// Returns a stream of incoming message data with the given name.
    ///
    /// - Parameter name: A name of message type which should be included into the stream.
    /// - Returns: A `Signal` sends incoming messages with sender peers.
    func incomingMessages(forName name: MessageName) -> Signal<(Data?, Peer), NoError>

    /// Returns a stream of incoming messages of the given type.
    ///
    /// - Parameter type: A type of message which should be included into the stream.
    /// - Returns: A `Signal` sends incoming messages with sender peers.
    func incomingMessages<Message: Tuka.Message>(of type: Message.Type) -> Signal<(Message, Peer), NoError>
}

extension MessageReceiver {
    /// Returns a stream of senders of incoming messages for the given name.
    ///
    /// - Parameter name: A name of message type which should be included into the stream.
    /// - Returns: A `Signal` sends senders of incoming messages.
    public func incomingMessagesWithoutData(forName name: MessageName) -> Signal<Peer, NoError> {
        return incomingMessages(forName: name).map { $0.1 }
    }
}

extension MessageReceiver {
    public func incomingMessages<Message: Tuka.Message>(of type: Message.Type) -> Signal<(Message, Peer), NoError> {
        return incomingMessages(forName: Message.messageName).filterMap { data, peer -> (Message, Peer)? in
            guard let data = data, let message = try? Message(serializedData: data) else {
                return nil
            }
            return (message, peer)
        }
    }
}

extension MessageReceiver where Self: DataReceiver {
    public func incomingMessages(forName name: MessageName) -> Signal<(Data?, Peer), NoError> {
        return incomingData.filterMap { data, peer -> (Data?, Peer)? in
            guard let packet = NSKeyedUnarchiver.unarchiveObject(with: data) as? MessagePacket else {
                return nil
            }
            guard packet.name == name.rawValue else {
                return nil
            }
            return (packet.data, peer)
        }
    }
}
