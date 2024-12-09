import SwiftUI
import SwiftData

struct GroupListRowView: View {
    
    let group: ChatGroup
    let lastMessage: ChatMessage?
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(group.name ?? "")
                    .bold()
                Spacer()
                if let lastMessage {
                    Text(lastMessage.createdAt, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(group.id)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(lastMessage?.content ?? "")
                .lineLimit(2)
                .foregroundStyle(.tertiary)
        }
        .frame(height: 60)
    }
}
