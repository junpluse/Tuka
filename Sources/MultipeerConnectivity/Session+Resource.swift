//
//  Session+Resource.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/18.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import MultipeerConnectivity
import ReactiveSwift
import Result

extension Session {
    public enum ResourceTransferEvent {
        case started(name: String, peer: Peer, progress: Progress?)
        case completed(name: String, peer: Peer, localURL: URL)
        case failed(name: String, peer: Peer, error: Error)
    }

    public func sendResource(at url: URL, withName name: String, to peer: Peer) -> SignalProducer<ResourceTransferEvent, AnyError> {
        return SignalProducer<ResourceTransferEvent, AnyError> { [mcSession] observer, lifetime in
            let progress = mcSession.sendResource(at: url, withName: name, toPeer: peer) { error in
                if let error = error {
                    observer.send(value: .failed(name: name, peer: peer, error: error))
                    observer.send(error: AnyError(error))
                } else {
                    observer.send(value: .completed(name: name, peer: peer, localURL: url))
                    observer.sendCompleted()
                }
            }
            if let progress = progress {
                progress.cancellationHandler = {
                    if lifetime.hasEnded == false {
                        observer.sendInterrupted()
                    }
                }
                lifetime.observeEnded {
                    if progress.isCancelled == false {
                        progress.cancel()
                    }
                }
            }
            observer.send(value: .started(name: name, peer: peer, progress: progress))
        }
    }

    public func sendResource(at url: URL, withName name: String, to peers: Set<Peer>, concurrently: Bool = false) -> SignalProducer<ResourceTransferEvent, AnyError> {
        let childProducers = peers.map { peer in
            return sendResource(at: url, withName: name, to: peer)
        }

        return SignalProducer { observer, lifetime in
            lifetime += childProducers
                .map { childProducer in
                    return childProducer.on(value: { event in observer.send(value: event) })
                }
                .reduce(SignalProducer<ResourceTransferEvent, AnyError>.empty) { previous, current in
                    if concurrently {
                        return previous.concat(current)
                    } else {
                        return previous.then(current)
                    }
                }
                .filter { _ in false }
                .start(observer)
        }
    }

    public func incomingResourceEvents(forName resourceName: String? = nil, from peers: Set<Peer>? = nil) -> Signal<ResourceTransferEvent, NoError> {
        return Signal.merge([
            startReceivingResourceEvents.filterMap { name, peer, progress -> ResourceTransferEvent? in
                guard (resourceName == nil || resourceName == name) && (peers == nil || peers?.contains(peer) == true) else {
                    return nil
                }
                return .started(name: name, peer: peer, progress: progress)
            },
            finishReceivingResourceEvents.filterMap { name, peer, url, error -> ResourceTransferEvent? in
                guard (resourceName == nil || resourceName == name) && (peers == nil || peers?.contains(peer) == true) else {
                    return nil
                }
                if let error = error {
                    return .failed(name: name, peer: peer, error: error)
                } else if let url = url {
                    return .completed(name: name, peer: peer, localURL: url)
                } else {
                    fatalError("Received `FinishReceivingResourceEvent` without both `error` and `url`")
                }
            }
        ])
    }

    public func incomingResources(forName resourceName: String? = nil, from peers: Set<Peer>? = nil) -> Signal<(String, URL, Peer), AnyError> {
        return finishReceivingResourceEvents
            .filter { name, peer, _, _ in
                return (resourceName == nil || resourceName == name) && (peers == nil || peers?.contains(peer) == true)
            }
            .promoteError(AnyError.self)
            .attemptMap { name, peer, url, error -> Result<(String, URL, Peer), AnyError> in
                if let error = error {
                    return Result(error: AnyError(error))
                } else if let url = url {
                    return Result(value: (name, url, peer))
                } else {
                    fatalError("Received `FinishReceivingResourceEvent` without both `error` and `url`")
                }
            }
    }
}
