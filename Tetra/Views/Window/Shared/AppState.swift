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
    @Published var selectedRelay: Relay?
    @Published var selectedGroup: ChatGroup? {
        didSet {
            chatMessageNumResults = 50
        }
    }
    @Published var chatMessageNumResults: Int = 50
    
    @Published var statuses: [String: Bool] = [:]
    
    init() {
        nostrClient.delegate = self
    }
    
    @MainActor
    func initialSetup() async {
        print("Starting initialSetup...")
        
        var selectedAccountDescriptor = FetchDescriptor<OwnerAccount>(predicate: #Predicate { $0.selected })
        selectedAccountDescriptor.fetchLimit = 1
        print("FetchDescriptor created with predicate for selected accounts.")
        
        if let context = modelContainer?.mainContext {
            do {
                print("Fetching selected account from context...")
                let fetchedAccounts = try context.fetch(selectedAccountDescriptor)
                self.selectedOwnerAccount = fetchedAccounts.first
                
                if let account = self.selectedOwnerAccount {
                    print("Selected account fetched successfully: \(account)")
                } else {
                    print("No selected account found.")
                }
            } catch {
                print("Error fetching selected account: \(error)")
            }
        } else {
            print("Error: modelContainer or mainContext is nil.")
        }
        
        print("initialSetup completed.")
    }
    
    
    //全てのアカウント（自分と、その他のチャットを行う人）の名前などのMetadataを取得する
    @MainActor func connectAllMetadataRelays() async {
        
        let relaysDescriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip1 })
        guard let relays = try? modelContainer?.mainContext.fetch(relaysDescriptor) else { return }
        
        var selectedAccountDescriptor = FetchDescriptor<OwnerAccount>(predicate: #Predicate { $0.selected })
        selectedAccountDescriptor.fetchLimit = 1
        guard let selectedAccount = try? modelContainer?.mainContext.fetch(selectedAccountDescriptor).first else { return }
        
        var pubkeys = Set([selectedAccount.publicKey])
        
        
        let membersDescriptor = FetchDescriptor<GroupMember>()
        if let members = try? modelContainer?.mainContext.fetch(membersDescriptor) {
            for member in members {
                pubkeys.insert(member.publicKey)
            }
        }
        
        let adminsDescriptor = FetchDescriptor<GroupAdmin>()
        if let admins = try? modelContainer?.mainContext.fetch(adminsDescriptor) {
            for admin in admins {
                pubkeys.insert(admin.publicKey)
            }
        }
        
        let sortedPubkeys = Array(pubkeys).sorted()
        
        for relay in relays {
            nostrClient.add(relayWithUrl: relay.url, subscriptions: [
                Subscription(filters: [
                    Filter(authors: sortedPubkeys, kinds: [
                        .setMetadata,
                    ])
                ], id: IdSubPublicMetadata),
                Subscription(filters: [
                    Filter(authors: [selectedAccount.publicKey], kinds: [
                        .setMetadata,
                    ])
                ], id: IdSubOwnerMetadata)
            ])
            nostrClient.connect(relayWithUrl: relay.url)
        }
    }
    
    //NIP-29対応のリレーにグループのメタデータ（メンバーなど？）を取得しにいく
    @MainActor func connectAllNip29Relays() async {
        let descriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip29 })
        if let relays = try? modelContainer?.mainContext.fetch(descriptor) {
            for relay in relays {
                nostrClient.add(relayWithUrl: relay.url, subscriptions: [
                    Subscription(filters: [
                        Filter(kinds: [
                            Kind.groupMetadata
                        ])
                    ], id: IdSubGroupList)
                ])
            }
            self.selectedRelay = relays.first
        }
    }
    
    
    // This function is meant to be called anytime there has been a change
    // In subscriptions, etc. It should handle the case where it's simply
    // a no-op if nothing has actually changed in subscriptions, etc.
    @MainActor func subscribeGroups(withRelayUrl relayUrl: String) async {
        
        let descriptor = FetchDescriptor<ChatGroup>(predicate: #Predicate { $0.relayUrl == relayUrl  })
        if let events = try? modelContainer?.mainContext.fetch(descriptor) {
            
            // Get latest message and use since filter so we don't keep getting the same shit
            //let since = events.min(by: { $0.createdAt > $1.createdAt })
            // TODO: use the since fitler
            let groupIds = events.compactMap({ $0.id }).sorted()
            let sub = Subscription(filters: [
                Filter(kinds: [
                    Kind.groupChatMessage,
                    Kind.groupChatMessageReply,
                    Kind.groupForumMessage,
                    //Kind.groupForumMessageReply
                ], since: nil, tags: [Tag(id: "h", otherInformation: groupIds)]),
            ], id: IdSubChatMessages)
            
            nostrClient.add(relayWithUrl: relayUrl, subscriptions: [sub])
        }
    }
    
    @MainActor func subscribeGroupMemberships(withRelayUrl relayUrl: String) async {
        
        let descriptor = FetchDescriptor<ChatGroup>(predicate: #Predicate { $0.relayUrl == relayUrl  })
        if let events = try? modelContainer?.mainContext.fetch(descriptor) {
            
            // Get latest message and use since filter so we don't keep getting the same shit
            //let since = events.min(by: { $0.createdAt > $1.createdAt })
            // TODO: use the since fitler
            let groupIds = events.compactMap({ $0.id }).sorted()
            let sub = Subscription(filters: [
                Filter(kinds: [
                    Kind.groupAddUser,
                    Kind.groupRemoveUser
                ], since: nil, tags: [Tag(id: "h", otherInformation: groupIds)]),
            ], id: IdSubGroupMembers)
            
            nostrClient.add(relayWithUrl: relayUrl, subscriptions: [sub])
        }
    }
    
    @MainActor func subscribeGroupAdmins(withRelayUrl relayUrl: String) async {
        
        let descriptor = FetchDescriptor<ChatGroup>(predicate: #Predicate { $0.relayUrl == relayUrl  })
        if let events = try? modelContainer?.mainContext.fetch(descriptor) {
            
            // Get latest message and use since filter so we don't keep getting the same shit
            //let since = events.min(by: { $0.createdAt > $1.createdAt })
            // TODO: use the since fitler
            let groupIds = events.compactMap({ $0.id }).sorted()
            let sub = Subscription(filters: [
                Filter(kinds: [
                    Kind.groupAdmins
                ], since: nil, tags: [Tag(id: "d", otherInformation: groupIds)]),
            ], id: IdSubGroupAdmins)
            
            nostrClient.add(relayWithUrl: relayUrl, subscriptions: [sub])
        }
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
    func handleGroupAdmins(event: Event, relayUrl: String, modelContext: ModelContext) {
        let tags = event.tags.map { $0 }

        guard let groupTag = tags.first(where: { $0.id == "d" }),
              let groupId = groupTag.otherInformation.first else {
            return
        }

        let pTags = tags.filter { $0.id == "p" }

        let pOtherInfos: [[String]] = pTags.compactMap { $0.otherInformation }

        var admins: [GroupAdmin] = []
        for info in pOtherInfos {
            guard let publicKey = info.first else { continue }
            let capabilities = info.count > 2 ? Array(info[2...]) : []
            
            if let admin = GroupAdmin(publicKey: publicKey, groupId: groupId, capabilities: capabilities, relayUrl: relayUrl),
               admin.publicKey.isValidPublicKey {
                admins.append(admin)
            }
        }

        for admin in admins {
            modelContext.insert(admin)
        }

        let adminPublicKeys = admins.map { $0.publicKey }
        let adminsPredicate: Predicate<PublicKeyMetadata> = #Predicate<PublicKeyMetadata> { adminPublicKeys.contains($0.publicKey) }

        if let publicKeyMetadatas = self.getModels(context: modelContext, modelType: PublicKeyMetadata.self, predicate: adminsPredicate) {
            for admin in admins {
                admin.publicKeyMetadata = publicKeyMetadatas.first(where: { $0.publicKey == admin.publicKey })
            }
        }

        let groupPredicateForAdmins: Predicate<ChatGroup> = #Predicate<ChatGroup> { $0.relayUrl == relayUrl && $0.id == groupId }

        if let groups = self.getModels(context: modelContext, modelType: ChatGroup.self, predicate: groupPredicateForAdmins) {
            if let selectedOwnerAccount = self.selectedOwnerAccount {
                let selectedOwnerPublicKey = selectedOwnerAccount.publicKey
                for group in groups {
                    group.isAdmin = admins.first(where: { $0.publicKey == selectedOwnerPublicKey }) != nil
                }
            }
        }
        
        try? modelContext.save()
    }

    
    func process(event: Event, relayUrl: String) {
        Task.detached {
            
            let publicKey = event.pubkey
            guard let eventId = event.id else { return }
            
            print("event.kind: \(event.kind)")
            
            guard let modelContext = self.backgroundContext() else { return }
            switch event.kind {
            case Kind.setMetadata:
                
                if let publicKeyMetadata = PublicKeyMetadata(event: event) {
                    modelContext.insert(publicKeyMetadata)
                    
                    // Fetch all ChatMessages with publicKey and assign publicKeyMetadata relationship
                    if let messages = self.getModels(context: modelContext, modelType: ChatMessage.self,
                                                     predicate: #Predicate<ChatMessage> { $0.publicKey == publicKey }) {
                        for message in messages {
                            message.publicKeyMetadata = publicKeyMetadata
                        }
                    }
                    
                    try? modelContext.save()
                    
                }
                
            case Kind.groupMetadata:
                print("Let's create a group!")
                
                if let group = ChatGroup(event: event, relayUrl: relayUrl) {
                    let groupId = group.id
                    modelContext.insert(group)
                    
                    if let selectedOwnerAccount = self.selectedOwnerAccount {
                        
                        let selectedOwnerPublicKey = selectedOwnerAccount.publicKey
                        
                        group.isMember = self.getModels(context: modelContext, modelType: GroupMember.self,
                                                        predicate: #Predicate<GroupMember> { $0.publicKey == selectedOwnerPublicKey && $0.groupId == groupId && $0.relayUrl == relayUrl })?.first != nil
                        
                        group.isAdmin = self.getModels(context: modelContext, modelType: GroupAdmin.self,
                                                       predicate: #Predicate<GroupAdmin> { $0.publicKey == selectedOwnerPublicKey && $0.groupId == groupId  && $0.relayUrl == relayUrl })?.first != nil
                        
                    }
                    
                    try? modelContext.save()
                    
                }
                
            case Kind.groupAdmins:
                self.handleGroupAdmins(event: event, relayUrl: relayUrl, modelContext: modelContext)
                
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
                print("Messageを受信しました")
                
                if let chatMessage = ChatMessage(event: event, relayUrl: relayUrl) {
                    
                    if let chatMessages = self.getModels(context: modelContext, modelType: ChatMessage.self,
                                                         predicate: #Predicate<ChatMessage> { $0.id == eventId }), chatMessages.count == 0 {
                        
                        modelContext.insert(chatMessage)
                        
                        if let publicKeyMetadata = self.getModels(context: modelContext, modelType: PublicKeyMetadata.self,
                                                                  predicate: #Predicate<PublicKeyMetadata> { $0.publicKey == publicKey })?.first {
                            chatMessage.publicKeyMetadata = publicKeyMetadata
                        }
                        
                        if let replyToEventId = chatMessage.replyToEventId {
                            if let replyToChatMessage = self.getModels(context: modelContext, modelType: ChatMessage.self,
                                                                       predicate: #Predicate<ChatMessage> { $0.id == replyToEventId })?.first {
                                chatMessage.replyToChatMessage = replyToChatMessage
                            }
                        }
                        
                        // Check if any messages point to me?
                        if let replies = self.getModels(context: modelContext, modelType: ChatMessage.self, predicate: #Predicate<ChatMessage> { $0.replyToEventId == eventId }) {
                            
                            for message in replies {
                                message.replyToChatMessage = chatMessage
                            }
                            
                        }
                        
                        try? modelContext.save()
                        
                    }
                }
                
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
    func createGroup(ownerAccount: OwnerAccount) {
        guard let key = ownerAccount.getKeyPair() else { return }
        guard let selectedRelay else { return }
        let groupId = "testgroup"
        //var createGroupEvent = Event(pubkey: ownerAccount.publicKey, createdAt: .init(),
        //                         kind: .groupCreate, tags: [Tag(id: "h", otherInformation: groupId)], content: "")
        var createGroupEvent = Event(pubkey: ownerAccount.publicKey, createdAt: .init(),
                                     kind: .groupCreate, tags: [], content: "")
        do {
            try createGroupEvent.sign(with: key)
        } catch {
            print(error.localizedDescription)
        }
        
        nostrClient.send(event: createGroupEvent, onlyToRelayUrls: [selectedRelay.url])
    }
    
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
            let ownerPublicKeyMetadata = try? mainContext.fetch(FetchDescriptor(predicate: #Predicate<PublicKeyMetadata> { $0.publicKey == publicKey })).first
            if let chatMessage = ChatMessage(event: event, relayUrl: relayUrl) {
                chatMessage.publicKeyMetadata = ownerPublicKeyMetadata
                withAnimation {
                    mainContext.insert(chatMessage)
                    try? mainContext.save()
    
                }
                nostrClient.send(event: event, onlyToRelayUrls: [relayUrl])
            }
    
        }
    
        @MainActor
        func sendChatMessageReply(ownerAccount: OwnerAccount, group: ChatGroup, withText text: String, replyChatMessage: ChatMessage) async {
            guard let key = ownerAccount.getKeyPair() else { return }
            let relayUrl = group.relayUrl
            let groupId = group.id
            var tags: [Tag] = [Tag(id: "h", otherInformation: groupId)]
            if let rootEventId = replyChatMessage.rootEventId {
                tags.append(Tag(id: "e", otherInformation: [rootEventId, relayUrl, "root", replyChatMessage.publicKey]))
                tags.append(Tag(id: "e", otherInformation: [replyChatMessage.id, relayUrl, "reply", replyChatMessage.publicKey]))
            } else {
                tags.append(Tag(id: "e", otherInformation: [replyChatMessage.id, relayUrl, "root", replyChatMessage.publicKey]))
                tags.append(Tag(id: "e", otherInformation: [replyChatMessage.id, relayUrl, "reply", replyChatMessage.publicKey]))
            }
    
            var event = Event(pubkey: ownerAccount.publicKey, createdAt: .init(), kind: .groupChatMessage,
                              tags: tags, content: text)
            do {
                try event.sign(with: key)
            } catch {
                print(error.localizedDescription)
            }
    
            guard let mainContext = modelContainer?.mainContext else { return }
            let publicKey = ownerAccount.publicKey
            let ownerPublicKeyMetadata = try? mainContext.fetch(FetchDescriptor(predicate: #Predicate<PublicKeyMetadata> { $0.publicKey == publicKey })).first
            if let chatMessage = ChatMessage(event: event, relayUrl: relayUrl) {
                chatMessage.publicKeyMetadata = ownerPublicKeyMetadata
                chatMessage.replyToChatMessage = replyChatMessage
                withAnimation {
                    mainContext.insert(chatMessage)
                    try? mainContext.save()
    
                }
                nostrClient.send(event: event, onlyToRelayUrls: [relayUrl])
            }
        }
    
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
                    await connectAllMetadataRelays()
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
