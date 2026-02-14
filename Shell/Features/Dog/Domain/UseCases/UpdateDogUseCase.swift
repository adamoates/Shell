import Foundation

/// Use case for updating an existing dog
protocol UpdateDogUseCase {
    func execute(_ dog: Dog) async throws -> Dog
}

final class DefaultUpdateDogUseCase: UpdateDogUseCase {
    private let repository: DogRepository

    init(repository: DogRepository) {
        self.repository = repository
    }

    func execute(_ dog: Dog) async throws -> Dog {
        // Validation
        guard !dog.name.isEmpty else {
            throw DogError.validationFailed("Name cannot be empty")
        }

        guard !dog.breed.isEmpty else {
            throw DogError.validationFailed("Breed cannot be empty")
        }

        guard dog.age >= 0 else {
            throw DogError.validationFailed("Age must be non-negative")
        }

        guard dog.age <= 30 else {
            throw DogError.validationFailed("Age must be realistic (0-30 years)")
        }

        // Update dog
        do {
            return try await repository.update(dog)
        } catch {
            throw DogError.updateFailed
        }
    }
}
