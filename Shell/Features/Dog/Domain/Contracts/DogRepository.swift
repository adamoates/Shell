import Foundation

/// Repository protocol for dog data access
protocol DogRepository: Actor {
    /// Fetch all dogs
    func fetchAll() async throws -> [Dog]

    /// Fetch a specific dog by ID
    func fetch(id: UUID) async throws -> Dog?

    /// Create a new dog
    func create(_ dog: Dog) async throws -> Dog

    /// Update an existing dog
    func update(_ dog: Dog) async throws -> Dog

    /// Delete a dog by ID
    func delete(id: UUID) async throws
}
