import Foundation

// Assuming User.swift exists in TikTok/Models/ and defines a Decodable User struct.
// If not, a placeholder User struct would be needed here or User specific fields.
// For example:
// struct User: Identifiable, Decodable {
//     let id: String
//     let username: String
//     let profileImageURL: String?
// }

struct Post: Identifiable, Decodable {
    let id: String
    let videoURL: String // This will likely be sourced from Product.videoURL
    // let userID: String // If User struct is not directly embedded or available
    let user: User // Assuming User.swift provides a Decodable User struct

    let caption: String?
    var likes: Int
    var commentsCount: Int // Renamed from 'comments' to avoid confusion if 'comments' is a list of comment objects later
    var sharesCount: Int // Renamed from 'shares' for clarity
    var isLiked: Bool = false // New property for like state

    let productID: String // ID to link to a Product from MockDataService

    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case videoURL
        case user
        case caption
        case likes
        case commentsCount
        case sharesCount
        case productID
        case timestamp
        // isLiked is not included in CodingKeys by default if it's always locally managed
        // or if it's not part of the CSV/JSON decoding directly.
        // If it were to be decoded, add: case isLiked
    }

    // Example Initializer (if needed for manual creation, Decodable handles CSV/JSON cases)
    init(id: String = UUID().uuidString,
         videoURL: String,
         user: User,
         caption: String? = nil,
         likes: Int = 0,
         commentsCount: Int = 0,
         sharesCount: Int = 0,
         isLiked: Bool = false, // Added to initializer
         productID: String,
         timestamp: Date = Date()) {
        self.id = id
        self.videoURL = videoURL
        self.user = user
        self.caption = caption
        self.likes = likes
        self.commentsCount = commentsCount
        self.sharesCount = sharesCount
        self.isLiked = isLiked
        self.productID = productID
        self.timestamp = timestamp
    }
}

// Data Flow Consideration (Comment):
//
// How Post objects would be instantiated with product integration:
//
// 1. Fetch Products: Obtain `[Product]` from `MockDataService.fetchProducts()`.
// 2. Create Posts: For each `Product` (or a subset of them), a `Post` object will be created.
//    - `Post.id`: Can be a new UUID or derived.
//    - `Post.videoURL`: Will be set to `Product.videoURL`.
//    - `Post.productID`: Will be set to `Product.id`.
//    - `Post.user`: This needs to be determined.
//        - If we have a list of mock users, we can assign users to posts.
//        - For simplicity, a single mock user or a few predefined mock users could be used initially.
//        - The `User` object itself would need to be created (e.g., from a `users.csv` or hardcoded).
//    - `Post.caption`: Could be derived from `Product.name` or be a separate field.
//    - `Post.likes`, `Post.commentsCount`, `Post.sharesCount`: Can be initialized to 0 or random mock values.
//    - `Post.timestamp`: Can be set to the current date or staggered if creating multiple mock posts.
//
// Example snippet (conceptual):
//
// let mockDataService = MockDataService()
// let products = mockDataService.fetchProducts()
// var posts: [Post] = []
//
// // Assume mockUsers is an array of User objects
// let mockUser = User(id: "user123", username: "Shopper1", profileImageURL: nil) // Example
//
// for product in products {
//     let post = Post(
//         videoURL: product.videoURL,
//         user: mockUser, // Assign a mock user
//         caption: "Check out this product: \(product.name)!",
//         productID: product.id,
//         timestamp: Date() // Or a more sophisticated timestamp assignment
//     )
//     posts.append(post)
// }
//
// These `Post` objects would then be used to populate the app's feed.
// The actual fetching of posts for the feed will eventually be updated
// in `HomeViewController` (or similar) to use this new local mock data
// generation strategy instead of (or alongside) Firebase.
//
// For now, the `Post` model update is primarily for client-side data handling
// and to establish the link (`productID`) to the `Product` data.
// The existing Firebase fetching logic for posts (if any) will be addressed later.
// We are not modifying how posts are fetched from Firebase in this subtask.
// The focus is on the `Post` model structure and its relation to `Product`.
//
// If `User.swift` was not in the initial project, a basic `User` struct should be added to `TikTok/Models/`.
// Based on the initial `ls()` output, `TikTok/Models/User.swift` exists.
// The `User` struct in `Post.swift` assumes `User.swift` defines a `Decodable` struct `User`
// with at least `id`, `username`, and `profileImageURL` (optional).
// If its structure is different, `Post.user` type or its usage in mock data creation will need adjustment.
//
// The `Decodable` conformance allows `Post` objects to be potentially initialized from other
// data sources in the future (e.g., a JSON file representing posts if we move away from pure mock generation).
// The provided initializer is for convenience for programmatic creation.
//
// The properties like `likes`, `commentsCount`, `sharesCount` are included as they are typical
// for a post model and will likely be needed for UI representation.
//
// The `videoURL` in `Post` will directly correspond to `Product.videoURL`.
// This means that a "post" in our app is essentially a promotional video for a "product".
//
// The `productID` allows us to easily fetch the full `Product` details using `MockDataService.fetchProducts().first(where: { $0.id == post.productID })`
// when a user interacts with a post and we need to show more product information (e.g., navigate to the product page).
//
// No properties from a hypothetical original Post model are being removed as we are creating it anew.
// We've included common properties relevant to a video post and the new `productID` link.
//
// End of Data Flow Consideration comment.
//
// Ensure User.swift contains something like:
// struct User: Identifiable, Decodable {
//     let id: String
//     let username: String
//     let profileImageURL: String?
//     // other user-related properties
// }
