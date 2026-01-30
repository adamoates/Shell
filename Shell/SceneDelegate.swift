//
//  SceneDelegate.swift
//  Shell
//
//  Created by Adam Oates on 1/30/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var appCoordinator: AppCoordinator?
    private var appBootstrapper: AppBootstrapper?
    private var appRouter: Router?
    private var deepLinkHandlers: [DeepLinkHandler] = []
    private let dependencyContainer = AppDependencyContainer()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Create window
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // Create coordinator, router, and bootstrapper
        let coordinator = dependencyContainer.makeAppCoordinator(window: window)
        let router = dependencyContainer.makeAppRouter(coordinator: coordinator)
        let bootstrapper = dependencyContainer.makeAppBootstrapper(router: coordinator)

        appCoordinator = coordinator
        appRouter = router
        appBootstrapper = bootstrapper

        // Create deep link handlers
        deepLinkHandlers = dependencyContainer.makeDeepLinkHandlers(router: router)

        // Start boot sequence
        // Bootstrapper will call coordinator.route(to:) when ready
        bootstrapper.start()

        // Handle deep links from initial launch (if any)
        if let urlContext = connectionOptions.urlContexts.first {
            handleDeepLink(urlContext.url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // Handle deep links when app is already running
        guard let url = URLContexts.first?.url else { return }
        handleDeepLink(url)
    }

    // MARK: - Deep Link Handling

    private func handleDeepLink(_ url: URL) {
        print("🔗 SceneDelegate: Handling deep link: \(url)")

        for handler in deepLinkHandlers {
            if handler.handle(url: url) {
                print("✅ SceneDelegate: Deep link handled by \(type(of: handler))")
                return
            }
        }

        print("⚠️ SceneDelegate: No handler could process URL: \(url)")
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }


}

