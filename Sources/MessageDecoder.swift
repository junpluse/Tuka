//
//  MessageDecoder.swift
//  Tuka
//
//  Created by Jun Tanaka on 2018/09/23.
//  Copyright © 2018 Jun Tanaka. All rights reserved.
//

import Foundation

/// Represents a message decoder.
public protocol MessageDecoder {
    /// Returns a message of the given type, decoded from the given data.
    ///
    /// - Parameters:
    ///   - type: The type of the message to decode.
    ///   - data: The data to decode from.
    /// - Returns: A decoded message of the given type.
    /// - Throws: An error if any value throws an error during decoding.
    func decodeMessage<Message: Tuka.Message>(of type: Message.Type, from data: Data) throws -> Message
}
