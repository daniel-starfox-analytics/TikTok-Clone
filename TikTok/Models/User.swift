import Foundation

struct User: Identifiable, Decodable {
    let id: String
    let username: String
    let profileImageURL: String?
    // Add any other properties you might need from a user,
    // but keep it simple for now as it's derived from Brand data.
}
