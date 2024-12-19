import Foundation

struct ChatMessageMetadata: Identifiable, Hashable {
    var id: String
    var createdAt: Date
    var groupId: String
    var publicKey: String
//    var publicKeyMetadata: PublicKeyMetadata
    var content: String
}
