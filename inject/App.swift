import SwiftUI
import UIKit

@main
struct ThreeOneOSFiveApp: App {
    @StateObject private var appState = AppState()

    init() {
        setupLogCapture()
        log("app: OGIOS INJECT launching — iOS \(AppInfo.osVersion) (\(AppInfo.osBuild))")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .onAppear {
                    appState.detectSupport()
                }
        }
    }
}
