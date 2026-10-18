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

class AppState: ObservableObject {
    @Published var exploitStatus: ExploitStatus = .notStarted
    @Published var unsupportedMessage: String?
    @Published var kernelExploitRunning = false
    @Published var lastExploitDetail: String = ""

    private var autoRunAttempted = false

    var isSupported: Bool { unsupportedMessage == nil }

    func detectSupport() {
        let v = AppInfo.versionTuple
        let supported = ExploitSupportPolicy.isSupported(
            major: v.major,
            minor: v.minor,
            patch: v.patch,
            build: AppInfo.osBuild
        )
#if targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains("--simulate-access") {
            exploitStatus = .success(method: "Simulator preview")
        }
#endif
        unsupportedMessage = supported ? nil : "iOS \(AppInfo.osVersion) (\(AppInfo.osBuild))"
        if let unsupportedMessage {
            exploitStatus = .unsupported(unsupportedMessage)
            return
        }
        if KernelExploit.hasSandboxAccess() {
            exploitStatus = .success(method: "kexploit")
            return
        }
        if !autoRunAttempted && !exploitStatus.isSuccess {
            autoRunAttempted = true
            runKernelExploitIfNeeded(force: true)
        }
    }

    func runKernelExploitIfNeeded(force: Bool = false) {
        if force, case .failed = exploitStatus {
            exploitStatus = .notStarted
        }
        guard !kernelExploitRunning else { return }
        if exploitStatus.isSuccess { return }
        if !force, exploitStatus.isFailed { return }

        kernelExploitRunning = true
        exploitStatus = .notStarted
        lastExploitDetail = "running…"
        log("app: running kernel exploit (retries enabled)…")

        DispatchQueue.global(qos: .userInitiated).async {
            let ok = KernelExploit.runWithRetries(maxAttempts: 5, delaySeconds: 2.5)
            DispatchQueue.main.async {
                self.kernelExploitRunning = false
                if ok {
                    self.exploitStatus = .success(method: "kexploit")
                    self.lastExploitDetail = "OK"
                    log("app: kernel exploit success")
                } else {
                    self.exploitStatus = .failed(method: "kexploit", code: -1)
                    self.lastExploitDetail = "all retries failed — reboot device and try again"
                    log("app: kernel exploit failed after retries")
                }
            }
        }
    }
}
