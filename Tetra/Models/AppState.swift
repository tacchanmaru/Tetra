import Foundation
import SwiftUI
import SwiftData
import KeychainAccess
import NostrClient
import Nostr

let IdSubChatMessages = "IdSubChatMessages"
let IdSubPublicMetadata = "IdPublicMetadata"
let IdSubOwnerMetadata = "IdOwnerMetadata"
let IdSubGroupList = "IdGroupList"
let IdSubGroupMembers = "IdSubGroupMembers"
let IdSubGroupAdmins = "IdSubGroupAdmins"

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
    @Published var allPublicKeyMetadata: Array<PublicKeyMetadata> = []
    
    
    @Published var chatMessageNumResults: Int = 50
    
    @Published var statuses: [String: Bool] = [:]
    
    @Published var ownerPostContents: Array<Post> = []
    @Published var ownerMetadata: Metadata?
    
    init() {
        nostrClient.delegate = self
    }
    
    @MainActor
    func initialSetup() async {

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
            let fetchedAccounts = try context.fetch(selectedAccountDescriptor)
            self.selectedOwnerAccount = fetchedAccounts.first

            if let account = self.selectedOwnerAccount {

                let publicKey = account.publicKey
                nostrClient.add(relayWithUrl: selectedMetadataRelay.url, autoConnect: true)
                let metadataSubscription = Subscription(filters: [.init(authors: [publicKey], kinds: [Kind.setMetadata])])
                nostrClient.add(subscriptions: [metadataSubscription])
            }
        } catch {
            print("Error fetching selected account: \(error)")
        }
    }

    
    
    //全てのアカウント（自分と、その他のチャットを行う人）の名前などのMetadataを取得する
    @MainActor func connectAllMetadataRelays() async {
        
        //メタデータ用のリレー
        let relaysDescriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip1 && !$0.supportsNip29 })
        guard let relay = try? modelContainer?.mainContext.fetch(relaysDescriptor).first else { return }
        
        var selectedAccountDescriptor = FetchDescriptor<OwnerAccount>(predicate: #Predicate { $0.selected })
        selectedAccountDescriptor.fetchLimit = 1
        guard let selectedAccount = try? modelContainer?.mainContext.fetch(selectedAccountDescriptor).first else { return }
        
        var pubkeys = Set([selectedAccount.publicKey])
        
        
//        let membersDescriptor = FetchDescriptor<GroupMember>()
//        if let members = try? modelContainer?.mainContext.fetch(membersDescriptor) {
//            for member in members {
//                pubkeys.insert(member.publicKey)
//            }
//        }
        
//        let adminsDescriptor = FetchDescriptor<GroupAdmin>()
//        if let admins = try? modelContainer?.mainContext.fetch(adminsDescriptor) {
//            for admin in admins {
//                print("Adminユーザー：\(admin.publicKey)")
////                pubkeys.insert(admin.publicKey)
//            }
//        }
        
        let sortedPubkeys = Array(pubkeys).sorted()
        
        nostrClient.add(relayWithUrl: relay.url, subscriptions: [
            // メンバーのメタデータを取得できるようになる
            Subscription(filters: [
                Filter(authors: sortedPubkeys, kinds: [
                    .setMetadata,
                ])
            ], id: IdSubPublicMetadata),
            //これより下いるんか？
            Subscription(filters: [
                Filter(authors: [selectedAccount.publicKey], kinds: [
                    .setMetadata,
                ])
            ], id: IdSubOwnerMetadata)
        ])
        nostrClient.connect(relayWithUrl: relay.url)
    }
    
    //NIP-29対応のリレーにグループのメタデータ（メンバーなど？）を取得しにいく
    @MainActor func connectAllNip29Relays() async {
        let descriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip29 })
        if let relay = try? modelContainer?.mainContext.fetch(descriptor).first {
            nostrClient.add(relayWithUrl: relay.url, subscriptions: [
                Subscription(filters: [ Filter(kinds: [ Kind.groupMetadata ]) ], id: IdSubGroupList)]
            )
            self.selectedNip29Relay = relay
        }
    }
    
    func getOwnerMetadata(for key: String) -> (Metadata)? {
        return ownerMetadata
    }
    
    func saveOwnerMetadata(for key: String, pubkey: String, name: String?, picture: String?, about: String?) {
        let metadata = Metadata(id: key, pubkey: pubkey, name: name, picture: picture, about: about)
        
        DispatchQueue.main.async {
            self.ownerMetadata = metadata
        }
    }
    
    // MARK: ここから下タイムラインの内容なので最終的には必要ない
    
    func subscribeToPostsForOwner() {
        guard let public_key = selectedOwnerAccount?.publicKey else { return }
        let postSubscription = Subscription(filters: [.init(authors: [public_key], kinds: [Kind.textNote])])
        nostrClient.add(subscriptions: [postSubscription])
    }
    
    func appendOwnerPost(_ post: Post) {
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
    
    
    // This function is meant to be called anytime there has been a change
    // In subscriptions, etc. It should handle the case where it's simply
    // a no-op if nothing has actually changed in subscriptions, etc.
    @MainActor func subscribeGroups(withRelayUrl relayUrl: String) async {
        
//        let descriptor = FetchDescriptor<ChatGroup>(predicate: #Predicate { $0.relayUrl == relayUrl  })
//        if let events = try? modelContainer?.mainContext.fetch(descriptor) {
            
            // Get latest message and use since filter so we don't keep getting the same shit
            //let since = events.min(by: { $0.createdAt > $1.createdAt })
            // TODO: use the since fitler
        let groupIds = self.allChatGroup.compactMap({ $0.id }).sorted()
        let sub = Subscription(filters: [
            Filter(kinds: [
                Kind.groupChatMessage,
                Kind.groupChatMessageReply,
                Kind.groupForumMessage,
                //Kind.groupForumMessageReply
            ], since: nil, tags: [Tag(id: "h", otherInformation: groupIds)]),
        ], id: IdSubChatMessages)
            
        nostrClient.add(relayWithUrl: relayUrl, subscriptions: [sub])
//        }
    }
    
    @MainActor func subscribeGroupMemberships(withRelayUrl relayUrl: String) async {
        
//        let descriptor = FetchDescriptor<ChatGroup>(predicate: #Predicate { $0.relayUrl == relayUrl  })
//        if let events = try? modelContainer?.mainContext.fetch(descriptor) {
//            
//            // Get latest message and use since filter so we don't keep getting the same shit
//            //let since = events.min(by: { $0.createdAt > $1.createdAt })
//            // TODO: use the since fitler
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
    
    @MainActor func subscribeGroupAdmins(withRelayUrl relayUrl: String) async {
        
//        let descriptor = FetchDescriptor<ChatGroup>(predicate: #Predicate { $0.relayUrl == relayUrl  })
//        if let events = try? modelContainer?.mainContext.fetch(descriptor) {
            
            // Get latest message and use since filter so we don't keep getting the same shit
            //let since = events.min(by: { $0.createdAt > $1.createdAt })
            // TODO: use the since fitler
            let groupIds = self.allChatGroup.compactMap({ $0.id }).sorted()
            let sub = Subscription(filters: [
                Filter(kinds: [
                    Kind.groupAdmins
                ], since: nil, tags: [Tag(id: "d", otherInformation: groupIds)]),
            ], id: IdSubGroupAdmins)
            
            nostrClient.add(relayWithUrl: relayUrl, subscriptions: [sub])
//        }
    }
    
    public func remove(relaysWithUrl relayUrls: [String]) {
        for relayUrl in relayUrls {
            self.nostrClient.remove(relayWithUrl: relayUrl)
        }
    }
    
    @MainActor
    func removeDataFor(relayUrl: String) async -> Void {
        Task.detached {
            guard let modelContext = self.backgroundContext() else { return }
            //try? modelContext.delete(model: DBEvent.self, where: #Predicate<DBEvent> { $0.relayUrl == relayUrl })
            try? modelContext.save()
        }
        print("Completed")
    }
    
    @MainActor
    func updateRelayInformationForAll() async -> Void {
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
    
    //GroupAdminの情報をとってくる
    func handleGroupAdmins(event: Event, relayUrl: String) {
        let tags = event.tags.map { $0 }

        guard let groupTag = tags.first(where: { $0.id == "d" }),
              let groupId = groupTag.otherInformation.first else {
            return
        }

        let pTags = tags.filter { $0.id == "p" }
        let pOtherInfos: [[String]] = pTags.compactMap { $0.otherInformation }

        var allAdmins: [GroupAdminMetadata] = []
        for info in pOtherInfos {
            guard let publicKey = info.first else { continue }

            let capabilities: Set<GroupAdminMetadata.Capability> = Set(
                info.dropFirst(2).compactMap { GroupAdminMetadata.Capability(rawValue: $0) }
            )

            let admin = GroupAdminMetadata(
                id: UUID().uuidString,
                publicKey: publicKey,
                groupId: groupId,
                capabilities: capabilities,
                relayUrl: relayUrl
            )

            if admin.publicKey.isValidPublicKey {
                allAdmins.append(admin)
            }
        }

        for i in 0..<allAdmins.count {
            var admin = allAdmins[i]
            admin.publicKeyMetadata = self.allPublicKeyMetadata.first(where: { $0.publicKey == admin.publicKey })
            allAdmins[i] = admin
        }

//        let adminPublicKeys = allAdmins.map { $0.publicKey }

        if let selectedOwnerAccount = self.selectedOwnerAccount {
            DispatchQueue.global(qos: .userInitiated).async {
                var updatedChatGroups = self.allChatGroup
                for i in 0..<updatedChatGroups.count {
                    var group = updatedChatGroups[i]
                    group.isAdmin = allAdmins.first(where: { $0.publicKey == selectedOwnerAccount.publicKey }) != nil
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
            
            let publicKey = event.pubkey
            guard let eventId = event.id else { return }
            
            guard let modelContext = self.backgroundContext() else { return }
            switch event.kind {
                
            case Kind.setMetadata:
//                if let jsonData = event.content.data(using: .utf8),
//                   let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
//                    print("publicKey: \(publicKey)")
//                    let name = jsonObject["display_name"] as? String
//                    let picture = jsonObject["picture"] as? String
//                    let about = jsonObject["about"] as? String
//
//                    self.saveOwnerMetadata(
//                        for: event.pubkey,
//                        pubkey: event.pubkey,
//                        name: name,
//                        picture: picture,
//                        about: about
//                    )
//                    if self.ownerPostContents.isEmpty {
//                        self.subscribeToPostsForOwner()
//                    }
//                    
//                }
                
                let publicKeyMetadata = PublicKeyMetadata(
                    publicKey: event.pubkey,
                    bech32PublicKey: {
                        guard let bech32PublicKey = try? event.pubkey.bech32FromHex(hrp: "npub") else {
                            return ""
                        }
                        return bech32PublicKey
                    }(),
                    createdAt: event.createdAt.date,
                    nip05Verified: false
                )
                DispatchQueue.main.async {
                    self.allChatMessage = self.allChatMessage.map { message in
                        var updatedMessage = message
                        if updatedMessage.publicKey == publicKey {
                            updatedMessage.publicKeyMetadata = publicKeyMetadata
                        }
                        return updatedMessage
                    }
                }
                
            
            case Kind.textNote:
                if let metadata = self.getOwnerMetadata(for: event.pubkey) {
                    let timeStampString = self.formatNostrTimestamp(event.createdAt)
                    let post = Post(
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
//                print("event.kind: \(event.kind)")
//                print("event.tag: \(event.tags)")
                let tags = event.tags.map({ $0 })
                guard let groupId = tags.first(where: { $0.id == "d" })?.otherInformation.first else { return  }
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
//                    print("exact metadata: \(metadata)")
                    self.allChatGroup.append(metadata)
                }
                
//                if let group = ChatGroup(event: event, relayUrl: relayUrl) {
//                    let groupId = group.id
//                    modelContext.insert(group)
//                    
//                    if let selectedOwnerAccount = self.selectedOwnerAccount {
//                        
//                        let selectedOwnerPublicKey = selectedOwnerAccount.publicKey
//                        
//                        group.isMember = self.getModels(context: modelContext, modelType: GroupMember.self,
//                                                        predicate: #Predicate<GroupMember> { $0.publicKey == selectedOwnerPublicKey && $0.groupId == groupId && $0.relayUrl == relayUrl })?.first != nil
//                        
//                        group.isAdmin = self.getModels(context: modelContext, modelType: GroupAdmin.self,
//                                                       predicate: #Predicate<GroupAdmin> { $0.publicKey == selectedOwnerPublicKey && $0.groupId == groupId  && $0.relayUrl == relayUrl })?.first != nil
//                        
//                    }
//                    
//                    try? modelContext.save()
//                    
//                }
                
            case Kind.groupAdmins:
                self.handleGroupAdmins(event: event, relayUrl: relayUrl)
                
                //                case Kind.groupMembers:
                //
                //                    let tags = event.tags.map({ $0 })
                //                    if let groupId = tags.first(where: { $0.id == "d" })?.otherInformation.first {
                //                        let members = tags.filter({ $0.id == "p" })
                //                            .compactMap({ $0.otherInformation.last })
                //                            .filter({ $0.isValidPublicKey })
                //                            .map({ GroupMember(publicKey: $0, groupId: groupId, relayUrl: relayUrl) })
                //
                //                        for member in members {
                //                            modelContext.insert(member)
                //                        }
                //
                //                        let publicKeys = members.map({ $0.publicKey })
                //                        if let publicKeyMetadatas = self.getModels(context: modelContext, modelType: PublicKeyMetadata.self,
                //                                                                   predicate: #Predicate<PublicKeyMetadata> { publicKeys.contains($0.publicKey) }) {
                //                            for member in members {
                //                                member.publicKeyMetadata = publicKeyMetadatas.first(where: { $0.publicKey == member.publicKey })
                //                            }
                //                        }
                //
                //                        // Set group isAdmin/isMember just incase we got the members/admins after the group was fetched
                //                        if let groups = self.getModels(context: modelContext, modelType: Group.self, predicate: #Predicate { $0.relayUrl == relayUrl && $0.id == groupId }) {
                //                            if let selectedOwnerAccount = self.selectedOwnerAccount {
                //                                let selectedOwnerPublicKey = selectedOwnerAccount.publicKey
                //                                for group in groups {
                //                                    group.isMember = members.first(where: { $0.publicKey == selectedOwnerPublicKey }) != nil
                //                                }
                //                            }
                //                        }
                //
                //                        try? modelContext.save()
                //                    }
                
            case Kind.groupChatMessage:
                print("event.tags: \(event.tags)")
                print("event.content: \(event.content)")
                guard let groupId = event.tags.first(where: { $0.id == "h" })?.otherInformation.first else { return }
                guard let id = event.id else { return }
                
               
                
                let chatMessage = ChatMessageMetadata(
                    id: id,
                    createdAt: event.createdAt.date,
                    groupId: groupId,
                    publicKey: event.pubkey,
//                    publicKeyMetadata: ,
                    content: event.content
                )
                
                DispatchQueue.main.async {
                    self.allChatMessage.append(chatMessage)
                }
                
                
//                if let chatMessage = ChatMessage(event: event, relayUrl: relayUrl) {
//                    
//                    if let chatMessages = self.getModels(context: modelContext, modelType: ChatMessage.self,
//                                                         predicate: #Predicate<ChatMessage> { $0.id == eventId }), chatMessages.count == 0 {
//                        
//                        modelContext.insert(chatMessage)
//                        
//                        if let publicKeyMetadata = self.getModels(context: modelContext, modelType: PublicKeyMetadata.self,
//                                                                  predicate: #Predicate<PublicKeyMetadata> { $0.publicKey == publicKey })?.first {
//                            chatMessage.publicKeyMetadata = publicKeyMetadata
//                        }
//                        
//                        if let replyToEventId = chatMessage.replyToEventId {
//                            if let replyToChatMessage = self.getModels(context: modelContext, modelType: ChatMessage.self,
//                                                                       predicate: #Predicate<ChatMessage> { $0.id == replyToEventId })?.first {
//                                chatMessage.replyToChatMessage = replyToChatMessage
//                            }
//                        }
//                        
//                        // Check if any messages point to me?
//                        if let replies = self.getModels(context: modelContext, modelType: ChatMessage.self, predicate: #Predicate<ChatMessage> { $0.replyToEventId == eventId }) {
//                            
//                            for message in replies {
//                                message.replyToChatMessage = chatMessage
//                            }
//                            
//                        }
//                        
//                        try? modelContext.save()
//                        
//                    }
//                }
                
            case Kind.groupAddUser:
                print(event)
                
            case Kind.groupRemoveUser:
                print(event)
                
            default: ( print("event.kind: ", event.kind))
            }
        }
    }
    //
    //    func editGroup(ownerAccount: OwnerAccount, group: Group) {
    //        guard let key = ownerAccount.getKeyPair() else { return }
    //        guard let selectedRelay else { return }
    //        let groupId = group.id
    //        var editGroupEvent = Event(pubkey: ownerAccount.publicKey, createdAt: .init(),
    //                                   kind: .groupEditMetadata, tags:
    //                                    [Tag(id: "h", otherInformation: groupId),
    //                                     Tag(underlyingData: ["name", "Cool Group"]),
    //                                     Tag(underlyingData: ["about", "This is a cool group"]),
    //                                     Tag(underlyingData: ["picture", "https://img.freepik.com/premium-vector/friendly-monkey-avatar_706143-7913.jpg"]),
    //                                     Tag(underlyingData: ["closed"])
    //                                    ]
    //                                   , content: "")
    //        do {
    //            try editGroupEvent.sign(with: key)
    //        } catch {
    //            print(error.localizedDescription)
    //        }
    //
    //        nostrClient.send(event: editGroupEvent, onlyToRelayUrls: [selectedRelay.url])
    //    }
    //
//    func createGroup(ownerAccount: OwnerAccount) {
//        guard let key = ownerAccount.getKeyPair() else { return }
//        let groupId = "testgroup"
//        //var createGroupEvent = Event(pubkey: ownerAccount.publicKey, createdAt: .init(),
//        //                         kind: .groupCreate, tags: [Tag(id: "h", otherInformation: groupId)], content: "")
//        var createGroupEvent = Event(pubkey: ownerAccount.publicKey, createdAt: .init(),
//                                     kind: .groupCreate, tags: [], content: "")
//        do {
//            try createGroupEvent.sign(with: key)
//        } catch {
//            print(error.localizedDescription)
//        }
//        
//        nostrClient.send(event: createGroupEvent, onlyToRelayUrls: [selectedNip29Relay.url])
//    }
    
    func joinGroup(ownerAccount: OwnerAccount, group: ChatGroup) {
        guard let key = ownerAccount.getKeyPair() else { return }
        let relayUrl = group.relayUrl
        let groupId = group.id
        var joinEvent = Event(pubkey: ownerAccount.publicKey, createdAt: .init(),
                              kind: .groupJoinRequest, tags: [Tag(id: "h", otherInformation: groupId)], content: "")

        do {
            try joinEvent.sign(with: key)
        } catch {
            print(error.localizedDescription)
        }

        nostrClient.send(event: joinEvent, onlyToRelayUrls: [relayUrl])
    }
    //
    //    func addMember(ownerAccount: OwnerAccount, group: Group, publicKey: String) {
    //        guard let key = ownerAccount.getKeyPair() else { return }
    //        let relayUrl = group.relayUrl
    //        let groupId = group.id
    //        var joinEvent = Event(pubkey: ownerAccount.publicKey, createdAt: .init(), kind: .groupAddUser,
    //                              tags: [Tag(id: "h", otherInformation: groupId), Tag(id: "p", otherInformation: publicKey)], content: "")
    //
    //        do {
    //            try joinEvent.sign(with: key)
    //        } catch {
    //            print(error.localizedDescription)
    //        }
    //
    //        nostrClient.send(event: joinEvent, onlyToRelayUrls: [relayUrl])
    //    }
    //
    //    func removeMember(ownerAccount: OwnerAccount, group: Group, publicKey: String) {
    //        guard let key = ownerAccount.getKeyPair() else { return }
    //        let relayUrl = group.relayUrl
    //        let groupId = group.id
    //        var joinEvent = Event(pubkey: ownerAccount.publicKey, createdAt: .init(), kind: .groupRemoveUser,
    //                              tags: [Tag(id: "h", otherInformation: groupId), Tag(id: "p", otherInformation: publicKey)], content: "")
    //
    //        do {
    //            try joinEvent.sign(with: key)
    //        } catch {
    //            print(error.localizedDescription)
    //        }
    //
    //        nostrClient.send(event: joinEvent, onlyToRelayUrls: [relayUrl])
    //    }
    //
        @MainActor
        func sendChatMessage(ownerAccount: OwnerAccount, group: ChatGroup, withText text: String) async {
            guard let key = ownerAccount.getKeyPair() else { return }
            let relayUrl = group.relayUrl
            let groupId = group.id
    
            var event = Event(pubkey: ownerAccount.publicKey, createdAt: .init(), kind: .groupChatMessage,
                              tags: [Tag(id: "h", otherInformation: groupId)], content: text)
            do {
                try event.sign(with: key)
            } catch {
                print(error.localizedDescription)
            }
    
            if let clientMessage = try? ClientMessage.event(event).string() {
               print(clientMessage)
            }
    
            guard let mainContext = modelContainer?.mainContext else { return }
            let publicKey = ownerAccount.publicKey
//            let ownerPublicKeyMetadata = try? mainContext.fetch(FetchDescriptor(predicate: #Predicate<PublicKeyMetadata> { $0.publicKey == publicKey })).first
//            if let chatMessage = ChatMessage(event: event, relayUrl: relayUrl) {
//                chatMessage.publicKeyMetadata = ownerPublicKeyMetadata
//                withAnimation {
//                    mainContext.insert(chatMessage)
//                    try? mainContext.save()
//    
//                }
//                nostrClient.send(event: event, onlyToRelayUrls: [relayUrl])
//            }
    
        }
    
//        @MainActor
//        func sendChatMessageReply(ownerAccount: OwnerAccount, group: ChatGroup, withText text: String, replyChatMessage: ChatMessage) async {
//            guard let key = ownerAccount.getKeyPair() else { return }
//            let relayUrl = group.relayUrl
//            let groupId = group.id
//            var tags: [Tag] = [Tag(id: "h", otherInformation: groupId)]
//            if let rootEventId = replyChatMessage.rootEventId {
//                tags.append(Tag(id: "e", otherInformation: [rootEventId, relayUrl, "root", replyChatMessage.publicKey]))
//                tags.append(Tag(id: "e", otherInformation: [replyChatMessage.id, relayUrl, "reply", replyChatMessage.publicKey]))
//            } else {
//                tags.append(Tag(id: "e", otherInformation: [replyChatMessage.id, relayUrl, "root", replyChatMessage.publicKey]))
//                tags.append(Tag(id: "e", otherInformation: [replyChatMessage.id, relayUrl, "reply", replyChatMessage.publicKey]))
//            }
//    
//            var event = Event(pubkey: ownerAccount.publicKey, createdAt: .init(), kind: .groupChatMessage,
//                              tags: tags, content: text)
//            do {
//                try event.sign(with: key)
//            } catch {
//                print(error.localizedDescription)
//            }
//    
//            guard let mainContext = modelContainer?.mainContext else { return }
//            let publicKey = ownerAccount.publicKey
//            let ownerPublicKeyMetadata = try? mainContext.fetch(FetchDescriptor(predicate: #Predicate<PublicKeyMetadata> { $0.publicKey == publicKey })).first
//            if let chatMessage = ChatMessage(event: event, relayUrl: relayUrl) {
//                chatMessage.publicKeyMetadata = ownerPublicKeyMetadata
//                chatMessage.replyToChatMessage = replyChatMessage
//                withAnimation {
//                    mainContext.insert(chatMessage)
//                    try? mainContext.save()
//    
//                }
//                nostrClient.send(event: event, onlyToRelayUrls: [relayUrl])
//            }
//        }
    
#if os(macOS)
    func copyToClipboard(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }
#else
    func copyToClipboard(_ string: String) {
        UIPasteboard.general.string = string
    }
#endif
    
}

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
                print("event is ok.")
            } else {
                print("\(event.id ?? "") is an invalid event on \(relayUrl)")
            }
        case .notice(let notice):
            print(notice)
        case .ok(let id, let acceptance, let m):
            print(id, acceptance, m)
        case .eose(let id):
//            print("EOSE => Subscription: \(id), relay: \(relayUrl)")
            switch id {
            case IdSubGroupList:
                Task {
                    print("ここにきている可能性")
                    await subscribeGroups(withRelayUrl: relayUrl)
                    await subscribeGroupMemberships(withRelayUrl: relayUrl)
                    await subscribeGroupAdmins(withRelayUrl: relayUrl)
                }
            case IdSubChatMessages,IdSubGroupList:
                Task {
//                    await connectAllMetadataRelays()
                }
            default:
                ()
            }
        case .closed(let id, let message):
            print(id, message)
        case .other(let other):
            print(other)
        case .auth(let challenge):
            print("Auth: \(challenge)")
        }
    }
    
}
