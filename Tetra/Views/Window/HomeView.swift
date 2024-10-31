import SwiftData
import SwiftUI

/// A view that presents the app's content library.
struct HomeView: View {
    @Environment(AppModel.self) var appModel
    @State private var searchText = ""

    var body: some View {
        ScrollView {
            VStack {
                Spacer().frame(height: 10)
                
                HStack {
                    Spacer()
                    HStack {
                        TextField("Search", text: $searchText)
                            .padding()
                            .background(Color.gray.opacity(0.4))
                            .cornerRadius(32)
                            .frame(width: 600)
                            .frame(height: 40)
                        Spacer()
                    }
                    .padding()
                    .foregroundColor(Color.gray.opacity(0.4))
                    .cornerRadius(12)
                    .frame(height: 40)

                    Spacer()

                    NavigationLink(destination: AddSpaceView()) {
                        Text("+ Add Space")
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .cornerRadius(12)
                    }

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
