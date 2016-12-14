//
//  Coding.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/30.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

public protocol Coding {
	func encode(with encoder: NSCoder)

	static func decode(with decoder: NSCoder) -> Self?
}

extension Coding where Self: NSCoding {
	static func decode(with decoder: NSCoder) -> Self? {
		return Self(coder: decoder)
	}
}

public protocol CodingKeyPresentable {
	var codingKey: String { get }
}

extension CodingKeyPresentable where Self: RawRepresentable, Self.RawValue == String {
	public var codingKey: String {
		return rawValue
	}
}

extension String: CodingKeyPresentable {
	public var codingKey: String {
		return self
	}
}

public final class CodingContainer<Value: Coding>: NSObject, NSSecureCoding {
	public var value: Value?

	public init(_ value: Value?) {
		self.value = value
		super.init()
	}

	public class var codedClassName: String {
		return String(describing: self)
	}

	public convenience init?(coder aDecoder: NSCoder) {
		let value = Value.decode(with: aDecoder)
		self.init(value)
	}

	public func encode(with aCoder: NSCoder) {
		value?.encode(with: aCoder)
	}

	public static var supportsSecureCoding: Bool {
		return true
	}
}

public protocol KeyedCoding: Coding {
	associatedtype CodingKey: CodingKeyPresentable

	func encode(with encoder: KeyedCoder<CodingKey>)

	static func decode(with decoder: KeyedCoder<CodingKey>) -> Self?
}

extension KeyedCoding {
	public func encode(with encoder: NSCoder) {
		encode(with: KeyedCoder<CodingKey>(nsCoder: encoder))
	}

	public static func decode(with decoder: NSCoder) -> Self? {
		return decode(with: KeyedCoder<CodingKey>(nsCoder: decoder))
	}
}

public struct KeyedCoder<Key: CodingKeyPresentable> {
	public let nsCoder: NSCoder

	public init(nsCoder: NSCoder) {
		self.nsCoder = nsCoder
	}

	public func encode(_ object: Any?, for key: Key) {
		nsCoder.encode(object, forKey: key.codingKey)
	}

	public func encodeConditionalObject(_ object: Any?, for key: Key) {
		nsCoder.encodeConditionalObject(object, forKey: key.codingKey)
	}

	public func encode(_ value: Bool, for key: Key) {
		nsCoder.encode(value, forKey: key.codingKey)
	}

	public func encode(_ value: Int, for key: Key) {
		nsCoder.encode(value, forKey: key.codingKey)
	}

	public func encode(_ value: Int32, for key: Key) {
		nsCoder.encode(value, forKey: key.codingKey)
	}

	public func encode(_ value: Int64, for key: Key) {
		nsCoder.encode(value, forKey: key.codingKey)
	}

	public func encode(_ value: Float, for key: Key) {
		nsCoder.encode(value, forKey: key.codingKey)
	}

	public func encode(_ value: Double, for key: Key) {
		nsCoder.encode(value, forKey: key.codingKey)
	}

	public func encodeBytes(_ bytes: UnsafePointer<UInt8>?, length: Int, for key: Key) {
		nsCoder.encodeBytes(bytes, length: length, forKey: key.codingKey)
	}

	public func containsValue(for key: Key) -> Bool {
		return nsCoder.containsValue(forKey: key.codingKey)
	}

	public func decodeObject<T>(of type: T.Type, for key: Key) -> T? where T: NSCoding, T: NSObject {
		return nsCoder.decodeObject(of: type, forKey: key.codingKey)
	}

	public func decodeObject(of classes: [AnyClass]?, for key: Key) -> Any? {
		return nsCoder.decodeObject(of: classes, forKey: key.codingKey)
	}

	public func decodeObject(for key: Key) -> Any? {
		return nsCoder.decodeObject(forKey: key.codingKey)
	}

	public func decodeBool(for key: Key) -> Bool {
		return nsCoder.decodeBool(forKey: key.codingKey)
	}

	public func decodeInt(for key: Key) -> Int {
		return nsCoder.decodeInteger(forKey: key.codingKey)
	}

