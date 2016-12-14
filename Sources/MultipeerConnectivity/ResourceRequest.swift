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
	var mimeType: String? { get }
}

public final class ResourceRequest: ResourceRequestProtocol, KeyedCoding {
	public typealias Response = ResourceResponse

	public let requestID: String
	public let resourceName: String
	public let mimeType: String?

	public init(requestID: String = UUID().uuidString, resourceName: String, mimeType: String? = nil) {
		self.requestID = requestID
		self.resourceName = resourceName
		self.mimeType = mimeType
	}

	// MARK: KeyedCoding

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
