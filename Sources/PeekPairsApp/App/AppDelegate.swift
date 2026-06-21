import AppKit
import Combine
import PeekPairsCore
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let defaultWindowSide: CGFloat = 760
    private let minimumWindowSide: CGFloat = 520

    private let viewModel = GameViewModel()
    private var window: NSWindow?
    private var hotkeyCenter: GlobalHotkeyCenter?
    private var activeAppMonitor: Timer?
    private var lastWindowPresentationDate = Date.distantPast
    private var waitingForPresentedWindowActivation = false
    private var cancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
        buildMainMenu()
        createWindow()
        observeActiveApplicationChanges()
        startActiveApplicationMonitor()

        hotkeyCenter = GlobalHotkeyCenter { [weak self] action in
            Task { @MainActor in
                self?.handleGlobalHotkey(action)
            }
        }

        viewModel.$settings
            .sink { [weak self] settings in
                guard let self else { return }
                let statuses = self.hotkeyCenter?.register(bindings: settings.hotkeys) ?? [:]
                self.viewModel.updateHotkeyStatuses(statuses)
            }
            .store(in: &cancellables)

        viewModel.updateHotkeyStatuses(hotkeyCenter?.register(bindings: viewModel.settings.hotkeys) ?? [:])
        showWindow(activate: true)

        DispatchQueue.main.async { [weak self] in
            self?.applyLaunchFrame()
            self?.showWindow(activate: true)
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        waitingForPresentedWindowActivation = false
        viewModel.applicationDidBecomeActive()
    }

    func applicationWillResignActive(_ notification: Notification) {
        viewModel.applicationWillResignActive()
        collapseWindowForFocusLossIfNeeded()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow(activate: true)
        return true
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        viewModel.openPausedBoard()
        return false
    }

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        let currentSize = sender.frame.size
        let widthDelta = abs(frameSize.width - currentSize.width)
        let heightDelta = abs(frameSize.height - currentSize.height)
        let proposedSide = widthDelta > heightDelta ? frameSize.width : frameSize.height
        let side = max(minimumWindowSide, proposedSide)
        return NSSize(width: side, height: side)
    }

    @objc private func openSettings() {
        showWindow(activate: true)
        viewModel.showSettings()
    }

    @objc private func startNewGame() {
        showWindow(activate: true)
        viewModel.startNewGame()
    }

    @objc private func openPausedBoard() {
        showWindow(activate: true)
        viewModel.openPausedBoard()
    }

    @objc private func resumeOrStartGame() {
        showWindow(activate: true)
        viewModel.resumeOrStartGame()
    }

    @objc private func activeApplicationDidChange(_ notification: Notification) {
        guard let activatedApp = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }

        collapseWindowIfNeeded(for: activatedApp)
    }

    private func handleGlobalHotkey(_ action: HotkeyAction) {
        switch action {
        case .openPausedBoard:
            showWindow(activate: true)
            viewModel.openPausedBoard()
        case .startNewGame:
            showWindow(activate: true)
            viewModel.startNewGame()
        case .resumeOrStartGame:
            if shouldCollapseForResumeHotkey {
                collapseWindowFromResumeHotkey()
                return
            }

            showWindow(activate: true)
            viewModel.resumeOrStartGame()
        }
    }

    private func createWindow() {
        let rootView = RootView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        let glassView = NSGlassEffectView()
        glassView.style = .regular
        glassView.cornerRadius = 0
        glassView.tintColor = NSColor.white.withAlphaComponent(0.035)
        glassView.translatesAutoresizingMaskIntoConstraints = false
        glassView.contentView = hostingView

        hostingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: glassView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: glassView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: glassView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: glassView.bottomAnchor)
        ])

        let window = PeekPairsWindow(
            contentRect: NSRect(x: 0, y: 0, width: defaultWindowSide, height: defaultWindowSide),
            styleMask: [.borderless, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "PeekPairs"
        window.titleVisibility = .hidden
        window.isRestorable = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.minSize = NSSize(width: minimumWindowSide, height: minimumWindowSide)
        window.contentAspectRatio = NSSize(width: 1, height: 1)
        window.aspectRatio = NSSize(width: 1, height: 1)
        window.contentView = glassView
        window.setContentSize(NSSize(width: defaultWindowSide, height: defaultWindowSide))
        window.delegate = self
        window.level = .popUpMenu
        window.isMovableByWindowBackground = true
        window.tabbingMode = .disallowed
        window.collectionBehavior = [.managed, .moveToActiveSpace, .fullScreenPrimary]
        window.center()
        hideSystemWindowControls(for: window)

        self.window = window
    }

    private func applyLaunchFrame() {
        guard let window else { return }
        window.setContentSize(NSSize(width: defaultWindowSide, height: defaultWindowSide))
        window.center()
    }

    private func showWindow(activate: Bool) {
        guard let window else { return }
        lastWindowPresentationDate = Date()
        waitingForPresentedWindowActivation = activate && !NSApp.isActive
        window.level = .popUpMenu
        window.deminiaturize(nil)
        if activate {
            NSApp.unhide(nil)
            NSRunningApplication.current.activate(options: [.activateAllWindows])
            NSApp.activate(ignoringOtherApps: true)
        }
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)

        if activate {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                guard let self else { return }
                self.lastWindowPresentationDate = Date()
                NSRunningApplication.current.activate(options: [.activateAllWindows])
                NSApp.activate(ignoringOtherApps: true)
                self.window?.makeKeyAndOrderFront(nil)
            }
        }
    }

    private var shouldCollapseForResumeHotkey: Bool {
        guard let window else { return false }
        return NSApp.isActive && window.isVisible && !window.isMiniaturized
    }

    private func collapseWindowFromResumeHotkey() {
        viewModel.pauseForManualDismissal()
        window?.miniaturize(nil)
        NSApp.hide(nil)
    }

    private func collapseWindowForFocusLossIfNeeded() {
        guard viewModel.settings.minimizeOnFocusLoss,
              let window,
              window.isVisible,
              !window.isMiniaturized,
              !waitingForPresentedWindowActivation,
              Date().timeIntervalSince(lastWindowPresentationDate) > 0.6
        else {
            return
        }

        window.miniaturize(nil)
        NSApp.hide(nil)
    }

    private func collapseWindowIfNeeded(for frontmostApplication: NSRunningApplication?) {
        guard let frontmostApplication else { return }
        guard !NSApp.isActive else { return }

        if frontmostApplication.processIdentifier == ProcessInfo.processInfo.processIdentifier {
            return
        }

        if let bundleIdentifier = Bundle.main.bundleIdentifier,
           frontmostApplication.bundleIdentifier == bundleIdentifier {
            return
        }

        viewModel.applicationWillResignActive()
        collapseWindowForFocusLossIfNeeded()
    }

    private func observeActiveApplicationChanges() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeApplicationDidChange(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    private func startActiveApplicationMonitor() {
        let timer = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.collapseWindowIfNeeded(for: NSWorkspace.shared.frontmostApplication)
            }
        }

        activeAppMonitor = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func hideSystemWindowControls(for window: NSWindow) {
        [
            NSWindow.ButtonType.closeButton,
            .miniaturizeButton,
            .zoomButton
        ].forEach { buttonType in
            let button = window.standardWindowButton(buttonType)
            button?.isHidden = true
            button?.isEnabled = false
        }
    }

    private func buildMainMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(appCommand(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Hide PeekPairs", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        appMenu.addItem(NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h"))
        appMenu.items.last?.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Quit PeekPairs", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        let gameItem = NSMenuItem()
        let gameMenu = NSMenu(title: "Game")
        gameMenu.addItem(appCommand(title: "New Game", action: #selector(startNewGame), keyEquivalent: "n"))
        gameMenu.addItem(appCommand(title: "Open Paused Board", action: #selector(openPausedBoard), keyEquivalent: ""))
        gameMenu.addItem(appCommand(title: "Resume or Start", action: #selector(resumeOrStartGame), keyEquivalent: "r"))
        gameItem.submenu = gameMenu
        mainMenu.addItem(gameItem)

        NSApp.mainMenu = mainMenu
    }

    private func appCommand(title: String, action: Selector, keyEquivalent: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }
}

private final class PeekPairsWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
