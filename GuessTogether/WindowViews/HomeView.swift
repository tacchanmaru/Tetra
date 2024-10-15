/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view that presents the app's content library.
*/

import SwiftUI
import SwiftData

/// A view that presents the app's content library.
struct HomeView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
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
                Text("Search")
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding()
            .background(Color(.systemGray5))
            .cornerRadius(12)
            .frame(height: 40)
            
            Spacer()
            
            Button(action: {
                //アクションを追加
            }){
                Text("+ Add Space")
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
            }
            
            Image(systemName: "person.crop.circle")
                .resizable()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

}
