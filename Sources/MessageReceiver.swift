//
//  MessageReceiver.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/17.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import ReactiveSwift
import Result

/// Represents a message receiver.
public protocol MessageReceiver {
    associatedtype Peer: Tuka.Peer

    /// Returns a stream of incoming messages of the given type.
    ///
    /// - Parameter type: A type of message which should be included into the stream.
    /// - Returns: A `Signal` sends incoming messages with sender peers.
    func incomingMessages<Message: Tuka.Message>(of type: Message.Type) -> Signal<(Message, Peer), NoError>
}

extension MessageReceiver where Self: DataReceiver {
    /// Returns a stream of incoming messages of the given type.
    ///
    /// - Parameter type: A type of message which should be included into the stream.
    /// - Returns: A `Signal` sends incoming messages with sender peers.
    public func incomingMessages<Message: Tuka.Message>(of type: Message.Type) -> Signal<(Message, Peer), NoError> {
        return incomingData.filterMap { data, peer -> (Message, Peer)? in
            let context = MessageDeserializationContext(data: data)
            guard let message = try? Message(context: context) else {
                return nil
            }
            return (message, peer)
        }
    }
}
