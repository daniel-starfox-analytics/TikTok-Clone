//
//  HomeFeedController.swift
//  SamiSays11
//
//  Created by Osaretin Uyigue on 5/05/19.
//  Copyright © 2019 Osaretin Uyigue. All rights reserved.
//

import UIKit
import AVKit
import Lottie
// import Firebase // Firebase is no longer needed here

//let paddingForTabbar: CGFloat = 30 // This might not be needed if cells account for tab bar

// Using the new Post model
typealias PostDataModel = TikTok.Models.Post
typealias UserDataModel = TikTok.Models.User

class HomeFeedController: UIViewController {
    
    //MARK: Init
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        navigationController?.navigationBar.isHidden = true
        setupVerticalCollectionView()
        loadMockData() // Initial load respects preferences
        
        // Add observer for Buy Now button tap from overlay
        NotificationCenter.default.addObserver(self, selector: #selector(handleBuyNowNotification(_:)), name: .init("ProductDetailsOverlayBuyNowTapped"), object: nil)
    }

    // MARK: - Brand Preferences Properties
    private var scrollCountSinceLastPrompt = 0
    private let scrollsNeededForPrompt = 3 // Show prompt after 3 full page scrolls

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleBuyNowNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let urlString = userInfo["url"] as? String, let url = URL(string: urlString) else {
            return
        }
        // Could use SFSafariViewController for in-app browsing
        // For now, just open in default browser
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            print("Cannot open URL: \(urlString)")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.pause()
        // Stop disc animation for current cell if any
        if let cell = currentVerticalCell {
            cell.stopRotatingView(view: cell.discJockeyView)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Attempt to play only if the view is fully visible and a cell is active
        if isPlaying, let cell = currentVerticalCell {
            player.play()
            cell.rotateView(view: cell.discJockeyView)
        } else {
            // If not already playing, try to play the current cell upon appearing
             playVideoForVisibleCells()
        }
    }
    
    //MARK: - Properties
    fileprivate var isPlaying = false
    var timeObserverToken: Any?
    weak var currentVerticalCell: VerticalFeedCell?
    private var mockDataService = MockDataService()
    
    // Using the new PostDataModel (TikTok.Models.Post)
    fileprivate var posts: [PostDataModel] = [] {
        didSet {
            verticalCollectionView.reloadData()
            // Attempt to play the first video if data loads and not already playing
            // and if the view is currently visible (important for when preferences change)
            if !posts.isEmpty && player.currentItem == nil && self.view.window != nil {
                 playVideoForVisibleCells()
            }
        }
    }

    let VERTICAL_CELL_ID = "VERTICALCELLID"

