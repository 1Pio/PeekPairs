import AppKit
import Combine
import PeekPairsCore
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let viewModel = GameViewModel()
    private var window: NSWindow?
    private var hotkeyCenter: GlobalHotkeyCenter?
    private var cancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
        buildMainMenu()
        createWindow()

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
        viewModel.applicationDidBecomeActive()
    }

    func applicationWillResignActive(_ notification: Notification) {
        viewModel.applicationWillResignActive()
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

        let effectView = NSVisualEffectView()
        effectView.material = .underWindowBackground
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.addSubview(hostingView)

        hostingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: effectView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: effectView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: effectView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: effectView.bottomAnchor)
        ])

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 860),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "PeekPairs"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isRestorable = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.minSize = NSSize(width: 480, height: 560)
        window.contentView = effectView
        window.setContentSize(NSSize(width: 760, height: 860))
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
        window.setContentSize(NSSize(width: 760, height: 860))
        window.center()
    }

    private func showWindow(activate: Bool) {
        guard let window else { return }
        window.level = .popUpMenu
        window.deminiaturize(nil)
        if activate {
            NSApp.unhide(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
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
