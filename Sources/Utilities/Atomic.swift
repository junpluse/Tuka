//
//  Atomic.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/29.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

public protocol AtomicProtocol: class {
	associatedtype Value

	@discardableResult
	func perform<T>(_ action: (Value) -> T) -> T

	@discardableResult
	func modify<T>(_ action: (inout Value) -> T) -> T
}

public extension AtomicProtocol {
	public var value: Value {
		get {
			return perform { $0 }
		}
		set(newValue) {
			swap(newValue)
		}
	}

	@discardableResult
	public func swap(_ newValue: Value) -> Value {
		return modify { (value: inout Value) in
			let oldValue = value
			value = newValue
			return oldValue
		}
	}
}

public final class DispatchAtomic<Value>: AtomicProtocol {
	private var _value: Value
	private let _queue: DispatchQueue

	public init(_ value: Value, queue: DispatchQueue = DispatchQueue(label: "com.junpluse.Tuka.DispatchAtomic.defaultQueue")) {
		_value = value
		_queue = queue
	}

	public func perform<T>(_ action: (Value) -> T) -> T {
		return _queue.sync { action(_value) }
	}

	public func modify<T>(_ action: (inout Value) -> T) -> T {
		return _queue.sync { action(&_value) }
	}

	public func performAsync(_ action: @escaping (Value) -> Void) {
		_queue.async { action(self._value) }
	}

	public func modifyAsync(_ action: @escaping (inout Value) -> Void) {
		_queue.async { action(&self._value) }
	}
}
