import SwiftUI
import GroupActivities

/// A view that presents the video content details.
struct DetailView: View {
    @State var inputSharePlayLink = ""
    
    let room: (
        title: String,
        memberNum: Int,
        location: String,
        image: String,
        description: String
    )
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()

                VStack(alignment: .leading, spacing: 15) {
                    
                    Text(room.title)
                        .font(.largeTitle)
                        .bold()
                    
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                        Text(String(room.memberNum))
                            .font(.headline)
                        Spacer().frame(width: 30)
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.white)
                        Text(room.location)
                            .font(.headline)
                    }
                    
                    Text("tacchanmaru , yugo , morinosuke")
                        .font(.headline)

                    Text(room.description)
                        .multilineTextAlignment(.leading)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Text("FaceTime link: ")
                        
                        TextField("your FaceTime link", text: $inputSharePlayLink)
                            .padding(8)
                            .overlay(
                                Rectangle()
                                    .frame(height: 2) // 下線の高さを設定
                                    .foregroundColor(.black), // 下線の色を黒に設定
                                alignment: .bottom // 下線の位置を下に設定
                            )
                            .fixedSize(horizontal: false, vertical: true)
                       
                        Button {
                            // action
                        } label: {
                            Text("paste")
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack {
                        Text("FaceTime link: ")
                        
                        let sharePlayLink = "https://facetime.apple.com/join#v=1&p=d5fKQIrYEe+qASYt62+A9A&k=FnnTTVJo0RcCT6MJfZtQ5P0tT-OM9g4cgYhTMqFQLg0"
                        
                        Text(sharePlayLink)
                            .padding(8)
                            .overlay(
                                Rectangle()
                                    .frame(height: 2) // 下線の高さを設定
                                    .foregroundColor(.black), // 下線の色を黒に設定
                                alignment: .bottom // 下線の位置を下に設定
                            )
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(1)
        
                        Button {
                            // action
                        } label: {
                            Text("copy")
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                }
                .padding(50)
                .padding(.bottom, 0)
                .padding(.trailing, 100)
                .frame(height: geometry.size.height, alignment: .bottom) // GeometryReaderから高さを取得
                .background(alignment: .bottom) {
                    backgroundView(geometry: geometry) // 背景画像にGeometryReaderを渡す
                }
                
            }
        }
    }
    
    private func backgroundView(geometry: GeometryProxy) -> some View {
        ZStack {
            Image(room.image)
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea()

            Color.black
                .opacity(0.2)
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea()
        }
    }

}

