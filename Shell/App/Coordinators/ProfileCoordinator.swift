//
//  ProfileCoordinator.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import UIKit

/// Coordinator responsible for profile-related flows
final class ProfileCoordinator: Coordinator {
    // MARK: - Properties

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: Coordinator?

    private let fetchProfile: FetchProfileUseCase
    private let userID: String

    // MARK: - Init

    init(
        navigationController: UINavigationController,
        userID: String,
        fetchProfile: FetchProfileUseCase
    ) {
        self.navigationController = navigationController
        self.userID = userID
        self.fetchProfile = fetchProfile
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
}
