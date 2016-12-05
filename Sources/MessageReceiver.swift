//
//  MessageReceiver.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/17.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

public protocol MessageReceiverProtocol {
	associatedtype Peer: PeerProtocol

	func observeReceivedData(on queue: DispatchQueue, handler: @escaping (Data, Peer) -> Void) -> Disposable
}

public struct MessageReceiver<Peer: PeerProtocol>: MessageReceiverProtocol {
	private let _action: (DispatchQueue, @escaping (Data, Peer) -> Void) -> Disposable

	public init(_ action: @escaping (DispatchQueue, @escaping (Data, Peer) -> Void) -> Disposable) {
		_action = action
	}

	public init<T: MessageReceiverProtocol>(_ base: T) where T.Peer == Peer {
		_action = { base.observeReceivedData(on: $0, handler: $1) }
	}

	public func observeReceivedData(on queue: DispatchQueue, handler: @escaping (Data, Peer) -> Void) -> Disposable {
		return _action(queue, handler)
	}
}

extension MessageReceiverProtocol {
	public func observeMessages<T: MessageProtocol>(_ type: T.Type, on queue: DispatchQueue, handler: @escaping (T, Peer) -> Void) -> Disposable {
		return observeReceivedData(on: queue) { data, peer in
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
