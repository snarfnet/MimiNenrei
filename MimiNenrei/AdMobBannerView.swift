import GoogleMobileAds
import SwiftUI
import UIKit

enum AdMobConfig {
    static let bannerAdUnitID = "ca-app-pub-9404799280370656/9802920121"
}

struct AdMobBannerView: View {
    let adUnitID: String

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 320)
            let adSize = currentOrientationAnchoredAdaptiveBanner(width: width)

            BannerViewContainer(adUnitID: adUnitID, adSize: adSize)
                .frame(width: adSize.size.width, height: adSize.size.height)
                .frame(maxWidth: .infinity)
        }
        .frame(height: 64)
    }
}

private struct BannerViewContainer: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.rootViewController = UIApplication.shared.topViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        uiView.adSize = adSize
        uiView.rootViewController = UIApplication.shared.topViewController
    }
}

private extension UIApplication {
    var topViewController: UIViewController? {
        guard let scene = connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
            ?? connectedScenes.first as? UIWindowScene else { return nil }
        return scene.windows.first(where: \.isKeyWindow)?.rootViewController
    }
}
