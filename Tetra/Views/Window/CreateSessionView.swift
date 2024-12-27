import SwiftUI
import PhotosUI

struct CreateSessionView: View {
    @EnvironmentObject private var appState: AppState
    @State private var groupName: String = ""
    @State private var maxMembers: String = ""
    @State private var groupDescription: String = ""
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var groupImage: Image? = nil
    @State private var sheetDetailForSessionLink: InventoryItem?
    @Binding var sheetDetail: InventoryItem?
    
    var body: some View {
        
        GeometryReader { geometry in
            
            VStack(alignment: .leading, spacing: 20) {
                
                HStack {
                    Button(action: {
                        sheetDetail = nil
                    }) {
                        Image(systemName: "xmark")
                            .resizable()
                            .foregroundColor(.white)
                            .frame(width: 15, height: 15)
                    }
                    .frame(width: 15, height: 15)
                    .contentShape(Circle())
                    .padding(.leading, 30)
                    .padding(.bottom)
                    
                    
                    Spacer()
                    
                    Text("Create a Session")
                        .font(.title)
                        .padding(.bottom, 20)
                        .padding(.trailing, 50)
                    
                    Spacer()
                    
                }
                .padding(.top, 10)
                
                Button(action: {
                    sheetDetailForSessionLink = InventoryItem(
                        id: "0123456789",
                        partNumber: "Z-1234A",
                        quantity: 100,
                        name: "Widget"
                    )
                }) {
                    HStack {
                        Image(systemName: "plus.square")
                            .font(.system(size: 40))
                        
                        Text("New Playlist")
                            .padding(.leading, 8)
                        
                        Spacer()
                    }
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(0)
                }
                .frame(maxWidth: .infinity)
                .cornerRadius(0)
//                .sheet(item: $sheetDetailForSessionLink) { detail in
//                    VStack(alignment: .leading, spacing: 20) {
//                        SessionLinkView(sheetDetail: $sheetDetailForSessionLink)
//                    }
//                    .presentationDetents([
//                        .large,
//                        .large,
//                        .height(300),
//                        .fraction(1.0),
//                    ])
//                }
                
                
                
                Text("All Groups of which you are a member")
                    .font(.headline)
                    .padding(.leading, 30)
                        
                List(selection: $appState.selectedGroup) {
                    ForEach(appState.allChatGroup.filter({ $0.isMember == true }), id: \.id) { group in
                        HStack {
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
                            
                            Text(group.name ?? "")
                                .padding(.leading, 8)
                            
                            Spacer()
                            
                            Button("Edit") {
                                appState.selectedGroup = group
                                sheetDetailForSessionLink = InventoryItem(
                                    id: "0123456789",
                                    partNumber: "Z-1234A",
                                    quantity: 100,
                                    name: "Widget")
                            }
                            .foregroundColor(.clear)
                            .sheet(item: $sheetDetailForSessionLink) { detail in
                                VStack(alignment: .leading, spacing: 20) {
                                    SessionLinkView(sheetDetail: $sheetDetailForSessionLink)
                                }
                                .presentationDetents([
                                    .large,
                                    .large,
                                    .height(300),
                                    .fraction(1.0),
                                ])
                            }
                        }
                        .padding(.vertical, 4)
                        .tag(group)
                    }
                }

                Spacer()
                
            }
            .padding()
            
        }
    }
}
