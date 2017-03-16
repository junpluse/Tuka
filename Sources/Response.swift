//
//  Response.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/17.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

/// Represents a response message to a request.
public protocol Response: Message {
    associatedtype RequestID: Hashable

    /// A value which identifies the original request.
    var requestID: RequestID { get }
}
