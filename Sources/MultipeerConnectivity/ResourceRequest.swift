//
//  ResourceRequest.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/18.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

public protocol ResourceRequestProtocol: RequestProtocol, SessionMessageProtocol {
	associatedtype Response: ResourceResponseProtocol

	var resourceName: String { get }
	var preferredFilename: String { get }
}

public struct ResourceRequest: ResourceRequestProtocol, KeyedCoding {
	public typealias Response = ResourceResponse

	public let requestID: String
	public let resourceName: String
	public let preferredFilename: String

	public init(requestID: String = UUID().uuidString, resourceName: String, preferredFilename: String) {
		self.requestID = requestID
		self.resourceName = resourceName
		self.preferredFilename = preferredFilename
	}

	// MARK: KeyedCoding

	public enum CodingKey: String, CodingKeyPresentable {
		case requestID
		case resourceName
		case preferredFilename
	}

	public func encode(with encoder: KeyedCoder<CodingKey>) {
		encoder.encode(requestID as NSString, for: .requestID)
		encoder.encode(resourceName as NSString, for: .resourceName)
		encoder.encode(preferredFilename as NSString, for: .preferredFilename)
	}

	public static func decode(with decoder: KeyedCoder<CodingKey>) -> ResourceRequest? {
		guard
			let requestID = decoder.decodeObject(of: NSString.self, for: .requestID) as? String,
			let resourceName = decoder.decodeObject(of: NSString.self, for: .resourceName) as? String,
			let preferredFilename = decoder.decodeObject(of: NSString.self, for: .preferredFilename) as? String else {
				return nil
		}
		return ResourceRequest(requestID: requestID, resourceName: resourceName, preferredFilename: preferredFilename)
	}
}
