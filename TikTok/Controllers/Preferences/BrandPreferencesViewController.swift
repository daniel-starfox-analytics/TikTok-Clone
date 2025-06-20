import UIKit
import PanModal

protocol BrandPreferencesViewControllerDelegate: AnyObject {
    func brandPreferencesViewController(_ controller: BrandPreferencesViewController, didFinishWithSelectedBrandIDs: [String])
}

class BrandPreferencesViewController: UIViewController {

    // MARK: - Properties
    weak var delegate: BrandPreferencesViewControllerDelegate?

    private let allBrands: [Brand]
    private var selectedBrandIDs: Set<String> // Use a Set for efficient lookup and modification

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(BrandPreferenceCell.self, forCellReuseIdentifier: BrandPreferenceCell.identifier)
        tableView.allowsMultipleSelection = true
        return tableView
    }()

    private lazy var doneButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
    }()

    private lazy var resetButton: UIBarButtonItem = {
        return UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(resetButtonTapped))
    }()


    // MARK: - Init
    init(allBrands: [Brand], selectedBrandIDs: [String]) {
        self.allBrands = allBrands
        self.selectedBrandIDs = Set(selectedBrandIDs)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Customize Your Feed"
        view.backgroundColor = .systemBackground

        setupTableView()
        setupNavigationBar()
    }

    // MARK: - UI Setup
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = doneButton
        navigationItem.leftBarButtonItem = resetButton
        // For PanModal presentation, the navigation bar might be part of PanModal's container.
        // If presented as a standard modal with its own navigation controller, this is fine.
        // If presented directly with PanModal, PanModal usually adds its own title bar.
        // We can customize PanModal's title view if needed, or ensure this VC is wrapped in a NavController.
    }

    // MARK: - Actions
    @objc private func doneButtonTapped() {
        delegate?.brandPreferencesViewController(self, didFinishWithSelectedBrandIDs: Array(selectedBrandIDs))
        dismiss(animated: true, completion: nil)
    }

    @objc private func resetButtonTapped() {
        selectedBrandIDs.removeAll()
        tableView.reloadData()
        // Optionally, immediately save this reset state
        // UserPreferences.shared.saveSelectedBrandIDs([])
        // And inform delegate if live update is desired, or wait for "Done"
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension BrandPreferencesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allBrands.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BrandPreferenceCell.identifier, for: indexPath) as? BrandPreferenceCell else {
            return UITableViewCell()
        }
        let brand = allBrands[indexPath.row]
        let isSelected = selectedBrandIDs.contains(brand.id)
        cell.configure(with: brand, isSelected: isSelected)
        // tableView.selectRow/deselectRow is not needed here due to cell.configure handling checkmark
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let brand = allBrands[indexPath.row]
        if selectedBrandIDs.contains(brand.id) {
            selectedBrandIDs.remove(brand.id)
        } else {
            selectedBrandIDs.insert(brand.id)
        }
        // Update cell's appearance directly
        if let cell = tableView.cellForRow(at: indexPath) as? BrandPreferenceCell {
            cell.setSelectedState(selectedBrandIDs.contains(brand.id))
        }
        // No need to reload the whole table, just the cell's selection state.
        // tableView.reloadRows(at: [indexPath], with: .none) // This would also work but is heavier
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60 // Adjust as needed
    }
}

// MARK: - PanModalPresentable (Optional - if you want to present this with PanModal)
// If using PanModal, it's often better to present a UINavigationController whose root is this VC.
extension BrandPreferencesViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return tableView
    }

    var shortFormHeight: PanModalHeight {
        return .contentHeight(view.frame.height * 0.6) // Example: 60% of screen
    }

    var longFormHeight: PanModalHeight {
        return .maxHeightWithTopInset(topLayoutGuide.length + 20) // Adjust top inset as needed
    }

    var showDragIndicator: Bool {
        return true // Default is true, but can be explicit
    }

     var allowsTapToDismiss: Bool {
        return false // User must tap Done or Reset
    }

    var allowsDragToDismiss: Bool {
        return false // User must tap Done or Reset
    }

    // This helps PanModal to use our navigationItem.title
     var panModal쇤View: UIView? {
        return navigationController?.navigationBar
    }

    var shouldRoundTopCorners: Bool {
        return true
    }
}
