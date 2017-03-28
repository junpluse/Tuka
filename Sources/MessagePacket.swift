//
//  MessagePacket.swift
//  Tuka
//
//  Created by Jun Tanaka on 2017/03/28.
//  Copyright © 2017 Jun Tanaka. All rights reserved.
//

import Foundation

@objc(TUKAMessagePacket)
internal final class MessagePacket: NSObject, NSSecureCoding {
    let name: String
    let data: Data

    init(name: String, data: Data) {
        self.name = name
        self.data = data
    }

    private enum CodingKey: String {
        case name
        case data
    }

    convenience init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(of: NSString.self, forKey: CodingKey.name.rawValue) else {
            return nil
        }
        guard let data = aDecoder.decodeObject(of: NSData.self, forKey: CodingKey.data.rawValue) else {
            return nil
        }
        self.init(name: name as String, data: data as Data)
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: CodingKey.name.rawValue)
        aCoder.encode(data, forKey: CodingKey.data.rawValue)
    }

    static var supportsSecureCoding: Bool {
        return true
    }
}
