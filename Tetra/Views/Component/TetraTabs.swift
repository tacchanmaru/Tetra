import SwiftUI

struct TetraTabs: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            GroupListView(relayUrl: appState.selectedRelay?.url ?? "")
                .tabItem {
                    Label("【開発用】グループリスト", systemImage: "person.3")
                }
            //なぜかNavigationStackを導入するとhoverなどが効き、正常に動くようになった。
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
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
