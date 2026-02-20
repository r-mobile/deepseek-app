//
//  AppCoordinator.swift
//  AIChat Desktop
//

import SwiftUI
import AppKit
import WebKit

extension Notification.Name {
    static let openMainWindow = Notification.Name("openMainWindow")
    static let providerChanged = Notification.Name("providerChanged")
}

@Observable
class AppCoordinator {
    // Singleton instance для всего приложения
    static let shared = AppCoordinator()
    
    private var chatBar: ChatBarPanel?
    var providerManager: AIProviderManager
    var webViewModel: WebViewModel

    var openWindowAction: ((String) -> Void)?

    var canGoBack: Bool { webViewModel.canGoBack }
    var canGoForward: Bool { webViewModel.canGoForward }
    var currentProvider: AIProvider { webViewModel.currentProvider }
    var currentWebView: WKWebView { webViewModel.currentWebView }

    init() {
        let manager = AIProviderManager()
        self.providerManager = manager
        self.webViewModel = WebViewModel(provider: manager.currentProvider)
        
        // Observe notifications for window opening
        NotificationCenter.default.addObserver(forName: .openMainWindow, object: nil, queue: .main) { [weak self] _ in
            self?.openMainWindow()
        }
        
        // Sync provider changes between manager and webViewModel
        manager.onProviderChanged = { [weak self] oldProvider, newProvider in
            self?.webViewModel.switchToProvider(newProvider)
            // Отправляем уведомление об изменении провайдера
            NotificationCenter.default.post(name: .providerChanged, object: newProvider)
        }
        
        // Observe visible providers changes
        NotificationCenter.default.addObserver(forName: Notification.Name("VisibleProvidersChanged"), object: nil, queue: .main) { [weak self] _ in
            self?.handleVisibleProvidersChanged()
        }
    }
    
    private func handleVisibleProvidersChanged() {
        // Check if current provider is still visible
        let manager = AIProviderManager()
        if !manager.isProviderVisible(currentProvider) {
            // Switch to first visible provider
            if let firstVisible = manager.visibleProvidersList.first {
                switchToProvider(firstVisible)
            }
        }
    }

    // MARK: - Provider Switching
    
    func switchToProvider(_ provider: AIProvider) {
        providerManager.switchToProvider(provider)
    }

    // MARK: - Navigation

    func goBack() { webViewModel.goBack() }
    func goForward() { webViewModel.goForward() }
    func goHome() { webViewModel.loadHome() }
    func reload() { webViewModel.reload() }

    // MARK: - Zoom

    func zoomIn() { webViewModel.zoomIn() }
    func zoomOut() { webViewModel.zoomOut() }
    func resetZoom() { webViewModel.resetZoom() }

    // MARK: - Chat Bar

    func showChatBar() {
        // Hide main window when showing chat bar
        closeMainWindow()

        if let bar = chatBar {
            // Reuse existing chat bar - reposition to current mouse screen
            repositionChatBarToMouseScreen(bar)
            bar.orderFront(nil)
            bar.makeKeyAndOrderFront(nil)
            bar.checkAndAdjustSize()
            return
        }

        // Create ChatBarPanel
        let bar = ChatBarPanel()

        // Position at bottom center of the screen where mouse is located
        if let screen = NSScreen.screenAtMouseLocation() {
            let origin = screen.bottomCenterPoint(for: bar.frame.size, dockOffset: Constants.dockOffset)
            bar.setFrameOrigin(origin)
        }

        bar.orderFront(nil)
        bar.makeKeyAndOrderFront(nil)
        chatBar = bar
    }

    /// Repositions an existing chat bar to the screen containing the mouse cursor
    private func repositionChatBarToMouseScreen(_ bar: ChatBarPanel) {
        guard let screen = NSScreen.screenAtMouseLocation() else { return }
        let origin = screen.bottomCenterPoint(for: bar.frame.size, dockOffset: Constants.dockOffset)
        bar.setFrameOrigin(origin)
    }

    func hideChatBar() {
        chatBar?.orderOut(nil)
    }

    func closeMainWindow() {
        // Find and hide the main window
        for window in NSApp.windows {
            if window.identifier?.rawValue == Constants.mainWindowIdentifier || window.title == Constants.mainWindowTitle {
                if !(window is NSPanel) {
                    window.orderOut(nil)
                }
            }
        }
    }

    func toggleChatBar() {
        if let bar = chatBar, bar.isVisible {
            hideChatBar()
        } else {
            showChatBar()
        }
    }

    func expandToMainWindow() {
        // Capture the screen where the chat bar is located before hiding it
        let targetScreen = chatBar.flatMap { bar -> NSScreen? in
            let center = NSPoint(x: bar.frame.midX, y: bar.frame.midY)
            return NSScreen.screen(containing: center)
        } ?? NSScreen.main

        hideChatBar()
        openMainWindow(on: targetScreen)
    }

    func openMainWindow(on targetScreen: NSScreen? = nil) {
        // Hide chat bar first - WebView can only be in one view hierarchy
        hideChatBar()

        let hideDockIcon = UserDefaults.standard.bool(forKey: UserDefaultsKeys.hideDockIcon.rawValue)
        if !hideDockIcon {
            NSApp.setActivationPolicy(.regular)
        }

        // Find existing main window (may be hidden/suppressed)
        let mainWindow = findMainWindow()

        if let window = mainWindow {
            // Window exists - show it (works for suppressed windows too)
            if let screen = targetScreen {
                centerWindow(window, on: screen)
            }
            window.makeKeyAndOrderFront(nil)
        } else if let openWindowAction = openWindowAction {
            // Window doesn't exist yet - use SwiftUI openWindow to create it
            openWindowAction("main")
            // Position newly created window with retry mechanism
            if let screen = targetScreen {
                centerNewlyCreatedWindow(on: screen)
            }
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    /// Finds the main window by identifier or title
    private func findMainWindow() -> NSWindow? {
        NSApp.windows.first {
            $0.identifier?.rawValue == Constants.mainWindowIdentifier || $0.title == Constants.mainWindowTitle
        }
    }

    /// Centers a window on the specified screen
    private func centerWindow(_ window: NSWindow, on screen: NSScreen) {
        let origin = screen.centerPoint(for: window.frame.size)
        window.setFrameOrigin(origin)
    }

    /// Centers a newly created window on the target screen with retry mechanism
    private func centerNewlyCreatedWindow(on screen: NSScreen, attempt: Int = 1) {
        let maxAttempts = 5
        let retryDelay = 0.05 // 50ms between attempts

        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
            guard let self = self else { return }

            if let window = self.findMainWindow() {
                self.centerWindow(window, on: screen)
            } else if attempt < maxAttempts {
                // Window not found yet, retry
                self.centerNewlyCreatedWindow(on: screen, attempt: attempt + 1)
            }
        }
    }
}


extension AppCoordinator {

    struct Constants {
        static let dockOffset: CGFloat = 50
        static let mainWindowIdentifier = "main"
        static let mainWindowTitle = "AI Chat App"
    }

}
