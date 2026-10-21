import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let menuController = MenuController()
    private let captureController = CaptureController()
    private let shortcutManager = ShortcutManager()
    private let pasteMonitor = PasteMonitor()
    private lazy var settingsWindowController = SettingsWindowController()
    private var observers: [NSObjectProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureMainMenu()

        configureStatusItem()
        configureMenuActions()
        configureShortcuts()
        configureObservers()

        _ = pasteMonitor.start()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            Task { @MainActor in
                OnboardingController.shared.showIfNeeded()
            }
        }

    }

    func applicationWillTerminate(_ notification: Notification) {
        pasteMonitor.stop()
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if statusItem?.isVisible == false {
            Preferences.shared.showInMenuBar = true
            statusItem?.isVisible = true
        } else if !flag {
            showPreferences()
        }
        return true
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        shortcutManager.registerAll()
        if !pasteMonitor.isRunning {
            _ = pasteMonitor.start()
        }
    }

    private func configureMainMenu() {
        let mainMenu = NSMenu()

        let applicationItem = NSMenuItem()
        mainMenu.addItem(applicationItem)
        let applicationMenu = NSMenu(title: "SnippetFlow")
        applicationItem.submenu = applicationMenu

        let about = NSMenuItem(
            title: "About SnippetFlow",
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )
        about.target = NSApp
        applicationMenu.addItem(about)
        applicationMenu.addItem(.separator())

        let preferences = NSMenuItem(
            title: "Preferences…",
            action: #selector(showPreferencesFromMainMenu),
            keyEquivalent: ","
        )
        preferences.target = self
        applicationMenu.addItem(preferences)
        applicationMenu.addItem(.separator())

        let quit = NSMenuItem(
            title: "Quit SnippetFlow",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quit.target = NSApp
        applicationMenu.addItem(quit)

        let editItem = NSMenuItem()
        mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: "Edit")
        editItem.submenu = editMenu
        addEditItem("Undo", selector: Selector(("undo:")), key: "z", to: editMenu)
        let redo = addEditItem("Redo", selector: Selector(("redo:")), key: "z", to: editMenu)
        redo.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(.separator())
        addEditItem("Cut", selector: #selector(NSText.cut(_:)), key: "x", to: editMenu)
        addEditItem("Copy", selector: #selector(NSText.copy(_:)), key: "c", to: editMenu)
        addEditItem("Paste", selector: #selector(NSText.paste(_:)), key: "v", to: editMenu)
        addEditItem("Select All", selector: #selector(NSText.selectAll(_:)), key: "a", to: editMenu)

        let windowItem = NSMenuItem()
        mainMenu.addItem(windowItem)
        let windowMenu = NSMenu(title: "Window")
        windowItem.submenu = windowMenu
        addEditItem("Minimize", selector: #selector(NSWindow.performMiniaturize(_:)), key: "m", to: windowMenu)
        addEditItem("Close", selector: #selector(NSWindow.performClose(_:)), key: "w", to: windowMenu)
        NSApp.windowsMenu = windowMenu

        NSApp.mainMenu = mainMenu
    }

    @discardableResult
    private func addEditItem(_ title: String, selector: Selector, key: String, to menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: key)
        item.keyEquivalentModifierMask = [.command]
        menu.addItem(item)
        return item
    }

    @objc private func showPreferencesFromMainMenu() {
        showPreferences()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item

        if let button = item.button {
            let image = NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: "SnippetFlow")
                ?? NSImage(systemSymbolName: "viewfinder", accessibilityDescription: "SnippetFlow")
            image?.isTemplate = true
            button.image = image
            button.toolTip = "SnippetFlow"
        }

        menuController.install(on: item)
        Preferences.shared.showInMenuBar = true
        item.isVisible = true
    }

    private func configureMenuActions() {
        menuController.onCaptureText = { [weak self] in
            self?.captureController.captureText()
        }
        menuController.onCaptureBarcode = { [weak self] in
            self?.captureController.captureBarcode()
        }
        menuController.onTakePhoto = { [weak self] in
            self?.captureController.importImage()
        }
        menuController.onShowPreferences = { [weak self] in
            self?.showPreferences()
        }
        menuController.onClearHistory = { [weak self] in
            self?.clearHistory()
        }
        menuController.onStopSpeaking = {
            SpeechManager.shared.stop()
        }
    }

    private func configureShortcuts() {
        shortcutManager.onAction = { [weak self] action in
            self?.perform(action)
        }
        shortcutManager.registerAll()
    }

    private func configureObservers() {
        let center = NotificationCenter.default

        observers.append(center.addObserver(forName: .shortcutsChanged, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.shortcutManager.registerAll()
            }
        })

        observers.append(center.addObserver(forName: .preferencesChanged, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.menuController.refresh()
                self.statusItem?.isVisible = Preferences.shared.showInMenuBar
            }
        })

        observers.append(center.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.menuController.refresh()
                self.statusItem?.isVisible = Preferences.shared.showInMenuBar
            }
        })
    }

    private func perform(_ action: ShortcutAction) {
        switch action {
        case .captureText:
            captureController.captureText()
        case .capturePreviousArea:
            captureController.capturePreviousArea()
        case .captureWithoutLineBreaks:
            captureController.captureText(forceLineBreaks: false)
        case .captureWithLineBreaks:
            captureController.captureText(forceLineBreaks: true)
        case .textToSpeech:
            captureController.captureText(forceTTS: true)
        case .toggleLineBreaks:
            Preferences.shared.lineSettings.toggle()
            menuController.refresh()
            NotificationPresenter.shared.show(
                Preferences.shared.lineSettings ? "Keep Line Breaks On" : "Keep Line Breaks Off"
            )
        case .toggleAdditiveClipboard:
            Preferences.shared.keepHistory.toggle()
            menuController.refresh()
            NotificationPresenter.shared.show(
                Preferences.shared.keepHistory ? "Additive Clipboard On" : "Additive Clipboard Off"
            )
        case .clearHistory:
            clearHistory()
        case .stopSpeaking:
            SpeechManager.shared.stop()
        case .barcode:
            captureController.captureBarcode()
        }
    }

    private func clearHistory() {
        ClipboardManager.shared.clearHistory()
        NotificationPresenter.shared.show("Additive Clipboard Emptied", force: true)
    }

    private func showPreferences() {
        settingsWindowController.show()
    }
}
