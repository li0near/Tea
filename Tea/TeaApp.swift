import SwiftUI

@main
struct TeaApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(appState)
        } label: {
            Image(systemName: appState.menuBarIcon)
        }

        Window("Tea Settings", id: WindowID.settings) {
            SettingsView()
                .environment(appState)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Window("Quit Tea (v\(Bundle.main.shortVersion))", id: WindowID.quit) {
            QuitView()
                .environment(appState)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
