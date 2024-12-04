import GroupActivities
import SwiftUI
import SwiftData


struct ContentView: View {
    @Environment(AppModel.self) var appModel
    @EnvironmentObject var appState: AppState
    @Query private var ownerAccounts: [OwnerAccount]
    
    var body: some View {
        Group {
            if appState.registeredNsec {
                TetraTabs()
            } else {
                StartView()
            }
        }.onAppear {
            if ownerAccounts.isEmpty {
                appState.registeredNsec = false
            }
        }
    }
    
    @Sendable
    func observeGroupSessions() async {
        for await session in TetraActivity.sessions() {
            let sessionController = await SessionController(session, appModel: appModel)
            guard let sessionController else {
                continue
            }
            appModel.sessionController = sessionController
            
            // Create a task to observe the group session state and clear the
            // session controller when the group session invalidates.
            Task {
                for await state in session.$state.values {
                    guard appModel.sessionController?.session.id == session.id else {
                        return
                    }
                    
                    if case .invalidated = state {
                        appModel.sessionController = nil
                        return
                    }
                }
            }
        }
    }
}
