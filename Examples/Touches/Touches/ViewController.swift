//
//  ViewController.swift
//  Touches
//
//  Created by Jun Tanaka on 2017/03/29.
//  Copyright © 2017 Jun Tanaka. All rights reserved.
//

import UIKit
import Tuka
import ReactiveSwift

final class ViewController: UIViewController {
    @IBOutlet weak var peerCountLabel: UILabel?

    let session = Session()

    var viewBindingDisposable: Disposable?
    var messageObservingDisposable: Disposable?
    var peerInvitationsDisposable: Disposable?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // bind peer count with label
        let disposable = session.connectedPeers.producer
            .observe(on: UIScheduler())
            .startWithValues { [weak self] peers in
                self?.peerCountLabel?.text = "connections: \(peers.count)"
            }

        viewBindingDisposable = ScopedDisposable(disposable)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        startObservingMessages()
        startPeerInvitations()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        stopPeerInvitations()
        stopObservingMessages()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        guard let touch = touches.first else {
            return
        }

        let location = touch.location(in: view)
        let radius = min(view.bounds.width, view.bounds.height) / 2 * (touch.force + 1)

        self.startRippleEffect(at: location, radius: radius)

        // broadcast a message to connected peers
        let message = TouchMessage(location: location, radius: radius)
        do {
            try session.broadcast(message)
            print("Broadcast message: \(message)")
        } catch {
            print("Failed to send message with error: \(error)")
        }
    }

    func startRippleEffect(at location: CGPoint, radius: CGFloat) {
        let layer = CALayer()
        layer.position = location
        layer.bounds = CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2)
        layer.cornerRadius = radius
        layer.masksToBounds = true
        layer.backgroundColor = UIColor.white.cgColor

        view.layer.addSublayer(layer)

        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 0.01
        scaleAnimation.toValue = 1
        scaleAnimation.fillMode = .both

        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.fromValue = 1
        fadeAnimation.toValue = 0
        fadeAnimation.fillMode = .both

        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [scaleAnimation, fadeAnimation]
        animationGroup.fillMode = .both
        animationGroup.isRemovedOnCompletion = false

        CATransaction.begin()
        CATransaction.setAnimationDuration(1)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.215, 0.61, 0.355, 1))
        CATransaction.setCompletionBlock { 
            layer.removeFromSuperlayer()
        }

        layer.add(animationGroup, forKey: nil)

        CATransaction.commit()
    }

    func startObservingMessages() {
        // receive messages from connected peers
        messageObservingDisposable = session.incomingMessages(of: TouchMessage.self)
            .observe(on: UIScheduler())
            .observeValues { [weak self] message, peer in
                self?.startRippleEffect(at: message.location, radius: message.radius)
            }
    }

    func stopObservingMessages() {
        messageObservingDisposable?.dispose()
    }

    func startPeerInvitations() {
        // automatically invite nearby peers
        peerInvitationsDisposable = session.automaticPeerInvitations(withServiceType: "tuka-touches").startWithResult { result in
            switch result {
            case .success(let peer):
                print("Connected: \(peer)")
            case .failure(let error):
                print("Peer invitations failed with error: \(error)")
            }
        }
    }

    func stopPeerInvitations() {
        peerInvitationsDisposable?.dispose()
    }
}
