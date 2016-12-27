//
//  Message.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/17.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

/// Represents a message.
public protocol MessageProtocol {
	/// Serialize the receiver to data.
	///
	/// - Returns: A serialized message data of the receiver
	func serializedMessage() -> Data

	/// Deserialize a message of the receiver type from data.
	///
	/// - Parameter data: A serialized data.
	/// - Returns: A deserialize message.
	/// - Throws: An `Error` if the operation could not be completed.
	static func deserializeMessage(from data: Data) throws -> Self?
}

extension MessageProtocol where Self: Coding {
	public func serializedMessage() -> Data {
		return Archiver().archive(self)
	}

	public static func deserializeMessage(from data: Data) throws -> Self? {
		return try Unarchiver().unarchive(data, of: Self.self)
	}
}

extension MessageProtocol where Self: NSCoding {
	public func serializedMessage() -> Data {
		let data = NSMutableData()
		let archiver = NSKeyedArchiver(forWritingWith: data)
		archiver.encodeRootObject(self)
		archiver.finishEncoding()
		return data as Data
	}

	public static func deserializeMessage(from data: Data) throws -> Self? {
		let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
		defer { unarchiver.finishDecoding() }
		do {
			return try unarchiver.decodeTopLevelObject() as? Self
		} catch let error as NSError where error.code == 4864 {
			// ignore unknown classes in the data
		}
		return nil
	}
}
