import SwiftUI

struct TetraTabs: View {
    var body: some View {
        TabView {
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
