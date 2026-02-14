import UIKit

/// Protocol for DogCoordinator to communicate with parent
protocol DogCoordinatorDelegate: AnyObject {
    func dogCoordinatorDidRequestLogout(_ coordinator: DogCoordinator)
}

/// Coordinator for the Dog feature flow
final class DogCoordinator: Coordinator {
    // MARK: - Properties
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: Coordinator?
    weak var delegate: DogCoordinatorDelegate?

    // MARK: - Dependencies
    private let dependencyContainer: AppDependencyContainer

    // MARK: - Initialization
    init(
        navigationController: UINavigationController,
        dependencyContainer: AppDependencyContainer
    ) {
        self.navigationController = navigationController
        self.dependencyContainer = dependencyContainer
    }

    // MARK: - Coordinator
    func start() {
        Task {
            // Validate session before showing Dog feature
            guard await hasValidSession() else {
                // No valid session, request logout
                await MainActor.run {
                    delegate?.dogCoordinatorDidRequestLogout(self)
                }
                return
            }

            // Session is valid, show dog list
            await MainActor.run {
                showDogList()
            }
        }
    }

    func finish() {
        parentCoordinator?.childDidFinish(self)
    }

    // MARK: - Session Validation

    private func hasValidSession() async -> Bool {
        let sessionRepository = dependencyContainer.makeSessionRepository()

        do {
            guard let session = try await sessionRepository.getCurrentSession() else {
                return false
            }
            return session.isValid
        } catch {
            return false
        }
    }

    // MARK: - Navigation
    private func showDogList() {
        let listViewModel = dependencyContainer.makeDogListViewModel()
        listViewModel.coordinator = self

        let listViewController = DogListViewController(viewModel: listViewModel)
        navigationController.pushViewController(listViewController, animated: true)
    }

    private func showDogEditor(dog: Dog? = nil) {
        let editorViewModel = dependencyContainer.makeDogEditorViewModel(dog: dog)
        editorViewModel.coordinator = self

        let editorViewController = DogEditorViewController(viewModel: editorViewModel)
        let navController = UINavigationController(rootViewController: editorViewController)

        navigationController.present(navController, animated: true)
    }
}

// MARK: - DogListCoordinatorDelegate
extension DogCoordinator: DogListCoordinatorDelegate {
    func didRequestAddDog() {
        showDogEditor()
    }

    func didSelectDog(_ dog: Dog) {
        showDogEditor(dog: dog)
    }

    func didRequestLogout() {
        delegate?.dogCoordinatorDidRequestLogout(self)
    }
}

// MARK: - DogEditorCoordinatorDelegate
extension DogCoordinator: DogEditorCoordinatorDelegate {
    func didSaveDog() {
        navigationController.dismiss(animated: true)
    }

    func didCancelEditing() {
        navigationController.dismiss(animated: true)
    }
}
