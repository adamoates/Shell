import Foundation

/// Use case for deleting a dog
protocol DeleteDogUseCase {
    func execute(id: UUID) async throws
}

final class DefaultDeleteDogUseCase: DeleteDogUseCase {
    private let repository: DogRepository

    init(repository: DogRepository) {
        self.repository = repository
    }

    func execute(id: UUID) async throws {
        do {
            try await repository.delete(id: id)
        } catch {
            throw DogError.deleteFailed
        }
    }
}
