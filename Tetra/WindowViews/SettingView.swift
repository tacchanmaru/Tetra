import SwiftUI
import SwiftData

/// A view that presents the app's content library.
struct SettingView: View {
    @Environment(AppModel.self) var appModel
    @State private var accountName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var selfIntroduction: String = ""
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading, spacing: 20){
                Text("Account Settings")
                    .font(.largeTitle.bold())
                    .padding(.bottom, 20)
                
                Group{
                    Text("Account Name")
                        .font(.headline)
                    TextField("Enter account name", text: $accountName)
                        .padding()
                        .frame(width:500)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    
                    Text("Email Address")
                        .font(.headline)
                    TextField("Enter email", text: $email)
                        .keyboardType(.emailAddress)
                        .padding()
                        .frame(width:500)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    
                    Text("Password")
                        .font(.headline)
                    SecureField("Enter password", text: $password)
                        .padding()
                        .frame(width:500)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    
                    Text("Self Introduction")
                        .font(.headline)
                    TextField("Write something about yourself", text: $selfIntroduction)
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
