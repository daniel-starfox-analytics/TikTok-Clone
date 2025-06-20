import UIKit
import Kingfisher

class BrandPreferenceCell: UITableViewCell {

    static let identifier = "BrandPreferenceCell"

    // UI Elements
    private let brandLogoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 5 // Optional: if you want rounded corners for logos
        imageView.backgroundColor = .systemGray5 // Placeholder
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let brandNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .label // Adapts to light/dark mode
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark.circle.fill")
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true // Hidden by default
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(brandLogoImageView)
        contentView.addSubview(brandNameLabel)
        contentView.addSubview(checkmarkImageView)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            brandLogoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            brandLogoImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            brandLogoImageView.widthAnchor.constraint(equalToConstant: 40),
            brandLogoImageView.heightAnchor.constraint(equalToConstant: 40),

            brandNameLabel.leadingAnchor.constraint(equalTo: brandLogoImageView.trailingAnchor, constant: 12),
            brandNameLabel.trailingAnchor.constraint(equalTo: checkmarkImageView.leadingAnchor, constant: -12),
            brandNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    // MARK: - Configuration
    public func configure(with brand: Brand, isSelected: Bool) {
        brandNameLabel.text = brand.name
        if let logoUrlString = brand.logoURL, let logoUrl = URL(string: logoUrlString) {
            brandLogoImageView.kf.setImage(with: logoUrl, placeholder: UIImage(systemName: "photo"))
        } else {
            brandLogoImageView.image = UIImage(systemName: "photo")
        }
        checkmarkImageView.isHidden = !isSelected
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        brandLogoImageView.kf.cancelDownloadTask()
        brandLogoImageView.image = nil
        brandNameLabel.text = nil
        checkmarkImageView.isHidden = true
    }

    // Call this from the table view's didSelectRow/didDeselectRow to update UI
    func setSelectedState(_ isSelected: Bool) {
        checkmarkImageView.isHidden = !isSelected
    }
}
