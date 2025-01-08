import SwiftUI
import GroupActivities

struct SessionDetailView: View {
    @State var inputSharePlayLink = ""
    @EnvironmentObject var appState: AppState
    let group: ChatGroupMetadata
    @State var groupActivityManager: GroupActivityManager
    @StateObject private var groupStateObserver = GroupStateObserver()
    
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
                    HStack{
                        if let pictureURL = group.picture,
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
                                    Image("noImage")
                                        .resizable()
                                        .scaledToFill()
                                @unknown default:
                                    Image("noImage")
                                        .resizable()
                                        .scaledToFill()
                                }
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        } else {
                            Image("noImage")
                                .resizable()
                                .frame(width: 40, height: 40)
                        }
                        Text(group.name ?? "")
                            .font(.title)
                            .bold()
                    }
                    Text("By Morinosuke")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(group.about ?? "")
                        .font(.body)

                }
                .padding(.horizontal)

                
                HStack(spacing: 20) {
                    // MARK: すでにShareplayセッションが確立されている状態
                    if group.isMember && groupActivityManager.isSharePlaying {
                        Button(action: {
                            Task {
                                // SharePlayセッションを終了する
                                let didActivate = await groupActivityManager.endSession()
                                if didActivate {
                                    guard let selectedOwnerAccount = appState.selectedOwnerAccount else { return }

                                    //Nostrのグループから抜ける
                                    appState.leaveGroup(ownerAccount: selectedOwnerAccount, group: group)
                                    // グループメンバーから自分を削除する
                                    appState.allGroupMember.removeAll { member in
                                        member.publicKey == selectedOwnerAccount.publicKey && member.groupId == group.id
                                    }
                                    for index in appState.allChatGroup.indices {
                                        if appState.allChatGroup[index].id == group.id {
                                            appState.allChatGroup[index].isMember = false
                                        }
                                    }
                                    sharePlayStatus = "セッションから離脱しました。"
                                } else {
                                    sharePlayStatus = "セッションの離脱に失敗しました。"
                                }
                            }
                        }) {
                            Text("Leave Chat")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }.tint(.red)
                    // MARK: Shareplayセッションを確立していない場合
                    } else if !group.isMember && !groupActivityManager.isSharePlaying  {
                        Button(action: {
                            Task {
                                let newFaceTimeLink = "https://facetime.apple.com/join#v=1&p=ZwAt7KeXEe+n9Y4xRDecvg&k=zyPbaG1l2PV4HUrjZFLUDoL0zQBUTwnPB2svFjYJToQ"
                                // 1) まずFaceTimeリンクを開いて通話を開始
                                // 現状テストできないのでコメントアウト中
//                                if let url = URL(string: newFaceTimeLink) {
//                                    // 完了ハンドラーを使用して、処理が終わった後に続きの処理を実行
//                                    await withCheckedContinuation { continuation in
//                                        UIApplication.shared.open(url) { success in
//                                            // FaceTimeが開かれた後の処理
//                                            if success {
//                                                continuation.resume()
//                                            } else {
//                                                sharePlayStatus = "FaceTimeを開けませんでした"
//                                                continuation.resume()
//                                            }
//                                        }
//                                    }
//                                }
                                
                                // 2) FaceTime通話を開始した後、SharePlayの準備を進める
                                let activationResult = await TetraActivity().prepareForActivation()
                                switch activationResult {
                                    case .activationPreferred:
                                        let didActivate = await groupActivityManager.startSession()
                                        if didActivate {
                                            guard let selectedOwnerAccount = appState.selectedOwnerAccount else { return }

                                            appState.joinGroup(ownerAccount: selectedOwnerAccount, group: group)
                                            sharePlayStatus = "セッションに参加中です"
                                        } else {
                                            sharePlayStatus = "他の参加者が参加するのを待機中です"
                                        }

                                    case .activationDisabled:

                                        sharePlayStatus = "SharePlayは利用できません"
                                    
                                    case .cancelled:
                                        sharePlayStatus = "セッションの開始をキャンセルしました"
                                    @unknown default:
                                        sharePlayStatus = "予期しないエラーが発生しました"
                                }
                            }
                        }) {
                            Text("Join Chat")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .disabled(!groupStateObserver.isEligibleForGroupSession)
                        .tint(.green)
                    }
                    
                    Button(action: {
                    }) {
                        HStack {
                            Image(systemName: "heart")
                            Text("Favorite")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
                .padding(.horizontal)
                
                Text(sharePlayStatus)
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
                                Text(user.displayName ?? "")
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
                                    Text(user.displayName ?? "")
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
