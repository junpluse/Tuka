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

	/// A mime type of the resource.
	var mimeType: String? { get }
}

/// A basic class which implements 'ResourceRequestProtocol'.
public final class ResourceRequest: ResourceRequestProtocol {
	public typealias Response = ResourceResponse

	/// A string which identifies the request between peers.
	public let requestID: String

	/// A name for the resource.
	public let resourceName: String

	/// A mime type of the resource.
	public let mimeType: String?

	/// Initializes a resource request with values for requestID/resourceName/mimeType
	///
	/// - Parameters:
	///   - requestID: A string which identifies the request between peers.
	///   - resourceName: A name for the resource.
	///   - mimeType: A mime type of the resource.
	public init(requestID: String = UUID().uuidString, resourceName: String, mimeType: String? = nil) {
		self.requestID = requestID
		self.resourceName = resourceName
		self.mimeType = mimeType
	}
}

extension ResourceRequest: KeyedCoding {
	public enum CodingKey: String, CodingKeyPresentable {
		case requestID
		case resourceName
		case mimeType
	}

	public func encode(with encoder: KeyedCoder<CodingKey>) {
		encoder.encode(requestID, for: .requestID)
		encoder.encode(resourceName, for: .resourceName)
		encoder.encode(mimeType, for: .mimeType)
	}

	public static func decode(with decoder: KeyedCoder<CodingKey>) -> ResourceRequest? {
		guard
			let requestID = decoder.decodeString(for: .requestID),
			let resourceName = decoder.decodeString(for: .resourceName) else {
				return nil
		}
		let mimeType = decoder.decodeString(for: .mimeType)
		return ResourceRequest(requestID: requestID, resourceName: resourceName, mimeType: mimeType)
	}
}
