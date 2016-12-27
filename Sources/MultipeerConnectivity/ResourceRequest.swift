//
//  ResourceRequest.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/18.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

/// Represents a request message which be sent before transferring a resource
/// to another peer in a session.
public protocol ResourceRequestProtocol: RequestProtocol, SessionMessageProtocol {
	associatedtype Response: ResourceResponseProtocol

	/// A name for the resource.
	var resourceName: String { get }
}

extension ResourceRequestProtocol {
	/// A name for the resource. Uses requestID as default.
	public var resourceName: String {
		return requestID
	}
}

/// A basic class which implements 'ResourceRequestProtocol'.
public final class ResourceRequest: ResourceRequestProtocol {
	public typealias Response = ResourceResponse

	/// A string which identifies the request between peers.
	public let requestID: String

	/// Initializes a resource request with requestID
	///
	/// - Parameters:
	///   - requestID: A string which identifies the request between peers.
	public init(requestID: String = UUID().uuidString) {
		self.requestID = requestID
	}
}

extension ResourceRequest: KeyedCoding {
	public enum CodingKey: String, CodingKeyPresentable {
		case requestID
		case resourceName
	}

	public func encode(with encoder: KeyedCoder<CodingKey>) {
		encoder.encode(requestID, for: .requestID)
	}

	public static func decode(with decoder: KeyedCoder<CodingKey>) -> ResourceRequest? {
		guard
			let requestID = decoder.decodeString(for: .requestID) else {
				return nil
		}
		return ResourceRequest(requestID: requestID)
	}
}
