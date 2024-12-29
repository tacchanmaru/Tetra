import Foundation
import Nostr

func handleGroupMetadata(appState: AppState, event: Event) {
    let tags = event.tags.map({ $0 })
    guard let groupId = tags.first(where: { $0.id == "d" })?.otherInformation.first else { return }
    let isPublic = tags.first(where: { $0.id == "private"}) == nil
    let isOpen = tags.first(where: { $0.id == "closed" }) == nil
    let name = tags.first(where: { $0.id == "name" })?.otherInformation.first
    let about = tags.first(where: { $0.id == "about" })?.otherInformation.first
    let picture = tags.first(where: { $0.id == "picture" })?.otherInformation.first
    let link = tags.first(where: { $0.id == "r" })?.otherInformation.first
    print("【Debug】rタグ link:", link)
    
    let metadata = ChatGroupMetadata(
        id: groupId,
        relayUrl: appState.selectedNip29Relay?.url ?? "",
        name: name,
        picture: picture,
        about: about,
        isPublic: isPublic,
        isOpen: isOpen,
        isMember: false,
        isAdmin: false,
        link: link
    )
    
    DispatchQueue.main.async {
        appState.allChatGroup.append(metadata)
    }

}
