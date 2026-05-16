import Foundation

@MainActor
final class IdlePreventionService {
    private var activityToken: NSObjectProtocol?
    private var isRunning = false
    private var lockTask: Task<Void, Never>?

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

    private var unlockTask: Task<Void, Never>?

    func start() {
        guard !isRunning else { return }
        isRunning = true
        isPausedForLock = false

        beginActivity()
        observeScreenLock()
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        isPausedForLock = false
        endActivity()
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
    }

    private func endActivity() {
        if let token = activityToken {
            ProcessInfo.processInfo.endActivity(token)
            activityToken = nil
        }
    }

    private func observeScreenLock() {
        lockTask = Task {
            for await _ in DistributedNotificationCenter.default().notifications(named: NSNotification.Name("com.apple.screenIsLocked")) {
                await handleScreenLocked()
            }
        }
        unlockTask = Task {
            for await _ in DistributedNotificationCenter.default().notifications(named: NSNotification.Name("com.apple.screenIsUnlocked")) {
                await handleScreenUnlocked()
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
