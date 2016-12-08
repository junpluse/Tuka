//
//  MessageReceiver.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/17.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

/// Represents a message receiver
public protocol MessageReceiverProtocol {
	associatedtype Peer: PeerProtocol

	/// Adds a received data handler with a dispatch queue and a closure to add to the queue.
	///
	/// - Parameters:
	///   - queue: A dispatch queue to which closure should be added.
	///   - handler: A closure to be executed when the data is received.
	/// - Returns: A `Disposable` which can be used to stop the invocation of the closure.
	func addDataObserver(on queue: DispatchQueue, handler: @escaping (Data, Peer) -> Void) -> Disposable
}

/// A struct that implements `MessageReceiverProtocol` using a closure or
/// another one that conforms `MessageReceiverProtocol` to be wrapped.
public struct MessageReceiver<Peer: PeerProtocol>: MessageReceiverProtocol {
	private let _action: (DispatchQueue, @escaping (Data, Peer) -> Void) -> Disposable

	/// Initializes a receiver which invoke the geven closure to add received data observers.
	///
	/// - Parameter action: A closure to add received data observers.
	public init(_ action: @escaping (DispatchQueue, @escaping (Data, Peer) -> Void) -> Disposable) {
		_action = action
	}

	/// Initializes a receiver which wraps the given receiver.
	///
	/// - Parameter receiver: A receiver to be wrapped.
	public init<T: MessageReceiverProtocol>(_ base: T) where T.Peer == Peer {
		_action = { base.addDataObserver(on: $0, handler: $1) }
	}

	/// Adds a received data handler with a dispatch queue and a closure to add to the queue.
	///
	/// - Parameters:
	///   - queue: A dispatch queue to which closure should be added.
	///   - handler: A closure to be executed when the data is received.
	/// - Returns: A `Disposable` which can be used to stop the invocation of the closure.
	public func addDataObserver(on queue: DispatchQueue, handler: @escaping (Data, Peer) -> Void) -> Disposable {
		return _action(queue, handler)
	}
}

extension MessageReceiverProtocol {
	/// Adds a received message handler with a dispatch queue and a closure to add to the queue.
	///
	/// - Parameters:
	///   - messageType: A type of message which should be observed.
	///   - queue: A dispatch queue to which closure should be added.
	///   - handler: A closure to be executed when a message is received.
	/// - Returns: A `Disposable` which can be used to stop the invocation of the closure.
	public func addObserver<T: MessageProtocol>(for messageType: T.Type, on queue: DispatchQueue, handler: @escaping (T, Peer) -> Void) -> Disposable {
		return addDataObserver(on: queue) { data, peer in
			do {
				if let message = try Unarchiver().unarchive(data, of: T.self) {
					handler(message, peer)
				}
			} catch let error as NSError {
				if error.code == 4864 {
					// ignore unknown classes in the data
				} else {
					print("[Tuka.MessageReceiverProtocol] failed to unarchive data as \(T.self) with error: \(error)")
				}
			}
		}
	}
}
