import Foundation

enum DogError: Error, LocalizedError, Equatable {
    case notFound
    case validationFailed(String)
    case createFailed
    case updateFailed
    case deleteFailed
    case repositoryError(String)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Dog not found"
        case .validationFailed(let reason):
            return "Validation failed: \(reason)"
        case .createFailed:
            return "Failed to create dog"
        case .updateFailed:
            return "Failed to update dog"
        case .deleteFailed:
            return "Failed to delete dog"
        case .repositoryError(let message):
            return "Repository error: \(message)"
        }
    }
}
