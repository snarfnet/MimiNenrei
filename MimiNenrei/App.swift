import SwiftUI
import AppTrackingTransparency
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if UIDevice.current.userInterfaceIdiom == .phone {
            DispatchQueue.main.async {
                MobileAds.shared.start { _ in }
            }
        }
        return true
    }
}

@main
struct MimiNenreiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @State private var attRequested = false

    static let isScreenshotMode: Bool = {
        ProcessInfo.processInfo.arguments.contains("SCREENSHOT_MODE")
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active && !attRequested && !Self.isScreenshotMode {
                        attRequested = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            ATTrackingManager.requestTrackingAuthorization { _ in }
                        }
                    }
                }
        }
    }
}
