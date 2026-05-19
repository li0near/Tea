import Foundation
import CoreGraphics

@MainActor
final class IdlePreventionService {
    private var activityToken: NSObjectProtocol?
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
            options: .userInitiated,
            reason: "Tea heartbeat"
        )
        postSyntheticMouseEvent()
    }

    private func endActivity() {
        if let token = activityToken {
            ProcessInfo.processInfo.endActivity(token)
            activityToken = nil
        }
    }

    private func startHeartbeat() {
        heartbeatTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                guard !Task.isCancelled, self.isRunning, self.activityToken != nil else { continue }
                self.postSyntheticMouseEvent()
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

    private func postSyntheticMouseEvent() {
        let pos = CGEvent(source: nil)?.location ?? .zero
        guard let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: pos, mouseButton: .left) else { return }
        event.post(tap: .cghidEventTap)
    }
}
