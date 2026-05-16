import SwiftUI
import KeyboardShortcuts
import ServiceManagement

extension KeyboardShortcuts.Name {
    static let toggleTea = Self("toggleTea")
}

enum TimeUnit: String, CaseIterable, Identifiable {
    case seconds = "seconds"
    case minutes = "minutes"
    case hours = "hours"

    var id: String { rawValue }

    var abbreviation: String {
        switch self {
        case .seconds: "sec"
        case .minutes: "min"
        case .hours: "hr"
        }
    }

    func toSeconds(_ value: Int) -> Int {
        switch self {
        case .seconds: value
        case .minutes: value * 60
        case .hours: value * 3600
        }
    }
}

@Observable
@MainActor
final class AppState {
    var isActive: Bool {
        didSet {
            UserDefaults.standard.set(isActive, forKey: "isActive")
            if isActive {
                idleService.start()
            } else {
                idleService.stop()
                timedQuitService.stop()
                timedQuitSecondsRemaining = 0
            }
        }
    }

    var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateLoginItem()
        }
    }

    var pauseWhenLocked: Bool {
        didSet {
            UserDefaults.standard.set(pauseWhenLocked, forKey: "pauseWhenLocked")
            idleService.pauseWhenLocked = pauseWhenLocked
        }
    }

    var timedQuitSecondsRemaining: Int = 0

    var timedQuitActive: Bool { timedQuitSecondsRemaining > 0 }

    var menuBarIcon: String {
        isActive ? "cup.and.heat.waves.fill" : "cup.and.heat.waves"
    }

    var formattedRemaining: String {
        let total = max(0, timedQuitSecondsRemaining)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else if m > 0 {
            return String(format: "%d:%02d", m, s)
        } else {
            return "\(s)s"
        }
    }

    private let idleService = IdlePreventionService()
    private let timedQuitService = TimedQuitService()

    init() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            "isActive": false,
            "launchAtLogin": false,
            "pauseWhenLocked": true,
        ])

        self.isActive = defaults.bool(forKey: "isActive")
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        self.pauseWhenLocked = defaults.bool(forKey: "pauseWhenLocked")

        idleService.pauseWhenLocked = pauseWhenLocked

        timedQuitService.onTick = { [weak self] remaining in
            self?.timedQuitSecondsRemaining = remaining
        }

        if isActive {
            idleService.start()
        }

        KeyboardShortcuts.onKeyUp(for: .toggleTea) { [weak self] in
            Task { @MainActor in
                self?.toggle()
            }
        }
    }

    func toggle() {
        isActive.toggle()
    }

    func startTimedQuit(seconds: Int) {
        guard seconds > 0 else { return }

        if !isActive {
            isActive = true
        }
        timedQuitService.start(seconds: seconds)
        timedQuitSecondsRemaining = seconds
    }

    func cancelTimedQuit() {
        timedQuitService.stop()
        timedQuitSecondsRemaining = 0
    }

    private func updateLoginItem() {
        if launchAtLogin {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }
}
