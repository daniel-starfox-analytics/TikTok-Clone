//
//  VerticalFeedCell.swift
//  TikTok
//
//  Created by Osaretin Uyigue on 9/9/20.
//  Copyright © 2020 Osaretin Uyigue. All rights reserved.
//

//
//  CollectionViewCell
//
//  Created by Osaretin Uyigue on 4/29/19.
//  Copyright © 2019 Osaretin Uyigue. All rights reserved.
//

import UIKit

// Define or update the delegate protocol
protocol VerticalFeedCellDelegate: AnyObject {
    func didTapPlayButton(play: Bool, cell: VerticalFeedCell) // Pass cell for context if needed by controller
    func handleDidTapExitController(cell: VerticalFeedCell)
    // func didTapCommentTextViewInCell(currentCell: VerticalFeedCell) // Commented out as per previous changes
    func didTapLikeButton(for post: TikTok.Models.Post, cell: VerticalFeedCell)
    func didTapViewProduct(for post: TikTok.Models.Post, cell: VerticalFeedCell) // New delegate method for product view
}

class VerticalFeedCell: UICollectionViewCell {
    
    //MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpSubViews()
        setUpPausePlayTapGesture()
        profileImageView.backgroundColor = .white
        handleRotateDiscJockey()
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleDidTapExitController))
        swipeGesture.direction = .right
        addGestureRecognizer(swipeGesture)
        commentInputAccessoryView.commentTextView.text = nil
        commentInputAccessoryView.commentTextView.placeholderLabel.text = "Add comment..."
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        commentInputAccessoryView.commentTextView.text = nil
        commentInputAccessoryView.commentTextView.placeholderLabel.text = "Add comment..."
    }
   
    
    //MARK: - Properties
    weak var delegate: VerticalFeedCellDelegate?
    fileprivate let kRotationAnimationKey = "com.myapplication.rotationanimationkey" // Any key

    // Changed to use the new Post model from TikTok/Models/Post.swift
    var post: TikTok.Models.Post? { // Assuming TikTok is the project name for module resolution
        didSet {
            guard let postUnwrapped = post else { return }

            // Video thumbnail: Original used post.postImageUrl.
            // New Post model doesn't have a direct thumbnail image URL from Product.
            // For now, set placeholder or clear the image.
            // A proper solution would involve adding a thumbnail property to Product/Post.
            postImageView.image = nil // Or some placeholder
            postImageView.backgroundColor = .darkGray // Placeholder background
            // Ensure Kingfisher doesn't try to load an old image if cell is reused
            postImageView.kf.cancelDownloadTask()


            // Profile Image
            if let profileImageStr = postUnwrapped.user.profileImageURL, !profileImageStr.isEmpty, let profileUrl = URL(string: profileImageStr) {
                profileImageView.kf.indicatorType = .activity
                profileImageView.kf.setImage(with: profileUrl, placeholder: UIImage(systemName: "person.circle.fill"))
            } else {
                profileImageView.image = UIImage(systemName: "person.circle.fill") // Default placeholder
                profileImageView.kf.cancelDownloadTask()
            }
            
            // Username
            usernameLabel.text = "@\(postUnwrapped.user.username)"
            
            // Caption
            captionLabel.text = postUnwrapped.caption ?? "" // Use empty string if caption is nil
            
            // Counts - using new Post model properties
            loveCountLabel.text = postUnwrapped.likes.formatUsingAbbrevation()
            commentCountLabel.text = postUnwrapped.commentsCount.formatUsingAbbrevation()
            shareCountLabel.text = postUnwrapped.sharesCount.formatUsingAbbrevation()
            
            // Artist image view (spinning disc)
            // Using user's profile image (brand logo) for the spinning disc for now.
            if let brandLogoStr = postUnwrapped.user.profileImageURL, !brandLogoStr.isEmpty, let brandLogoUrl = URL(string: brandLogoStr) {
                 artistImageView.kf.indicatorType = .activity
                 artistImageView.kf.setImage(with: brandLogoUrl, placeholder: UIImage(systemName: "music.note"))
            } else {
                artistImageView.image = UIImage(systemName: "music.note") // Placeholder
                artistImageView.kf.cancelDownloadTask()
            }
            
            // Music Title Label
            // Using product name as aplaceholder for the sound title.
            musicTitleLabel.text = postUnwrapped.caption ?? "Original Sound"
            
            // Update like button state
            updateLikeButtonAppearance()
        }
    }
    
     let postImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill // Changed to scaleAspectFill for better video presentation
        imageView.clipsToBounds = true
        return imageView
    }()
    
    
    fileprivate let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 50 / 2
        return imageView
    }()
    
    
    fileprivate let addButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: "addIcon")
        button.setImage(image?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false 
        return button
    }()
    
    
    fileprivate let loveButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "heart.fill") // Using SF Symbol
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.addTarget(self, action: #selector(handleLikeTapped), for: .touchUpInside) // Added target
        return button
    }()
    
    
    fileprivate let loveCountLabel: UILabel = {
        let label = UILabel()
        label.text = "1.8M"
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 12.5)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Shop Button (New)
    fileprivate let shopButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "bag.fill") // SF Symbol for shopping bag
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        // No target action for now
        return button
    }()

    // Save Button (New)
    fileprivate let saveButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "bookmark.fill") // SF Symbol for save/bookmark
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        // No target action for now
        return button
    }()
    
    // Comment button and label are removed as per requirements.
    // fileprivate let commentButton: UIButton = ... (Removed)
    // fileprivate let commentCountLabel: UILabel = ... (Removed)
   
    fileprivate let shareButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "arrowshape.turn.up.right.fill") // SF Symbol for share
        button.setImage(image?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        return button
    }()
    
    
    fileprivate let shareCountLabel: UILabel = {
        let label = UILabel()
        label.text = "15.5K"
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 12.5)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    
     let discJockeyView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = 50 / 2
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        view.addSubview(blurView)
        blurView.fillSuperview()
        return view
    }()
    
    
    fileprivate let artistImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 30 / 2
        imageView.backgroundColor = .yellow
