import SwiftUI

@main
struct PylonPalApp: App {
    @StateObject private var controller = PylonController()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(controller)
                .onAppear { UIApplication.shared.isIdleTimerDisabled = true } // no auto-lock
        }
    }
}
