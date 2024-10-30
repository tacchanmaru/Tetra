//
//  NostrClientManager.swift
//  Tetra
//
//  Created by yugoatobe on 10/19/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import NostrClient
import Nostr

class NostrMetadataManager: ObservableObject {
    private var client: NostrClient
    private lazy var delegate: NostrDelegate = NostrDelegate(manager: self)
    
    @Published var accountName: String = ""
    @Published var displayName: String = ""
    @Published var about: String = ""
    @Published var pictureUrl: String = ""
    
    init() {
        client = NostrClient()
        client.delegate = delegate
        client.add(relayWithUrl: "wss://relay.damus.io", autoConnect: true)
        
        let subscription = Subscription(filters: [.init(authors: ["670874fa6dd544edc5867763ce793552396aedda1a5fda3a97949f66ab0acfb3"], kinds: [Kind(id: 0)])])
        client.add(subscriptions: [subscription])
    }
    
    func updateMetadata(_ metadata: [String: String]) {
        DispatchQueue.main.async {
            self.accountName = metadata["name"] ?? ""
            self.displayName = metadata["displayName"] ?? ""
            self.about = metadata["about"] ?? ""
            self.pictureUrl = metadata["picture"] ?? ""
        }
    }
}

class NostrDelegate: NostrClientDelegate {
    weak var manager: NostrMetadataManager?
    
    init(manager: NostrMetadataManager) {
        self.manager = manager
    }
    
    func didReceive(message: Nostr.RelayMessage, relayUrl: String) {
        
        if case .event(_, let event) = message, event.kind == .setMetadata {
            
            
            if let metadata = try? JSONDecoder().decode([String: String].self, from: event.content.data(using: .utf8)!) {
                print("Decoded metadata: \(metadata)")
                manager?.updateMetadata(metadata)
            }
            else {
                print("Failed to decode metadata")
            }
        }
    }
    
    func didConnect(relayUrl: String) {
        print("Connected to \(relayUrl)")
    }
    
    func didDisconnect(relayUrl: String) {
        print("Disconnected from \(relayUrl)")
    }
}
