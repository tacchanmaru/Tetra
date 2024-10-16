/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main window that presents the app's user interface.
*/

import SwiftUI

struct TetraWindow: Scene {
    @Environment(AppModel.self) var appModel
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
            .nameAlert()
        }
        .windowResizability(.contentSize)
    }
}
