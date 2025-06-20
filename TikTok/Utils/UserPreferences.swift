import Foundation

class UserPreferences {

    static let shared = UserPreferences()

    private let selectedBrandIDsKey = "selectedBrandIDs"
    private let hasShownBrandPromptKey = "hasShownBrandPrompt"

    private init() {}

    // MARK: - Selected Brand IDs
    func saveSelectedBrandIDs(_ ids: [String]) {
        UserDefaults.standard.set(ids, forKey: selectedBrandIDsKey)
    }

    func getSelectedBrandIDs() -> [String] {
        return UserDefaults.standard.stringArray(forKey: selectedBrandIDsKey) ?? []
    }

    // MARK: - Has Shown Brand Prompt
    func setHasShownBrandPrompt(_ hasShown: Bool) {
        UserDefaults.standard.set(hasShown, forKey: hasShownBrandPromptKey)
    }

    func getHasShownBrandPrompt() -> Bool {
        return UserDefaults.standard.bool(forKey: hasShownBrandPromptKey)
    }

    // MARK: - Reset (Optional - for testing)
    func resetBrandPreferences() {
        UserDefaults.standard.removeObject(forKey: selectedBrandIDsKey)
        UserDefaults.standard.removeObject(forKey: hasShownBrandPromptKey)
    }
}
