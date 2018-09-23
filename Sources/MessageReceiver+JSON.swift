//
//  MessageReceiver+JSON.swift
//  Tuka
//
//  Created by Jun Tanaka on 2017/03/29.
//  Copyright © 2017 Jun Tanaka. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result

public enum MessageReceiverJSONError: Error {
    case nilObject
    case invalidJSONFormat(Error)
}

extension MessageReceiver {
    /// Returns a stream of JSON objects as incoming message data for the given name.
    ///
    /// - Parameter name: A name of message type which should be included into the stream.
    /// - Returns: A `Signal` sends JSON objects with sender peers.
    public func incomingMessagesWithJSONObject(forName name: MessageName) -> Signal<(Any, Peer), MessageReceiverJSONError> {
        return incomingMessages(forName: name)
            .promoteError(MessageReceiverJSONError.self)
            .attemptMap { data, peer in
                guard let data = data else {
                    return Result(error: .nilObject)
                }
                do {
                    let object = try JSONSerialization.jsonObject(with: data, options: [])
                    return Result(value: (object, peer))
                } catch {
                    return Result(error: .invalidJSONFormat(error))
                }
            }
    }
}
