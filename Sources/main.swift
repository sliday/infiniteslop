import AppKit
import WebKit

// MARK: - injected CSS: strip site to video-only
let hideCSS = """
#sidebar,#chat,#chattoggle,#credit,#topleft,#livepill,#splash,#heartbtn,#mute,#namemodal,#tsmodal{display:none !important}
::-webkit-scrollbar{display:none}
body{background:#000 !important}
"""

// MARK: - hover control button
final class HoverButton: NSButton {
    init(symbol: String, size: CGFloat, action sel: Selector, target: AnyObject) {
        super.init(frame: .zero)
        isBordered = false
        bezelStyle = .regularSquare
        let cfg = NSImage.SymbolConfiguration(pointSize: size, weight: .semibold)
        image = NSImage(systemSymbolName: symbol, accessibilityDescription: symbol)?
            .withSymbolConfiguration(cfg)
        contentTintColor = .white
        self.target = target
        self.action = sel
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.8
        layer?.shadowRadius = 3
        layer?.shadowOffset = .zero
    }
    required init?(coder: NSCoder) { fatalError() }
    func setSymbol(_ symbol: String, size: CGFloat) {
        let cfg = NSImage.SymbolConfiguration(pointSize: size, weight: .semibold)
        image = NSImage(systemSymbolName: symbol, accessibilityDescription: symbol)?
            .withSymbolConfiguration(cfg)
    }
}

// MARK: - overlay: swallows mouse for drag, hosts native controls
final class OverlayView: NSView {
    weak var webView: WKWebView?
    var controls: [NSView] = []
    var likeLabel: NSTextField?
    private var tracking: NSTrackingArea?
    private var hideTimer: Timer?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let t = tracking { removeTrackingArea(t) }
        let t = NSTrackingArea(rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
            owner: self, userInfo: nil)
        addTrackingArea(t); tracking = t
    }
    override func mouseEntered(with e: NSEvent) { showControls() }
    override func mouseMoved(with e: NSEvent) { showControls() }
    override func mouseExited(with e: NSEvent) { hideControls() }
    override func mouseDown(with e: NSEvent) { window?.performDrag(with: e) }

    func showControls() {
        hideTimer?.invalidate()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            controls.forEach { $0.animator().alphaValue = 1 }
        }
        hideTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.hideControls()
        }
    }
    func hideControls() {
        hideTimer?.invalidate()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            controls.forEach { $0.animator().alphaValue = 0 }
        }
    }
}

// MARK: - floating panel
final class SlopPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate {
    var panel: SlopPanel!
    var webView: WKWebView!
    var overlay: OverlayView!
    var likeCountLabel: NSTextField!
    var muteButton: HoverButton!
    var pollTimer: Timer?

    func applicationDidFinishLaunching(_ n: Notification) {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let w: CGFloat = 340, h: CGFloat = w * 16 / 9
        let rect = NSRect(x: screen.maxX - w - 24, y: screen.minY + 24, width: w, height: h)

        panel = SlopPanel(contentRect: rect,
                          styleMask: [.borderless, .nonactivatingPanel, .resizable],
                          backing: .buffered, defer: false)
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        panel.contentAspectRatio = NSSize(width: 9, height: 16)
        panel.minSize = NSSize(width: 180, height: 320)
        panel.setFrameAutosaveName("SlopWindowFrame")

        let container = NSView(frame: rect)
        container.wantsLayer = true
        container.layer?.cornerRadius = 14
        container.layer?.masksToBounds = true
        container.layer?.backgroundColor = NSColor.black.cgColor

        let cfg = WKWebViewConfiguration()
        cfg.mediaTypesRequiringUserActionForPlayback = []
        let script = WKUserScript(
            source: "const s=document.createElement('style');s.textContent=`\(hideCSS)`;document.documentElement.appendChild(s);",
            injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        cfg.userContentController.addUserScript(script)
        webView = WKWebView(frame: container.bounds, configuration: cfg)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")
        container.addSubview(webView)

        overlay = OverlayView(frame: container.bounds)
        overlay.autoresizingMask = [.width, .height]
        overlay.webView = webView
        container.addSubview(overlay)

        buildControls()
        panel.contentView = container
        panel.makeKeyAndOrderFront(nil)

        webView.load(URLRequest(url: URL(string: "https://infiniteslop.ai")!))

        pollTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.refreshLikeCount()
        }
    }

    func buildControls() {
        let close = HoverButton(symbol: "xmark.circle.fill", size: 16,
                                action: #selector(quit), target: self)
        muteButton = HoverButton(symbol: "speaker.slash.fill", size: 15,
                                 action: #selector(toggleMute), target: self)
        let heart = HoverButton(symbol: "heart.fill", size: 20,
                                action: #selector(like), target: self)
        heart.contentTintColor = NSColor(red: 1, green: 0.25, blue: 0.55, alpha: 1)

        likeCountLabel = NSTextField(labelWithString: "")
        likeCountLabel.textColor = .white
        likeCountLabel.font = .systemFont(ofSize: 12, weight: .bold)
        likeCountLabel.translatesAutoresizingMaskIntoConstraints = false
        likeCountLabel.shadow = {
            let s = NSShadow(); s.shadowColor = .black; s.shadowBlurRadius = 3; return s
        }()

        let ctrls: [NSView] = [close, muteButton!, heart, likeCountLabel!]
        for v in ctrls {
            v.alphaValue = 0
            overlay.addSubview(v)
        }
        overlay.controls = ctrls

        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: overlay.topAnchor, constant: 10),
            close.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 10),
            muteButton.topAnchor.constraint(equalTo: overlay.topAnchor, constant: 10),
            muteButton.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -10),
            heart.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -14),
            heart.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 14),
            likeCountLabel.centerYAnchor.constraint(equalTo: heart.centerYAnchor),
            likeCountLabel.leadingAnchor.constraint(equalTo: heart.trailingAnchor, constant: 6),
        ])
    }

    @objc func quit() { NSApp.terminate(nil) }

    @objc func toggleMute() {
        let js = """
        (function(){
          const m=document.getElementById('mute'), v=document.getElementById('tv');
          if(m && getComputedStyle(m).display!=='none' && v.muted){ m.click(); return v.muted; }
          v.muted=!v.muted; return v.muted;
        })()
        """
        webView.evaluateJavaScript(js) { [weak self] result, _ in
            let muted = (result as? Bool) ?? true
            self?.muteButton.setSymbol(muted ? "speaker.slash.fill" : "speaker.wave.2.fill", size: 15)
        }
    }

    @objc func like() {
        webView.evaluateJavaScript(
            "heartPress(30, innerHeight - 80); document.querySelector('#heartbtn .cnt')?.textContent"
        ) { [weak self] result, _ in
            if let s = result as? String { self?.likeCountLabel.stringValue = s }
        }
    }

    func refreshLikeCount() {
        webView.evaluateJavaScript(
            "document.querySelector('#heartbtn .cnt')?.textContent"
        ) { [weak self] result, _ in
            if let s = result as? String { self?.likeCountLabel.stringValue = s }
        }
    }

    func webView(_ w: WKWebView, didFinish nav: WKNavigation!) {
        refreshLikeCount()
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
