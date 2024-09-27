/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that's shown during the app's game stage and displays the score of
  each team next to the end-of-round timer.
*/

import SwiftUI

/// ```
/// ┌────────────────────────────────────┐
/// │ Blue Team                          │
/// │ ────────────                       │
/// │ 3                                  │
/// │                                    │
/// │                        00:27       │
/// │ Red Team                           │
/// │ ────────────                       │
/// │ 4                                  │
/// │                                    │
/// └────────────────────────────────────┘
/// ```
struct ScoreBoardView: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    
    @State var showEndGameConfirmation: Bool = false
    
    var body: some View {
        HStack {
            List {TeamStatusView()}
            .frame(maxWidth: .infinity)
            
            Group {
                if let currentRoundEndTime = appModel.sessionController?.game.currentRoundEndTime {
                    if currentRoundEndTime > .now {
                        Text(timerInterval: .now...currentRoundEndTime)
                    } else {
                        Text("0:00")
                    }
                } else {
                    Text("0:30")
                }
            }
            .font(.system(size: 150, weight: .bold))
            .frame(maxWidth: .infinity)
        }
        .padding()
        .guessTogetherToolbar()
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !appModel.isImmersiveSpaceOpen {
                    Button("Open Immersive Space", systemImage: "mountain.2.fill") {
                        Task {
                            await openImmersiveSpace(id: GameSpace.spaceID)
                        }
                    }
                }
                
                Button("End game", systemImage: "xmark") {
                    showEndGameConfirmation = true
                }
            }
        }
//        .confirmationDialog("End the game for everyone?", isPresented: $showEndGameConfirmation, titleVisibility: .visible) {
//            Button("End game", role: .destructive) {
//                appModel.sessionController?.endGame()
//            }
//        }
    }
    
}

struct TeamStatusView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        if let gameStage = appModel.sessionController?.game.stage {
            switch gameStage {
            case .inGame(let stage):
                Text(stageText(for: stage))
            }
        } else {
            Text("スペースに入ってないです")
        }
    }

    private func stageText(for stage: GameModel.GameStage) -> String {
        switch stage {
            case .connectMode:
                return "connectMode"
            case .broadcastMode:
                return "broadcastMode"
            case .breakoutMode:
                return "breakoutMode"
        }
    }
}
