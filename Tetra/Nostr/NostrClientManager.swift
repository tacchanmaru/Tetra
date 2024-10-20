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

class NostrClientManager: ObservableObject {
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
        
        let subscription = Subscription(filters: [.init(authors: ["6bcc27d284f7b10c0ec4252ac90d37b3aaeb30a53fadf2ce798d7d47b67d296e"], kinds: [Kind(id: 0)])])
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
    weak var manager: NostrClientManager?
    
    init(manager: NostrClientManager) {
        self.manager = manager
    }
    
    func didReceive(message: Nostr.RelayMessage, relayUrl: String) {
        if case .event(_, let event) = message, event.kind == .setMetadata {
            if let metadata = try? JSONDecoder().decode([String: String].self, from: event.content.data(using: .utf8)!) {
                manager?.updateMetadata(metadata)
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
