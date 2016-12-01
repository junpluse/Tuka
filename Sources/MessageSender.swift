//
//  MessageSender.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/17.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

public protocol MessageSenderProtocol {
	associatedtype Peer: PeerProtocol

	func send(_ data: Data, of message: MessageProtocol, to peers: [Peer]) throws
}

public struct MessageSender<Peer: PeerProtocol>: MessageSenderProtocol {
	private let _action: (Data, MessageProtocol, [Peer]) throws -> Void

	public init(_ send: @escaping (Data, MessageProtocol, [Peer]) throws -> Void) {
		_action = send
	}

	public init<T: MessageSenderProtocol>(_ base: T) where T.Peer == Peer {
		_action = { try base.send($0, of: $1, to: $2) }
	}

	public 	func send(_ data: Data, of message: MessageProtocol, to peers: [Peer]) throws {
		try _action(data, message, peers)
	}
}

extension MessageSenderProtocol {
	public func send<T: MessageProtocol>(_ message: T, to peers: [Peer]) throws {
		let data = Archiver().archive(message)
		try send(data, of: message, to: peers)
	}
}
