import Foundation
import Nostr

func handleGroupChatMessage(appState: AppState, event: Event) {
    guard let groupId = event.tags.first(where: { $0.id == "h" })?.otherInformation.first else { return }
    guard let id = event.id else { return }
    
    // MARK: これやっぱりリアルタイムを確立するには必要な気がしてきた。後ほど修正。
    //                let userMetadata = self.allUserMetadata.filter({ $0.publicKey == event.pubkey }).first
    let chatMessage = ChatMessageMetadata(
        id: id,
        createdAt: event.createdAt.date,
        groupId: groupId,
        publicKey: event.pubkey,
        content: event.content
    )
    DispatchQueue.main.async {
        appState.allChatMessage.append(chatMessage)
    }
}
