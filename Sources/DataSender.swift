//
//  DataSender.swift
//  Tuka
//
//  Created by Jun Tanaka on 2017/03/16.
//  Copyright © 2017 Jun Tanaka. All rights reserved.
//

/// Represents a data sender.
public protocol DataSender {
    associatedtype Peer: Tuka.Peer

    /// Sends a serialized data to peers.
    ///
    /// - Parameters:
    ///   - data: An serialized data to send.
    ///   - peers: A set of peers that should receive the data.
    /// - Throws: An `Error` if sending the data could not be completed.
    func send(_ data: Data, to peers: Set<Peer>) throws
}
