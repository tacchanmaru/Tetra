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
                        ZStack {
                            Rectangle()
                                .fill(Material.thin) // より薄いスタイルを適用
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                        }
                        
                        // テキスト
                        Text("New Playlist")
                            .padding(.leading, 8)
                        
                        Spacer() // 右端までのスペースを確保
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle()) // ボタンのデフォルトスタイルを抑制
                .sheet(item: $sheetDetailForSessionLink, onDismiss: didDismiss) { detail in
                    VStack(alignment: .leading, spacing: 20) {
                        SessionLinkView(sheetDetail: $sheetDetailForSessionLink)
                    }
                    .presentationDetents([
                        .large,
                        .height(300),
                        .fraction(1.0),
                    ])
                }
                
                
                
                Text("All Groups")
                    .font(.headline)
                    .padding(.leading, 30)
                        
                
                ForEach(0..<6) { index in
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
                            ZStack {
                                Rectangle()
                                    .fill(Material.thin) // より薄いスタイルを適用
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(.white)
                            }
                            
                            // テキスト
                            Text("New Playlist")
                                .padding(.leading, 8)
                            
                            Spacer() // 右端までのスペースを確保
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PlainButtonStyle()) // ボタンのデフォルトスタイルを抑制
                    .sheet(item: $sheetDetailForSessionLink, onDismiss: didDismiss) { detail in
                        VStack(alignment: .leading, spacing: 20) {
                            SessionLinkView(sheetDetail: $sheetDetailForSessionLink)
                        }
                        .presentationDetents([
                            .large,
                            .height(300),
                            .fraction(1.0),
                        ])
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
