//
//  MessageEncoder.swift
//  Tuka
//
//  Created by Jun Tanaka on 2018/09/23.
//  Copyright © 2018 Jun Tanaka. All rights reserved.
//

import Foundation

/// Represents a message encoder.
public protocol MessageEncoder {
    /// Returns an encoded data of the given message.
    ///
    /// - Parameter message: A message to encode.
    /// - Returns: An encoded `Data` of the message.
    /// - Throws: An error if any value throws an error during encoding.
    func encodeMessage<Message: Tuka.Message>(_ message: Message) throws -> Data
}
