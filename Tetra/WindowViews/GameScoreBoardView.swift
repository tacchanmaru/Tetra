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
        .tetraToolbar()
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
        if let game = appModel.sessionController?.game {
            ForEach(GameModel.GameStage.allCases, id: \.self) { stage in
                Button(action: {
                    selectStage(stage)
                }) {
                    HStack {
                        Text(stageText(for: stage))
                            .foregroundStyle(stage == game.activeStage ? .green : .primary)
                            .bold(stage == game.activeStage)
                        Spacer()
                        if stage == game.activeStage {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .buttonStyle(.borderless)
            }
        } else {
            Text("You need to enter the space")
        }
    }

    private func selectStage(_ stage: GameModel.GameStage) {
        appModel.sessionController?.game.activeStage = stage
        appModel.sessionController?.game.stage = .inGame(stage)
    }

    private func stageText(for stage: GameModel.GameStage) -> String {
        switch stage {
            case .connectMode:
                return "Connect Mode"
            case .broadcastMode:
                return "Broadcast Mode"
            case .breakoutMode:
                return "Breakout Mode"
        }
    }
}