    lazy var verticalCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.isPagingEnabled = true
        cv.showsVerticalScrollIndicator = false
        cv.backgroundColor = .clear
        return cv
    }()
    
    // Removed tikTokMenuBar
    
    lazy var player: AVPlayer = {
        let player = AVPlayer()
        return player
    }()
    
    lazy var playerLayer: AVPlayerLayer = {
        let playerLayer = AVPlayerLayer()
        return playerLayer
    }()
    
    lazy var loadingAnimation: AnimationView = {
        let animationView = AnimationView(name: "TikTokLoadingAnimation")
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.animationSpeed = 1
        animationView.loopMode = .loop
        return animationView
    }()
    
    //MARK: - Handlers
    fileprivate func setupVerticalCollectionView() {
        view.addSubview(verticalCollectionView)
        // Adjust bottom padding to account for tab bar if necessary
        let tabBarHeight = self.tabBarController?.tabBar.frame.height ?? 49.0
        verticalCollectionView.fillSuperview(padding: .init(top: 0, left: 0, bottom: -tabBarHeight, right: 0)) // Ensure cells are full screen
        verticalCollectionView.register(VerticalFeedCell.self, forCellWithReuseIdentifier: VERTICAL_CELL_ID)

        view.addSubview(loadingAnimation)
        loadingAnimation.centerInSuperview(size: .init(width: 50, height: 50))
        // Don't play loading animation by default, only when actually loading
        loadingAnimation.isHidden = true
    }
    
    fileprivate func loadMockData() {
        handlePlayAnimation(show: true)

        var fetchedProducts = mockDataService.fetchProducts()
        let fetchedBrands = mockDataService.fetchBrands()
        let selectedBrandIDs = UserPreferences.shared.getSelectedBrandIDs()

        // Filter products if brand preferences are set and not empty
        if !selectedBrandIDs.isEmpty {
            fetchedProducts = fetchedProducts.filter { selectedBrandIDs.contains($0.brandID) }
        }

        // If after filtering, no products match, we might want to show all products as a fallback
        // or show a specific message. For now, if filter results in empty, it will show empty.
        // Consider: if fetchedProducts.isEmpty && !selectedBrandIDs.isEmpty { fetchedProducts = mockDataService.fetchProducts() }


        var tempPosts: [PostDataModel] = []
        for product in fetchedProducts {
            let brandForProduct = fetchedBrands.first(where: { $0.id == product.brandID })
            let mockUser = UserDataModel(
                id: product.brandID,
                username: brandForProduct?.name ?? "Unknown Brand",
                profileImageURL: brandForProduct?.logoURL
            )
            let post = PostDataModel(
                id: product.id,
                videoURL: product.videoURL,
                user: mockUser,
                caption: product.name,
                likes: Int.random(in: 10...1000), // Initialized likes
                commentsCount: Int.random(in: 0...500),
                sharesCount: Int.random(in: 0...300),
                isLiked: false, // Initialized isLiked
                productID: product.id,
                timestamp: Date()
            )
            tempPosts.append(post)
        }

        // Stop current video before reloading data
        if player.rate != 0 {
            player.pause()
            currentVerticalCell?.stopRotatingView(view: currentVerticalCell!.discJockeyView)
            removePeriodicTimeObserver() // Clean up player state
        }
        currentVerticalCell = nil // Reset current cell

        self.posts = tempPosts
        handlePlayAnimation(show: false)

        // After loading data, reset collection view to the top if it's not empty
        if !self.posts.isEmpty {
            self.verticalCollectionView.setContentOffset(.zero, animated: false)
             // Crucially, after data reload and potential scroll to top,
             // explicitly try to play the first video if view is visible.
            DispatchQueue.main.async { // Ensure layout is complete
                 if self.view.window != nil { // Check if view is visible
                    self.playVideoForVisibleCells()
                 }
            }
        }
    }

    fileprivate func handlePlayAnimation(show: Bool) {
        if show {
            loadingAnimation.isHidden = false
            loadingAnimation.play()
        } else {
            loadingAnimation.pause()
            loadingAnimation.isHidden = true
        }
    }
    
    // Removed Firebase fetching methods: handleFetchCurrentUser, handleFetchPost
    
    fileprivate func removePeriodicTimeObserver() {
        // isPlaying = false // Don't necessarily set isPlaying to false here, just remove observer
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
        // Do not set player.currentItem to nil here, as it might be needed by the visible cell
        // player.replaceCurrentItem(with: nil)
        playerLayer.removeFromSuperlayer() // Remove old layer before adding to a new cell
        // print("stopped firing period observer, removed playerLayer")
    }
    
    fileprivate func handleFetchVideoFromCachingManagerUsing(urlString: String, completion: @escaping (URL?) -> ()) {
        // Assuming CacheManager.shared exists and is correctly implemented (e.g., VideoCacheManager.swift)
        CacheManager.shared.getFileWith(stringUrl: urlString) { result in
            switch result {
            case .success(let url):
                completion(url)
            case .failure(let error):
                print("Error fetching video from cache or network: \(error)")
                completion(nil)
            }
        }
    }
        
    func initializeVideoPlayer(url: URL, cell: VerticalFeedCell) {
        removePeriodicTimeObserver() // Clean up previous observers and player layer

        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        playerLayer.player = player // Assign player to existing layer
        playerLayer.frame = cell.bounds // Update frame
        playerLayer.videoGravity = .resizeAspectFill // Fill the cell bounds

        // Ensure layer is added to the correct view in cell (e.g., cell.postImageView.layer)
        // and only if it's not already there or if the cell is new.
        if playerLayer.superlayer == nil {
             cell.postImageView.layer.addSublayer(playerLayer)
        } else if playerLayer.superlayer != cell.postImageView.layer {
            playerLayer.removeFromSuperlayer()
            cell.postImageView.layer.addSublayer(playerLayer)
        }

        cell.handleResetCellUI() // Rotates disc jockey view, hides play button overlay
        player.play()
        isPlaying = true
        currentVerticalCell = cell // Set current cell

        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.001, preferredTimescale: timeScale)

        timeObserverToken = player.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] (progressTime) in
            guard let self = self, self.player.currentItem != nil else { return }
            // Progress view logic removed as MainTabBarController's progressView is gone.
            // If a per-cell progress is desired, it should be handled in VerticalFeedCell.
            self.handlePlayAnimation(show: false) // Hide loading animation if it was showing
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidPlayToEndTime),
                                               name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
    }

    @objc fileprivate func playerDidPlayToEndTime(notification: Notification) {
        player.seek(to: .zero)
        player.play()
        if let cell = currentVerticalCell {
            cell.rotateView(view: cell.discJockeyView) // Keep disc spinning
        }
    }
    
    private func playVideoForVisibleCells() {
        let visibleCells = verticalCollectionView.visibleCells.compactMap { $0 as? VerticalFeedCell }
        if let cell = visibleCells.first, let post = cell.post { // Play for the first fully visible cell
            handleSetUpVideoPlayer(cell: cell, videoUrlString: post.videoURL)
        }
    }
}

