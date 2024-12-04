import SwiftUI

struct RoomCard: View {
    let title: String
    let memberNum: Int
    let location: String
    let image: String
    let description: String

    var body: some View {
        NavigationLink(destination: DetailView(room: (title, memberNum, location, image, description))) {
            VStack(alignment: .leading) {
                Image(image)
                    .resizable()
                    .frame(width: 250, height: 250)
                    .cornerRadius(12)
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
                            .clipShape(RoundedCorners(cornerRadius: 12, corners: [.bottomLeft, .bottomRight]))
                        }
                    )
                VStack(alignment: .leading) {
                    Text(location)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .background(Color(UIColor.systemBackground))
            }
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .cornerRadius(12)
            .hoverEffect()
            .background(Color(UIColor.systemBackground))
        }
        .buttonStyle(PlainButtonStyle())
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
