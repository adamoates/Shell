import Foundation
import Combine

@MainActor
final class DogEditorViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var name = ""
    @Published var breed = ""
    @Published var age = ""
    @Published var medicalNotes = ""
    @Published var behaviorNotes = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let createDogUseCase: CreateDogUseCase
    private let updateDogUseCase: UpdateDogUseCase
    weak var coordinator: DogEditorCoordinatorDelegate?

    // MARK: - State
    private let existingDog: Dog?

    // MARK: - Computed Properties
    var isEditMode: Bool {
        existingDog != nil
    }

    var title: String {
        isEditMode ? "Edit Dog" : "Add Dog"
    }

    var saveButtonTitle: String {
        isEditMode ? "Update" : "Create"
    }

    // MARK: - Initialization
    init(
        dog: Dog? = nil,
        createDogUseCase: CreateDogUseCase,
        updateDogUseCase: UpdateDogUseCase,
        coordinator: DogEditorCoordinatorDelegate? = nil
    ) {
        self.existingDog = dog
        self.createDogUseCase = createDogUseCase
        self.updateDogUseCase = updateDogUseCase
        self.coordinator = coordinator

        if let dog = dog {
            self.name = dog.name
            self.breed = dog.breed
            self.age = "\(dog.age)"
            self.medicalNotes = dog.medicalNotes
            self.behaviorNotes = dog.behaviorNotes
        }
    }

    // MARK: - Actions
    func save() async {
        isLoading = true
        errorMessage = nil

        do {
            let ageInt = Int(age) ?? 0

            if let existingDog = existingDog {
                // Update existing dog
                let updatedDog = Dog(
                    id: existingDog.id,
                    name: name,
                    breed: breed,
                    age: ageInt,
                    medicalNotes: medicalNotes,
                    behaviorNotes: behaviorNotes,
                    imageURL: existingDog.imageURL,
                    createdAt: existingDog.createdAt,
                    updatedAt: Date()
                )
                _ = try await updateDogUseCase.execute(updatedDog)
            } else {
                // Create new dog
                _ = try await createDogUseCase.execute(
                    name: name,
                    breed: breed,
                    age: ageInt,
                    medicalNotes: medicalNotes,
                    behaviorNotes: behaviorNotes
                )
            }

            coordinator?.didSaveDog()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func cancel() {
        coordinator?.didCancelEditing()
    }
}

// MARK: - Coordinator Delegate
protocol DogEditorCoordinatorDelegate: AnyObject {
    func didSaveDog()
    func didCancelEditing()
}
