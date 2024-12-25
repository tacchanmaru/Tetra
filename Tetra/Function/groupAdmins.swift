import Foundation
import Nostr

func handleGroupAdmins(appState: AppState, event: Event, relayUrl: String) {
    let tags = event.tags.map { $0 }
    
    guard let groupTag = tags.first(where: { $0.id == "d" }),
          let groupId = groupTag.otherInformation.first else {
        return
    }
    
    let pTags = tags.filter { $0.id == "p" }.compactMap { $0.otherInformation.first }
    guard let publicKey = pTags.first else { return }
    
    let capabilities: Set<GroupAdmin.Capability> = Set(
        pTags.dropFirst(2).compactMap { GroupAdmin.Capability(rawValue: $0) }
    )
    
    let admin = GroupAdmin(
        id: UUID().uuidString,
        publicKey: publicKey,
        groupId: groupId,
        capabilities: capabilities,
        relayUrl: relayUrl
    )
    
    DispatchQueue.main.async {
        appState.allGroupAdmin.append(admin)
    }
    
    // TODO: もう少し綺麗に書きたい。している作業はallChatGroupsは初めisAdminが全てfalseであるが、それのうち、self.selectedOwnerAccountとself.allGroupAdminのpublicKeyが一致するものはtrueにしている。
    if let selectedOwnerAccount = appState.selectedOwnerAccount {
        DispatchQueue.global(qos: .userInitiated).async {
            var updatedChatGroups = appState.allChatGroup
            for i in 0..<updatedChatGroups.count {
                var group = updatedChatGroups[i]
                group.isAdmin = appState.allGroupAdmin.first(where: { $0.publicKey == selectedOwnerAccount.publicKey }) != nil
                updatedChatGroups[i] = group
            }
            
            DispatchQueue.main.async {
                appState.allChatGroup = updatedChatGroups
            }
        }
    }
}