//        let image = UIImage(named: "play")
//        imageView.image = image
        return imageView
    }()
    
    
    fileprivate let captionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 13.5)
        label.text = "samma video, annan musik \n #tiktok #samisays11 #objective c"
        return label
    }()
    
    
    fileprivate let usernameLabel: UILabel = {
       let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15.5)
        label.text = "@samisays11"
        label.textColor = .white
       return label
   }()
    
    
    fileprivate let musicIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        let image = UIImage(named: "music")
        imageView.image = image?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .white
        return imageView
    }()
    
    
    fileprivate let musicTitleLabel: UILabel = {
        let label = UILabel()
         label.font = UIFont.systemFont(ofSize: 13.5)
         label.text = "Original Sound - Artist Name" // Placeholder, will be updated by post data
         label.textColor = .white
        return label
    }()
    
    // View Product Button (New)
    fileprivate lazy var viewProductButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("View Product", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 5
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleViewProductTapped), for: .touchUpInside)
        return button
    }()
    
    fileprivate let pausePlayButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: "play") // This is an old asset name, consider SF Symbol if "play" doesn't exist
        button.setImage(image?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.white.withAlphaComponent(0.4)
        button.alpha = 0
        button.isUserInteractionEnabled = false
        return button
    }()

    
    let musicPlayingImageView: UIImageView = {
        let imageView = UIImageView()
        let image = UIImage(named: "music")
        imageView.image = image?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .lightGray
        return imageView
    }()
    
    
    
    lazy var backTapGestureView: UIView = {
        let view = UIView()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDidTapExitController))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tapGesture)
        view.isHidden = true
        return view
    }()
    
    
    
    fileprivate let backButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: "backArrow")
        button.setImage(image?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.white
        button.isUserInteractionEnabled = false
        return button
    }()

    
    fileprivate lazy var commentInputAccessoryView: CommentInputAccessoryView = {
        let view = CommentInputAccessoryView()
        view.isHidden = true
        view.backgroundColor = .clear
        view.commentTextView.textColor = .white
        view.commentTextView.backgroundColor = .clear
        view.emojisButton.tintColor = .lightGray
        view.mentionsButton.tintColor = .lightGray
        view.lineSeparatorView.alpha = 0
        return view
    }()
    
    
    lazy var commentTextViewTapGestureView: UIView = {
       let view = UIView()
       let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDidTapCommentTextView))
       view.addGestureRecognizer(tapGesture)
       view.isUserInteractionEnabled = true
       return view
   }()
    
    
     let progressView: UIProgressView = {
      let progressView = UIProgressView()
      progressView.isHidden = true
      progressView.progressTintColor = UIColor.white
      progressView.trackTintColor = UIColor.lightGray
      progressView.constrainHeight(constant: 0.75)
//      progressView.transform = progressView.transform.scaledBy(x: 1, y: 0.5)
      return progressView
   }()
    
    
    //MARK: - Handlers
    
    fileprivate func setUpSubViews() {
        addSubview(postImageView)
        addSubview(discJockeyView)
        // commentInputAccessoryView and commentTextViewTapGestureView are not added if comments are removed
        // addSubview(commentInputAccessoryView)
        // commentInputAccessoryView.addSubview(commentTextViewTapGestureView)
        addSubview(progressView) // Keep progress view for video loading indication if needed

        // Add new buttons to the view hierarchy
        addSubview(shopButton)
        addSubview(saveButton)

        addSubview(shareButton)
        addSubview(shareCountLabel)
        // addSubview(commentButton) // Removed
        // addSubview(commentCountLabel) // Removed
        addSubview(loveButton)
        addSubview(loveCountLabel)
        addSubview(profileImageView)
        addSubview(addButton) // This will be our "Follow Brand" button
        discJockeyView.addSubview(artistImageView)
        addSubview(musicIcon)
        addSubview(musicTitleLabel)
        addSubview(captionLabel)
        addSubview(usernameLabel)
        addSubview(viewProductButton) // Add new button
        insertSubview(pausePlayButton, aboveSubview: postImageView)
        insertSubview(backTapGestureView, aboveSubview: postImageView)
        backTapGestureView.addSubview(backButton)


        
        
        postImageView.fillSuperview()
        
        guard let maintabbarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController else {return}
        let height = maintabbarController.tabBar.frame.height //?? 49.0

        discJockeyView.anchor(top: nil, leading: nil, bottom: bottomAnchor, trailing: trailingAnchor, padding: .init(top: 0, left: 0, bottom: height + 15 , right: 8), size: .init(width: 50, height: 50))

        // commentInputAccessoryView.anchor... (Removed)
        // commentTextViewTapGestureView.fillSuperview() (Removed)
       
        // Anchor progressView to bottom of the cell, or above tab bar if accessory view is truly gone
        progressView.anchor(top: nil, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor, padding: .init(top: 0, left: 0, bottom: height, right: 0) ) // Assuming height is tabbar height
        

        // --- Vertical Stack of Icons ---
        // Disc Jockey View (Spinning Brand Logo) - Stays at the bottom of the stack
        discJockeyView.anchor(top: nil, leading: nil, bottom: bottomAnchor, trailing: trailingAnchor, padding: .init(top: 0, left: 0, bottom: height + 15 , right: 8), size: .init(width: 50, height: 50))

        // Share Button & Label
        shareButton.centerXAnchor.constraint(equalTo: discJockeyView.centerXAnchor).isActive = true
        shareButton.bottomAnchor.constraint(equalTo: discJockeyView.topAnchor, constant: -25).isActive = true // Adjusted spacing
        shareButton.constrainHeight(constant: 33)
        shareButton.constrainWidth(constant: 33)

        shareCountLabel.centerXAnchor.constraint(equalTo: shareButton.centerXAnchor).isActive = true
        shareCountLabel.topAnchor.constraint(equalTo: shareButton.bottomAnchor, constant: 5).isActive = true

        // Save Button (New) - No label for this one
        saveButton.centerXAnchor.constraint(equalTo: discJockeyView.centerXAnchor).isActive = true
        saveButton.bottomAnchor.constraint(equalTo: shareButton.topAnchor, constant: -25).isActive = true // Place above Share
        saveButton.constrainHeight(constant: 33)
        saveButton.constrainWidth(constant: 33)

        // Shop Button (New) - No label for this one
        shopButton.centerXAnchor.constraint(equalTo: discJockeyView.centerXAnchor).isActive = true
        shopButton.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -25).isActive = true // Place above Save
        shopButton.constrainHeight(constant: 33)
        shopButton.constrainWidth(constant: 33)
            
        // Love Button & Label
        loveButton.centerXAnchor.constraint(equalTo: discJockeyView.centerXAnchor).isActive = true
        loveButton.bottomAnchor.constraint(equalTo: shopButton.topAnchor, constant: -25).isActive = true // Place above Shop
        loveButton.constrainHeight(constant: 35)
        loveButton.constrainWidth(constant: 35)

        loveCountLabel.centerXAnchor.constraint(equalTo: loveButton.centerXAnchor).isActive = true
        loveCountLabel.topAnchor.constraint(equalTo: loveButton.bottomAnchor, constant: 5).isActive = true
    
        // Profile Image View (Brand Logo)
        profileImageView.centerXAnchor.constraint(equalTo: discJockeyView.centerXAnchor).isActive = true
        profileImageView.bottomAnchor.constraint(equalTo: loveButton.topAnchor, constant: -25).isActive = true // Place above Love
        profileImageView.constrainHeight(constant: 50)
        profileImageView.constrainWidth(constant: 50)
        
        // Add Button (Follow Brand Button) - Repurposed, ensure icon is updated
        // Using SF Symbol "plus.circle.fill" for the follow button icon
        let plusImage = UIImage(systemName: "plus.circle.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        addButton.setImage(plusImage, for: .normal) // Changed icon
        addButton.backgroundColor = .darkGray // Example to make it more visible if icon is simple
        addButton.layer.cornerRadius = 11 // Make it circular if it's 22x22
        
        addButton.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor).isActive = true
        // Position it slightly overlapping or just below the profileImageView
        addButton.centerYAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: -5).isActive = true
        addButton.constrainHeight(constant: 22)
        addButton.constrainWidth(constant: 22)
           
        artistImageView.centerInSuperview(size: .init(width: 30, height: 30))

        // --- Bottom Left Info ---
        musicIcon.anchor(top: nil, leading: leadingAnchor, bottom: bottomAnchor, trailing: nil, padding: .init(top: 0, left: 5, bottom: height + 15, right: 0), size: .init(width: 15, height: 15))
        
        musicTitleLabel.anchor(top: nil, leading: musicIcon.trailingAnchor, bottom: nil, trailing: discJockeyView.leadingAnchor, padding: .init(top: 0, left: 5, bottom: 0, right: 8))
        musicTitleLabel.centerYAnchor.constraint(equalTo: musicIcon.centerYAnchor, constant: -1.3).isActive = true
        
        captionLabel.anchor(top: nil, leading: leadingAnchor, bottom: musicIcon.topAnchor, trailing: discJockeyView.leadingAnchor, padding: .init(top: 0, left: 5, bottom: 10, right: 8))
        usernameLabel.anchor(top: nil, leading: captionLabel.leadingAnchor, bottom: captionLabel.topAnchor, trailing: captionLabel.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 10, right: 0))
        
        // Layout for viewProductButton (below captionLabel)
        viewProductButton.anchor(top: nil, leading: captionLabel.leadingAnchor, bottom: captionLabel.topAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: -35, right: 0)) // Place it below caption by spacing
        // Or, more robustly, anchor its top to captionLabel.bottomAnchor:
        // viewProductButton.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 8).isActive = true
        // viewProductButton.leadingAnchor.constraint(equalTo: captionLabel.leadingAnchor).isActive = true

        // Re-anchoring viewProductButton to be above captionLabel and usernameLabel for better visibility
        viewProductButton.anchor(top: nil, leading: leadingAnchor, bottom: usernameLabel.topAnchor, trailing: nil, padding: .init(top: 0, left: 8, bottom: 8, right: 0))


        pausePlayButton.centerInSuperview(size: .init(width: 60, height: 60))
        
        backTapGestureView.anchor(top: topAnchor, leading: leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 20, left: 0, bottom: 0, right: 0), size: .init(width: 60, height: 44))
        
        backButton.centerInSuperview(size: .init(width: 30, height: 30))
        
    

    }
    
    
    
    func handleShowOptionalSubViewsInCell() {
        commentInputAccessoryView.isHidden = false
        progressView.isHidden = false
        backTapGestureView.isHidden = false
    }
    
    
    func handleResetCellUI() {
        rotateView(view: discJockeyView)
        pausePlayButton.alpha = 0
    }
    
        
    

    @objc func handleDidTapCommentTextView() {
        commentInputAccessoryView.alpha = 0
        delegate?.didTapCommentTextViewInCell(currentCell: self)
    }
    
   fileprivate func setUpPausePlayTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDidTapPausePlayButton))
        addGestureRecognizer(tapGesture)
    }
    
    
    
    @objc fileprivate func handleDidTapPausePlayButton() {
        if pausePlayButton.alpha == 0 {
            pausePlayButton.alpha = 1
            delegate?.didTapPlayButton(play: false, cell: self)
            stopRotatingView(view: discJockeyView)
        } else {
            pausePlayButton.alpha = 0
            delegate?.didTapPlayButton(play: true, cell: self)
            rotateView(view: discJockeyView)
        }
    }
    
    @objc fileprivate func handleViewProductTapped() {
        guard let currentPost = post else { return }
        delegate?.didTapViewProduct(for: currentPost, cell: self)
    }

    @objc fileprivate func handleLikeTapped() {
        guard var currentPost = post else { return }
        currentPost.isLiked.toggle()
        if currentPost.isLiked {
            currentPost.likes += 1
        } else {
            currentPost.likes -= 1
        }
        post = currentPost // Assign back to trigger didSet and update UI elements if needed, or update directly

        updateLikeButtonAppearance()
        loveCountLabel.text = currentPost.likes.formatUsingAbbrevation() // Update count label

        delegate?.didTapLikeButton(for: currentPost, cell: self)
    }

    func updateLikeButtonAppearance() {
        if post?.isLiked == true {
            loveButton.tintColor = .red // Or your app's like color
            // Optionally change the image to a filled heart if using different images for selected state
            // loveButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        } else {
            loveButton.tintColor = .white
            // loveButton.setImage(UIImage(systemName: "heart"), for: .normal) // SF Symbol for unfilled heart
        }
    }

    
    
    func handleRotateDiscJockey() {
        rotateView(view: discJockeyView)
    }
    
    
    func rotateView(view: UIView, duration: Double = 3) {
        if view.layer.animation(forKey: kRotationAnimationKey) == nil {
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")

            rotationAnimation.fromValue = 0.0
            rotationAnimation.toValue = CGFloat.pi * 2.0
            rotationAnimation.duration = duration
            rotationAnimation.repeatCount = Float.infinity

            view.layer.add(rotationAnimation, forKey: kRotationAnimationKey)
        }
    }
       
    
    func stopRotatingView(view: UIView) {
        if view.layer.animation(forKey: kRotationAnimationKey) != nil {
            view.layer.removeAnimation(forKey: kRotationAnimationKey)
        }
    }
    
    
    func handleAnimateMusicLabel() {
        
    }
    
    
    
    @objc func handleDidTapExitController() {
        delegate?.handleDidTapExitController(cell: self)
    }
    
    //MARK: - Code Was Created by SamiSays11. Copyright © 2019 SamiSays11 All rights reserved.
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


//MARK: - TikTokDetailsVCDelegate
extension VerticalFeedCell: TikTokDetailsVCDelegate {
    
    func didTapZoomBack(scrollToIndexPath: IndexPath, isZoomingBackFromDetailsVC: Bool) {}
    
    func commentInputAccessoryViewDidResignFirstResponder(text: String) {
        if text.isEmpty == false {
        commentInputAccessoryView.commentTextView.placeholderLabel.text = nil
        }
        commentInputAccessoryView.commentTextView.text = text
        commentInputAccessoryView.alpha = 1
    }
}
