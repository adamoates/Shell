//
//  ProfileEditorView.swift
//  Shell
//
//  Created by Shell on 2026-01-31.
//

import SwiftUI

/// SwiftUI Profile Editor View
/// Demonstrates:
/// - SwiftUI form with TextField and DatePicker
/// - @ObservedObject binding to ViewModel
/// - Reactive UI updates via @Published properties
/// - SwiftUI validation feedback
/// - Integration with UIKit coordinator pattern via UIHostingController
struct ProfileEditorView: View {
    // MARK: - Properties

    @ObservedObject var viewModel: ProfileEditorViewModel

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Screen Name", text: $viewModel.screenName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Screen Name")
                        .accessibilityHint("Enter your screen name (3-20 characters)")

                    DatePicker(
                        "Birthday",
                        selection: $viewModel.birthday,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .accessibilityLabel("Birthday")
                    .accessibilityHint("Select your birth date")
                }

                Section(header: Text("Requirements")) {
                    RequirementRow(
                        title: "Screen name: 2-20 characters",
                        isMet: viewModel.screenName.count >= 2 && viewModel.screenName.count <= 20
                    )

                    RequirementRow(
                        title: "Only letters, numbers, _ and -",
                        isMet: isValidCharacters(viewModel.screenName)
                    )

                    RequirementRow(
                        title: "Must be 13 years or older",
                        isMet: isAgeValid(viewModel.birthday)
                    )
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Error: \(errorMessage)")
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancel()
                    }
                    .accessibilityLabel("Cancel editing")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.save()
                        }
                    }
                    .disabled(!viewModel.isSaveEnabled || viewModel.isLoading)
                    .accessibilityLabel(viewModel.isSaveEnabled ? "Save profile" : "Save disabled")
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay()
                }
            }
        }
    }

    // MARK: - Validation Helpers

    private func isValidCharacters(_ text: String) -> Bool {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        return text.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }

    private func isAgeValid(_ birthday: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        guard let age = calendar.dateComponents([.year], from: birthday, to: now).year else {
            return false
        }
        return age >= 13
    }
}

// MARK: - Supporting Views

/// Requirement row showing met/unmet status
struct RequirementRow: View {
    let title: String
    let isMet: Bool

    var body: some View {
        HStack {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : .gray)

            Text(title)
                .foregroundColor(isMet ? .primary : .secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(isMet ? "met" : "not met")")
    }
}

/// Loading overlay
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading")
    }
}

// MARK: - Preview

#Preview {
    // Preview with mock ViewModel
    let mockRepository = InMemoryUserProfileRepository()
    let useCase = SetupIdentityUseCase(repository: mockRepository)
    let viewModel = ProfileEditorViewModel(
        userID: "preview",
        setupIdentityUseCase: useCase
    )

    return ProfileEditorView(viewModel: viewModel)
}
