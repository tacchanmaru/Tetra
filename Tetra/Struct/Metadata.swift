struct Metadata: Identifiable, Encodable {
    var id: String
    var pubkey: String
    var name: String?
    var picture: String?
    var about: String?
}
