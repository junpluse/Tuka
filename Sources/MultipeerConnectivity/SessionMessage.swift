//
//  SessionMessage.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/18.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import MultipeerConnectivity

public protocol SessionMessageProtocol: MessageProtocol {
	var preferredSendDataMode: MCSessionSendDataMode { get }
}

public extension SessionMessageProtocol {
	var preferredSendDataMode: MCSessionSendDataMode {
		return .reliable
	}
}
