/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An observable controller class that manages the active SharePlay
  group session.
*/

import GroupActivities
import Observation

@Observable @MainActor
class SessionController {
    let session: GroupSession<GuessTogetherActivity>
    let messenger: GroupSessionMessenger
    let systemCoordinator: SystemCoordinator
    
    var game: GameModel {
        get {
            gameSyncStore.game
        }
        set {
            if newValue != gameSyncStore.game {
                gameSyncStore.game = newValue
                shareLocalGameState(newValue)
            }
        }
    }
    var gameSyncStore = GameSyncStore() {
        didSet {
            gameStateChanged()
        }
    }

    var players = [Participant: PlayerModel]() {
        didSet {
            if oldValue != players {
//                updateCurrentPlayer()
            }
        }
    }
    var localPlayer: PlayerModel {
        get {
            players[session.localParticipant]!
        }
        set {
            if newValue != players[session.localParticipant] {
                players[session.localParticipant] = newValue
                shareLocalPlayerState(newValue)
            }
        }
    }
    
    init?(_ session: GroupSession<GuessTogetherActivity>, appModel: AppModel) async {
        guard let systemCoordinator = await session.systemCoordinator else {
            return nil
        }
        
        self.session = session
        self.messenger = GroupSessionMessenger(session: session)
        self.systemCoordinator = systemCoordinator

        self.localPlayer = PlayerModel(
            id: session.localParticipant.id,
            name: appModel.playerName
        )
        appModel.showPlayerNameAlert = localPlayer.name.isEmpty
        
        observeRemoteParticipantUpdates()
        configureSystemCoordinator()
        
        self.session.join()
    }
    
    func updateSpatialTemplatePreference() {
        switch game.stage {
        case .inGame:
            systemCoordinator.configuration.spatialTemplatePreference = .sideBySide
        }
    }
    
    func configureSystemCoordinator() {
        systemCoordinator.configuration.supportsGroupImmersiveSpace = true
        
        Task {
            for await localParticipantState in systemCoordinator.localParticipantStates {
                localPlayer.seatPose = localParticipantState.seat?.pose
            }
        }
    }
    
    
    func startGame() {
        game.stage = .inGame(.connectMode)
    }
    
    func beginTurn() {
        
        game.stage = .inGame(.broadcastMode)
        game.currentRoundEndTime = .now.addingTimeInterval(30)
        
        let sleepUntilTime = ContinuousClock.now.advanced(by: .seconds(30))
        Task {
            try await Task.sleep(until: sleepUntilTime)
            if case .inGame(.broadcastMode) = game.stage {
                game.stage = .inGame(.breakoutMode)
            }
        }
    }
    
    func endTurn() {
        guard game.stage.isInGame, localPlayer.isPlaying else {
            return
        }
        
        game.turnHistory.append(session.localParticipant.id)
        game.currentRoundEndTime = nil
        game.stage = .inGame(.connectMode)
        
    }
    
//    func endGame() {
//        game.stage = .none
//    }
    
    func gameStateChanged() {
        updateSpatialTemplatePreference()
    }
}
