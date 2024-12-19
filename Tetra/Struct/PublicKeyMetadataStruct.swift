import Foundation

struct PublicKeyMetadata: Encodable, Hashable {
    var publicKey: String
    var bech32PublicKey: String
    
    var name: String?
    var about: String?
    var picture: String?
    var nip05: String?
    var lud06: String?
    var lud16: String?
    var createdAt: Date
    var nip05Verified: Bool
}

