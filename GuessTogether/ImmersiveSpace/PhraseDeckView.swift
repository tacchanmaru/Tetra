/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents the current secret phrase "card" to the active player
   along with buttons to go to the next card.
*/

import Spatial
import SwiftUI

struct PhraseDeckView: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.physicalMetrics) var converter
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.clear)
                .glassBackgroundEffect()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            switch appModel.sessionController?.game.stage {
            case .none, .teamSelection, .inGame(.beforePlayersTurn):
                Button("Begin Turn", systemImage: "play.circle") {
                    appModel.sessionController?.beginTurn()
                }
                .controlSize(.extraLarge)
                .font(.largeTitle)
            case .inGame(.duringPlayersTurn):
                ZStack {
                    PhraseCardView()
                }
            case .inGame(.afterPlayersTurn):
                Button("End Round", systemImage: "stop.circle") {
                    appModel.sessionController?.endTurn()
                }
                .controlSize(.extraLarge)
                .font(.largeTitle)
            }
        }
        .frame(width: 650, height: 400)
        .rotation3DEffect(Rotation3D(angle: .degrees(20), axis: .x), anchor: .center)
        .rotation3DEffect(Rotation3D(angle: .degrees(270), axis: .y), anchor: .center)
        .offset(y: -converter.convert(1.1, from: .meters))
    }
}

struct PhraseCardView: View {
    
    var body: some View {
        VStack {
            Text("おはよう")
                .font(.extraLargeTitle)
                .multilineTextAlignment(.center)
                .frame(maxHeight: .infinity)
            
            Divider()
            
            Text("おやすみ")
                .font(.title)
                .italic()
                .padding()
        }
        .padding()
    }
}
