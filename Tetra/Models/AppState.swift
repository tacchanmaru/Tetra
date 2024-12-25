import Foundation
import SwiftUI
import SwiftData
import KeychainAccess
import NostrClient
import Nostr

class AppState: ObservableObject {
    
    var modelContainer: ModelContainer?
    var nostrClient = NostrClient()
    
    var checkUnverifiedTimer: Timer?
    var checkVerifiedTimer: Timer?
    var checkBusyTimer: Timer?
    
    @Published var registeredNsec: Bool = true
    @Published var selectedOwnerAccount: OwnerAccount?
    @Published var selectedNip29Relay: Relay?
    @Published var selectedGroup: ChatGroupMetadata? {
        didSet {
            chatMessageNumResults = 50
        }
    }
    @Published var allChatGroup: Array<ChatGroupMetadata> = []
    @Published var allChatMessage: Array<ChatMessageMetadata> = []
    @Published var allUserMetadata: Array<UserMetadata> = []
    @Published var allGroupAdmin: Array<GroupAdmin> = []
    
    @Published var chatMessageNumResults: Int = 50
    
    @Published var statuses: [String: Bool] = [:]
    
    @Published var ownerPostContents: Array<PostMetadata> = []
    @Published var profileMetadata: ProfileMetadata?
    
    init() {
        nostrClient.delegate = self
    }
    
    // MARK: - Context/Model helpers
    
    func backgroundContext() -> ModelContext? {
        guard let modelContainer else { return nil }
        return ModelContext(modelContainer)
    }
    
    func getModels<T: PersistentModel>(context: ModelContext, modelType: T.Type, predicate: Predicate<T>) -> [T]? {
        let descriptor = FetchDescriptor<T>(predicate: predicate)
        return try? context.fetch(descriptor)
    }
    
