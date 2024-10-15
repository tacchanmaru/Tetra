import SwiftUI
import SwiftData

/// A view that presents the app's content library.
struct HomeView: View {
    @Environment(AppModel.self) var appModel
    @State private var searchText = ""
    
    var body: some View {
        ScrollView{
            VStack {
                HStack {
                    Button(action: {
                        //アクションを追加
                    }){
                        Image(systemName: "line.horizontal.3.decrease.circle")
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                    
                    Button(action: {
                        //アクションを追加
                    }){
                        Image(systemName: "arrow.left")
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                    
                    Spacer()
                    
                    HStack{
                        Image(systemName: "mic")
                        
                        TextField("Search", text: $searchText)
                            .padding()
                            .background(Color.gray.opacity(0.4))
                            .cornerRadius(32)
                            .frame(height: 40)
                        Spacer()
                    }
                    .padding()
                    .foregroundColor(Color.gray.opacity(0.4))
                    .cornerRadius(12)
                    .frame(maxWidth: 500)
                    .frame(height: 40)
                    
                    Spacer()
                    
                    Button(action: {
                        //アクションを追加
                    }){
                        Text("+ Add Space")
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .cornerRadius(12)
                    }
                    
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                }
                .padding()
            
                VStack(alignment: .leading) {
                    
                    Spacer().frame(height: 30)
                    
                    Text("Now active")
                        .font(.title2.bold())
                        .padding(.leading, 16)
                    
                    RoomListView()
                    
                    Spacer().frame(height: 30)
                    
                    Text("The Most Popular")
                        .font(.title2.bold())
                        .padding(.leading, 16)
                    
                    RoomListView()
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

