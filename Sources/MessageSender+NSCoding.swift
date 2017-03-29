//
//  MessageSender+NSCoding.swift
//  Tuka
//
//  Created by Jun Tanaka on 2017/03/29.
//  Copyright © 2017 Jun Tanaka. All rights reserved.
//

import Foundation

extension MessageSender {
    /// Sends a message with NSCoding object to peers.
    ///
    /// - Parameters:
    ///   - name: A name of message type.
    ///   - object: An object to be send as a serialized data.
    ///   - peers: A set of peers that should receive the message.
    /// - Throws: An `Error` if sending the message could not be completed.
    public func send<Object>(name: MessageName, withObject object: Object, to peers: Set<Peer>) throws where Object: NSObject, Object: NSCoding {
        let data = NSKeyedArchiver.archivedData(withRootObject: object)
        try send(name: name, with: data, to: peers)
    }
}
