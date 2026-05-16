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

        Window("Tea Settings", id: "settings") {
            SettingsView()
                .environment(appState)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Window("Quit Tea", id: "quit") {
            QuitView()
                .environment(appState)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
