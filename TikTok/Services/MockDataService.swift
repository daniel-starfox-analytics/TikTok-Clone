import Foundation

class MockDataService {

    private var brands: [Brand] = []
    private var products: [Product] = []

    private static var isDataLoaded = false
    private static let loadDataQueue = DispatchQueue(label: "com.tiktok.mockdataservice.loaddataqueue")
    private static var loadError: Error?

    init(bundle: Bundle = .main) {
        // Ensure data is loaded only once, even if multiple instances are created.
        // This is a common pattern for a service that provides static/mock data.
        MockDataService.loadDataQueue.sync {
            if !MockDataService.isDataLoaded && MockDataService.loadError == nil {
                self.loadAllData(bundle: bundle) { error in
                    if let error = error {
                        print("Error loading mock data: \(error)")
                        MockDataService.loadError = error
                    }
                    MockDataService.isDataLoaded = true
                }
            }
        }
    }

    private func loadAllData(bundle: Bundle, completion: @escaping (Error?) -> Void) {
        let group = DispatchGroup()
        var brandsError: Error?
        var productsError: Error?

        group.enter()
        CSVParser.parse(fileName: "brands", bundle: bundle) { [weak self] (result: Result<[Brand], Error>) in
            switch result {
            case .success(let loadedBrands):
                self?.brands = loadedBrands
            case .failure(let error):
                brandsError = error
            }
            group.leave()
        }

        group.enter()
        CSVParser.parse(fileName: "products", bundle: bundle) { [weak self] (result: Result<[Product], Error>) in
            switch result {
            case .success(let loadedProducts):
                self?.products = loadedProducts
            case .failure(let error):
                productsError = error
            }
            group.leave()
        }

        group.notify(queue: .main) {
            if let brandsError = brandsError {
                completion(brandsError)
            } else if let productsError = productsError {
                completion(productsError)
            } else {
                completion(nil)
            }
        }
    }

    func fetchBrands() -> [Brand] {
        if let error = MockDataService.loadError {
            print("Cannot fetch brands due to previous loading error: \(error)")
            return []
        }
        guard MockDataService.isDataLoaded else {
            print("Warning: fetchBrands called before data was loaded.")
            return []
        }
        return self.brands
    }

    func fetchProducts() -> [Product] {
        if let error = MockDataService.loadError {
            print("Cannot fetch products due to previous loading error: \(error)")
            return []
        }
        guard MockDataService.isDataLoaded else {
            print("Warning: fetchProducts called before data was loaded.")
            return []
        }
        return self.products
    }

    // Potentially add methods to fetch products by brandID, etc.
    func fetchProducts(for brandId: String) -> [Product] {
        if let error = MockDataService.loadError {
            print("Cannot fetch products for brandID due to previous loading error: \(error)")
            return []
        }
        guard MockDataService.isDataLoaded else {
            print("Warning: fetchProducts(for brandId:) called before data was loaded.")
            return []
        }
        return self.products.filter { $0.brandID == brandId }
    }
}
