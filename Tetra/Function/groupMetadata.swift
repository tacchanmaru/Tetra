import Foundation
import Nostr

func handleGroupMetadata(appState: AppState, event: Event) {
    let targetGroupIds = [
        "c39cbb08b200e6ef876af8b7f053510fa38b251b4789dac5525ea344e9df1908",
        "39984c613072802df81cda7db0adc5e86edbe143eae5fadb38d8d3789f31b070",
        "825f1ed57f20d06d43e93f3cb8207d61ce8cdfff9d9f6722540329c00fba1b44"
    ]
    
    let tags = event.tags.map({ $0 })
    guard let groupId = tags.first(where: { $0.id == "d" })?.otherInformation.first, targetGroupIds.contains(groupId) else {
        return
    }
    let isPublic = tags.first(where: { $0.id == "private" }) == nil
    let isOpen = tags.first(where: { $0.id == "closed" }) == nil
    let name = tags.first(where: { $0.id == "name" })?.otherInformation.first
    let about = tags.first(where: { $0.id == "about" })?.otherInformation.first
    let picture = tags.first(where: { $0.id == "picture" })?.otherInformation.first
    let link = tags.first(where: { $0.id == "r" })?.otherInformation.first
    
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
