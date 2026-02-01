//
//  ProfileCoordinator.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import UIKit
import SwiftUI

/// Coordinator responsible for profile-related flows
/// Demonstrates hybrid UIKit/SwiftUI coordination
final class ProfileCoordinator: Coordinator {
    // MARK: - Properties

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: Coordinator?

    private let fetchProfile: FetchProfileUseCase
    private let setupIdentity: SetupIdentityUseCase
    private let userID: String

    // MARK: - Init

    init(
        navigationController: UINavigationController,
        userID: String,
        fetchProfile: FetchProfileUseCase,
        setupIdentity: SetupIdentityUseCase
    ) {
        self.navigationController = navigationController
        self.userID = userID
        self.fetchProfile = fetchProfile
        self.setupIdentity = setupIdentity
    }

    // MARK: - Coordinator

    func start() {
        showProfile()
    }

    func finish() {
        parentCoordinator?.childDidFinish(self)
    }

    // MARK: - Navigation

    private func showProfile() {
        let viewModel = ProfileViewModel(
            userID: userID,
            fetchProfile: fetchProfile
        )
        let viewController = ProfileViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    /// Show SwiftUI Profile Editor
    /// Demonstrates UIHostingController integration for hybrid UIKit/SwiftUI apps
    func showProfileEditor() {
        let viewModel = ProfileEditorViewModel(
            userID: userID,
            setupIdentityUseCase: setupIdentity
        )
        viewModel.delegate = self

        // Wrap SwiftUI view in UIHostingController
        let swiftUIView = ProfileEditorView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: swiftUIView)

        // Configure like any UIViewController
        hostingController.title = "Edit Profile"

        // Push onto navigation stack
        navigationController.pushViewController(hostingController, animated: true)
    }
}

// MARK: - ProfileEditorViewModelDelegate

extension ProfileCoordinator: ProfileEditorViewModelDelegate {
    func profileEditorDidSave(_ viewModel: ProfileEditorViewModel) {
        // Profile saved successfully - pop back
        navigationController.popViewController(animated: true)
    }

    func profileEditorDidCancel(_ viewModel: ProfileEditorViewModel) {
        // User cancelled - pop back
        navigationController.popViewController(animated: true)
    }
}
