//
//  ResourceResponse.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/18.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

/// Represents either a failure or a success of a resource request.
public enum ResourceRequestResult: String {
	case success
	case failure
}

/// Represents a response to a resource request.
public protocol ResourceResponseProtocol: ResponseProtocol, SessionMessageProtocol {
	/// A result of the request.
	var result: ResourceRequestResult { get }

	/// Initializes a response to a request and a result.
	///
	/// - Parameters:
	///   - requestID: A string which identifies the original request.
	///   - result: A result of the request.
	init(requestID: String, result: ResourceRequestResult)
}

/// A basic class which implements 'ResourceResponseProtocol'.
public final class ResourceResponse: ResourceResponseProtocol {
	/// A string which identifies the request between peers.
	public let requestID: String

	/// A result of the request.
	public let result: ResourceRequestResult

	/// Initializes a response to a request and a result.
	///
	/// - Parameters:
	///   - requestID: A string which identifies the original request.
	///   - result: A result of the request.
	public init(requestID: String, result: ResourceRequestResult) {
		self.requestID = requestID
		self.result = result
	}
}

extension ResourceResponse: KeyedCoding {
	public enum CodingKey: String, CodingKeyPresentable {
		case requestID
		case result
	}

	public func encode(with encoder: KeyedCoder<ResourceResponse.CodingKey>) {
		encoder.encode(requestID, for: .requestID)
		encoder.encode(result, for: .result)
	}

	public static func decode(with decoder: KeyedCoder<ResourceResponse.CodingKey>) -> ResourceResponse? {
		guard
			let requestID = decoder.decodeString(for: .requestID),
			let result = decoder.decodeValue(of: ResourceRequestResult.self, for: .result) else {
				return nil
		}
		return ResourceResponse(requestID: requestID, result: result)
	}
}
