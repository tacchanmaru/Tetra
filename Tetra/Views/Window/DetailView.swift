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
                        
                        let newFaceTimeLink = "https://facetime.apple.com/join#v=1&p=ZwAt7KeXEe+n9Y4xRDecvg&k=zyPbaG1l2PV4HUrjZFLUDoL0zQBUTwnPB2svFjYJToQ"
                        
                        Text(newFaceTimeLink)
                            .padding(8)
                            .overlay(
                                Rectangle()
                                    .frame(height: 2)
                                    .foregroundColor(.black),
                                alignment: .bottom
                            )
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(1)

                        Button {
                            if let url = URL(string: newFaceTimeLink) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("open")
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                }
                .padding(50)
                .padding(.bottom, 0)
                .padding(.trailing, 100)
                .frame(height: geometry.size.height, alignment: .bottom)
                .background(alignment: .bottom) {
                    backgroundView(geometry: geometry)
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

