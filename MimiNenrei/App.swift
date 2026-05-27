import SwiftUI
import AppTrackingTransparency
import GoogleMobileAds

@main
struct MimiNenreiApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var attRequested = false

    static let isScreenshotMode: Bool = {
        ProcessInfo.processInfo.arguments.contains("SCREENSHOT_MODE")
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    Task { await MobileAds.shared.start() }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active && !attRequested {
                        attRequested = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            ATTrackingManager.requestTrackingAuthorization { _ in }
                        }
                    }
                }
        }
    }
}
