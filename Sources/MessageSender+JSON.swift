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
    ///   - JSONObject: A JSON object to be sent.
    ///   - name: A name of message type.
    ///   - peers: A set of peers that should receive the message.
    /// - Throws: An `Error` if sending the message could not be completed.
    public func send(JSONObject: [String: Any], withName name: MessageName, to peers: Set<Peer>) throws {
        let data = try JSONSerialization.data(withJSONObject: JSONObject, options: [])
        try send(data, withName: name, to: peers)
    }

    /// Sends a message with a JSON object to peers.
    ///
    /// - Parameters:
    ///   - JSONObject: A JSON object to be sent.
    ///   - name: A raw name of message type.
    ///   - peers: A set of peers that should receive the message.
    /// - Throws: An `Error` if sending the message could not be completed.
    public func send(JSONObject: [String: Any], withName rawName: String, to peers: Set<Peer>) throws {
        try send(JSONObject: JSONObject, withName: MessageName(rawValue: rawName), to: peers)
    }
}
