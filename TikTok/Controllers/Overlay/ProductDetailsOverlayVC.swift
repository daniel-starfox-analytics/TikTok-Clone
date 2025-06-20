import UIKit
import PanModal

class ProductDetailsOverlayVC: UIViewController {

    // MARK: - Properties
    private let product: Product
    private let brand: Brand? // Optional: if brand info is fetched separately or might be missing

    // UI Elements
    private lazy var productNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var brandNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .darkGray
        label.textAlignment = .center
        return label
    }()

    private lazy var brandLogoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        // Placeholder for logo
        imageView.backgroundColor = .lightGray.withAlphaComponent(0.5)
        imageView.layer.cornerRadius = 20 // Example: if you want a circular logo
        return imageView
    }()

    // Assuming no separate product description field in Product model for now
    // private lazy var productDescriptionLabel: UILabel = { ... }()

    private lazy var buyNowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Buy Now", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue // Or your app's theme color
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(handleBuyNowTapped), for: .touchUpInside)
        return button
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .lightGray
        button.addTarget(self, action: #selector(handleCloseTapped), for: .touchUpInside)
        return button
    }()


    // MARK: - Init
    init(product: Product, brand: Brand?) {
        self.product = product
        self.brand = brand
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        populateData()
    }

    // MARK: - UI Setup
    private func setupUI() {
        let mainStackView = UIStackView(arrangedSubviews: [
            brandLogoImageView,
            productNameLabel,
            brandNameLabel,
            buyNowButton
        ])
        mainStackView.axis = .vertical
        mainStackView.spacing = 16
        mainStackView.alignment = .center
        mainStackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mainStackView)
        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false


        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),

            brandLogoImageView.widthAnchor.constraint(equalToConstant: 80),
            brandLogoImageView.heightAnchor.constraint(equalToConstant: 80),

            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            // Center stackView vertically if shortFormHeight is tall enough, or pin to top.
            // For PanModal, the height is dynamic, so centering might be fine.
            mainStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40), // Shift up a bit

            buyNowButton.heightAnchor.constraint(equalToConstant: 50),
            buyNowButton.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor, constant: 20),
            buyNowButton.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor, constant: -20)
        ])
    }

    // MARK: - Data Population
    private func populateData() {
        productNameLabel.text = product.name
        brandNameLabel.text = brand?.name ?? "Brand" // Fallback if brand is nil

        if let logoUrlString = brand?.logoURL, let logoUrl = URL(string: logoUrlString) {
            // Use Kingfisher or another image loading library if available and needed for web URLs
            // For now, assuming direct image loading or placeholder
            // Example: brandLogoImageView.kf.setImage(with: logoUrl)
            // If logoURL is a local asset name:
            // brandLogoImageView.image = UIImage(named: logoUrlString)
            // For now, just keeping placeholder. Kingfisher is in the project.
            brandLogoImageView.kf.setImage(with: logoUrl, placeholder: UIImage(systemName: "photo"))
        } else {
             brandLogoImageView.image = UIImage(systemName: "photo") // Default SF Symbol placeholder
        }
    }

    // MARK: - Actions
    @objc private func handleBuyNowTapped() {
        // Open product.productPageURL in a SFSafariViewController or external browser
        print("Buy Now tapped for product: \(product.name), URL: \(product.productPageURL)")
        guard let url = URL(string: product.productPageURL) else { return }
        // UIApplication.shared.open(url, options: [:], completionHandler: nil)
        // For SFSafariViewController:
        // let safariVC = SFSafariViewController(url: url)
        // present(safariVC, animated: true, completion: nil)
        // This will be handled by the presenting view controller for better control.

        var urlComponents = URLComponents(string: product.productPageURL)
        var queryItems = urlComponents?.queryItems ?? []

        for (key, value) in product.utmParameters {
            // Add new UTM parameter, replacing if key already exists from base URL's query
            if let existingIndex = queryItems.firstIndex(where: { $0.name == key }) {
                queryItems[existingIndex].value = value
            } else {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
        }
        urlComponents?.queryItems = queryItems

        if let finalURLString = urlComponents?.string {
            NotificationCenter.default.post(name: .init("ProductDetailsOverlayBuyNowTapped"), object: nil, userInfo: ["url": finalURLString])
        } else {
            // Fallback to base URL if components manipulation fails
            NotificationCenter.default.post(name: .init("ProductDetailsOverlayBuyNowTapped"), object: nil, userInfo: ["url": product.productPageURL])
            print("Warning: Could not construct URL with UTM parameters, using base URL.")
        }

        dismiss(animated: true, completion: nil)
    }

    @objc private func handleCloseTapped() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - PanModalPresentable
extension ProductDetailsOverlayVC: PanModalPresentable {
    var panScrollable: UIScrollView? {
        nil // No specific scroll view in this simple layout
    }

    var shortFormHeight: PanModalHeight {
        // Adjust based on content. ~60% of screen height might be a good start.
        return .contentHeight(view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height > 400 ? 400 : .contentHeight(300))
        // return .relative(percent: 0.5)
    }

    var longFormHeight: PanModalHeight {
        // Can be same as short form if content is fixed, or taller if scrollable.
         return .contentHeight(view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height > 400 ? 400 : .contentHeight(300))
       // return .maxHeightWithTopInset(40)
    }

    var cornerRadius: CGFloat {
        return 20.0 // Standard corner radius for PanModal
    }

    var allowsDragToDismiss: Bool {
        return true
    }

    var allowsTapToDismiss: Bool {
        return true
    }

    var showDragIndicator: Bool {
        return true // Show the small drag indicator at the top
    }
}
