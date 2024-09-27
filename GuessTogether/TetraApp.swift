/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app structure.
*/

import SwiftUI

@main
struct TetraApp: App {
    @State var appModel = AppModel()
    
    var body: some Scene {
        Group {
            TetraWindow()
            GameSpace()
        }
        .environment(appModel)
    }
}
