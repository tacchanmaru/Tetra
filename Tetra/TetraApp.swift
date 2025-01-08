import SwiftUI
import SwiftData
import Nostr
import NostrClient

@main
struct TetraApp: App {
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            OwnerAccount.self,
            Relay.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
//    @State var appModel = AppModel()
    @StateObject var appState = AppState()
    let groupActivityManager = GroupActivityManager()
    
    
    var body: some Scene {
        WindowGroup {
            ContentView(groupActivityManager: groupActivityManager )
                .modelContainer(sharedModelContainer)
                .environmentObject(appState)
                .task {
                    appState.modelContainer = sharedModelContainer
                    await appState.setupYourOwnMetadata()
                    await appState.subscribeGroupMetadata()
                }
        }
    }
}
