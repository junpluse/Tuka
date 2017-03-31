//
//  NSCoder+Tuka.swift
//  Tuka
//
//  Created by Jun Tanaka on 2017/03/31.
//  Copyright © 2017 Jun Tanaka. All rights reserved.
//

import Foundation

extension NSCoder {
    public struct TukaExtension {
        let coder: NSCoder
    }

    public var tuka: TukaExtension {
        return TukaExtension(coder: self)
    }
}

extension NSCoder.TukaExtension {
    public func encode<Value>(_ value: Value, forKey key: String) where Value: RawRepresentable {
        coder.encode(value.rawValue, forKey: key)
    }
}

extension NSCoder.TukaExtension {
    public func decodeString(forKey key: String) -> String? {
        return coder.decodeObject(of: NSString.self, forKey: key) as String?
    }

    public func decodeObject<Object>(of type: Object.Type, forKey key: String) -> Object? where Object: ReferenceConvertible, Object.ReferenceType: NSCoding {
        return coder.decodeObject(of: Object.ReferenceType.self, forKey: key) as? Object
    }

    public func decodeValue<Value>(of type: Value.Type, forKey key: String) -> Value? where Value: RawRepresentable, Value.RawValue == Int {
        let rawValue = coder.decodeInteger(forKey: key)
        return Value(rawValue: rawValue)
    }

    public func decodeValue<Value>(of type: Value.Type, forKey key: String) -> Value? where Value: RawRepresentable, Value.RawValue == Double {
        let rawValue = coder.decodeDouble(forKey: key)
        return Value(rawValue: rawValue)
    }

    public func decodeValue<Value>(of type: Value.Type, forKey key: String) -> Value? where Value: RawRepresentable, Value.RawValue == String {
        guard let rawValue = decodeString(forKey: key) else {
            return nil
        }
        return Value(rawValue: rawValue)
    }
}

extension NSCoder.TukaExtension {
    public func encode<Key>(_ object: Any?, forKey key: Key) where Key: RawRepresentable, Key.RawValue == String {
        coder.encode(object, forKey: key.rawValue)
    }

    public func encode<Value, Key>(_ value: Value, forKey key: Key) where Value: RawRepresentable, Key: RawRepresentable, Key.RawValue == String {
        coder.encode(value.rawValue, forKey: key.rawValue)
    }
}

extension NSCoder.TukaExtension {
    public func decodeObject<Object, Key>(of type: Object.Type, forKey key: Key) -> Object? where Object: NSObject, Object: NSCoding, Key: RawRepresentable, Key.RawValue == String {
        return coder.decodeObject(of: type, forKey: key.rawValue)
    }

    public func decodeInt<Key>(forKey key: Key) -> Int where Key: RawRepresentable, Key.RawValue == String {
        return coder.decodeInteger(forKey: key.rawValue)
    }

    public func decodeDouble<Key>(forKey key: Key) -> Double where Key: RawRepresentable, Key.RawValue == String {
        return coder.decodeDouble(forKey: key.rawValue)
    }

    public func decodeString<Key>(forKey key: Key) -> String? where Key: RawRepresentable, Key.RawValue == String {
        return decodeString(forKey: key.rawValue)
    }

    public func decodeObject<Object, Key>(of type: Object.Type, forKey key: Key) -> Object? where Object: ReferenceConvertible, Object.ReferenceType: NSCoding, Key: RawRepresentable, Key.RawValue == String {
        return decodeObject(of: Object.self, forKey: key.rawValue)
    }

    public func decodeValue<Value, Key>(of type: Value.Type, forKey key: Key) -> Value? where Value: RawRepresentable, Value.RawValue == Int, Key: RawRepresentable, Key.RawValue == String {
        let rawValue = decodeInt(forKey: key)
        return Value(rawValue: rawValue)
    }

    public func decodeValue<Value, Key>(of type: Value.Type, forKey key: Key) -> Value? where Value: RawRepresentable, Value.RawValue == Double, Key: RawRepresentable, Key.RawValue == String {
        let rawValue = decodeDouble(forKey: key)
        return Value(rawValue: rawValue)
    }

    public func decodeValue<Value, Key>(of type: Value.Type, forKey key: Key) -> Value? where Value: RawRepresentable, Value.RawValue == String, Key: RawRepresentable, Key.RawValue == String {
        guard let rawValue = decodeString(forKey: key) else {
            return nil
        }
        return Value(rawValue: rawValue)
    }
}
