import SwiftUI
import SwiftData

/// アプリのコンテンツライブラリを表示するビュー。
struct TimeLineView: View {
    @Environment(AppModel.self) var appModel
    @ObservedObject var nostrTimeLineManager = NostrTimeLineManager(public_keys: ["670874fa6dd544edc5867763ce793552396aedda1a5fda3a97949f66ab0acfb3","6bcc27d284f7b10c0ec4252ac90d37b3aaeb30a53fadf2ce798d7d47b67d296e","63e37dc3317417a3676d67adb7fbbf77c98271015299af634093e31b54f632a2"])
    
    // タイムスタンプを "MM/dd HH:mm" 形式に変換する関数
    func formatTimeStamp(_ timeStamp: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"  // 元の形式
        
        // 文字列を Date に変換
        guard let date = dateFormatter.date(from: timeStamp) else {
            return timeStamp  // 変換に失敗したらそのまま返す
        }
        
        // 希望の形式に変更
        dateFormatter.dateFormat = "MM/dd HH:mm"
        return dateFormatter.string(from: date)
    }
    
    var body: some View {
        List(nostrTimeLineManager.contents, id: \.id) { post in
            VStack(spacing: 0) {  // VStackのspacingを0に設定
                HStack(alignment: .top, spacing: 5) {
                    // プロフィール画像
                    if let pictureUrlString = post.picture, let url = URL(string: pictureUrlString) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 50, height: 50)
                        }
                    } else {
                        // プロフィール画像がない場合のプレースホルダー
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 50, height: 50)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        // ユーザー名とタイムスタンプの表示
                        HStack {
                            Text(post.name ?? "匿名ユーザー")
                                .font(.headline)
                            Spacer()
                            Text(formatTimeStamp(post.timeStamp))
                                .font(.subheadline)
                        }
                        // 投稿内容の表示
                        Text(post.text)
                            .font(.body)
                    }
                }
                .padding(.vertical, 10)  // 上下のpaddingを均等に設定
                
            }
        }
        .listStyle(PlainListStyle())
    }
}

#Preview {
    TimeLineView()
        .environment(AppModel())
}