//MARK: - CollectionView Delegates for Vertical Feed
extension HomeFeedController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VERTICAL_CELL_ID, for: indexPath) as! VerticalFeedCell
        cell.post = posts[indexPath.item]
        cell.delegate = self // Set delegate for play/pause button taps
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Ensure cells are full screen, accounting for safe areas if navigation bar/status bar were visible
        return CGSize(width: view.frame.width, height: verticalCollectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    // Autoplay logic when scrolling stops & Brand Preference Prompt
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        playVideoForVisibleCells()

        // Check for brand preference prompt
        if !UserPreferences.shared.getHasShownBrandPrompt() {
            // A simple way to count "pages" scrolled.
            // This assumes each deceleration is roughly a new page.
            // More sophisticated logic might track actual distance or index changes.
            scrollCountSinceLastPrompt += 1

            print("Scroll count: \(scrollCountSinceLastPrompt)") // For debugging

            if scrollCountSinceLastPrompt >= scrollsNeededForPrompt {
                presentBrandPreferences()
                scrollCountSinceLastPrompt = 0 // Reset counter
            }
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            playVideoForVisibleCells()
        }
        // Note: Prompt logic is primarily in scrollViewDidEndDecelerating to avoid multiple triggers
        // during a single scroll-drag-release action.
    }

    private func presentBrandPreferences() {
        let allBrands = mockDataService.fetchBrands()
        let selectedIDs = UserPreferences.shared.getSelectedBrandIDs()
        
        let preferencesVC = BrandPreferencesViewController(allBrands: allBrands, selectedBrandIDs: selectedIDs)
        preferencesVC.delegate = self
        
        let navController = UINavigationController(rootViewController: preferencesVC)
        // For PanModal presentation, ensure `preferencesVC` itself conforms to `PanModalPresentable`
        // and set `navController.isNavigationBarHidden = true` if PanModal provides its own chrome,
        // or configure PanModal to work with the nav bar.
        // If `BrandPreferencesViewController` is already PanModal ready, can present `navController` using PanModal.
        // However, standard modal presentation is simpler here for a full-screen takeover.
        if UIDevice.current.userInterfaceIdiom == .pad {
             navController.modalPresentationStyle = .formSheet
        } else {
             navController.modalPresentationStyle = .pageSheet // Or .fullScreen
        }
        
        // Pause video before presenting modal
        if player.rate != 0 {
            player.pause()
            currentVerticalCell?.stopRotatingView(view: currentVerticalCell!.discJockeyView)
        }
        
        present(navController, animated: true) {
            // Set flag only after successful presentation and first time.
            // Or better, set it when the user dismisses the preferences screen for the first time.
            // For this iteration, setting it on presentation is simpler.
            if !UserPreferences.shared.getHasShownBrandPrompt() {
                 UserPreferences.shared.setHasShownBrandPrompt(true)
            }
        }
    }
    
    // Pause video of cells that are about to be hidden
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let videoCell = cell as? VerticalFeedCell, videoCell == currentVerticalCell {
            // Only pause if this cell was the one actively playing
            if player.rate != 0 { // Check if player is playing
                 player.pause()
                 isPlaying = false // Update global playing state
                 videoCell.stopRotatingView(view: videoCell.discJockeyView) // Stop disc animation
                 // Do not remove playerLayer here, it's managed by initializeVideoPlayer
                 // Do not set currentVerticalCell to nil here, let playVideoForVisibleCells handle it
            }
        }
    }
}


