//
//  Messages.swift
//  Chat
//
//  Created by Jun Tanaka on 2017/03/28.
//  Copyright © 2017 Jun Tanaka. All rights reserved.
//

import Tuka

extension MessageName {
    static let join = MessageName(rawValue: "com.junpluse.Tuka.Chat.join")
    static let post = MessageName(rawValue: "com.junpluse.Tuka.Chat.post")
    static let leave = MessageName(rawValue: "com.junpluse.Tuka.Chat.leave")
}

struct PostMessage: Message {
    static var messageName: MessageName {
        return MessageName.post
    }

    var text: String

    init(text: String) {
        self.text = text
    }

    enum SerializationError: Error {
        case failed
    }

    func serializedData() throws -> Data {
        guard let data = text.data(using: .utf8) else {
            throw SerializationError.failed
        }
        return data
    }

    init(serializedData: Data) throws {
        guard let text = String(data: serializedData, encoding: .utf8) else {
            throw SerializationError.failed
        }
        self.text = text
    }
}
