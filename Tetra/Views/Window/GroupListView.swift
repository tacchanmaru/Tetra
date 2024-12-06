import SwiftUI
import SwiftData

struct GroupListView: View {
    
    @EnvironmentObject var appState: AppState

    let relayUrl: String
    
    @Query private var groups: [ChatGroup]
    @Query private var chatMessages: [ChatMessage]
    
    func latestMessage(for groupId: String) -> ChatMessage? {
        return chatMessages
            .filter({ $0.groupId == groupId })
            .sorted(by: { $0.createdAt > $1.createdAt }).first
    }
    
    init(relayUrl: String) {
        self.relayUrl = relayUrl
        _groups = Query(filter: ChatGroup.predicate(relayUrl: relayUrl), sort: [SortDescriptor(\.name, order: .forward)]) // TODO: order by last message?
//        _chatMessages = Query(filter: ChatMessage.predicate(relayUrl: relayUrl))
    }
    
    var body: some View {
        
        List(selection: $appState.selectedGroup) {
            ForEach(groups, id: \.id) { group in
                NavigationLink(value: group) {
                    GroupListRowView(group: group)
                }
            }
        }
        .listStyle(.automatic)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Spacer()
                Button(action: {
                    appState.createGroup(ownerAccount: appState.selectedOwnerAccount!)
                }) {
                    Image(systemName: "plus.circle")
                }
                
            }
            
        }
    }
}
