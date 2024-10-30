import SwiftUI
import SwiftData

/// A view that presents the app's content library.
struct SettingView: View {
    @Environment(AppModel.self) var appModel
    @ObservedObject var nostrClientManager = NostrMetadataManager()
    @State private var accountName: String = ""
    @State private var displayName: String = ""
    @State private var about: String = ""
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading, spacing: 20){
                Text("Account Settings")
                    .font(.largeTitle.bold())
                    .padding(.bottom, 20)
                
                Group{
                    AsyncImage(url: URL(string: nostrClientManager.pictureUrl)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                    } placeholder: {
                        ProgressView()
                    }
                    Text("Name")
                        .font(.headline)
                    TextField("Enter account name", text: $nostrClientManager.accountName)
                        .padding()
                        .frame(width:500)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    
                    Text("Display Name")
                        .font(.headline)
                    TextField("Enter display name", text: $nostrClientManager.displayName)
                        .padding()
                        .frame(width:500)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    
                    Text("About")
                        .font(.headline)
                    TextField("Write something about yourself", text: $nostrClientManager.about)
                        .lineLimit(5, reservesSpace: true)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    
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
