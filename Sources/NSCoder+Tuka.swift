//
//  NSCoder+Tuka.swift
//  Tuka
//
//  Created by Jun Tanaka on 2017/03/31.
//  Copyright © 2017 Jun Tanaka. All rights reserved.
//

import Foundation

public protocol CodingKeyRepresentable {
    var codingKey: String { get }
}

extension String: CodingKeyRepresentable {
    public var codingKey: String {
        return self
    }
}

extension RawRepresentable where RawValue == String, Self: CodingKeyRepresentable {
    public var codingKey: String {
        return rawValue
    }
}

extension NSCoder {
    public struct TukaExtension {
        let coder: NSCoder
    }

    public var tuka: TukaExtension {
        return TukaExtension(coder: self)
    }
}

extension NSCoder.TukaExtension {
    public func encode(_ value: Any?, forKey key: CodingKeyRepresentable) {
        coder.encode(value, forKey: key.codingKey)
    }
}

extension NSCoder.TukaExtension {
    public func decodeObject<Object>(of type: Object.Type, forKey key: CodingKeyRepresentable) -> Object? where Object: NSObject, Object: NSCoding {
        return coder.decodeObject(of: Object.self, forKey: key.codingKey)
    }

    public func decodeObject<Object>(of type: Object.Type, forKey key: CodingKeyRepresentable) -> Object? where Object: ReferenceConvertible, Object.ReferenceType: NSCoding {
        return coder.decodeObject(of: Object.ReferenceType.self, forKey: key.codingKey) as? Object
    }

    public func decodeValue<Value>(of type: Value.Type, forKey key: CodingKeyRepresentable) -> Value? where Value: ExpressibleByBooleanLiteral {
        return coder.decodeObject(of: NSNumber.self, forKey: key.codingKey) as? Value
    }

    public func decodeValue<Value>(of type: Value.Type, forKey key: CodingKeyRepresentable) -> Value? where Value: ExpressibleByIntegerLiteral {
        return coder.decodeObject(of: NSNumber.self, forKey: key.codingKey) as? Value
    }

    public func decodeValue<Value>(of type: Value.Type, forKey key: CodingKeyRepresentable) -> Value? where Value: ExpressibleByStringLiteral {
        return coder.decodeObject(of: NSString.self, forKey: key.codingKey) as? Value
    }
}

extension NSCoder.TukaExtension {
    public func encode<Value>(_ value: Value, forKey key: CodingKeyRepresentable) where Value: RawRepresentable {
        encode(value.rawValue, forKey: key)
    }
}

extension NSCoder.TukaExtension {
    public func decodeValue<Value>(of type: Value.Type, forKey key: CodingKeyRepresentable) -> Value? where Value: RawRepresentable, Value.RawValue: ExpressibleByBooleanLiteral {
        guard let rawValue = decodeValue(of: Value.RawValue.self, forKey: key) else {
            return nil
        }
        return Value(rawValue: rawValue)
    }

    public func decodeValue<Value>(of type: Value.Type, forKey key: CodingKeyRepresentable) -> Value? where Value: RawRepresentable, Value.RawValue: ExpressibleByIntegerLiteral {
        guard let rawValue = decodeValue(of: Value.RawValue.self, forKey: key) else {
            return nil
        }
        return Value(rawValue: rawValue)
    }

    public func decodeValue<Value>(of type: Value.Type, forKey key: CodingKeyRepresentable) -> Value? where Value: RawRepresentable, Value.RawValue: ExpressibleByStringLiteral {
        guard let rawValue = decodeValue(of: Value.RawValue.self, forKey: key) else {
            return nil
        }
        return Value(rawValue: rawValue)
    }
}
