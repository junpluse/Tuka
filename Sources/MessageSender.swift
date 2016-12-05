//
//  MessageSender.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/17.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

/// Represents a message sender
public protocol MessageSenderProtocol {
	associatedtype Peer: PeerProtocol

	/// Send an archived data of message to peers.
	///
	/// - Parameters:
	///   - data: An archived data of message.
	///   - message: The orignal message of the data.
	///   - peers: An array of peers that should receive the data.
	/// - Throws: An `Error` if sending the message could not be completed.
	func send(_ data: Data, of message: MessageProtocol, to peers: [Peer]) throws
}

/// A struct that implements `MessageSenderProtocol` using a closure or
/// another one that conforms `MessageSenderProtocol` to be wrapped.
public struct MessageSender<Peer: PeerProtocol>: MessageSenderProtocol {
	private let _action: (Data, MessageProtocol, [Peer]) throws -> Void

	/// Initializes a sender which sends data of messages using the given closure.
	///
	/// - Parameter action: A closure to send data of messages.
	public init(_ action: @escaping (Data, MessageProtocol, [Peer]) throws -> Void) {
		_action = action
	}

	/// Initializes a sender which wraps the given sender.
	///
	/// - Parameter sender: A sender to be wrapped.
	public init<T: MessageSenderProtocol>(_ sender: T) where T.Peer == Peer {
		_action = { try sender.send($0, of: $1, to: $2) }
	}

	/// Send an archived data of message to peers.
	///
	/// - Parameters:
	///   - data: An archived data of message.
	///   - message: The orignal message of the data.
	///   - peers: An array of peers that should receive the data.
	/// - Throws: An `Error` if sending the data could not be completed.
	public func send(_ data: Data, of message: MessageProtocol, to peers: [Peer]) throws {
		try _action(data, message, peers)
	}
}

extension MessageSenderProtocol {
	/// Send a message to peers.
	///
	/// - Parameters:
	///   - message: A message to be sent.
	///   - peers: An array of peers that should receive the message.
	/// - Throws: An `Error` if sending the message could not be completed.
	public func send<T: MessageProtocol>(_ message: T, to peers: [Peer]) throws {
		let data = Archiver().archive(message)
		try send(data, of: message, to: peers)
	}
}
