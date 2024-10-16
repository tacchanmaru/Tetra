import SwiftUI

struct RoomCard: View {
    let roomName: String
    let participantCount: Int
    let location: String
    let imageName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 画像部分
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 250, height: 250)
                .cornerRadius(10) // 画像の上部分だけ角を丸める
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Text(roomName)
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                                Text("\(participantCount)")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.3))
                        
                    }
                )
            // テキスト部分
            VStack(alignment: .leading) {
                Text(location)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
            
        }
        .frame(width: 250) // カード全体の幅を指定
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12) // カード全体に角丸を設定
        .shadow(radius: 4) // 影を追加
    }
}

// カスタム角丸を部分的に適用するためのModifier
struct RoundedCorner: Shape {
    var radius: CGFloat = 12
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}


struct RoomListView: View{
    let rooms = [
        ("LT room", 98, "VisionDevCamp Tokyo", "VisionPro"),
        ("Group1", 12, "VisionDevCamp Tokyo", "VisionPro"),
        ("Group2", 3, "VisionDevCamp Tokyo", "VisionPro"),
        ("Group3", 43, "VisionDevCamp Tokyo", "VisionPro")
    ]
    
    var body: some View {
        VStack(alignment: .leading){
            
            
            ScrollView(.horizontal, showsIndicators: false){
                HStack(spacing: 16){
                    ForEach(rooms, id: \.0){ room in
                        RoomCard(roomName: room.0, participantCount: room.1, location: room.2, imageName: room.3)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
