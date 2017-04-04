//
//  MessageSender+JSON.swift
//  Tuka
//
//  Created by Jun Tanaka on 2017/03/28.
//  Copyright © 2017 Jun Tanaka. All rights reserved.
//

import Foundation

extension MessageSender {
    /// Sends a message with a JSON object to peers.
    ///
    /// - Parameters:
    ///   - name: A name of message type.
    ///   - jsonObject: A JSON object to be sent.
    ///   - peers: A set of peers that should receive the message.
    /// - Throws: An `Error` if sending the message could not be completed.
    public func send(name: MessageName, withJSONObject jsonObject: Any, to peers: Set<Peer>) throws {
        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        try send(name: name, withData: data, to: peers)
    }
}
