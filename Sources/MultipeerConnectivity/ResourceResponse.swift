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
public final class ResourceResponse: NSObject, ResourceResponseProtocol {
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

extension ResourceResponse: NSSecureCoding {
	public convenience init?(coder aDecoder: NSCoder) {
		guard
			let requestID = aDecoder.decodeObject(of: NSString.self, forKey: "requestID") as? String,
			let rawResult = aDecoder.decodeObject(of: NSString.self, forKey: "result") as? String,
			let result = ResourceRequestResult(rawValue: rawResult) else {
			return nil
		}
		self.init(requestID: requestID, result: result)
	}

	public func encode(with aCoder: NSCoder) {
		aCoder.encode(requestID, forKey: "requestID")
		aCoder.encode(result.rawValue, forKey: "result")
	}

	public static var supportsSecureCoding: Bool {
		return true
	}
}
