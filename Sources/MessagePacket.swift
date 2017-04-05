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
    let data: Data?

    init(name: String, data: Data? = nil) {
        self.name = name
        self.data = data
    }

    private enum CodingKey: String, CodingKeyRepresentable {
        case name
        case data
    }

    convenience init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.tuka.decodeValue(of: String.self, forKey: CodingKey.name) else {
            return nil
        }
        let data = aDecoder.tuka.decodeObject(of: Data.self, forKey: CodingKey.data)
        self.init(name: name as String, data: data)
    }

    func encode(with aCoder: NSCoder) {
        aCoder.tuka.encode(name, forKey: CodingKey.name)
        aCoder.tuka.encode(data, forKey: CodingKey.data)
    }

    static var supportsSecureCoding: Bool {
        return true
    }
}
