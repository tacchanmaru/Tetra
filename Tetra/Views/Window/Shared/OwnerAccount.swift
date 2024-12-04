import Foundation
import SwiftData
import KeychainAccess
import Nostr

@Model final class OwnerAccount {
    
    @Attribute(.unique) var publicKey: String
    var selected: Bool
    var metadataRelayIds: Set<String>
    var messageRelayIds: Set<String>
    
    init(publicKey: String, selected: Bool, metadataRelayIds: Set<String>, messageRelayIds: Set<String>) {
        self.publicKey = publicKey
        self.selected = selected
        self.metadataRelayIds = metadataRelayIds
        self.messageRelayIds = messageRelayIds
    }
    
    var bestPublicName: String {
        return publicKey
    }
    
    func getKeyPair() -> KeyPair? {
        let keychain = Keychain(service: "tetra")
        guard let privateKey = try? keychain.getString(publicKey) else {
            return nil
        }
        return try? KeyPair(hex: privateKey)
    }
    
    func removeKeyPair() {
        if let keyPair = getKeyPair() {
            OwnerAccount.removeKeyPairFromKeychain(keyPair: keyPair)
        }
    }

}

extension OwnerAccount {
    
    // TODO: 新規登録に必要な部分なので後ほど実装
//    static func createNew() -> OwnerAccount? {
//        if let keypair = try? KeyPair() {
//            OwnerAccount.saveKeyPairToKeychain(keyPair: keypair)
//            return OwnerAccount(publicKey: keypair.publicKey, selected: false, metadataRelayIds: [], messageRelayIds: [])
//        }
//        return nil
//    }
    
    static func restore(withPrivateKeyHexOrNsec k: String) -> OwnerAccount? {
        if k.hasPrefix("nsec") {
            if let keypair = try? KeyPair(bech32PrivateKey: k) {
                OwnerAccount.saveKeyPairToKeychain(keyPair: keypair)
                print("publicKey:", keypair.publicKey)
                return OwnerAccount(publicKey: keypair.publicKey, selected: false, metadataRelayIds: [], messageRelayIds: [])
            }
        } else {
            if let keypair = try? KeyPair(hex: k) {
                OwnerAccount.saveKeyPairToKeychain(keyPair: keypair)
                return OwnerAccount(publicKey: keypair.publicKey, selected: false, metadataRelayIds: [], messageRelayIds: [])
            }
        }
        return nil
    }
    
    static func saveKeyPairToKeychain(keyPair: KeyPair) {
        let keychain = Keychain(service: "seer")
        try? keychain.set(keyPair.privateKey, key: keyPair.publicKey)
    }
    
    static func removeKeyPairFromKeychain(keyPair: KeyPair) {
        let keychain = Keychain(service: "seer")
        try? keychain.remove(keyPair.publicKey)
    }
    
}
