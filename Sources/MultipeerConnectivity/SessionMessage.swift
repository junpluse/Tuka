//
//  SessionMessage.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/18.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import MultipeerConnectivity

public protocol SessionMessage: Message {
    var preferredSendDataMode: MCSessionSendDataMode { get }
}

extension SessionMessage {
    public var preferredSendDataMode: MCSessionSendDataMode {
        return .reliable
    }
}
