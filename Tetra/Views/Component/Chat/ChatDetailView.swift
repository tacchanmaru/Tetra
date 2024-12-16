import SwiftUI
import SwiftData
import Nostr

//struct ToolbarContentView: View {
//    @EnvironmentObject var appState: AppState
//    let groupMembers: [GroupMember]
//    let groupAdmins: [GroupAdmin]
//
//    var body: some View {
//        HStack {
//            GroupPicture(pictureUrl: appState.selectedGroup?.picture)
//            VStack(alignment: .leading) {
//                Text(appState.selectedGroup?.name ?? "---")
//                    .font(.headline)
//                    .bold()
//                Text(appState.selectedGroup?.relayUrl ?? "--")
//                    .font(.subheadline)
//                    .foregroundStyle(.secondary)
//            }
//            .opacity(appState.selectedGroup == nil ? 0.0 : 1.0)
//
//            Spacer()
//
//            if !isMemberOrAdmin() && groupMembers.count > 0 {
//                Button(action: joinGroupAction) {
//                    Text("Join")
//                        .foregroundStyle(.white)
//                }
//                .buttonStyle(.plain)
//                .padding(.horizontal, 8)
//                .padding(.vertical, 4)
//                .background(.blue)
//                .cornerRadius(6)
//            }
//
//            if let selectedGroup = appState.selectedGroup {
//                if appState.chatMessageNumResults < appState.allMessagesCount {
//                    Button(action: loadMoreMessages) {
//                        Text("Load More")
//                    }
//                }
//
//                ShareLink(item: selectedGroup.relayUrl + "'" + selectedGroup.id)
//                    .fontWeight(.semibold)
//            }
//        }
//    }
//
//    private func joinGroupAction() {
//        guard let selectedOwnerAccount = appState.selectedOwnerAccount else { return }
//        guard let selectedGroup = appState.selectedGroup else { return }
//        appState.joinGroup(ownerAccount: selectedOwnerAccount, group: selectedGroup)
//    }
//
//    private func loadMoreMessages() {
//        appState.chatMessageNumResults *= 2
//    }
//
//    private func isMemberOrAdmin() -> Bool {
//        if let selectedGroup = appState.selectedGroup {
//            return selectedGroup.isMember || selectedGroup.isAdmin
//        }
//        return false
//    }
//}



struct ChatDetailView: View {
    
    @EnvironmentObject var appState: AppState
    
    let relayUrl: String
    let groupId: String
    
    @Query private var allMessages: [ChatMessage]
    @Query var groupMembers: [GroupMember]
    @Query var groupAdmins: [GroupAdmin]
    
    var chatMessages: [ChatMessage] {
        return Array(allMessages.suffix(appState.chatMessageNumResults))
    }
    
    @State private var scroll: ScrollViewProxy?
    @State private var messageText = ""
    @State private var textEditorHeight : CGFloat = 32
    @State private var searchText = ""
    @State private var infoPopoverPresented = false
    @State private var showTranslation: Bool = false
    @State private var replyMessage: ChatMessage?
    
    @State private var highlightedMessageId: String?
    @State private var isHighlitedMessageAnimating = false
    
    @FocusState private var inputFocused: Bool

    private let maxHeight : CGFloat = 350
    
    init(relayUrl: String, groupId: String, chatMessageNumResults: Binding<Int>) {
        self.relayUrl = relayUrl
        self.groupId = groupId
        _groupMembers = Query(filter: GroupMember.predicate(byGroupId: groupId, relayUrl: relayUrl))
        _groupAdmins = Query(filter: GroupAdmin.predicate(byGroupId: groupId, relayUrl: relayUrl))
        _allMessages = Query(filter: ChatMessage.predicate(byGroupId: groupId, relayUrl: relayUrl),
                             sort: [SortDescriptor(\.createdAt, order: .forward)], animation: .interactiveSpring)
    }
    
