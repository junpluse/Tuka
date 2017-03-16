//
//  PeerInvitationManager.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/12/27.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import MultipeerConnectivity

public protocol PeerInvitationManagerLogicDelegate: class {
	func peerInvitationManager(_ manager: PeerInvitationManager, discoveryInfoFor peer: MCPeerID) -> [String: String]?
	func peerInvitationManager(_ manager: PeerInvitationManager, shouldInvite peer: MCPeerID, withDiscoveryInfo info: [String: String]?) -> Bool
	func peerInvitationManager(_ manager: PeerInvitationManager, shouldAcceptInvitationFrom peer: MCPeerID) -> Bool
}

public protocol PeerInvitationManagerErrorDelegate: class {
	func peerInvitationManager(_ manager: PeerInvitationManager, didNotStartAdvertisingPeer error: Error)
	func peerInvitationManager(_ manager: PeerInvitationManager, didNotStartBrowsingPeer error: Error)
}

public final class PeerInvitationManager: NSObject {
	public let session: MCSession
	public let serviceType: String
	public let maximumNumberOfPeers: Int
	public let invitationTimeoutInterval: TimeInterval

	public weak var logicDelegate: PeerInvitationManagerLogicDelegate?
	public weak var errorDelegate: PeerInvitationManagerErrorDelegate?

	public static let defaultLogic: PeerInvitationManagerLogicDelegate = HashBasedInvitationLogic()

	private var advertiser: MCNearbyServiceAdvertiser?
	private var browser: MCNearbyServiceBrowser?
	private var logic: PeerInvitationManagerLogicDelegate {
		return logicDelegate ?? PeerInvitationManager.defaultLogic
	}

	public init(session: MCSession, serviceType: String, maximumNumberOfPeers: Int = kMCSessionMaximumNumberOfPeers, invitationTimeoutInterval: TimeInterval = 30) {
		self.session = session
		self.serviceType = serviceType
		self.maximumNumberOfPeers = maximumNumberOfPeers
		self.invitationTimeoutInterval = invitationTimeoutInterval
		super.init()
	}

	public func start() {
		let peer = session.myPeerID

		advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: discoveryInfo(for: peer), serviceType: serviceType)
		advertiser?.delegate = self
		advertiser?.startAdvertisingPeer()

		browser = MCNearbyServiceBrowser(peer: peer, serviceType: serviceType)
		browser?.delegate = self
		browser?.startBrowsingForPeers()
	}

	public func stop() {
		advertiser?.delegate = nil
		advertiser?.stopAdvertisingPeer()
		advertiser = nil

		browser?.delegate = nil
		browser?.stopBrowsingForPeers()
		browser = nil
	}

	public func discoveryInfo(for peer: MCPeerID) -> [String: String]? {
		return logic.peerInvitationManager(self, discoveryInfoFor: peer)
	}

	public func shouldInvite(_ peer: MCPeerID, discoveryInfo: [String: String]?) -> Bool {
		guard session.connectedPeers.count < maximumNumberOfPeers - 1 else {
			return false
		}
		return logic.peerInvitationManager(self, shouldInvite: peer, withDiscoveryInfo: discoveryInfo)
	}

	public func shouldAcceptInvitation(from peer: MCPeerID) -> Bool {
		guard session.connectedPeers.count < maximumNumberOfPeers - 1 else {
			return false
		}
		return logic.peerInvitationManager(self, shouldAcceptInvitationFrom: peer)
	}
}

extension PeerInvitationManager {
	public final class HashBasedInvitationLogic: PeerInvitationManagerLogicDelegate {
		public func peerInvitationManager(_ manager: PeerInvitationManager, discoveryInfoFor peer: MCPeerID) -> [String : String]? {
			return ["hash": "\(peer.hashValue)"]
		}

		public func peerInvitationManager(_ manager: PeerInvitationManager, shouldInvite peer: MCPeerID, withDiscoveryInfo info: [String : String]?) -> Bool {
			guard let hash = info?["hash"], hash > "\(manager.session.myPeerID.hashValue)" else {
				return false
			}
			return true
		}

		public func peerInvitationManager(_ manager: PeerInvitationManager, shouldAcceptInvitationFrom peer: MCPeerID) -> Bool {
			return true
		}
	}
}

extension PeerInvitationManager: MCNearbyServiceAdvertiserDelegate {
	public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
		invitationHandler(shouldAcceptInvitation(from: peerID), session)
	}

	public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
		errorDelegate?.peerInvitationManager(self, didNotStartAdvertisingPeer: error)
	}
}

extension PeerInvitationManager: MCNearbyServiceBrowserDelegate {
	public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
		guard shouldInvite(peerID, discoveryInfo: info) else {
			return
		}
		browser.invitePeer(peerID, to: session, withContext: nil, timeout: invitationTimeoutInterval)
	}

	public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

	public func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
		errorDelegate?.peerInvitationManager(self, didNotStartBrowsingPeer: error)
	}
}
