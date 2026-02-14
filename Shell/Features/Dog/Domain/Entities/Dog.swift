import Foundation

/// Represents a dog in the system
struct Dog: Identifiable, Sendable, Codable, Equatable {
    let id: UUID
    var name: String
    var breed: String
    var age: Int
    var medicalNotes: String
    var behaviorNotes: String
    var imageURL: String?
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        breed: String,
        age: Int,
        medicalNotes: String = "",
        behaviorNotes: String = "",
        imageURL: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.breed = breed
        self.age = age
        self.medicalNotes = medicalNotes
        self.behaviorNotes = behaviorNotes
        self.imageURL = imageURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
