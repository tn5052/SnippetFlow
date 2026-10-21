import AppKit

@MainActor
final class OnboardingController: NSObject, NSWindowDelegate {
    static let shared = OnboardingController()

    private var window: NSWindow?

    private override init() {
        super.init()
    }

    func showIfNeeded() {
        guard Preferences.shared.firstLaunch else { return }
        if let window {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let contentSize = NSSize(width: 440, height: 290)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = true
        window.delegate = self
        window.center()

        let effect = NSVisualEffectView()
        effect.material = .windowBackground
        effect.blendingMode = .behindWindow
        effect.state = .active
        window.contentView = effect

        let icon = NSImageView()
        icon.image = NSApp.applicationIconImage
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.translatesAutoresizingMaskIntoConstraints = false

        let title = NSTextField(labelWithString: "👋 Hey!")
        title.font = NSFont.systemFont(ofSize: 26, weight: .bold)
        title.alignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false

        let body = NSTextField(wrappingLabelWithString: "Click the icon in the menu bar to get started with SnippetFlow")
        body.font = NSFont.systemFont(ofSize: 14)
        body.alignment = .center
        body.textColor = .secondaryLabelColor
        body.translatesAutoresizingMaskIntoConstraints = false

        let button = NSButton(title: "Got It", target: self, action: #selector(dismiss))
        button.bezelStyle = .rounded
        button.keyEquivalent = "\r"
        button.translatesAutoresizingMaskIntoConstraints = false

        effect.addSubview(icon)
        effect.addSubview(title)
        effect.addSubview(body)
        effect.addSubview(button)

        NSLayoutConstraint.activate([
            icon.topAnchor.constraint(equalTo: effect.topAnchor, constant: 28),
            icon.centerXAnchor.constraint(equalTo: effect.centerXAnchor),
            icon.widthAnchor.constraint(equalToConstant: 76),
            icon.heightAnchor.constraint(equalToConstant: 76),

            title.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 12),
            title.centerXAnchor.constraint(equalTo: effect.centerXAnchor),

            body.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            body.leadingAnchor.constraint(equalTo: effect.leadingAnchor, constant: 36),
            body.trailingAnchor.constraint(equalTo: effect.trailingAnchor, constant: -36),

            button.topAnchor.constraint(equalTo: body.bottomAnchor, constant: 18),
            button.centerXAnchor.constraint(equalTo: effect.centerXAnchor),
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: 110),
            button.bottomAnchor.constraint(lessThanOrEqualTo: effect.bottomAnchor, constant: -22)
        ])

        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    @objc private func dismiss() {
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        Preferences.shared.firstLaunch = false
        window = nil
    }
}
