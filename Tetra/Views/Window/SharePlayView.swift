import SwiftUI
import GroupActivities
import UIKit

@available(iOS 15.4, visionOS 1.0, *)
struct SharePlayView: View {
    var body: some View {
        Button(action: startSharePlay) {
            Text("Start SharePlay")
                .font(.title)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }

    func startSharePlay() {
        // GroupActivityの定義
        let activity = MyGroupActivity()
        
        // GroupActivitySharingControllerを初期化して表示
        if let sharingController = try? GroupActivitySharingController(activity) {
            // UIKitとの統合が必要な場合、UIViewControllerのcontextで呼び出します。
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(sharingController, animated: true)
            }
        }
    }
}

// GroupActivityの定義
struct MyGroupActivity: GroupActivity {
    var metadata: GroupActivityMetadata {
        var meta = GroupActivityMetadata()
        meta.title = "My SharePlay Activity"
        meta.type = .generic
        return meta
    }
}
