//
//  DataReceiver.swift
//  Tuka
//
//  Created by Jun Tanaka on 2017/03/16.
//  Copyright © 2017 Jun Tanaka. All rights reserved.
//

import ReactiveSwift
import Result

/// Represents a data receiver.
public protocol DataReceiver {
    associatedtype Peer: Tuka.Peer

    /// Stream of incoming data.
    var incomingData: Signal<(Data, Peer), NoError> { get }
}
