//
//  Disposable.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/17.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

public protocol Disposable: class {
	var isDisposed: Bool { get }

	func dispose()
}

public final class ActionDisposable: Disposable {
	private let _disposable = DispatchAtomic<(() -> Void)?>(nil)

	public init(_ disposable: @escaping () -> Void) {
		_disposable.value = disposable
	}

	public var isDisposed: Bool {
		return _disposable.value == nil
	}

	public func dispose() {
		let disposable = _disposable.swap(nil)
		disposable?()
	}
}

public final class CompositeDisposable: Disposable {
	private let _disposables = DispatchAtomic<Array<Disposable>?>(nil)

	public init() {
		_disposables.value = []
	}

	public var isDisposed: Bool {
		return _disposables.value == nil
	}

	public func add(_ disposable: Disposable) {
		_disposables.modify { $0?.append(disposable) }
	}

	public func add(_ action: @escaping () -> Void) {
		add(ActionDisposable(action))
	}

	public func dispose() {
		let disposables = _disposables.swap(nil)
		disposables?.forEach { $0.dispose() }
	}
}

public func +=(lhs: CompositeDisposable, rhs: Disposable?) {
	guard let rhs = rhs else { return }
	lhs.add(rhs)
}

public func +=(lhs: CompositeDisposable, rhs: @escaping () -> Void) {
	lhs.add(rhs)
}
