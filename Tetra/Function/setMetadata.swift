import Nostr
import NostrClient
import Foundation

func handleSetMetadata(appState: AppState, event: Event) {
    if let metadata = decodeUserMetadata(from: event.content) {
        let (name, picture, about) = metadata
        
        //TODO: 以下によって自分の投稿が2回fetchされているのを修正する必要がある
        if event.pubkey == appState.selectedOwnerAccount?.publicKey {
            handleSelectedOwnerProfile(
                pubkey: event.pubkey,
                name: name,
                picture: picture,
                about: about,
                appState: appState,
                nostrClient: appState.nostrClient
            )
        }
        
        let userMetadata = createUserMetadata(from: event, name: name, about: about, picture: picture)
        updateChatMessages(for: event, with: userMetadata, appState: appState)
    }
}

func getProfileMetadata(for key: String, appState: AppState) -> ProfileMetadata? {
    return appState.profileMetadata
}

private func decodeUserMetadata(from content: String) -> (name: String?, picture: String?, about: String?)? {
    guard let jsonData = content.data(using: .utf8),
          let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
        return nil
    }
    let name = jsonObject["display_name"] as? String
    let picture = jsonObject["picture"] as? String
    let about = jsonObject["about"] as? String
    return (name, picture, about)
}

func formatNostrTimestamp(_ nostrTimestamp: Nostr.Timestamp) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(nostrTimestamp.timestamp))
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return dateFormatter.string(from: date)
}

private func handleSelectedOwnerProfile(pubkey: String, name: String?, picture: String?, about: String?, appState: AppState, nostrClient: NostrClient) {
    saveProfileMetadata(
        for: pubkey,
        pubkey: pubkey,
        name: name,
        picture: picture,
        about: about,
        appState: appState
    )
    subscribeToPostsForOwner(appState: appState, nostrClient: nostrClient)
}

private func createUserMetadata(from event: Event, name: String?, about: String?, picture: String?) -> UserMetadata {
    return UserMetadata(
        publicKey: event.pubkey,
        bech32PublicKey: {
            guard let bech32PublicKey = try? event.pubkey.bech32FromHex(hrp: "npub") else {
                return ""
            }
            return bech32PublicKey
        }(),
        name: name,
        about: about,
        picture: picture,
        createdAt: event.createdAt.date,
        nip05Verified: false
    )
}

private func updateChatMessages(for event: Event, with userMetadata: UserMetadata, appState: AppState) {
    DispatchQueue.main.async {
        appState.allUserMetadata.append(userMetadata)
        appState.allChatMessage = appState.allChatMessage.map { message in
            var updatedMessage = message
            if updatedMessage.publicKey == event.pubkey {
                updatedMessage.userMetadata = userMetadata
            }
            return updatedMessage
        }
    }
}

private func saveProfileMetadata(for key: String, pubkey: String, name: String?, picture: String?, about: String?, appState: AppState) {
    let metadata = ProfileMetadata(id: key, pubkey: pubkey, name: name, picture: picture, about: about)
    DispatchQueue.main.async {
        appState.profileMetadata = metadata
    }
}

private func subscribeToPostsForOwner(appState: AppState, nostrClient: NostrClient) {
    guard let public_key = appState.selectedOwnerAccount?.publicKey else { return }
    let postSubscription = Subscription(filters: [.init(authors: [public_key], kinds: [Kind.textNote])])
    nostrClient.add(subscriptions: [postSubscription])
}

