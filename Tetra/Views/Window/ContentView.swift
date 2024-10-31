import GroupActivities
import SwiftUI


struct ContentView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        TetraTabs()
    }
    
    /// Monitors for new Guess Together group activity sessions.
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
