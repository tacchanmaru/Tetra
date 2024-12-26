import Foundation
import Nostr

func handleGroupMembers(appState: AppState, event: Event, relayUrl: String) {
    //TODO: Memberはそれぞれのグループに対して複数存在する。なので、Adminとは違ってfirstなどは使えないことを覚えておく。
    let tags = event.tags.map { $0 }
    
    guard let groupTag = tags.first(where: { $0.id == "d" }),
          let groupId = groupTag.otherInformation.first else {
        return
    }
    print("groupId: \(groupId)")
    
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
    
    
    
//    // TODO: もう少し綺麗に書きたい。している作業はallChatGroupsは初めisAdminが全てfalseであるが、それのうち、self.selectedOwnerAccountとself.allGroupAdminのpublicKeyが一致するものはtrueにしている。
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
