import Foundation
import Nostr

func handleGroupMembers(appState: AppState, event: Event, relayUrl: String) {
    let tags = event.tags.map { $0 }
    
    guard let groupTag = tags.first(where: { $0.id == "d" }),
          let groupId = groupTag.otherInformation.first else {
        return
    }
    
    let publicKeys = tags.filter { $0.id == "p" }.compactMap { $0.otherInformation.first }
    for publicKey in publicKeys {
        let member = GroupMember(
            id: UUID().uuidString,
            publicKey: publicKey,
            groupId: groupId,
            relayUrl: relayUrl
        )
        
        DispatchQueue.main.async {
            appState.allGroupMember.append(member)
        }
    }
    
    // MARK: allChatGroupのisMemberを更新する
    // TODO: もしかしたら、チャット画面を開いた時に更新するの方がいいかもしれない
    if let selectedOwnerAccount = appState.selectedOwnerAccount {
        DispatchQueue.global(qos: .userInitiated).async {
            var updatedChatGroups = appState.allChatGroup
            for i in 0..<updatedChatGroups.count {
                var group = updatedChatGroups[i]
                group.isMember = appState.allGroupMember.first(where: { $0.publicKey == selectedOwnerAccount.publicKey && $0.groupId == group.id }) != nil
                updatedChatGroups[i] = group
            }
            
            DispatchQueue.main.async {
                appState.allChatGroup = updatedChatGroups
            }
        }
    }
}
