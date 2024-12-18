import SwiftUI
import SwiftData

struct ChatGroupView: View {
    
    @EnvironmentObject var appState: AppState

    let relayUrl: String
    
    @Query private var groups: [ChatGroup]
    @Query private var chatMessages: [ChatMessage]
    
    func latestMessage(for groupId: String) -> ChatMessage? {
        return chatMessages
            .filter({ $0.groupId == groupId })
            .sorted(by: { $0.createdAt > $1.createdAt }).first
    }
    
    
    private var sortedGroups: [ChatGroup] {
        groups.sorted { group1, group2 in
            let lastMessage1 = latestMessage(for: group1.id)
            let lastMessage2 = latestMessage(for: group2.id)
            
            let date1 = lastMessage1?.createdAt ?? Date.distantPast
            let date2 = lastMessage2?.createdAt ?? Date.distantPast
            return date1 > date2
        }
    }
    
    init(relayUrl: String) {
        self.relayUrl = relayUrl
        _groups = Query(filter: ChatGroup.predicate(relayUrl: relayUrl))
        _chatMessages = Query(filter: ChatMessage.predicate(relayUrl: relayUrl))
    }
    
    var body: some View {
        NavigationSplitView {
            ChatListView(
                sortedGroups: sortedGroups,
                latestMessage: latestMessage
            )
            .environmentObject(appState)
            
        } detail: {
            ChatDetailView(
                relayUrl: appState.selectedRelay?.url ?? "",
                groupId: appState.selectedGroup?.id ?? "",
                chatMessageNumResults: $appState.chatMessageNumResults
            )
        }
    }
}

