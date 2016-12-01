//
//  ResourceResponse.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/18.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

public enum ResourceRequestResult: String {
	case success
	case failure
}

public protocol ResourceResponseProtocol: ResponseProtocol, SessionMessageProtocol {
	var result: ResourceRequestResult { get }

	init(requestID: String, result: ResourceRequestResult)
}

public struct ResourceResponse: ResourceResponseProtocol, KeyedCoding {
	public let requestID: String
	public let result: ResourceRequestResult

	public init(requestID: String, result: ResourceRequestResult) {
		self.requestID = requestID
		self.result = result
	}

	// MARK: KeyedCoding

	public enum CodingKey: String, CodingKeyPresentable {
		case requestID
		case result
	}

	public func encode(with encoder: KeyedCoder<ResourceResponse.CodingKey>) {
		encoder.encode(requestID as NSString, for: .requestID)
		encoder.encode(result.rawValue as NSString, for: .result)
	}

	public static func decode(with decoder: KeyedCoder<ResourceResponse.CodingKey>) -> ResourceResponse? {
		guard
			let requestID = decoder.decodeObject(of: [NSString.self], for: .requestID) as? String,
			let resultString = decoder.decodeObject(of: [NSString.self], for: .result) as? String,
			let result = ResourceRequestResult(rawValue: resultString) else {
				return nil
		}
		return ResourceResponse(requestID: requestID, result: result)
	}
}
