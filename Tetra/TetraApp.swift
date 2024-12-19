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
            PublicKeyMetadata.self,
            ChatGroup.self,
            ChatMessage.self,
            GroupAdmin.self,
            GroupMember.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @State var appModel = AppModel()
    @StateObject var appState = AppState()
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
                .environment(appModel)
                .environmentObject(appState)
                .task {
                    appState.modelContainer = sharedModelContainer
                    await appState.initialSetup()
                    await appState.connectAllNip29Relays()
                    await appState.connectAllMetadataRelays()
                }
        }
    }
}
