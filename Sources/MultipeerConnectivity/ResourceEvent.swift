//
//  ResourceEvent.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/28.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

public enum ResourceEvent<Request: ResourceRequestProtocol> {
	case transferStarted(Request, Session.Peer, Progress?)
	case transferFinished(Request, Session.Peer)
	case transferFailed(Request, Session.Peer, Error)
}
