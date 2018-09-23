//
//  Request.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/17.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

/// Represents a request message.
public protocol Request: Message {
    associatedtype Response: Tuka.Response

    /// A value which identifies the request between peers.
    var requestID: Response.RequestID { get }
}