    private func scrollToLastMessageIfNeeded() {
        DispatchQueue.main.async {
            if let last = chatMessages.last {
                scroll?.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
    
    var body: some View {
        
        ZStack {
            ScrollViewReader { reader in
                List(chatMessages) { message in
                    ChatMessageRow(
                        message: message,
                        isHighlighted: isHighlitedMessageAnimating,
                        highlightedMessageId: highlightedMessageId,
                        scroll: scroll,
                        replyMessage: $replyMessage
                    )
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .onChange(of: chatMessages, initial: true, { oldValue, newValue in
                    DispatchQueue.main.async {
                        if let last = chatMessages.last {
                            scroll?.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                })
                .onAppear {
                    scroll = reader
                    DispatchQueue.main.async {
                        if let last = chatMessages.last {
                            scroll?.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                
                if let replyMessage = replyMessage {
                    ChatReply(
                        replyMessage: replyMessage,
                        isHighlitedMessageAnimating: $isHighlitedMessageAnimating,
                        highlightedMessageId: $highlightedMessageId,
                        scroll: scroll
                    )
                }
                
            }
        }
        .safeAreaInset(edge: .bottom) {
            if appState.selectedGroup != nil && isMemberOrAdmin() {
                
                HStack(spacing: 8) {
                    
                    TextField("Write a message...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .onSubmit(of: .text, {
                            guard let selectedOwnerAccount = appState.selectedOwnerAccount else { return }
                            guard let selectedGroup = appState.selectedGroup else { return }
                            if let replyMessage {
                                let text = messageText.trimmingCharacters(in: .newlines)
                                let reply = replyMessage
                                Task {
                                    await appState.sendChatMessageReply(ownerAccount: selectedOwnerAccount, group: selectedGroup,
                                                                        withText: text,
                                                                        replyChatMessage: reply)
                                    
                                    if let last = chatMessages.last {
                                        self.scroll?.scrollTo(last.id, anchor: .bottom)
                                    }
                                }
                                
                                self.replyMessage = nil
                                messageText = ""
                                
                            } else {
                                let text = messageText.trimmingCharacters(in: .newlines)
                                Task {
                                    await appState.sendChatMessage(ownerAccount: selectedOwnerAccount,
                                                                   group: selectedGroup, withText: text)
                                    
                                    if let last = chatMessages.last {
                                        self.scroll?.scrollTo(last.id, anchor: .bottom)
                                    }
                                    
                                }
                                messageText = ""
                            }
                        })
                        .padding(.leading, 12)
                        .padding(.trailing, 16)
                        .padding(.vertical, 8)
                        .background(.background)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    //                    .background(
                    //                        RoundedRectangle(cornerRadius: 16)
                    //                            .stroke(style: .init(lineWidth: 1))
                    //                            .foregroundStyle(.secondary.opacity(0.6))
                    //                    )
//                        .overlay(alignment: .trailing) {
//                            Button("", systemImage: "face.smiling") {
//                                Task {
//                                    NSApp.orderFrontCharacterPalette($messageText) // TODO: Fix where this comes up
//                                }
//                            }
//                            .buttonStyle(.plain)
//                            .imageScale(.large)
//                        }
                        .focused($inputFocused)
                    
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(
                    .background
                )
                .overlay(alignment: .top) {
                    Color.secondary.opacity(0.3)
                        .frame(height: 1)
                }
            }
        }
//        .toolbar {
//            ToolbarItemGroup(placement: .automatic) {
//                ToolbarContentView(groupMembers: groupMembers, groupAdmins: groupAdmins)
//            }
//        }
//        .onChange(of: appState.selectedGroup) { oldValue, newValue in
//            if oldValue != newValue {
//                self.replyMessage = nil
//
//            }
//        }
    }
    
    func isMemberOrAdmin() -> Bool {
        if let selectedGroup = appState.selectedGroup {
            return selectedGroup.isMember || selectedGroup.isAdmin
        }
        return false
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = value + nextValue()
    }
}
