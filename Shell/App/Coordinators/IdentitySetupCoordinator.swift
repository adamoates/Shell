//
//  IdentitySetupCoordinator.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import UIKit

/// Protocol for IdentitySetupCoordinator to communicate completion
protocol IdentitySetupCoordinatorDelegate: AnyObject {
    func identitySetupCoordinatorDidComplete(_ coordinator: IdentitySetupCoordinator, profile: UserProfile)
    func identitySetupCoordinatorDidCancel(_ coordinator: IdentitySetupCoordinator)
}

/// Coordinator responsible for the identity setup flow
/// Manages the multi-step process: screen name → birthday → avatar → review
final class IdentitySetupCoordinator: Coordinator {
    // MARK: - Properties

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: Coordinator?
    weak var delegate: IdentitySetupCoordinatorDelegate?

    private let viewModel: IdentitySetupViewModel
    private let userID: String
    private var currentStep: IdentityStep

    // MARK: - Init

    init(
        navigationController: UINavigationController,
        userID: String,
        completeIdentitySetup: CompleteIdentitySetupUseCase,
        startStep: IdentityStep? = nil
    ) {
        self.navigationController = navigationController
        self.userID = userID
        self.currentStep = startStep ?? .screenName
        self.viewModel = IdentitySetupViewModel(
            userID: userID,
            completeIdentitySetup: completeIdentitySetup
        )
    }

    // MARK: - Coordinator

    func start() {
        showStep(currentStep)
    }

    func finish() {
        parentCoordinator?.childDidFinish(self)
    }

    // MARK: - Navigation

    private func showStep(_ step: IdentityStep) {
        currentStep = step

        switch step {
        case .screenName:
            showScreenNameStep()
        case .birthday:
            showBirthdayStep()
        case .avatar:
            showAvatarStep()
        case .review:
            showReviewStep()
        }
    }

    private func showScreenNameStep() {
        let vc = ScreenNameViewController(viewModel: viewModel)
        vc.onNext = { [weak self] in
            self?.showStep(.birthday)
        }
        vc.onCancel = { [weak self] in
            guard let self = self else { return }
            self.delegate?.identitySetupCoordinatorDidCancel(self)
        }
        navigationController.setViewControllers([vc], animated: true)
    }

    private func showBirthdayStep() {
        let vc = BirthdayViewController(viewModel: viewModel)
        vc.onNext = { [weak self] in
            self?.showStep(.avatar)
        }
        vc.onBack = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        navigationController.pushViewController(vc, animated: true)
    }

    private func showAvatarStep() {
        let vc = AvatarViewController(viewModel: viewModel)
        vc.onNext = { [weak self] in
            self?.showStep(.review)
        }
        vc.onSkip = { [weak self] in
            self?.showStep(.review)
        }
        vc.onBack = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        navigationController.pushViewController(vc, animated: true)
    }

    private func showReviewStep() {
        let vc = ReviewViewController(viewModel: viewModel)
        vc.onComplete = { [weak self] profile in
            guard let self = self else { return }
            self.delegate?.identitySetupCoordinatorDidComplete(self, profile: profile)
        }
        vc.onBack = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        navigationController.pushViewController(vc, animated: true)
    }
}
