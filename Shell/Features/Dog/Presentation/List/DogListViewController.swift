import UIKit
import Combine

final class DogListViewController: UIViewController {
    // MARK: - Properties
    private let viewModel: DogListViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(UITableViewCell.self, forCellReuseIdentifier: "DogCell")
        table.delegate = self
        table.dataSource = self
        return table
    }()

    private lazy var addButton: UIBarButtonItem = {
        UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
    }()

    private lazy var logoutButton: UIBarButtonItem = {
        UIBarButtonItem(
            title: "Logout",
            style: .plain,
            target: self,
            action: #selector(logoutButtonTapped)
        )
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Initialization
    init(viewModel: DogListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        loadDogs()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadDogs()
    }

    // MARK: - Setup
    private func setupUI() {
        title = "Dogs"
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = logoutButton
        navigationItem.rightBarButtonItem = addButton
        navigationItem.hidesBackButton = true

        view.addSubview(tableView)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func bindViewModel() {
        viewModel.$dogs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let error = errorMessage {
                    self?.showError(error)
                }
            }
            .store(in: &cancellables)
    }

    private func loadDogs() {
        Task {
            await viewModel.loadDogs()
        }
    }

    // MARK: - Actions
    @objc private func addButtonTapped() {
        viewModel.addDogTapped()
    }

    @objc private func logoutButtonTapped() {
        viewModel.logoutTapped()
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension DogListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.dogs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DogCell", for: indexPath)
        let dog = viewModel.dogs[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = dog.name
        content.secondaryText = "\(dog.breed) • \(dog.age) years old"
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }

        let dog = viewModel.dogs[indexPath.row]
        Task {
            await viewModel.deleteDog(dog)
        }
    }
}

// MARK: - UITableViewDelegate
extension DogListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let dog = viewModel.dogs[indexPath.row]
        viewModel.selectDog(dog)
    }
}
