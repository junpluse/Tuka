//
//  BasicMessage.swift
//  Tuka
//
//  Created by Jun Tanaka on 2017/03/16.
//  Copyright © 2017 Jun Tanaka. All rights reserved.
//

import Foundation

open class BasicMessage: NSObject, NSCoding, Message {
    public var userInfo: [String: Any]? = nil

    public init(userInfo: [String: Any]? = nil) {
        self.userInfo = userInfo
        super.init()
    }

    public enum CodingKey: String {
        case userInfo
    }

    public required init?(coder aDecoder: NSCoder) {
        self.userInfo = aDecoder.decodeObject(forKey: CodingKey.userInfo.rawValue) as? [String: Any]
        super.init()
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(userInfo, forKey: CodingKey.userInfo.rawValue)
    }
}
