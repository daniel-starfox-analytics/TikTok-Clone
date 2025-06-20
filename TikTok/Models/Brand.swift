import Foundation

struct Brand: Identifiable, Decodable {
    let id: String
    let name: String
    let logoURL: String?
}
