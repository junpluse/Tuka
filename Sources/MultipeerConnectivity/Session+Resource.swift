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
        return SignalProducer<ResourceTransferEvent, AnyError> { [mcSession] observer, disposable in
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
                    if disposable.isDisposed == false {
                        observer.sendInterrupted()
                    }
                }
                disposable += {
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

        return SignalProducer { observer, disposable in
            disposable += childProducers
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

    public var incomingResourceEvents: Signal<ResourceTransferEvent, NoError> {
        return Signal.merge([
            startReceivingResourceEvents.map { name, peer, progress in
                return .started(name: name, peer: peer, progress: progress)
            },
            finishReceivingResourceEvents.map { name, peer, url, error in
                if let error = error {
                    return .failed(name: name, peer: peer, error: error)
                } else {
                    return .completed(name: name, peer: peer, localURL: url)
                }
            }
        ])
    }

    public func incomingResources() -> Signal<(String, URL, Peer), AnyError> {
        return finishReceivingResourceEvents
            .promoteErrors(AnyError.self)
            .attemptMap { name, peer, url, error -> Result<(String, URL, Peer), AnyError> in
                if let error = error {
                    return Result(error: AnyError(error))
                } else {
                    return Result(value: (name, url, peer))
                }
            }
    }

    public func incomingResources(forName resourceName: String) -> Signal<(URL, Peer), AnyError> {
        return finishReceivingResourceEvents
            .filter { name, _, _, _ in
                return name == resourceName
            }
            .promoteErrors(AnyError.self)
            .attemptMap { name, peer, url, error -> Result<(URL, Peer), AnyError> in
                if let error = error {
                    return Result(error: AnyError(error))
                } else {
                    return Result(value: (url, peer))
                }
        }
    }
}