    func getOwnerAccount(forPublicKey publicKey: String, modelContext: ModelContext?) async -> OwnerAccount? {
        let desc = FetchDescriptor<OwnerAccount>(predicate: #Predicate<OwnerAccount>{ pkm in
            pkm.publicKey == publicKey
        })
        return try? modelContext?.fetch(desc).first
    }
    
    
    // MARK: SwiftDataに保存されている自分のデータを取得し、そこからプロフィール/タイムラインのデータを取得する。
    @MainActor
    func setupYourOwnMetadata() async {
        var selectedAccountDescriptor = FetchDescriptor<OwnerAccount>(predicate: #Predicate { $0.selected })
        var selectedMetadataRelayDesctiptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip1 && !$0.supportsNip29 })
        selectedAccountDescriptor.fetchLimit = 1
        selectedMetadataRelayDesctiptor.fetchLimit = 1

        guard
            let context = modelContainer?.mainContext,
            let selectedMetadataRelay = try? context.fetch(selectedMetadataRelayDesctiptor).first
        else {
            print("Context or selectedMetadataRelay is nil.")
            return
        }

        do {
            let fetchedAccounts = try context.fetch(selectedAccountDescriptor).first
            self.selectedOwnerAccount = fetchedAccounts

            if let account = self.selectedOwnerAccount {
                let publicKey = account.publicKey
                let metadataSubscription = Subscription(filters: [.init(authors: [publicKey], kinds: [Kind.setMetadata])])
                nostrClient.add(relayWithUrl: selectedMetadataRelay.url, subscriptions: [metadataSubscription] )
            }
        } catch {
            print("Error fetching selected account: \(error)")
        }
    }
    
    // MARK: GroupのAdminの名前などのMetadataを取得する（本当はMemberにしたい）
    @MainActor
    func connectAllMetadataRelays() async {
        let relaysDescriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip1 && !$0.supportsNip29 })
        guard let relay = try? modelContainer?.mainContext.fetch(relaysDescriptor).first else { return }
        
        var pubkeys = [String]()
        print("self.allGroupAdmin: \(self.allGroupAdmin)")
        for admin in self.allGroupAdmin {
            pubkeys.append(admin.publicKey)
        }
        
        let metadataSubscription = Subscription(filters: [Filter(authors: pubkeys, kinds: [Kind.setMetadata])], id: IdSubPublicMetadata)
        nostrClient.add(relayWithUrl: relay.url, subscriptions: [metadataSubscription])
    }
    
    // MARK: NIP-29対応のリレーにグループの情報（グループ名など）を取得しにいく
    @MainActor
    func connectAllNip29Relays() async {
        let descriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip29 })
        if let relay = try? modelContainer?.mainContext.fetch(descriptor).first {
            let groupMetadataSubscription = Subscription(filters: [Filter(kinds: [Kind.groupMetadata])], id: IdSubGroupList)
            nostrClient.add(relayWithUrl: relay.url, subscriptions: [groupMetadataSubscription])
            self.selectedNip29Relay = relay
        }
    }
    
    @MainActor
    func subscribeGroups() async {
        let descriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip29 })
        if let relay = try? modelContainer?.mainContext.fetch(descriptor).first {
            let groupIds = self.allChatGroup.compactMap({ $0.id }).sorted()
            let groupMessageSubscription = Subscription(filters: [
                Filter(kinds: [Kind.groupChatMessage], since: nil, tags: [Tag(id: "h", otherInformation: groupIds)]),
            ], id: IdSubChatMessages)
            
            nostrClient.add(relayWithUrl: relay.url, subscriptions: [groupMessageSubscription])
        }
    }
    
    @MainActor
    func subscribeGroupMemberships() async {
        //        let descriptor = FetchDescriptor<ChatGroup>(predicate: #Predicate { $0.relayUrl == relayUrl  })
        //        if let events = try? modelContainer?.mainContext.fetch(descriptor) {
        //
        //            // Get latest message and use since filter so we don't keep getting the same shit
        //            // let since = events.min(by: { $0.createdAt > $1.createdAt })
        //            // TODO: use the since filter
        //            let groupIds = events.compactMap({ $0.id }).sorted()
        //            let sub = Subscription(filters: [
        //                Filter(kinds: [
        //                    Kind.groupAddUser,
        //                    Kind.groupRemoveUser
        //                ], since: nil, tags: [Tag(id: "h", otherInformation: groupIds)]),
        //            ], id: IdSubGroupMembers)
        //
        //            nostrClient.add(relayWithUrl: relayUrl, subscriptions: [sub])
        //        }
    }
    
    @MainActor
    func subscribeGroupAdmin() async {
        print("はい")
        let descriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip29 })
        //        let descriptor = FetchDescriptor<ChatGroup>(predicate: #Predicate { $0.relayUrl == relayUrl  })
        //        if let events = try? modelContainer?.mainContext.fetch(descriptor) {

        // Get latest message and use since filter so we don't keep getting the same shit
        // let since = events.min(by: { $0.createdAt > $1.createdAt })
        // TODO: use the since filter
        
        let groupIds = self.allChatGroup.compactMap({ $0.id }).sorted()
        let groupAdminSubscription = Subscription(filters: [
            Filter(kinds: [
                Kind.groupAdmins
            ], since: nil, tags: [Tag(id: "d", otherInformation: groupIds)]),
        ], id: IdSubGroupAdmins)
        
        if let relay = try? modelContainer?.mainContext.fetch(descriptor).first {
            nostrClient.add(relayWithUrl: relay.url, subscriptions: [groupAdminSubscription])
        }
    }
    
    @MainActor
    func removeDataFor(relayUrl: String) async {
        Task.detached {
            guard let modelContext = self.backgroundContext() else { return }
            //try? modelContext.delete(model: DBEvent.self, where: #Predicate<DBEvent> { $0.relayUrl == relayUrl })
            try? modelContext.save()
        }
    }
    
    @MainActor
    func updateRelayInformationForAll() async {
        Task.detached {
            guard let modelContext = self.backgroundContext() else { return }
            guard let relays = try? modelContext.fetch(FetchDescriptor<Relay>()) else { return }
            await withTaskGroup(of: Void.self) { group in
                for relay in relays {
                    group.addTask {
                        await relay.updateRelayInfo()
                    }
                }
                try? modelContext.save()
            }
        }
    }
    
    // MARK: - Profile Metadata
    
    func getProfileMetadata(for key: String) -> ProfileMetadata? {
        return profileMetadata
    }
    
    func saveProfileMetadata(for key: String, pubkey: String, name: String?, picture: String?, about: String?) {
        let metadata = ProfileMetadata(id: key, pubkey: pubkey, name: name, picture: picture, about: about)
        DispatchQueue.main.async {
            self.profileMetadata = metadata
        }
    }
    
    // MARK: - Timeline handling (owner's posts)
    
    func subscribeToPostsForOwner() {
        guard let public_key = selectedOwnerAccount?.publicKey else { return }
        let postSubscription = Subscription(filters: [.init(authors: [public_key], kinds: [Kind.textNote])])
        nostrClient.add(subscriptions: [postSubscription])
    }
    
    func appendOwnerPost(_ post: PostMetadata) {
        DispatchQueue.main.async {
            self.ownerPostContents.append(post)
        }
    }
    
    func formatNostrTimestamp(_ nostrTimestamp: Nostr.Timestamp) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(nostrTimestamp.timestamp))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: date)
    }
    
    func sortOwnerPostsByTimestamp() {
        DispatchQueue.main.async {
            self.ownerPostContents.sort { post1, post2 in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
                if let date1 = dateFormatter.date(from: post1.timeStamp),
                   let date2 = dateFormatter.date(from: post2.timeStamp) {
                    return date1 > date2
                }
                return false
            }
        }
    }
    
    // MARK: - Relay / Chat Management
    
    public func remove(relaysWithUrl relayUrls: [String]) {
        for relayUrl in relayUrls {
            self.nostrClient.remove(relayWithUrl: relayUrl)
        }
    }
    
    // MARK: この関数により、GroupAdminを一つずつ設定できる。
    func handleGroupAdmin(event: Event, relayUrl: String) {
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
            self.allGroupAdmin.append(admin)
        }
        
        // TODO: もう少し綺麗に書きたい。している作業はallChatGroupsは初めisAdminが全てfalseであるが、それのうち、self.selectedOwnerAccountとself.allGroupAdminのpublicKeyが一致するものはtrueにしている。
        if let selectedOwnerAccount = self.selectedOwnerAccount {
            DispatchQueue.global(qos: .userInitiated).async {
                var updatedChatGroups = self.allChatGroup
                for i in 0..<updatedChatGroups.count {
                    var group = updatedChatGroups[i]
                    group.isAdmin = self.allGroupAdmin.first(where: { $0.publicKey == selectedOwnerAccount.publicKey }) != nil
                    updatedChatGroups[i] = group
                }
                
                DispatchQueue.main.async {
                    self.allChatGroup = updatedChatGroups
                }
            }
        }
    }
    
    func process(event: Event, relayUrl: String) {
        Task.detached {
            
            switch event.kind {
            case Kind.setMetadata:
                if let jsonData = event.content.data(using: .utf8),
                   let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                    let name = jsonObject["display_name"] as? String
                    let picture = jsonObject["picture"] as? String
                    let about = jsonObject["about"] as? String
                    
                    if event.pubkey == self.selectedOwnerAccount?.publicKey {
                        self.saveProfileMetadata(
                            for: event.pubkey,
                            pubkey: event.pubkey,
                            name: name,
                            picture: picture,
                            about: about
                        )
                        // タイムライン用
                        self.subscribeToPostsForOwner()
                    }
                    
                    let userMetadata = UserMetadata(
                        publicKey: event.pubkey,
                        bech32PublicKey: {
                            guard let bech32PublicKey = try? event.pubkey.bech32FromHex(hrp: "npub") else {
                                return ""
                            }
                            return bech32PublicKey
                        }(),
                        name: name,
                        about: about,
                        picture: picture,
                        createdAt: event.createdAt.date,
                        nip05Verified: false
                    )
                    DispatchQueue.main.async {
                        self.allUserMetadata.append(userMetadata)
                        self.allChatMessage = self.allChatMessage.map { message in
                            var updatedMessage = message
                            if updatedMessage.publicKey == event.pubkey {
                                updatedMessage.userMetadata = userMetadata
                            }
                            return updatedMessage
                        }
                        
                    }
                }
                
            case Kind.textNote:
                if let metadata = self.getProfileMetadata(for: event.pubkey) {
                    let timeStampString = self.formatNostrTimestamp(event.createdAt)
                    let post = PostMetadata(
                        id: UUID().uuidString,
                        text: event.content,
                        name: metadata.name,
                        picture: metadata.picture,
                        timeStamp: timeStampString
                    )
                    self.appendOwnerPost(post)
                    self.sortOwnerPostsByTimestamp()
                }
                
            case Kind.groupMetadata:
                let tags = event.tags.map({ $0 })
                guard let groupId = tags.first(where: { $0.id == "d" })?.otherInformation.first else { return }
                let isPublic = tags.first(where: { $0.id == "private"}) == nil
                let isOpen = tags.first(where: { $0.id == "closed" }) == nil
                let name = tags.first(where: { $0.id == "name" })?.otherInformation.first
                let about = tags.first(where: { $0.id == "about" })?.otherInformation.first
                let picture = tags.first(where: { $0.id == "picture" })?.otherInformation.first
                
                let metadata = ChatGroupMetadata(
                    id: groupId,
                    relayUrl: self.selectedNip29Relay?.url ?? "",
                    name: name,
                    picture: picture,
                    about: about,
                    isPublic: isPublic,
                    isOpen: isOpen,
                    isMember: false,
                    isAdmin: false
                )
                
                DispatchQueue.main.async {
                    self.allChatGroup.append(metadata)
                }
                
            case Kind.groupAdmins:
                self.handleGroupAdmin(event: event, relayUrl: relayUrl)
                
            case Kind.groupChatMessage:
                
                guard let groupId = event.tags.first(where: { $0.id == "h" })?.otherInformation.first else { return }
                guard let id = event.id else { return }
                
                // MARK: これやっぱりリアルタイムを確立するには必要な気がしてきた。
//                let userMetadata = self.allUserMetadata.filter({ $0.publicKey == event.pubkey }).first
                let chatMessage = ChatMessageMetadata(
                    id: id,
                    createdAt: event.createdAt.date,
                    groupId: groupId,
                    publicKey: event.pubkey,
                    content: event.content
                )
                DispatchQueue.main.async {
                    self.allChatMessage.append(chatMessage)
                }
                
                
            case Kind.groupAddUser:
                print(event)
                
            case Kind.groupRemoveUser:
                print(event)
                
            default:
                print("event.kind: ", event.kind)
            }
        }
    }
    
    // MARK: - Group actions
    
    func joinGroup(ownerAccount: OwnerAccount, group: ChatGroupMetadata) {
        guard let key = ownerAccount.getKeyPair() else { return }
        let relayUrl = group.relayUrl
        let groupId = group.id
        var joinEvent = Event(pubkey: ownerAccount.publicKey,
                              createdAt: .init(),
                              kind: .groupJoinRequest,
                              tags: [Tag(id: "h", otherInformation: groupId)],
                              content: "")
        
        do {
            try joinEvent.sign(with: key)
        } catch {
            print(error.localizedDescription)
        }
        
        nostrClient.send(event: joinEvent, onlyToRelayUrls: [relayUrl])
    }
    
    // MARK: - Send Message
    
    @MainActor
    func sendChatMessage(ownerAccount: OwnerAccount, group: ChatGroupMetadata, withText text: String) async {
        guard let key = ownerAccount.getKeyPair() else { return }
        let relayUrl = group.relayUrl
        let groupId = group.id
        
        var event = Event(pubkey: ownerAccount.publicKey,
                          createdAt: .init(),
                          kind: .groupChatMessage,
                          tags: [Tag(id: "h", otherInformation: groupId)],
                          content: text)
        do {
            try event.sign(with: key)
        } catch {
            print(error.localizedDescription)
        }
        
        if let clientMessage = try? ClientMessage.event(event).string() {
            print(clientMessage)
        }
        
//        guard let mainContext = modelContainer?.mainContext else { return }
        let _ = ownerAccount.publicKey
//        let ownerPublicKeyMetadata = try? mainContext.fetch(FetchDescriptor(predicate: #Predicate<PublicKeyMetadata> { $0.publicKey == publicKey })).first
//        if let chatMessage = ChatMessage(event: event, relayUrl: relayUrl) {
//            chatMessage.publicKeyMetadata = ownerPublicKeyMetadata
//            withAnimation {
//                mainContext.insert(chatMessage)
//                try? mainContext.save()
//            }
//            nostrClient.send(event: event, onlyToRelayUrls: [relayUrl])
//        }
    }
    
    @MainActor
    func sendChatMessageReply(ownerAccount: OwnerAccount, withText text: String) async {
        guard let key = ownerAccount.getKeyPair() else { return }
        let relayUrl = selectedGroup?.relayUrl ?? ""
        let groupId = selectedGroup?.id ?? ""
        
        var tags: [Tag] = [Tag(id: "h", otherInformation: groupId)]
        // if let rootEventId = replyChatMessage.rootEventId { ... }
        
        var event = Event(pubkey: ownerAccount.publicKey,
                          createdAt: .init(),
                          kind: .groupChatMessage,
                          tags: tags,
                          content: text)
        do {
            try event.sign(with: key)
        } catch {
            print(error.localizedDescription)
        }
        
        let publicKey = ownerAccount.publicKey
        let ownerUserMetadata = self.allUserMetadata.filter({ $0.publicKey == publicKey }).first
        var chatMessage = allChatMessage.filter({ $0.publicKey == publicKey }).first
        chatMessage?.userMetadata = ownerUserMetadata
        
        nostrClient.send(event: event, onlyToRelayUrls: [relayUrl])
    }
    
    func copyToClipboard(_ string: String) {
        UIPasteboard.general.string = string
    }
    
}

