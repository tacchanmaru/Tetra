import SwiftUI
import SwiftData

/// A view that presents the app's content library.
struct SettingView: View {
    @Environment(AppModel.self) var appModel
    @State private var accountName: String = ""
    @State private var about: String = ""
    
    @EnvironmentObject private var appState: AppState
    
    @Query private var publicKeyMetadata: [PublicKeyMetadata]
    var selectedOwnerAccountPublicKeyMetadata: PublicKeyMetadata? {
        guard let selectedOwnerAccount = appState.selectedOwnerAccount else { return nil }
        return publicKeyMetadata.first(where: { $0.publicKey == selectedOwnerAccount.publicKey })
    }
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading, spacing: 20){
                Text("Account Settings")
                    .font(.largeTitle.bold())
                    .padding(.bottom, 20)
                
                Group{
                    if let picture = selectedOwnerAccountPublicKeyMetadata?.picture,
                       let url = URL(string: picture) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        Text("画像がありません")
                            .frame(width: 200, height: 200)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                    Text("Public Key")
                        .font(.headline)
                    if let publicKey = selectedOwnerAccountPublicKeyMetadata?.bech32PublicKey {
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
                    // Initialize state properties with data from the model
                    if let metadata = selectedOwnerAccountPublicKeyMetadata {
                        accountName = metadata.name ?? ""
                        about = metadata.about ?? ""
                    }
                }
                Spacer()
                HStack{
                    Spacer()
                    
                    Button(action: {
                        print("Account settings saved")
                    }) {
                        Text("Save Changes")
                            .font(.headline)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding()
                            .frame(width: 300)
                    }
                    .background(Color.blue)
                    .cornerRadius(12)
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                
            }
            .padding()
        }
    }
}

#Preview{
    SettingView()
        .environment(AppModel())
}
