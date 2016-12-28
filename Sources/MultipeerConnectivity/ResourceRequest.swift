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
public final class ResourceRequest: NSObject, ResourceRequestProtocol {
	public typealias Response = ResourceResponse

	/// A string which identifies the request between peers.
	public let requestID: String

	/// Initializes a resource request with requestID
	///
	/// - Parameters:
	///   - requestID: A string which identifies the request between peers.
	public init(requestID: String = UUID().uuidString) {
		self.requestID = requestID
		super.init()
	}
}

extension ResourceRequest: NSSecureCoding {
	public convenience init?(coder aDecoder: NSCoder) {
		guard let requestID = aDecoder.decodeObject(of: NSString.self, forKey: "requestID") as? String else {
			return nil
		}
		self.init(requestID: requestID)
	}

	public func encode(with aCoder: NSCoder) {
		aCoder.encode(requestID, forKey: "requestID")
	}

	public static var supportsSecureCoding: Bool {
		return true
	}
}