	public func decodeInt32(for key: Key) -> Int32 {
		return nsCoder.decodeInt32(forKey: key.codingKey)
	}

	public func decodeInt64(for key: Key) -> Int64 {
		return nsCoder.decodeInt64(forKey: key.codingKey)
	}

	public func decodeFloat(for key: Key) -> Float {
		return nsCoder.decodeFloat(forKey: key.codingKey)
	}

	public func decodeDouble(for key: Key) -> Double {
		return nsCoder.decodeDouble(forKey: key.codingKey)
	}

	public func decodeBytes(for key: Key, returnedLength length: UnsafeMutablePointer<Int>?) -> UnsafePointer<UInt8>? {
		return nsCoder.decodeBytes(forKey: key.codingKey, returnedLength: length)
	}
}

extension KeyedCoder {
	public func encode(_ value: String?, for key: Key) {
		encode(value as NSString?, for: key)
	}

	public func decodeString(for key: Key) -> String? {
		return decodeObject(of: NSString.self, for: key) as? String
	}
}

extension KeyedCoder {
	public func encode<T: RawRepresentable>(_ value: T, for key: Key) where T.RawValue == Int {
		encode(value.rawValue, for: key)
	}

	public func encode<T: RawRepresentable>(_ value: T, for key: Key) where T.RawValue == Int32 {
		encode(value.rawValue, for: key)
	}

	public func encode<T: RawRepresentable>(_ value: T, for key: Key) where T.RawValue == Int64 {
		encode(value.rawValue, for: key)
	}

	public func encode<T: RawRepresentable>(_ value: T, for key: Key) where T.RawValue == Float {
		encode(value.rawValue, for: key)
	}

	public func encode<T: RawRepresentable>(_ value: T, for key: Key) where T.RawValue == Double {
		encode(value.rawValue, for: key)
	}

	public func encode<T: RawRepresentable>(_ value: T, for key: Key) where T.RawValue == String {
		encode(value.rawValue, for: key)
	}

	public func decodeValue<T: RawRepresentable>(of type: T.Type, for key: Key) -> T? where T.RawValue == Int {
		return T(rawValue: decodeInt(for: key))
	}

	public func decodeValue<T: RawRepresentable>(of type: T.Type, for key: Key) -> T? where T.RawValue == Int32 {
		return T(rawValue: decodeInt32(for: key))
	}

	public func decodeValue<T: RawRepresentable>(of type: T.Type, for key: Key) -> T? where T.RawValue == Int64 {
		return T(rawValue: decodeInt64(for: key))
	}

	public func decodeValue<T: RawRepresentable>(of type: T.Type, for key: Key) -> T? where T.RawValue == Float {
		return T(rawValue: decodeFloat(for: key))
	}

	public func decodeValue<T: RawRepresentable>(of type: T.Type, for key: Key) -> T? where T.RawValue == Double {
		return T(rawValue: decodeDouble(for: key))
	}

	public func decodeValue<T: RawRepresentable>(of type: T.Type, for key: Key) -> T? where T.RawValue == String {
		guard let raw = decodeString(for: key) else { return nil }
		return T(rawValue: raw)
	}
}

public struct Archiver {
	public func archive<T: Coding>(_ value: T) -> Data {
		let data = NSMutableData()
		let archiver = NSKeyedArchiver(forWritingWith: data)

		let container = CodingContainer(value)
		let containerType = type(of: container)
		archiver.setClassName(containerType.codedClassName, for: containerType)
		archiver.encodeRootObject(container)
		archiver.finishEncoding()

		return data as Data
	}
}

public struct Unarchiver {
	public func unarchive<T: Coding>(_ data: Data, of type: T.Type) throws -> T? {
		let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
		defer { unarchiver.finishDecoding() }

		let containerType = CodingContainer<T>.self
		unarchiver.setClass(containerType, forClassName: containerType.codedClassName)

		guard let object = try unarchiver.decodeTopLevelObject(), let container = object as? CodingContainer<T> else {
			return nil
		}

		return container.value
	}
}
