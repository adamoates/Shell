import Foundation

/// Use case for creating a new dog
protocol CreateDogUseCase {
    func execute(
        name: String,
        breed: String,
        age: Int,
        medicalNotes: String,
        behaviorNotes: String
    ) async throws -> Dog
}

final class DefaultCreateDogUseCase: CreateDogUseCase {
    private let repository: DogRepository

    init(repository: DogRepository) {
        self.repository = repository
    }

    func execute(
        name: String,
        breed: String,
        age: Int,
        medicalNotes: String = "",
        behaviorNotes: String = ""
    ) async throws -> Dog {
        // Validation
        guard !name.isEmpty else {
            throw DogError.validationFailed("Name cannot be empty")
        }

        guard !breed.isEmpty else {
            throw DogError.validationFailed("Breed cannot be empty")
        }

        guard age >= 0 else {
            throw DogError.validationFailed("Age must be non-negative")
        }

        guard age <= 30 else {
            throw DogError.validationFailed("Age must be realistic (0-30 years)")
        }

        // Create dog
        let dog = Dog(
            name: name,
            breed: breed,
            age: age,
            medicalNotes: medicalNotes,
            behaviorNotes: behaviorNotes
        )

        do {
            return try await repository.create(dog)
        } catch {
            throw DogError.createFailed
        }
    }
}
