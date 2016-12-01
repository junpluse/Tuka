//
//  MCPeerID+Tuka.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/17.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation
import MultipeerConnectivity

extension MCPeerID: PeerProtocol {}

extension MCPeerID {
	public struct Tuka {
		public static let defaultPeerKey = "com.junpluse.Tuka.MCPeerID.default"

		public static var defaultPeer: MCPeerID {
			let name = UIDevice.current.name

			if
				let data = UserDefaults.standard.data(forKey: defaultPeerKey),
				let peer = NSKeyedUnarchiver.unarchiveObject(with: data) as? MCPeerID,
				peer.displayName == name {
				return peer
			}

			let peer = MCPeerID(displayName: name)
			let data = NSKeyedArchiver.archivedData(withRootObject: peer)
			UserDefaults.standard.set(data, forKey: defaultPeerKey)
			
			return peer
		}
	}
}
