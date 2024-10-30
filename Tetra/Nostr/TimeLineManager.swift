import Foundation
import NostrClient
import Nostr

// データの型
struct PostWithMetadata: Identifiable, Encodable {
    var id: String
    var text: String
    var name: String?
    var picture: String?
    var timeStamp: String
}

class NostrTimeLineManager: ObservableObject {
    private var client: NostrClient
    private lazy var delegate: NostrTimeLineDelegate = NostrTimeLineDelegate(manager: self)
    
    @Published var contents: Array<PostWithMetadata> = []
    
    private var metadataDict: [String: (name: String?, picture: String?)] = [:]
    
    init(public_keys: [String]) {
        client = NostrClient()
        client.delegate = delegate
        
        // まずkind 0 (メタデータ) を取得
        client.add(relayWithUrl: "wss://relay.damus.io", autoConnect: true)
        let metadataSubscription = Subscription(filters: [.init(authors: public_keys, kinds: [Kind(id: 0)])])
        client.add(subscriptions: [metadataSubscription])
    }
    
    // メタデータがすべて取得された後に投稿 (kind 1) を取得するメソッド
    func subscribeToPosts(public_keys: [String]) {
        let postSubscription = Subscription(filters: [.init(authors: public_keys, kinds: [Kind(id: 1)])])
        client.add(subscriptions: [postSubscription])
    }
    
    // postのデータを名前・画像と共にjson形式で追加する
    func appendPost(_ post: PostWithMetadata) {
        DispatchQueue.main.async {
            self.contents.append(post)
        }
    }
    
    // タイムスタンプ順に並べ替えるメソッド
    func sortPostsByTimestamp() {
        DispatchQueue.main.async {
            self.contents.sort { post1, post2 in
                // timeStamp を Date に変換
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
                if let date1 = dateFormatter.date(from: post1.timeStamp),
                   let date2 = dateFormatter.date(from: post2.timeStamp) {
                    return date1 > date2  // 昇順に並べ替え
                }
                return false  // 変換できない場合はそのまま
            }
        }
    }
    
    func getMetadata(for key: String) -> (name: String?, picture: String?)? {
        return metadataDict[key]
    }
    
    func saveMetadata(for key: String, name: String?, picture: String?) {
        metadataDict[key] = (name: name, picture: picture)
    }
    
    // タイムスタンプをStringに変換するメソッド
    func formatNostrTimestamp(_ nostrTimestamp: Nostr.Timestamp) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(nostrTimestamp.timestamp))  // UNIXタイムスタンプからDateに変換
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"  // 希望のフォーマットを設定
        return dateFormatter.string(from: date)  // Stringに変換して返す
    }

}

class NostrTimeLineDelegate: NostrClientDelegate {
    weak var manager: NostrTimeLineManager?
    
    init(manager: NostrTimeLineManager) {
        self.manager = manager
    }
    
    func didReceive(message: Nostr.RelayMessage, relayUrl: String) {
        switch message {
        case .event(_, let event):
            // textNote の場合
            if event.kind == .textNote {
                print("raw textNote: \(event)")
                
                if let metadata = manager?.getMetadata(for: event.pubkey) {
                    
                    let timeStampString = manager?.formatNostrTimestamp(event.createdAt)
                    
                    let post = PostWithMetadata(
                        id: UUID().uuidString,
                        text: event.content,
                        name: metadata.name,
                        picture: metadata.picture,
                        timeStamp: timeStampString ?? ""
                    )
                    manager?.appendPost(post)
                    manager?.sortPostsByTimestamp()
                }
            }
            // メタデータの場合
            if event.kind == .setMetadata {
                
                if let jsonData = event.content.data(using: .utf8),
                   let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                    let name = jsonObject["name"] as? String
                    let picture = jsonObject["picture"] as? String
                    
                    manager?.saveMetadata(
                        for: event.pubkey,
                        name: name,
                        picture: picture
                    )
                    
                    // メタデータが保存されたら投稿の取得を開始
                    manager?.subscribeToPosts(public_keys: [event.pubkey])
                }
            }
        default:
            break
        }
    }
    
    func didConnect(relayUrl: String) {
        print("Connected to \(relayUrl)")
    }
    
    func didDisconnect(relayUrl: String) {
        print("Disconnected from \(relayUrl)")
    }
}
