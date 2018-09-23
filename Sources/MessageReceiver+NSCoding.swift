//
//  MessageReceiver+NSCoding.swift
//  Tuka
//
//  Created by Jun Tanaka on 2017/03/29.
//  Copyright © 2017 Jun Tanaka. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result

public enum MessageReceiverNSCodingError: Error {
    case nilObject
    case invalidDecodedObject(Any)
    case invalidArchiveFormat(Error)
}

extension MessageReceiver {
    /// Returns a stream of decoded objects as incoming message data for the given name.
    ///
    /// - Parameters:
    ///   - name: A name of message type which should be included into the stream.
    ///   - type: A type of object which should be decoded as message data.
    /// - Returns: A `Signal` sends decoded objects with sender peers.
    public func incomingMessages<Object>(forName name: MessageName, withObjectOf type: Object.Type) -> Signal<(Object, Peer), MessageReceiverNSCodingError> where Object: NSObject, Object: NSCoding {
        return incomingMessages(forName: name)
            .promoteError(MessageReceiverNSCodingError.self)
            .attemptMap { data, peer in
                do {
                    guard let data = data else {
                        return Result(error: .nilObject)
                    }
                    guard let anyObject = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) else {
                        return Result(error: .nilObject)
                    }
                    guard let object = anyObject as? Object else {
                        return Result(error: .invalidDecodedObject(anyObject))
                    }
                    return Result(value: (object, peer))
                } catch {
                    return Result(error: .invalidArchiveFormat(error))
                }
            }
    }
}
