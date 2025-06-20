//
//  DiscoverVC.swift
//  TikTok
//
//  Created by Osaretin Uyigue on 10/12/20.
//  Copyright © 2020 Osaretin Uyigue. All rights reserved.
//

import UIKit
import AVKit // For AVPlayer
import Lottie // For Lottie animation (if used for loading)

// Using the new Post model types
typealias PostDataModel = TikTok.Models.Post
typealias UserDataModel = TikTok.Models.User

// Changed from UICollectionViewController to UIViewController
class DiscoverVC: UIViewController {
    
    //MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black // Match HomeFeedController
        navigationController?.navigationBar.isHidden = true // Typically hidden for feed VCs
        setupVerticalCollectionView()
        loadMockData()

        // Add observer for Buy Now button tap from overlay
        NotificationCenter.default.addObserver(self, selector: #selector(handleBuyNowNotification(_:)), name: .init("ProductDetailsOverlayBuyNowTapped"), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleBuyNowNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let urlString = userInfo["url"] as? String, let url = URL(string: urlString) else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            print("Cannot open URL: \(urlString)")
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.pause()
        if let cell = currentVerticalCell {
            cell.stopRotatingView(view: cell.discJockeyView)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isPlaying, let cell = currentVerticalCell {
            player.play()
            cell.rotateView(view: cell.discJockeyView)
        } else {
            playVideoForVisibleCells()
        }
    }
    
    //MARK: - Properties
    fileprivate var posts: [PostDataModel] = [] {
        didSet {
            verticalCollectionView.reloadData()
            if !posts.isEmpty && player.currentItem == nil {
                 playVideoForVisibleCells()
            }
        }
    }
    
    private var mockDataService = MockDataService()
    let VERTICAL_CELL_ID = "VERTICALCELLID_DISCOVER" // Unique ID

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
    
    // Video Player Properties (copied from HomeFeedController)
    fileprivate var isPlaying = false
    var timeObserverToken: Any?
    weak var currentVerticalCell: VerticalFeedCell?
    
    lazy var player: AVPlayer = {
        let player = AVPlayer()
        return player
    }()
    
    lazy var playerLayer: AVPlayerLayer = {
        let playerLayer = AVPlayerLayer()
        return playerLayer
    }()
    
    lazy var loadingAnimation: AnimationView = { // Optional: if you want a loading anim
        let animationView = AnimationView(name: "TikTokLoadingAnimation") // Ensure this animation exists
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.animationSpeed = 1
        animationView.loopMode = .loop
        animationView.isHidden = true
        return animationView
    }()

    //MARK: - Handlers
    fileprivate func setupVerticalCollectionView() {
        view.addSubview(verticalCollectionView)
        let tabBarHeight = self.tabBarController?.tabBar.frame.height ?? 49.0
        verticalCollectionView.fillSuperview(padding: .init(top: 0, left: 0, bottom: -tabBarHeight, right: 0))
        verticalCollectionView.register(VerticalFeedCell.self, forCellWithReuseIdentifier: VERTICAL_CELL_ID)

        view.addSubview(loadingAnimation) // Add loading animation to view
        loadingAnimation.centerInSuperview(size: .init(width: 50, height: 50))
    }
    
    fileprivate func loadMockData() {
        handlePlayAnimation(show: true)
        // Fetch a different set of products or shuffle them for Discover, or use the same for now.
        // For simplicity, using the same logic as HomeFeedController.
        // In a real app, Discover might fetch trending posts, different categories, etc.
        let fetchedProducts = mockDataService.fetchProducts().shuffled() // Example: Shuffle for different order
        let fetchedBrands = mockDataService.fetchBrands()
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
                likes: Int.random(in: 0...1000),
                commentsCount: Int.random(in: 0...500),
                sharesCount: Int.random(in: 0...300),
                productID: product.id,
                timestamp: Date()
            )
            tempPosts.append(post)
        }
        self.posts = tempPosts
        handlePlayAnimation(show: false)
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
    
