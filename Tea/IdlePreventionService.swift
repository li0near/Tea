import Foundation
import IOKit.pwr_mgt

@MainActor
final class IdlePreventionService {
    private var activityToken: NSObjectProtocol?
    private var userActivityAssertionID: IOPMAssertionID = IOPMAssertionID(0)
    private var isRunning = false
    private var lockTask: Task<Void, Never>?
    private var unlockTask: Task<Void, Never>?
    private var heartbeatTask: Task<Void, Never>?

    var pauseWhenLocked = false {
        didSet {
            guard isRunning else { return }
            if pauseWhenLocked && isPausedForLock {
                endActivity()
            } else if !pauseWhenLocked && activityToken == nil {
                isPausedForLock = false
                beginActivity()
            }
        }
    }

    private var isPausedForLock = false

    func start() {
        guard !isRunning else { return }
        isRunning = true
        isPausedForLock = false

        beginActivity()
        startHeartbeat()
        observeScreenLock()
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        isPausedForLock = false
        endActivity()
        heartbeatTask?.cancel()
        heartbeatTask = nil
        lockTask?.cancel()
        lockTask = nil
        unlockTask?.cancel()
        unlockTask = nil
    }

    private func beginActivity() {
        guard activityToken == nil else { return }
        activityToken = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleDisplaySleepDisabled],
            reason: "Tea is preventing idle sleep"
        )
        declareUserActivity()
    }

    private func endActivity() {
        if let token = activityToken {
            ProcessInfo.processInfo.endActivity(token)
            activityToken = nil
        }
    }

    private func declareUserActivity() {
        IOPMAssertionDeclareUserActivity(
            "Tea User Activity" as CFString,
            kIOPMUserActiveLocal,
            &userActivityAssertionID
        )
    }

    private func startHeartbeat() {
        heartbeatTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled, self.isRunning, self.activityToken != nil else { continue }
                self.declareUserActivity()
            }
        }
    }

    private func observeScreenLock() {
        lockTask = Task {
            for await _ in DistributedNotificationCenter.default().notifications(named: NSNotification.Name("com.apple.screenIsLocked")) {
                self.handleScreenLocked()
            }
        }
        unlockTask = Task {
            for await _ in DistributedNotificationCenter.default().notifications(named: NSNotification.Name("com.apple.screenIsUnlocked")) {
                self.handleScreenUnlocked()
            }
        }
    }

    private func handleScreenLocked() {
        guard isRunning, pauseWhenLocked else { return }
        isPausedForLock = true
        endActivity()
    }

    private func handleScreenUnlocked() {
        guard isRunning else { return }
        isPausedForLock = false
        beginActivity()
    }
}
