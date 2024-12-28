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
    @Published var allGroupMember: Array<GroupMember> = []
    
    @Published var chatMessageNumResults: Int = 50
    
    @Published var statuses: [String: Bool] = [:]
    
    @Published var ownerPostContents: Array<PostMetadata> = []
    @Published var profileMetadata: ProfileMetadata?
    
    init() {
        nostrClient.delegate = self
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
    
    // MARK: GroupのAdminの名前などのMetadataを購読する（本当はMemberにしたい）
    @MainActor
    func connectAllMetadataRelays() async {
        let relaysDescriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip1 && !$0.supportsNip29 })
        guard let relay = try? modelContainer?.mainContext.fetch(relaysDescriptor).first else { return }
        var pubkeys = Set<String>()

        for admin in self.allGroupAdmin {
            pubkeys.insert(admin.publicKey)
        }

        for member in self.allGroupMember {
            pubkeys.insert(member.publicKey)
        }
        
        let pubkeysArray = Array(pubkeys)
        
        let metadataSubscription = Subscription(
            filters: [Filter(authors: pubkeysArray, kinds: [Kind.setMetadata])],
            id: IdSubPublicMetadata
        )
        nostrClient.add(relayWithUrl: relay.url, subscriptions: [metadataSubscription])
    }
    
    // MARK: NIP-29対応のリレーでグループの情報（グループ名など）を購読する
    @MainActor
    func subscribeGroupMetadata() async {
        let descriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip29 })
        if let relay = try? modelContainer?.mainContext.fetch(descriptor).first {
            let groupMetadataSubscription = Subscription(filters: [Filter(kinds: [Kind.groupMetadata])], id: IdSubGroupList)
            nostrClient.add(relayWithUrl: relay.url, subscriptions: [groupMetadataSubscription])
            self.selectedNip29Relay = relay
        }
    }
    
    // MARK: NIP-29対応のリレーでメッセージを購読する
    @MainActor
    func subscribeChatMessages() async {
        let descriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip29 })
        if let relay = try? modelContainer?.mainContext.fetch(descriptor).first {
            let groupIds = self.allChatGroup.compactMap({ $0.id }).sorted()
            let groupMessageSubscription = Subscription(filters: [
                Filter(kinds: [Kind.groupChatMessage], since: nil, tags: [Tag(id: "h", otherInformation: groupIds)]),
            ], id: IdSubChatMessages)
            
            nostrClient.add(relayWithUrl: relay.url, subscriptions: [groupMessageSubscription])
        }
    }
    
    // MARK: NIP-29対応のリレーでそれぞれのグループのAdminとMembersを購読する
    @MainActor
    func subscribeGroupAdminAndMembers() async {
        let descriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip29 })
        
        let groupIds = self.allChatGroup.compactMap({ $0.id }).sorted()
        let groupAdminAndMembersSubscription = Subscription(filters: [
            Filter(kinds: [
                Kind.groupAdmins,
                Kind.groupMembers
            ], since: nil, tags: [Tag(id: "d", otherInformation: groupIds)]),
        ], id: IdSubGroupAdmins)
        
        if let relay = try? modelContainer?.mainContext.fetch(descriptor).first {
            nostrClient.add(relayWithUrl: relay.url, subscriptions: [groupAdminAndMembersSubscription])
        }
    }
    
    // MARK: 以下３つの関数はリレーの情報を消したい時に利用する。
    //    ・ removeDataFor
    //    ・ updateRelayInformationForAll
    //    ・ remove
    @MainActor
    func removeDataFor(relayUrl: String) async {
        Task.detached {
            guard let modelContext = self.backgroundContext() else { return }
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
    
    public func remove(relaysWithUrl relayUrls: [String]) {
        for relayUrl in relayUrls {
            self.nostrClient.remove(relayWithUrl: relayUrl)
        }
    }
    
    // MARK: これが動くことで購読しているデータを取得することができる。
    func process(event: Event, relayUrl: String) {
        Task.detached {
            switch event.kind {
                case Kind.setMetadata:
                    handleSetMetadata(appState: self, event: event)
                
                case Kind.textNote:
                    handleTextNote(appState: self, event: event)
                
                case Kind.groupMetadata:
                    handleGroupMetadata(appState: self, event: event)
                                        
                case Kind.groupAdmins:
                    handleGroupAdmins(appState: self, event: event, relayUrl: relayUrl)
                
                case Kind.groupMembers:
                    handleGroupMembers(appState: self, event: event, relayUrl: relayUrl)
                    
                case Kind.groupChatMessage:
                    handleGroupChatMessage(appState: self, event: event)

                case Kind.groupAddUser:
                    print(event)
                    
                case Kind.groupRemoveUser:
                    print(event)
                    
                default:
                    print("event.kind: ", event.kind)
                }
        }
    }
    
    // TODO: まだ参加していないグループに参加するための関数。まだ未実装。
    func joinGroup(ownerAccount: OwnerAccount, group: ChatGroupMetadata) {
        guard let key = ownerAccount.getKeyPair() else { return }
        let relayUrl = group.relayUrl
        let groupId = group.id
        var joinEvent = Event(
            pubkey: ownerAccount.publicKey,
            createdAt: .init(),
            kind: Kind.groupJoinRequest,
            tags: [Tag(id: "h", otherInformation: groupId)],
            content: ""
        )
        
        do {
            try joinEvent.sign(with: key)
        } catch {
            print(error.localizedDescription)
        }
        
        nostrClient.send(event: joinEvent, onlyToRelayUrls: [relayUrl])
    }
    
    // MARK: チャットのメッセージを送る関数
    @MainActor
    func sendChatMessage(ownerAccount: OwnerAccount, group: ChatGroupMetadata, withText text: String) async {
        guard let key = ownerAccount.getKeyPair() else { return }
        let relayUrl = group.relayUrl
        let groupId = group.id
    
        var event = Event(
            pubkey: ownerAccount.publicKey,
            createdAt: .init(),
            kind: Kind.groupChatMessage,
            tags: [Tag(id: "h", otherInformation: groupId)],
            content: text
        )
        
        do {
            try event.sign(with: key)
        } catch {
            print(error.localizedDescription)
        }
        
        if let clientMessage = try? ClientMessage.event(event).string() {
           print(clientMessage)
        }
        
        nostrClient.send(event: event, onlyToRelayUrls: [relayUrl])
    }
    
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
                } else {
                    print("\(event.id ?? "") is an invalid event on \(relayUrl)")
                }
            case .notice(let notice):
                print(notice)
            case .ok(let id, let acceptance, let m):
                print(id, acceptance, m)
            case .eose(let id):
                // MARK: EOSE(End of Stored Events Notice)はリレーから保存済み情報の終わり(ここから先はストリーミング)である旨を通知する仕組み。
                switch id {
                    case IdSubGroupList:
                        Task {
                            await subscribeChatMessages()
                            await subscribeGroupAdminAndMembers()
                        }
                    case IdSubGroupAdmins:
                        Task{
                            await connectAllMetadataRelays()
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
