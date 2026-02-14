import Foundation

/// Use case for fetching all dogs
protocol FetchDogsUseCase {
    func execute() async throws -> [Dog]
}

final class DefaultFetchDogsUseCase: FetchDogsUseCase {
    private let repository: DogRepository

    init(repository: DogRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Dog] {
        try await repository.fetchAll()
    }
}
