import SwiftUI

struct RoomCard: View {
    let title: String
    let memberNum: Int
    let location: String
    let image: String
    let description: String
    
    var body: some View {
        NavigationLink(destination: DetailView(room: (title, memberNum, location, image, description))){
            VStack(alignment: .leading, spacing: 0) {
                // 画像部分
                Image(image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 250, height: 250)
                    .cornerRadius(10) // 画像の上部分だけ角を丸める
                    .overlay(
                        VStack {
                            Spacer()
                            HStack {
                                Text(title)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white)
                                    Text("\(memberNum)")
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
            .frame(width: 250)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 4)
        }
        .buttonStyle(PlainButtonStyle())
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
    
    let rooms: [(
        title: String,
        memberNum: Int,
        location: String,
        image: String,
        description: String
    )]
    
    var body: some View {
        VStack(alignment: .leading){
            
            
            ScrollView(.horizontal, showsIndicators: false){
                HStack(spacing: 16){
                    ForEach(rooms, id: \.0){ room in
                        RoomCard(
                            title: room.title,
                            memberNum: room.memberNum,
                            location: room.location,
                            image: room.image,
                            description: room.description
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
