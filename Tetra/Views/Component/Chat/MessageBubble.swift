import SwiftUI
import SwiftData
import Translation

struct MessageBubble: View {
    
    let owner: Bool
    let chatMessage: ChatMessage
    @Binding var showTranslation: Bool
    
    var body: some View {
        HStack(alignment: .top) {
            
            if !owner {
                AvatarImage(avatarUrl: chatMessage.publicKeyMetadata?.picture ?? "", size: 40)
                    .offset(y: 8)
            }
            
            LazyVStack(alignment: owner ? .trailing : .leading, spacing: 6) {
                
                if !owner {
                    HStack {
                        
                        Text(chatMessage.publicKeyMetadata?.name ?? chatMessage.publicKey.prefix(12).lowercased())
                            .bold()
                            .padding(.leading, 8)
                        
                        if let nip05 = chatMessage.publicKeyMetadata?.nip05 { // TODO: Check nip verified
                            HStack(spacing: 2) {
                                Text(verbatim: nip05)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                    }
                }
                
                VStack(alignment: .leading) {
                    
                    if let replyToChatMessage = chatMessage.replyToChatMessage {
                        
                        HStack(spacing: 0) {
                            Color
                                .white
                                .frame(width: 3)
                            
                            VStack(alignment: .leading) {
                                Text(replyToChatMessage.publicKeyMetadata?.bestPublicName ?? replyToChatMessage.publicKey)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .bold()
                                Text(replyToChatMessage.content)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                            }
                            .padding(4)
                            
                        }
                        .background((owner ? Color.accentColor : .gray).brightness(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                    }
                    
                    Text(chatMessage.formatedContent() ?? "")
                        .foregroundStyle(.white)
                        .textSelection(.enabled)
                    
//                    ForEach(chatMessage.imageUrls, id: \.self) { imageUrl in
//                        AsyncImage(url: URL(string: imageUrl)) { phase in
//                            switch phase {
//                            case .empty:
//                                ProgressView()
//                                    .frame(width: 100, height: 100)
//                                    .background(Color.gray.opacity(0.2))
//                                    .clipShape(RoundedRectangle(cornerRadius: 8))
//                            case .success(let image):
//                                image
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fill)
//                                    .frame(width: 100, height: 100)
//                                    .background(Color.gray)
//                                    .clipShape(RoundedRectangle(cornerRadius: 8))
//                            case .failure(_):
//                                Image(systemName: "person.crop.circle.fill")
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fit)
//                                    .frame(width: 100, height: 100)
//                                    .foregroundColor(.secondary)
//                                    .background(Color.gray.opacity(0.2))
//                                    .clipShape(RoundedRectangle(cornerRadius: 8))
//                            }
//                        }
//                    }

                }
                .padding(8)
                .background(owner ? Color.accentColor : .gray)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .padding(owner ? .leading : .trailing, 150)
                .shadow(radius: 2, x: 1, y: 1)
                
//                if let links = chatMessage.urls["links"] {
//                    ForEach(links, id: \.self) { link in
//                        Link(destination: link) {
//                            LinkPreviewView(owner: owner, viewModel: .init(link.absoluteString))
//                        }
//                        .buttonStyle(.plain)
//                    }
//                }
                
                Text(chatMessage.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
            }
            
        }
        .listRowSeparator(.hidden, edges: .all)
        .padding(.bottom, 12)
    }
}