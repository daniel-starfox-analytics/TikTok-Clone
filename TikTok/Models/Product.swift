import Foundation

struct Product: Identifiable, Decodable {
    let id: String
    let name: String
    let videoURL: String
    let brandID: String
    let productPageURL: String
    var utmParameters: [String: String] = [:] // Initialize as empty
}
