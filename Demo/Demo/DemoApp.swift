//
//  DemoApp.swift
//  Demo
//
//  Created by yyjim on 19/02/2026.
//  Copyright © 2026 Cardinal Blue. All rights reserved.
//

import SwiftUI

@main
struct DemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var demoController = AssistiveTouchDemoController()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(demoController)
                .onAppear {
                    demoController.configureIfNeeded()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else {
                        return
                    }
                    demoController.configureIfNeeded()
                }
        }
    }
}
