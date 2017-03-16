//
//  Message.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/17.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

/// Represents a message.
public protocol Message {
    /// Serialize the receiver to data.
    ///
    /// - Parameter context: A context used for serialization.
    /// - Returns: A serialized data of the receiver.
    /// - Throws: An `Error` if the operation could not be completed.
    func serializedData(with context: MessageSerializationContext) throws -> Data

    /// Creates an instance of the message with the given deserialization context.
    ///
    /// - Parameter context: A context used for deserialization.
    /// - Returns: A deserialized message.
    /// - Throws: An `Error` if the operation could not be completed.
    init(context: MessageDeserializationContext) throws
}

public struct MessageSerializationContext {}

public struct MessageDeserializationContext {
    /// A serialized data for deserialization.
    public var data: Data
}