// MARK: - NostrClientDelegate

extension AppState: NostrClientDelegate {
    func didConnect(relayUrl: String) {
        DispatchQueue.main.async {
            self.statuses[relayUrl] = true
        }
    }
    
    func didDisconnect(relayUrl: String) {
        DispatchQueue.main.async {
            self.statuses[relayUrl] = false
        }
    }
    
    func didReceive(message: Nostr.RelayMessage, relayUrl: String) {
        switch message {
        case .event(_, let event):
            if event.isValid() {
                process(event: event, relayUrl: relayUrl)
            } else {
                print("\(event.id ?? "") is an invalid event on \(relayUrl)")
            }
        case .notice(let notice):
            print("case: .notice")
            print(notice)
        case .ok(let id, let acceptance, let m):
            print("case: .ok")
            print(id, acceptance, m)
        case .eose(let id):
            // MARK: EOSE(End of Stored Events Notice)はリレーから保存済み情報の終わり(ここから先はストリーミング)である旨を通知する仕組み。
            switch id {
            case IdSubGroupList:
                Task {
                    print("初めに動くべき関数の処理が終わったら動くべき関数")
                    await subscribeGroups()
                    await subscribeGroupMemberships()
                    await subscribeGroupAdmin()
//                    await connectAllMetadataRelays()
                }
            default:
                ()
            }
        case .closed(let id, let message):
            print("case: .closed")
            print(id, message)
        case .other(let other):
            print("case: .other")
            print(other)
        case .auth(let challenge):
            print("Auth: \(challenge)")
        }
    }
}
