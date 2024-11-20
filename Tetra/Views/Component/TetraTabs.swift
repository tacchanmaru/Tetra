import SwiftUI

struct TetraTabs: View {
    var body: some View {
        TabView {
            HomeView()
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
            SharePlayView()
                .tabItem {
                    Label("Share Play", systemImage: "arrow.2.circlepath.circle")
                }
        }
    }
}
