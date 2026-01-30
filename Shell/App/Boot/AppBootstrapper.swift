//
//  AppBootstrapper.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Thin orchestrator for app boot sequence
///
/// Responsibilities:
/// - Call use cases to restore state
/// - Map use case results to LaunchState
/// - Ask router to start the correct flow
///
/// NOT responsible for:
/// - Business logic (that's in use cases)
/// - Navigation (that's in coordinators)
/// - Persistence/network (that's in infrastructure)
final class AppBootstrapper {
    // MARK: - Properties

    private let restoreSession: RestoreSessionUseCase
    private let router: LaunchRouting

    // MARK: - Initialization

    init(
        restoreSession: RestoreSessionUseCase,
        router: LaunchRouting
    ) {
        self.restoreSession = restoreSession
        self.router = router
    }

    // MARK: - Public

    /// Entry point called once from SceneDelegate
    func start() {
        Task { [restoreSession, router] in
            let status = await restoreSession.execute()
            let state = Self.map(status: status)
            router.route(to: state)
        }
    }

    // MARK: - Private

    /// Map SessionStatus (domain) to LaunchState (orchestration)
    ///
    /// This is intentionally trivial. Complex logic belongs in use cases.
    private static func map(status: SessionStatus) -> LaunchState {
        switch status {
        case .authenticated:
            return .authenticated
        case .unauthenticated:
            return .unauthenticated
        case .locked:
            return .locked
        }
    }
}
