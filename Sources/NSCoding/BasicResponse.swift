//
//  BasicResponse.swift
//  Tuka
//
//  Created by Jun Tanaka on 2017/03/16.
//  Copyright © 2017 Jun Tanaka. All rights reserved.
//

import Foundation

@objc(TUKABasicResponse)
open class BasicResponse: NSObject, NSCoding, Response {
    public typealias RequestID = UUID

    open var requestID: UUID

    open var userInfo: [String: Any]?

    public init(requestID: UUID, userInfo: [String: Any]? = nil) {
        self.requestID = requestID
        self.userInfo = userInfo
        super.init()
    }

    public enum CodingKey: String {
        case requestID
        case userInfo
    }

    public required init?(coder aDecoder: NSCoder) {
        guard let requestID = aDecoder.decodeObject(forKey: CodingKey.requestID.rawValue) as? UUID else {
            return nil
        }
        self.requestID = requestID
        self.userInfo = aDecoder.decodeObject(forKey: CodingKey.userInfo.rawValue) as? [String: Any]
        super.init()
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(requestID, forKey: CodingKey.requestID.rawValue)
        aCoder.encode(userInfo, forKey: CodingKey.userInfo.rawValue)
    }
}

extension BasicResponse {
    public convenience init(request: BasicRequest, userInfo: [String: Any]? = nil) {
        self.init(requestID: request.requestID, userInfo: userInfo)
    }
}
