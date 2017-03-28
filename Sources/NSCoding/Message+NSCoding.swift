//
//  Message+NSCoding.swift
//  Tuka
//
//  Created by Jun Tanaka on 2017/03/14.
//  Copyright © 2017 Jun Tanaka. All rights reserved.
//

import Foundation

extension Message where Self: NSObject, Self: NSCoding {
    /// Serialize the receiver to data using `NSKeyedUnarchiver`.
    ///
    /// - Returns: A serialized data of the receiver.
    /// - Throws: An `Error` if the operation could not be completed.
    public func serializedData() throws -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }

    /// Creates an instance of the message with the given deserialization context.
    ///
    /// - Parameter serializedData: A serialized data.
    /// - Returns: A deserialized message.
    /// - Throws: An `Error` if the operation could not be completed.
    public init(serializedData: Data) throws {
        guard let message = NSKeyedUnarchiver.unarchiveObject(with: serializedData) as? Self else {
            throw MessageNSCodingError.nilObject
        }
        self = message
    }
}

public enum MessageNSCodingError: Error {
    case nilObject
}
