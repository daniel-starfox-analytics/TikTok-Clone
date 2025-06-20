//
//  MainTabBarController.swift
//  TikTok
//
//  Created by Osaretin Uyigue on 9/6/20.
//  Copyright © 2020 Osaretin Uyigue. All rights reserved.
//

import UIKit
import FirebaseAuth
class MainTabBarController: UITabBarController {
    
    
    //MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Standard tab bar appearance
        tabBar.tintColor = .black // Color for selected item
        tabBar.unselectedItemTintColor = .gray // Color for unselected items
        tabBar.backgroundColor = .white // Background color of the tab bar
        tabBar.isTranslucent = false // Make it opaque

        // Remove default top line (shadow)
        tabBar.shadowImage = UIImage()
        tabBar.backgroundImage = UIImage()

        // Add a custom top border line if desired (optional)
        let topLineView = UIView(frame: CGRect(x: 0, y: 0, width: tabBar.frame.width, height: 0.5))
        topLineView.backgroundColor = UIColor.lightGray
        tabBar.addSubview(topLineView)

        delegate = self
        checkIfUserIsLoggedIn()
    }
    
    
    //MARK: - Properties
    // Removed tabBarSeperatorTopLine and progressView as they are no longer needed
    // for the simplified design.
    
    
    //MARK: - Tabbar Delegates
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        // Simplified: No special logic needed for specific tabs anymore in this basic setup.
        // The default behavior is sufficient.
        // You can add custom logic per tab index if needed later.
        // print("Selected tab with tag: \(item.tag)")
    }

    
    //MARK: - Handlers

    func handleSetUpViewControllers() {
        // For You Tab (using existing HomeFeedController)
        let forYouImage = handleSetUpTabbarImages(item: "house").first!
        let forYouSelectedImage = handleSetUpTabbarImages(item: "house").last!
        let forYouVC = HomeFeedController() // Assuming this is the correct controller for "For You"
        let forYouNavController = handleNavigationControllers(controller: forYouVC, selectedImage: forYouSelectedImage, image: forYouImage, title: "For You", tag: 0)

        // Explore Tab (using existing DiscoverVC)
        let exploreImage = handleSetUpTabbarImages(item: "safari").first!
        let exploreSelectedImage = handleSetUpTabbarImages(item: "safari").last!
        let exploreVC = DiscoverVC(collectionViewLayout: UICollectionViewFlowLayout()) // Assuming this is for "Explore"
        let exploreNavController = handleNavigationControllers(controller: exploreVC, selectedImage: exploreSelectedImage, image: exploreImage, title: "Explore", tag: 1)

        // Search Tab (using new SearchViewController)
        let searchImageSystemName = "magnifyingglass" // SF Symbol for search
        let searchImageConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .medium)
        let searchImg = UIImage(systemName: searchImageSystemName, withConfiguration: searchImageConfig)!
        let searchSelectedImg = UIImage(systemName: "\(searchImageSystemName).fill", withConfiguration: searchImageConfig) ?? searchImg // Fallback if fill is not available

        // Need to import SearchViewController, assuming it's in the "TikTok.Controllers.Search" module or similar
        // For now, let's assume the project name is TikTok and it's directly accessible.
        // If `SearchViewController` is in a module like `TikTok.SearchViewController`, adjust accordingly.
        // The file `SearchViewController.swift` was created in `TikTok/Controllers/Search/SearchViewController.swift`
        // Make sure the project is configured to find it.
        let searchVC = SearchViewController()
        let searchNavController = handleNavigationControllers(controller: searchVC, selectedImage: searchSelectedImg, image: searchImg, title: "Search", tag: 2)

        viewControllers = [forYouNavController, exploreNavController, searchNavController]

        // No special image insets needed for a simple 3-tab layout
    }
    
    
    // Updated to assign a tag to the tabBarItem for potential use in `didSelect`
    func handleNavigationControllers(controller: UIViewController, selectedImage: UIImage, image: UIImage, title: String?, tag: Int) -> UINavigationController {
        // Assuming MyNavigationController exists and is a custom UINavigationController.
        // If not, use a standard UINavigationController.
        // let navController = UINavigationController(rootViewController: controller)
        let navController = MyNavigationController(rootViewController: controller)
        navController.tabBarItem.image = image
        navController.tabBarItem.selectedImage = selectedImage
        navController.tabBarItem.title = title
        navController.tabBarItem.tag = tag // Assign tag
        return navController
    }
    
    
    
  
    fileprivate func handleSetUpTabbarImages(item: String) -> [UIImage] {
        // Using a slightly less bold weight for a more standard look, adjust as needed
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .medium)
        guard let normalImage = UIImage(systemName: item, withConfiguration: symbolConfig),
              let selectedImage = UIImage(systemName: "\(item).fill", withConfiguration: symbolConfig) else {
            // Fallback to a default icon if system icons fail (e.g., name typo)
            return [UIImage(systemName: "questionmark.circle")!, UIImage(systemName: "questionmark.circle.fill")!]
        }
        return [normalImage, selectedImage]
    }
    
    // Removed setTabBarToTransparent and restoreTabBar as we are using a standard appearance now.
    // If transparency is needed later, these can be re-added or modified.
    
    
    
    func checkIfUserIsLoggedIn() {
           if Auth.auth().currentUser == nil {
               
               DispatchQueue.main.async {
                   self.handlePresentLoginVc()
                
               }
           } else {
              handleSetUpViewControllers()
           }
       }
    
    
    fileprivate func handlePresentLoginVc() {
        let authVC = AuthViewController(authType: .signUp)
        let navController = UINavigationController(rootViewController: authVC)
        navController.modalPresentationStyle = .fullScreen //or .overFullScreen for transparency
        present(navController, animated: true, completion: nil)
    }
    
}


//MARK: - UITabBarControllerDelegate
extension MainTabBarController : UITabBarControllerDelegate {
    
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // Removed the logic that presented CreatePostVC modally.
        // All tabs are now selectable directly.
        return true
    }
}


// Assuming MyNavigationController.swift exists. If not, it should be created or replaced with UINavigationController.
// Example:
// class MyNavigationController: UINavigationController {
//     override func viewDidLoad() {
//         super.viewDidLoad()
//         // Custom navigation bar appearance if needed
//     }
// }

