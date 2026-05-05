import SwiftUI

@main
struct ItInventoryApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var container = AppContainer.bootstrap()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(container)
                .applyAppTheme()
        }
    }
}
