import SwiftUI

struct SessionDetailView: View {
    @State var inputSharePlayLink = ""
    @EnvironmentObject var appState: AppState
    let group: ChatGroupMetadata
    
    @State private var sharePlayStatus: String = ""
    
    var body: some View {
        HStack {
            PersonaCameraView()
                .frame(width: 400, height: 400)
                .background(Color.black)
                .cornerRadius(10)
                .padding(.leading, 60)
            
            Spacer()

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(group.name ?? "")
                        .font(.title)
                        .bold()
                    Text("By Morinosuke")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(group.about ?? "")
                        .font(.body)

                }
                .padding(.horizontal)

                
                HStack(spacing: 20) {
//                    Button(action: {
//                        if let link = group.link,
//                           let url = URL(string: link) {
//
//                            UIApplication.shared.open(url)
//                        }
//                        
//                    }) {
                    let newFaceTimeLink = "https://facetime.apple.com/join#v=1&p=ZwAt7KeXEe+n9Y4xRDecvg&k=zyPbaG1l2PV4HUrjZFLUDoL0zQBUTwnPB2svFjYJToQ"
                    
                    Button(action: {
                        Task {
                            // 1) まずSharePlayの準備をする
                            let activity = TetraActivity()
                            
                            do {
                                // prepareForActivation()でSharePlay開始の事前チェック
                                let activationResult = try await activity.prepareForActivation()
                                
                                switch activationResult {
                                case .activationPreferred:
                                    // FaceTime通話が確立している場合
                                    let didActivate = try await activity.activate()
                                    if didActivate {
                                        // Activate成功 => NIP-29グループにも参加
                                        sharePlayStatus = "セッションに参加中です"
                                        
                                        if let userPubKey = appState.selectedOwnerAccount?.publicKey {
                                            appState.addUserAsMemberToGroup(
                                                userPubKey: userPubKey,
                                                groupId: group.id
                                            )
                                        }
                                    } else {
                                        // FaceTimeはあるが、まだ人数不足等でセッション未成立の場合
                                        sharePlayStatus = "他の参加者が参加するのを待機中です"
                                    }

                                case .activationDisabled:
                                    // ユーザがSharePlayをオフにしているなど
                                    sharePlayStatus = "SharePlayは利用できません"
                                
                                @unknown default:
                                    sharePlayStatus = "予期しないエラーが発生しました"
                                }
                            } catch {
                                // prepareForActivation() または activate() が投げるエラー処理
                                sharePlayStatus = "セッションの開始に失敗しました: \(error.localizedDescription)"
                            }

                            // 2) FaceTimeリンクを踏んで通話を開始(または参加)
                            if let url = URL(string: newFaceTimeLink) {
                                await UIApplication.shared.open(url)
                            }
                        }

                    }) {
                        Text("Join Chat")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                    }) {
                        HStack {
                            Image(systemName: "heart")
                            Text("Favorite")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Text(sharePlayStatus) // SharePlayのステータス表示用
                    .foregroundColor(.blue)
                    .font(.caption)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Admin")
                        .font(.callout)
                    ForEach(fetchAdminUserMetadata(), id: \.publicKey) { user in
                        HStack(alignment: .center, spacing: 10) {
                            if let pictureURL = user.picture,
                               let url = URL(string: pictureURL) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    case .failure:
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .scaledToFill()
                                    @unknown default:
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .scaledToFill()
                                    }
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(user.name ?? "")
                                    .font(.body)
                                    .bold()
                                Text(user.publicKey)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Member")
                        .font(.callout)
                    Text("\(countGroupMembers(groupId: group.id))")
                    ScrollView{
                        ForEach(fetchMemberUserMetadata(), id: \.publicKey) { user in
                            HStack(alignment: .center, spacing: 10) {
                                if let pictureURL = user.picture,
                                   let url = URL(string: pictureURL) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        case .failure:
                                            Image(systemName: "person.crop.circle.fill")
                                                .resizable()
                                                .scaledToFill()
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                }

                                VStack(alignment: .leading) {
                                    Text(user.name ?? "")
                                        .font(.body)
                                        .bold()
                                    Text(user.publicKey)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }}
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
            .padding(.trailing, 100)
            .frame(maxWidth: 500)
        }
    }
                         
    private func countGroupMembers(groupId: String) -> Int {
     let memberCount = appState.allGroupMember
         .filter { $0.groupId == groupId }
         .count
     return memberCount
    }
    
    private func fetchAdminUserMetadata() -> [UserMetadata] {
        let adminPublicKeys = appState.allGroupAdmin
            .filter { $0.groupId == group.id }
            .map { $0.publicKey }

        let adminMetadatas = appState.allUserMetadata.filter { user in
            adminPublicKeys.contains(user.publicKey)
        }
        return adminMetadatas
    }
    
    private func fetchMemberUserMetadata() -> [UserMetadata] {
        
        let memberPublicKeys = appState.allGroupMember
            .filter { $0.groupId == group.id }
            .map { $0.publicKey }
        
        let memberMetadatas = appState.allUserMetadata.filter { user in
            memberPublicKeys.contains(user.publicKey)
        }
        return memberMetadatas
    }
}
