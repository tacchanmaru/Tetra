import SwiftUI

struct TetraTabs: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            
            NavigationStack { HomeView() }
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            ChatGroupView(relayUrl: appState.selectedRelay?.url ?? "")
                .tabItem {
                    Label("【開発用】グループリスト", systemImage: "person.3")
                }
            TimeLineView()
                .tabItem {
                    Label("Timeline", systemImage: "clock")
                }
            
            SettingView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .navigationBarBackButtonHidden()
    }
}