// MARK: - BrandPreferencesViewControllerDelegate
extension HomeFeedController: BrandPreferencesViewControllerDelegate {
    func brandPreferencesViewController(_ controller: BrandPreferencesViewController, didFinishWithSelectedBrandIDs selectedIDs: [String]) {
        UserPreferences.shared.saveSelectedBrandIDs(selectedIDs)

        // Reload data with new preferences
        // Pause player before reloading
        if player.rate != 0 {
            player.pause()
            // isPlaying = false // Already handled by viewWillDisappear or cell didEndDisplaying
        }
        // It's crucial to reset player state that might be tied to old cells/items
        removePeriodicTimeObserver()
        currentVerticalCell = nil // No cell is "current" after a full reload

        loadMockData() // This will now use the new preferences
    }
}

//MARK: - VerticalFeedCellDelegate
extension HomeFeedController: VerticalFeedCellDelegate {
    func didTapLikeButton(for post: PostDataModel, cell: VerticalFeedCell) {
        if let index = self.posts.firstIndex(where: { $0.id == post.id }) {
            self.posts[index].isLiked = post.isLiked
            self.posts[index].likes = post.likes

            // Optional: To confirm data is updated in the controller's source
            // print("Updated post in HomeFeedController: ID \(self.posts[index].id), Liked: \(self.posts[index].isLiked), Likes: \(self.posts[index].likes)")

            // The cell already updates its UI. If further non-local UI updates were needed,
            // you might reload the cell, but it's often not necessary for just a like.
            // verticalCollectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
        }
    }

    func didTapViewProduct(for post: PostDataModel, cell: VerticalFeedCell) {
        guard let product = mockDataService.fetchProducts().first(where: { $0.id == post.productID }) else {
            print("Error: Product not found for ID \(post.productID)")
            return
        }
        let brand = mockDataService.fetchBrands().first(where: { $0.id == product.brandID })

        let productOverlayVC = ProductDetailsOverlayVC(product: product, brand: brand)
        presentPanModal(productOverlayVC)
    }

    func handleDidTapExitController(cell: VerticalFeedCell) {
        // Not used in this simplified feed
    }
    
    func didTapCommentTextViewInCell(currentCell: VerticalFeedCell) {
        // Placeholder for comment functionality (currently removed from cell)
        // print("Comment tapped for post: \(currentCell.post?.id ?? "N/A")")
    }
    
    func handleSetUpVideoPlayer(cell: VerticalFeedCell, videoUrlString: String) {
        if currentVerticalCell == cell && player.rate != 0 && player.error == nil {
            // If the current cell is already playing this video, do nothing
            // or ensure UI is in correct playing state (e.g. disc spinning)
            cell.rotateView(view: cell.discJockeyView)
            return
        }

        // If another cell was playing, pause its video and stop its animation
        if let previousCell = currentVerticalCell, previousCell != cell {
            // Check if player is associated with previous cell and pause
             if player.currentItem != nil { // A simple check, more robust would be to track player item per cell
                player.pause() // Pause the shared player
             }
            previousCell.stopRotatingView(view: previousCell.discJockeyView)
        }

        handlePlayAnimation(show: true) // Show loading animation
        currentVerticalCell = cell // Set the new current cell

        handleFetchVideoFromCachingManagerUsing(urlString: videoUrlString) { [weak self] (url) in
            guard let self = self, let urlUnwrapped = url else {
                self.handlePlayAnimation(show: false) // Hide loading animation if URL fetch fails
                return
            }
            // Ensure we are still working with the same cell, in case of quick scrolls
            if self.currentVerticalCell == cell {
                 self.initializeVideoPlayer(url: urlUnwrapped, cell: cell)
            } else {
                // The cell has changed since we started fetching, abort.
                // Another call to handleSetUpVideoPlayer will occur for the new current cell.
                self.handlePlayAnimation(show: false)
            }
        }
    }
    
    func didTapPlayButton(play: Bool, cell: VerticalFeedCell) { // This is from VerticalFeedCell's own pause/play overlay
        if play && player.currentItem != nil {
            player.play()
            isPlaying = true
            // Ensure the correct cell's disc is rotating if it's the current one
            if cell == currentVerticalCell {
                 currentVerticalCell?.rotateView(view: currentVerticalCell!.discJockeyView)
            }
        } else {
            player.pause()
            isPlaying = false
            if cell == currentVerticalCell {
                 currentVerticalCell?.stopRotatingView(view: currentVerticalCell!.discJockeyView)
            }
        }
    }
}
