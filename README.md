# Tea

A lightweight macOS menu bar utility that prevents your Mac from going to sleep.

Tea uses macOS power assertions to keep your system awake — no mouse jiggling, no accessibility permissions required.

## Features

- **One-click toggle** — enable/disable from the menu bar
- **Global keyboard shortcut** — configurable hotkey to toggle from any app
- **Teams/Slack compatible** — keeps you "Available" in apps that check idle time
- **Timed quit** — automatically quit after a set duration (seconds, minutes, or hours)
- **Screen lock awareness** — optionally pause when the screen is locked
- **Launch at Login** — start automatically with your Mac
- **Minimal footprint** — no Dock icon, no visible cursor movement

## Requirements

- macOS 15.0 or later
- Xcode 16.0 or later (to build from source)

## Installation

### Build from source

```bash
git clone https://github.com/yourname/Tea.git
cd Tea
open Tea.xcodeproj
```

In Xcode, select **Product → Build** (⌘B), then **Product → Run** (⌘R).

To export a standalone app, use **Product → Archive**, or copy the built `.app` from the Products folder to `/Applications/`.

### Pre-built binary

Download `Tea.app` from [Releases](../../releases) and move it to `/Applications/`.

### Bypassing Gatekeeper

Since Tea is not signed with an Apple Developer ID certificate, macOS will block it on first launch. To allow it:

**Option A — Right-click to open (simplest):**

Right-click (or Control-click) `Tea.app` → select **Open** → click **Open** in the dialog. You only need to do this once.

**Option B — System Settings:**

1. Try to open `Tea.app` (it will be blocked)
2. Go to **System Settings → Privacy & Security**
3. Scroll down — you'll see "Tea was blocked from use because it is not from an identified developer"
4. Click **Open Anyway**

**Option C — Terminal:**

```bash
xattr -cr /Applications/Tea.app
```

This removes the quarantine attribute entirely.

## Usage

After launching, Tea appears as a cup icon in your menu bar.

**Menu items:**
- **Enabled** — toggle idle prevention on/off (checkmark when active)
- **Settings** — configure keyboard shortcut, screen lock behavior, launch at login
- **Quit Tea** — quit immediately or set a delayed quit timer

**Keyboard shortcut:**

Open **Settings** and click the shortcut recorder to assign a global hotkey for toggling Tea from any app.

**Timed quit:**

Click **Quit Tea...** → enable "Quit after a delay" → set duration and unit → **Start Timer**. The countdown appears in the menu and in the quit window. Click the countdown in the quit window to cancel.

## How it works

Tea posts a synthetic mouse-moved event (at the current cursor position) every 60 seconds. This resets the system idle timer, preventing display sleep and keeping apps like Microsoft Teams from marking you as away.

Additionally, `ProcessInfo.beginActivity(.userInitiated)` prevents macOS from App Napping the process.

Unlike traditional mouse-jiggling utilities, Tea:
- Does not visibly move your cursor
- Does not generate keyboard events
- Works reliably on macOS 15+ and macOS 26
- Requires Accessibility permission (for posting HID events)

## Verification

You can verify Tea is working by checking the system idle time resets:

```bash
ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print $NF/1000000000; exit}'
```

With Tea enabled, this value should never exceed ~60 seconds.

## License

MIT License. See [LICENSE](LICENSE) for details.
