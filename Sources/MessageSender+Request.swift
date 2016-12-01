//
//  MessageSender+Request.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/18.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

extension MessageSenderProtocol {
	@discardableResult
	public func submit<T: RequestProtocol>(_ request: T, to peers: [Peer]) throws -> RequestReceipt<T, Self.Peer> {
		try send(request, to: peers)
		return RequestReceipt(request: request, peers: peers)
	}
}
