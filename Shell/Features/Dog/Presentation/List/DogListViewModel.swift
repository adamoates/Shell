import Foundation
import Combine

@MainActor
final class DogListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var dogs: [Dog] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let fetchDogsUseCase: FetchDogsUseCase
    private let deleteDogUseCase: DeleteDogUseCase
    weak var coordinator: DogListCoordinatorDelegate?

    // MARK: - Initialization
    init(
        fetchDogsUseCase: FetchDogsUseCase,
        deleteDogUseCase: DeleteDogUseCase,
        coordinator: DogListCoordinatorDelegate? = nil
    ) {
        self.fetchDogsUseCase = fetchDogsUseCase
        self.deleteDogUseCase = deleteDogUseCase
        self.coordinator = coordinator
    }

    // MARK: - Actions
    func loadDogs() async {
        isLoading = true
        errorMessage = nil

        do {
            dogs = try await fetchDogsUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func addDogTapped() {
        coordinator?.didRequestAddDog()
    }

    func selectDog(_ dog: Dog) {
        coordinator?.didSelectDog(dog)
    }

    func deleteDog(_ dog: Dog) async {
        errorMessage = nil

        do {
            try await deleteDogUseCase.execute(id: dog.id)
            await loadDogs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logoutTapped() {
        coordinator?.didRequestLogout()
    }
}

// MARK: - Coordinator Delegate
protocol DogListCoordinatorDelegate: AnyObject {
    func didRequestAddDog()
    func didSelectDog(_ dog: Dog)
    func didRequestLogout()
}
