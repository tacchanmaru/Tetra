import SwiftUI
import GroupActivities

/// A view that presents the video content details.
struct DetailView: View {
    @State private var viewSize: CGSize = .zero
    @State var inputSharePlayLink = ""
    
    var body: some View {
        VStack {
            
            Spacer()

            VStack(alignment: .leading, spacing: 15) {
                
                Text("タイトル：VisionDevCamp, LT")
                    .font(.largeTitle)
                    .bold()
                
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                    Text("3")
                        .font(.headline)
                }
                
                Text("欄木 , 跡部 , 斎藤")
                    .font(.headline)

                Text("説明：このSpaceはVisionDevCampにおけるLT用の部屋になってます。")
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
            .frame(height: viewSize.height, alignment: .bottom)
            .background(alignment: .bottom) { backgroundView }
            
        }
        
        
    }
    
    private var backgroundView: some View {
        Image("VisionPro")
            .resizable()
            .scaledToFill()
            .frame(width: viewSize.width, height: viewSize.height)
            .clipped()
    }
}
