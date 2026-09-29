//
//  SceneDelegate.swift
//  Example
//
//  Created by Keke Arif on 2024/7/31.
//

import CBAssistiveTouch
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private var assistiveTouch: AssistiveTouch!

    private func makeAssistiveTouch(windowScene: UIWindowScene) -> AssistiveTouch {
        let contentViewController = CBConsoleViewController()
        contentViewController.toggleHandler = { [unowned self] in
            self.assistiveTouch.toggleContent()
        }
        let layout = DefaultAssistiveTouchLayout()
        layout.customView = { () -> UIView in
            let label = UILabel(frame: .zero)
            label.text = "🛠️"
            label.sizeToFit()
            return label
        }()
        layout.assistiveTouchSize = layout.customView!.bounds.size
        layout.margin = 15
        // A zero width means "fill the safe area", so the console tracks screen size changes.
        contentViewController.preferredContentSize = CGSize(width: 0, height: 300)

        return AssistiveTouch(windowScene: windowScene, layout: layout, contentViewController: contentViewController)
    }

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        assistiveTouch = makeAssistiveTouch(windowScene: windowScene)
        let rootVC = ViewController(assistiveTouch: assistiveTouch)

        window?.rootViewController = rootVC
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
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
    }
}