    //MARK: - Video Playback Logic (Copied and adapted from HomeFeedController)
    fileprivate func removePeriodicTimeObserver() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
        playerLayer.removeFromSuperlayer()
    }

    fileprivate func handleFetchVideoFromCachingManagerUsing(urlString: String, completion: @escaping (URL?) -> ()) {
        CacheManager.shared.getFileWith(stringUrl: urlString) { result in
            switch result {
            case .success(let url):
                completion(url)
            case .failure(let error):
                print("Error fetching video: \(error)")
                completion(nil)
            }
        }
    }

    func initializeVideoPlayer(url: URL, cell: VerticalFeedCell) {
        removePeriodicTimeObserver()
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        playerLayer.player = player
        playerLayer.frame = cell.bounds
        playerLayer.videoGravity = .resizeAspectFill
        
        if playerLayer.superlayer == nil {
             cell.postImageView.layer.addSublayer(playerLayer)
        } else if playerLayer.superlayer != cell.postImageView.layer {
            playerLayer.removeFromSuperlayer()
            cell.postImageView.layer.addSublayer(playerLayer)
        }

        cell.handleResetCellUI()
        player.play()
        isPlaying = true
        currentVerticalCell = cell

        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.001, preferredTimescale: timeScale)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] _ in
            self?.handlePlayAnimation(show: false)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidPlayToEndTime),
                                               name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
    }
        
    @objc fileprivate func playerDidPlayToEndTime(notification: Notification) {
        player.seek(to: .zero)
        player.play()
        currentVerticalCell?.rotateView(view: currentVerticalCell!.discJockeyView)
    }
    
    private func playVideoForVisibleCells() {
        let visibleCells = verticalCollectionView.visibleCells.compactMap { $0 as? VerticalFeedCell }
        if let cell = visibleCells.first, let post = cell.post {
            handleSetUpVideoPlayer(cell: cell, videoUrlString: post.videoURL)
        }
    }
}

//MARK: - CollectionView Delegates
extension DiscoverVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VERTICAL_CELL_ID, for: indexPath) as! VerticalFeedCell
        cell.post = posts[indexPath.item]
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: verticalCollectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        playVideoForVisibleCells()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            playVideoForVisibleCells()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let videoCell = cell as? VerticalFeedCell, videoCell == currentVerticalCell {
            if player.rate != 0 {
                 player.pause()
                 isPlaying = false
                 videoCell.stopRotatingView(view: videoCell.discJockeyView)
            }
        }
    }
}

//MARK: - VerticalFeedCellDelegate
extension DiscoverVC: VerticalFeedCellDelegate {
    func didTapLikeButton(for post: PostDataModel, cell: VerticalFeedCell) {
        if let index = self.posts.firstIndex(where: { $0.id == post.id }) {
            self.posts[index].isLiked = post.isLiked
            self.posts[index].likes = post.likes
            // Optional: print("Updated post in DiscoverVC: ID \(self.posts[index].id), Liked: \(self.posts[index].isLiked), Likes: \(self.posts[index].likes)")
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

    func handleDidTapExitController(cell: VerticalFeedCell) { /* Not used */ }
    func didTapCommentTextViewInCell(currentCell: VerticalFeedCell) { /* Placeholder */ }
    
    func handleSetUpVideoPlayer(cell: VerticalFeedCell, videoUrlString: String) {
        if currentVerticalCell == cell && player.rate != 0 && player.error == nil {
            cell.rotateView(view: cell.discJockeyView)
            return
        }
        if let previousCell = currentVerticalCell, previousCell != cell {
             if player.currentItem != nil { player.pause() }
            previousCell.stopRotatingView(view: previousCell.discJockeyView)
        }
        handlePlayAnimation(show: true)
        currentVerticalCell = cell
        handleFetchVideoFromCachingManagerUsing(urlString: videoUrlString) { [weak self] (url) in
            guard let self = self, let urlUnwrapped = url else {
                self.handlePlayAnimation(show: false)
                return
            }
            if self.currentVerticalCell == cell {
                 self.initializeVideoPlayer(url: urlUnwrapped, cell: cell)
            } else {
                self.handlePlayAnimation(show: false)
            }
        }
    }
    
    func didTapPlayButton(play: Bool, cell: VerticalFeedCell) { // Added cell parameter to match delegate
        if play && player.currentItem != nil {
            player.play()
            isPlaying = true
            if cell == currentVerticalCell { // Ensure correct cell's animation
                 currentVerticalCell?.rotateView(view: currentVerticalCell!.discJockeyView)
            }
        } else {
            player.pause()
            isPlaying = false
            if cell == currentVerticalCell { // Ensure correct cell's animation
                currentVerticalCell?.stopRotatingView(view: currentVerticalCell!.discJockeyView)
            }
        }
    }
}
