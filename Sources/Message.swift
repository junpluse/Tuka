//
//  Message.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/17.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

/// Represents name of a message type.
public struct MessageName: RawRepresentable {
    public typealias RawValue = String

    public let rawValue: RawValue

    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
}

/// Represents a message.
public protocol Message {
    /// A name describing this messsage type.
    static var messageName: MessageName { get }

    /// Serialize the receiver to data.
    ///
    /// - Returns: A serialized data of the receiver.
    /// - Throws: An `Error` if the operation could not be completed.
    func serializedData() throws -> Data

    /// Creates an instance of the message with the given deserialization context.
    ///
    /// - Parameter serializedData: A serialized data.
    /// - Returns: A deserialized message.
    /// - Throws: An `Error` if the operation could not be completed.
    init(serializedData: Data) throws
}

extension Message {
    public static var messageName: MessageName {
        return MessageName(rawValue: String(describing: self))
    }
}
