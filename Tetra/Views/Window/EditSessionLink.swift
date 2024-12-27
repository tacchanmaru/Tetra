import SwiftUI
import PhotosUI

struct SessionLinkView: View {
    @Environment(AppModel.self) var appModel
    @State private var sheetDetailForAddSessionLink: InventoryItem?
    @State private var groupName: String = ""
    @State private var maxMembers: String = ""
    @State private var groupDescription: String = ""
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var groupImage: Image? = nil
    @Binding var sheetDetail: InventoryItem?
    
    var body: some View {
            
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
                    .padding(.leading)
                
                Spacer()
                
                Button(action: {
                    print("Group settings saved")
                }) {
                    Text("Create")
                }
                .padding(.bottom)
                
            }
            .padding(.top, 10)
            
                
            HStack {
                
                Spacer()
                
                if let groupImage = groupImage {
                    groupImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                } else {
                    
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .foregroundColor(.gray) // 点線の色
                            
                            VStack {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.gray)
                                
                                Text("Add Image")
                                    .foregroundColor(.gray)
                                
                            }
                            
                        }
                        .frame(width: 180, height: 180) // 枠全体のサイズを指定
                    }
                    .onChange(of: selectedImage) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                groupImage = Image(uiImage: uiImage)
                            }
                        }
                    }
                }
//
                Spacer()
                
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Session Title")
                    .font(.headline)
                TextField("ex. Anyone can join!", text: $groupName)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                
                Text("Session Description")
                    .font(.headline)
                TextField("ex. This is a room for VisionDevCamp", text: $maxMembers)
                    .keyboardType(.numberPad)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                
                Text("Session Link")
                    .font(.headline)
                TextField("ex. https://...", text: $groupName)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            .frame(maxWidth: .infinity, alignment: .leading) // 全体を左揃え
            .padding(.leading, 60)
            .padding(.trailing, 60)
            
        }
        .padding()
        
        Spacer()
        
    }
}
