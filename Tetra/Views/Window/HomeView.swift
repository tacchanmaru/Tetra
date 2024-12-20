import SwiftData
import SwiftUI

/// A view that presents the app's content library.
struct HomeView: View {
    @Environment(AppModel.self) var appModel
    @State private var searchText = ""
    @State private var sheetDetail: InventoryItem?
    
    let nowActiveRooms = [
        ("VisionDevCamp: LT Room", 12, "Osaka", "Osaka", "オフラインでは大阪で行われるVisionDevCamp Osakaのオンライン参加用ルームです。お楽しみください。"),
        ("VisionDevCamp2: LT Room", 3, "Hokkaido", "Hokkaido", "オフラインでは北海道で行われるVisionDevCampのオンライン参加用ルームです。お楽しみください。"),
        ("VisionDevCamp3", 43, "Mt.Fuji", "MtFuji", "オフラインでは富士山麓で行われるVisionDevCampのオンライン参加用ルームです。お楽しみください。"),
        ("VisionDevCamp4", 32, "USA", "VisionPro", "オフラインではアメリカで行われるVisionDevCampのオンライン参加用ルームです。お楽しみください。"),
        ("VisionDevCamp5", 98, "Tokyo", "Tokyo", "オフラインでは東京で行われるVisionDevCampのオンライン参加用ルームです。お楽しみください。"),
        ("VisionDevCamp6", 7, "Italy", "Italy", "オフラインではイタリアで行われるVisionDevCampのオンライン参加用ルームです。お楽しみください。"),
    ]
    
    let mostPopularRooms = [
        ("VisionDevCamp1", 12, "Osaka", "Osaka", "オフラインでは大阪で行われるVisionDevCampのオンライン参加用ルームです。お楽しみください。"),
        ("VisionDevCamp2", 3, "Hokkaido", "Hokkaido", "オフラインでは北海道で行われるVisionDevCampのオンライン参加用ルームです。お楽しみください。"),
        ("VisionDevCamp3", 43, "Mt.Fuji", "MtFuji", "オフラインでは富士山麓で行われるVisionDevCampのオンライン参加用ルームです。お楽しみください。"),
        ("VisionDevCamp4", 32, "USA", "VisionPro", "オフラインではアメリカで行われるVisionDevCampのオンライン参加用ルームです。お楽しみください。"),
        ("VisionDevCamp5", 98, "Tokyo", "Tokyo", "オフラインでは東京で行われるVisionDevCampのオンライン参加用ルームです。お楽しみください。"),
        ("VisionDevCamp6", 7, "Italy", "Italy", "オフラインではイタリアで行われるVisionDevCampのオンライン参加用ルームです。お楽しみください。"),
    ]

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
                    
                    Button("+ Start Session") {
                        sheetDetail = InventoryItem(
                            id: "0123456789",
                            partNumber: "Z-1234A",
                            quantity: 100,
                            name: "Widget")
                    }
                    .sheet(item: $sheetDetail,onDismiss: didDismiss) { detail in
                        VStack(alignment: .leading, spacing: 20) {
                            CreateSessionView(sheetDetail: $sheetDetail)
                        }
                        .presentationDetents([
                            .large,
                            .large,
                            .height(300),
                            .fraction(0.9),
                        ])
                    }

                }
                .padding()

                VStack(alignment: .leading) {

                    Spacer().frame(height: 30)

                    Text("Now active")
                        .font(.title2.bold())
                        .padding(.leading, 16)

                    RoomListView(rooms: nowActiveRooms)

                    Spacer().frame(height: 30)

                    Text("The Most Popular")
                        .font(.title2.bold())
                        .padding(.leading, 16)

                    RoomListView(rooms: mostPopularRooms)

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    func didDismiss() {
        
    }
}

struct InventoryItem: Identifiable {
    var id: String
    let partNumber: String
    let quantity: Int
    let name: String
}
