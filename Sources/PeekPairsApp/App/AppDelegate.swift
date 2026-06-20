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
        showWindow(activate: true)

        switch action {
        case .openPausedBoard:
            viewModel.openPausedBoard()
        case .startNewGame:
            viewModel.startNewGame()
        case .resumeOrStartGame:
            viewModel.resumeOrStartGame()
        }
    }

    private func createWindow() {
        let rootView = RootView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        let effectView = NSVisualEffectView()
        effectView.material = .hudWindow
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
        window.isOpaque = false
        window.backgroundColor = .clear
        window.minSize = NSSize(width: 480, height: 560)
        window.contentView = effectView
        window.delegate = self
        window.collectionBehavior = [.managed, .fullScreenPrimary]
        window.center()

        self.window = window
    }

    private func showWindow(activate: Bool) {
        guard let window else { return }
        window.makeKeyAndOrderFront(nil)
        if activate {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func buildMainMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
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
        gameMenu.addItem(NSMenuItem(title: "New Game", action: #selector(startNewGame), keyEquivalent: "n"))
        gameMenu.addItem(NSMenuItem(title: "Open Paused Board", action: #selector(openPausedBoard), keyEquivalent: ""))
        gameMenu.addItem(NSMenuItem(title: "Resume or Start", action: #selector(resumeOrStartGame), keyEquivalent: "r"))
        gameItem.submenu = gameMenu
        mainMenu.addItem(gameItem)

        NSApp.mainMenu = mainMenu
    }
}
