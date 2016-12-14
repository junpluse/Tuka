//
//  Observer.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/29.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

public protocol ObserverProtocol: class {
	associatedtype Value

	func observe(_ value: Value)
}

public final class Observer<Value>: ObserverProtocol {
	private let _action: (Value) -> Void

	public init(_ action: @escaping (Value) -> Void) {
		_action = action
	}

	public init<T: ObserverProtocol>(_ base: T) where T.Value == Value {
		_action = { base.observe($0) }
	}

	public func observe(_ value: Value) {
		_action(value)
	}
}

public final class DispatchObserver<Value>: ObserverProtocol {
	private let _queue: DispatchQueue?
	private let _action: (Value) -> Void

	public init(queue: DispatchQueue? = nil, action: @escaping (Value) -> Void) {
		_queue = queue
		_action = action
	}

	public func observe(_ value: Value) {
		if let queue = _queue {
			queue.async { self._action(value) }
		} else {
			_action(value)
		}
	}
}

public final class CompositeObserver<Value>: ObserverProtocol {
	private let _observers = DispatchAtomic<[UUID: Observer<Value>]>([:])

	public init() {}

	public func observe(_ value: Value) {
		_observers.value.forEach { $0.value.observe(value) }
	}

	public func add<T: ObserverProtocol>(_ observer: T) -> Disposable where T.Value == Value {
		let key = UUID()
		_observers.modify { $0[key] = Observer(observer) }
		return ActionDisposable {
			self._observers.modify { $0.removeValue(forKey: key) }
		}
	}

	public func add(_ observer: @escaping (Value) -> Void) -> Disposable {
		return add(Observer(observer))
	}
}

public func +=<T, U: ObserverProtocol>(lhs: CompositeObserver<T>, rhs: U?) -> Disposable? where U.Value == T {
	guard let rhs = rhs else { return nil }
	return lhs.add(rhs)
}

public func +=<T>(lhs: CompositeObserver<T>, rhs: @escaping (T) -> Void) -> Disposable {
	return lhs.add(rhs)
}
