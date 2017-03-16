//
//  Message+NSCoding.swift
//  Tuka
//
//  Created by Jun Tanaka on 2017/03/14.
//  Copyright © 2017 Jun Tanaka. All rights reserved.
//

import Foundation

public extension Message where Self: NSObject, Self: NSCoding {
    /// Serialize the receiver to data using `NSKeyedUnarchiver`.
    ///
    /// - Parameter context: A context used for serialization.
    /// - Returns: A serialized data of the receiver.
    /// - Throws: An `Error` if the operation could not be completed.
    func serializedData(with context: MessageSerializationContext) throws -> Data {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(self, forKey: NSKeyedArchiveRootObjectKey)
        archiver.finishEncoding()
        return data as Data
    }

    /// Creates an instance of the message with the given deserialization context.
    ///
    /// - Parameter context: A context used for deserialization.
    /// - Returns: A deserialized message.
    /// - Throws: An `Error` if the operation could not be completed.
    init(context: MessageDeserializationContext) throws {
        let unarchiver = NSKeyedUnarchiver(forReadingWith: context.data)
        defer { unarchiver.finishDecoding() }
        guard let message = unarchiver.decodeObject(of: Self.self, forKey: NSKeyedArchiveRootObjectKey) else {
            throw MessageDeserializationNSCodingError.nilRootObject
        }
        self = message
    }
}

public enum MessageDeserializationNSCodingError: Error {
    case nilRootObject
}
