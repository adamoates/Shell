import Foundation

/// In-memory implementation of DogRepository for development and testing
actor InMemoryDogRepository: DogRepository {
    private var dogs: [UUID: Dog] = [:]

    func fetchAll() async throws -> [Dog] {
        Array(dogs.values).sorted { $0.createdAt < $1.createdAt }
    }

    func fetch(id: UUID) async throws -> Dog? {
        dogs[id]
    }

    func create(_ dog: Dog) async throws -> Dog {
        dogs[dog.id] = dog
        return dog
    }

    func update(_ dog: Dog) async throws -> Dog {
        guard dogs[dog.id] != nil else {
            throw DogError.notFound
        }

        var updatedDog = dog
        updatedDog = Dog(
            id: updatedDog.id,
            name: updatedDog.name,
            breed: updatedDog.breed,
            age: updatedDog.age,
            medicalNotes: updatedDog.medicalNotes,
            behaviorNotes: updatedDog.behaviorNotes,
            imageURL: updatedDog.imageURL,
            createdAt: updatedDog.createdAt,
            updatedAt: Date()
        )

        dogs[updatedDog.id] = updatedDog
        return updatedDog
    }

    func delete(id: UUID) async throws {
        guard dogs[id] != nil else {
            throw DogError.notFound
        }

        dogs.removeValue(forKey: id)
    }
}
