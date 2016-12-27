//
//  ResourceEventProducer.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/12/27.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

public protocol ResourceEventProducerProtocol: class {
	associatedtype Request: ResourceRequestProtocol

	func addEventObserver(on queue: DispatchQueue, action: @escaping (ResourceEvent<Request>) -> Void) -> Disposable
}
