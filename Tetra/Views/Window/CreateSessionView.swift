import SwiftUI
import PhotosUI

struct CreateSessionView: View {
    @Environment(AppModel.self) var appModel
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
                
                // 上部にxmarkボタン
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
                    // ボタンがタップされた時に sheetDetailForSessionLink を設定
                    sheetDetailForSessionLink = InventoryItem(
                        id: "0123456789",
                        partNumber: "Z-1234A",
                        quantity: 100,
                        name: "Widget"
                    )
                }) {
                    HStack {
                        // アイコン
                        Image(systemName: "plus.square")
                            .font(.system(size: 40))
                        
                        // テキスト
                        Text("New Playlist")
                            .padding(.leading, 8)
                        
                        Spacer()  // 右端までのスペースを確保
                    }
                    .background(Color.blue.opacity(0.1))  // ボタンの背景色
                    .cornerRadius(0)  // 角を丸く
                }
                .frame(maxWidth: .infinity)
                .cornerRadius(0)
                .sheet(item: $sheetDetailForSessionLink, onDismiss: didDismiss) { detail in
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
                
                
                
                Text("All Groups")
                    .font(.headline)
                    .padding(.leading, 30)
                        
                List {
                    ForEach(0..<6) { index in
                        HStack {
                            Image(systemName: "photo")
                            
                            // テキスト
                            Text("hello")
                                .padding(.leading, 8)
                            
                            Spacer()
                            
                            // 右端の編集ボタン
                            Button("Edit") {
                                sheetDetailForSessionLink = InventoryItem(
                                    id: "0123456789",
                                    partNumber: "Z-1234A",
                                    quantity: 100,
                                    name: "Widget")
                            }
                            .foregroundColor(.clear)
                            .sheet(item: $sheetDetailForSessionLink,onDismiss: didDismiss) { detail in
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
                    }
                }
                        
                Spacer()
                
            }
            .padding()
            
        }
    }
    func didDismiss() {
        
    }
}
