# DROP - Social Product Discovery App

## Introduction

DROP is an iOS mobile application designed for discovering products through an engaging, vertical video feed. Users can explore product videos, get brief details, and navigate to purchase locations. The application is currently in an active development phase, with core features implemented using mock data for products and brands.

## Key Features

*   **Vertical Video Feeds:**
    *   **For You:** A personalized feed of product videos. (Currently shows all products, will be filtered by brand preferences).
    *   **Explore:** A feed for discovering a broader range of product videos. (Currently shows all products, potentially shuffled).
    *   Autoplay functionality for videos as they become visible.
*   **Product Interaction Icons (on each video post):**
    *   **Like:** Functional, updates like count and visual state.
    *   **Shop:** (UI Only) Intended to show product variants or related items.
    *   **Save:** (UI Only) Intended for saving products to a wishlist.
    *   **Share:** (UI Only) Intended for sharing product videos.
    *   **Follow Brand:** (UI Only) Intended for following brands.
*   **Product Details Overlay:**
    *   Accessible via a "View Product" button on video posts.
    *   Displays product name, brand name, and brand logo.
    *   Presented as a swipeable bottom sheet using PanModal.
*   **"Buy Now" Functionality:**
    *   Located within the Product Details Overlay.
    *   Redirects the user to the brand's product page via the device's default browser.
    *   Appends UTM parameters to the URL for tracking.
*   **Brand Preferences:**
    *   Users are prompted (after a few scrolls on their first session) to select their favorite brands.
    *   The "For You" feed content is then filtered based on these selections.
    *   Preferences are stored locally using `UserDefaults`.
*   **Navigation:**
    *   Basic three-tab structure: "For You," "Explore," and "Search" (Search tab is currently a placeholder).

## Tech Stack

*   **Language:** Swift
*   **UI:** UIKit (Programmatic UI with Auto Layout)
*   **Key Dependencies:**
    *   `PanModal`: For the draggable bottom sheet (Product Details Overlay, Brand Preferences).
    *   `Kingfisher`: For asynchronous image loading and caching (brand logos, user profile images in feed).
    *   *(Firebase was part of the original project for backend features like Auth, Database, Storage. While not currently active for data serving, the dependency might still be in the project for potential future use.)*
*   **Data:**
    *   Currently utilizes mock data loaded from CSV files for products and brands.

## How to Build/Run

1.  **Clone the repository.**
2.  **Ensure CocoaPods is installed.** If not, install it (`sudo gem install cocoapods`).
3.  **Navigate to the project directory in Terminal and run `pod install`** to install dependencies.
4.  **Open `TikTok.xcworkspace` in Xcode.** (Note: The project root file is still named `TikTok.xcworkspace` from its previous iteration).
5.  **Select an iOS simulator or a connected iOS device.**
6.  **Build and run the project.**

## Project Status & Next Steps

This project is a significant refactor and transformation of an older "TikTok Clone" application into "DROP," a product discovery platform. The current focus has been on establishing the core user experience for browsing and interacting with product-focused video content using mock data.

**Potential Next Steps:**

*   **Backend Integration:** Replace mock CSV data with a live backend service for products, brands, user accounts, and interactions.
*   **Full Feature Implementation:**
    *   Implement full functionality for Shop, Save, Share, and Follow Brand buttons.
    *   Develop the "Search" tab functionality.
    *   Consider user accounts and persistence of likes/saves/follows.
*   **UI/UX Polish:** Refine animations, transitions, and overall visual design.
*   **Content Strategy:** Define how product videos and information will be sourced and managed.
*   **Testing:** Add unit and UI tests.
*   **Project Renaming:** Fully rename project files and internal references from "TikTok" to "DROP".

---
*This README has been updated to reflect the current state of the "DROP" application.*
