import SwiftUI
import SwiftData

struct ProfileView: View {
    @State private var accountName: String = ""
    @State private var about: String = ""
    @EnvironmentObject private var appState : AppState
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading, spacing: 20){
                Text("Account Settings")
                    .font(.largeTitle.bold())
                    .padding(.bottom, 20)
                
                Group{
                    if let picture = appState.profileMetadata?.picture,
                       let url = URL(string: picture) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 200, height: 200)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 200, height: 200)
                                case .failure(_):
                                    Text("画像がありません")
                                        .frame(width: 200, height: 200)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                @unknown default:
                                    Text("不明な状態です")
                                        .frame(width: 200, height: 200)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                            }
                        }
                    } else {
                        Text("画像がありません")
                            .frame(width: 200, height: 200)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                    Text("Public Key")
                        .font(.headline)
                    if let publicKey = appState.profileMetadata?.pubkey {
                        Text(publicKey)
                    } else {
                        Text("No public key available")
                            .foregroundColor(.red)
                            .font(.system(size: 18))
                            .fontWeight(.bold)
                    }
                    
                    Text("Name")
                        .font(.headline)
                    TextField("Enter account name", text: $accountName)
                        .padding()
                        .frame(width:300)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    
                    Text("About")
                        .font(.headline)
                    TextField("Write something about yourself", text: $about)
                        .lineLimit(5, reservesSpace: true)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    
                }.onAppear {
                    if let metadata = appState.profileMetadata {
                        accountName = metadata.name ?? ""
                        about = metadata.about ?? ""
                    }
                }
                Spacer()
                HStack{
                    Spacer()
                    
                    Button(action: {
                        appState.editUserMetadata()
                        print("Account settings saved")
                    }) {
                        Text("Save Changes")
                            .font(.headline)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding()
                            .frame(width: 300)
                    }
                    .cornerRadius(12)
                    
                    Spacer()
                }
                
            }
            .padding(32)
        }
    }
}
