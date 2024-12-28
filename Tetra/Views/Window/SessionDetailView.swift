import SwiftUI

struct SessionDetailView: View {
    @State var inputSharePlayLink = ""
    @EnvironmentObject var appState: AppState
    let group: ChatGroupMetadata
    
    
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
                    let newFaceTimeLink = "https://facetime.apple.com/join#v=1&p=ZwAt7KeXEe+n9Y4xRDecvg&k=zyPbaG1l2PV4HUrjZFLUDoL0zQBUTwnPB2svFjYJToQ"
                    
                    Button(action: {
                        if let url = URL(string: newFaceTimeLink) {
                            UIApplication.shared.open(url)
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
