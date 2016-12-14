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

/// A basic class which implements 'ResourceRequestProtocol'.
public final class ResourceRequest: ResourceRequestProtocol {
	public typealias Response = ResourceResponse

	/// A string which identifies the request between peers.
	public let requestID: String

	/// A name for the resource.
	public let resourceName: String

	/// Initializes a resource request with values for requestID and resourceName
	///
	/// - Parameters:
	///   - requestID: A string which identifies the request between peers.
	///   - resourceName: A name for the resource.
	public init(requestID: String = UUID().uuidString, resourceName: String) {
		self.requestID = requestID
		self.resourceName = resourceName
	}
}

extension ResourceRequest: KeyedCoding {
	public enum CodingKey: String, CodingKeyPresentable {
		case requestID
		case resourceName
	}

	public func encode(with encoder: KeyedCoder<CodingKey>) {
		encoder.encode(requestID, for: .requestID)
		encoder.encode(resourceName, for: .resourceName)
	}

	public static func decode(with decoder: KeyedCoder<CodingKey>) -> ResourceRequest? {
		guard
			let requestID = decoder.decodeString(for: .requestID),
			let resourceName = decoder.decodeString(for: .resourceName) else {
				return nil
		}
		return ResourceRequest(requestID: requestID, resourceName: resourceName)
	}
}
