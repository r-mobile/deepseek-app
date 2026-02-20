//
//  WebViewModel.swift
//  AIChat Desktop
//

import WebKit
import Combine

/// Handles console.log messages from JavaScript
class ConsoleLogHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let body = message.body as? String {
            print("[WebView] \(body)")
        }
    }
}

/// Observable wrapper around WKWebView with multi-AI provider support
@Observable
class WebViewModel {

    // MARK: - Constants

    static let defaultPageZoom: Double = 1.0
    private static let minZoom: Double = 0.6
    private static let maxZoom: Double = 1.4
    private static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    // MARK: - Public Properties

    private(set) var webViews: [AIProvider: WKWebView] = [:]
    private(set) var canGoBack: Bool = false
    private(set) var canGoForward: Bool = false
    private(set) var isAtHome: Bool = true
    private(set) var currentProvider: AIProvider

    /// Returns the current active WebView
    var currentWebView: WKWebView {
        webViews[currentProvider] ?? createWebView(for: currentProvider)
    }

    // MARK: - Private Properties

    private var backObserver: NSKeyValueObservation?
    private var forwardObserver: NSKeyValueObservation?
    private var urlObserver: NSKeyValueObservation?
    private let consoleLogHandler = ConsoleLogHandler()
    private var observers: [AIProvider: [NSKeyValueObservation]] = [:]

    // MARK: - Initialization

    init(provider: AIProvider) {
        self.currentProvider = provider
        
        // Create WebViews for all providers upfront
        for aiProvider in AIProvider.allCases {
            let webView = createWebView(for: aiProvider)
            webViews[aiProvider] = webView
            setupObservers(for: aiProvider, webView: webView)
        }
        
        // Load initial provider
        loadHome()
    }

    // MARK: - Provider Switching

    func switchToProvider(_ newProvider: AIProvider) {
        guard newProvider != currentProvider else { return }
        
        // Save zoom level for current provider
        let currentZoom = Double(webViews[currentProvider]?.pageZoom ?? CGFloat(Self.defaultPageZoom))
        UserDefaults.standard.set(currentZoom, forKey: "\(currentProvider.rawValue)_zoom")
        
        // Switch to new provider
        currentProvider = newProvider
        
        // Restore zoom level for new provider
        let savedZoom = UserDefaults.standard.double(forKey: "\(newProvider.rawValue)_zoom")
        webViews[newProvider]?.pageZoom = savedZoom > 0 ? savedZoom : Self.defaultPageZoom
        
        // Update navigation state for new provider
        updateNavigationState(for: newProvider)
    }

    // MARK: - Navigation

    func loadHome() {
        isAtHome = true
        canGoBack = false
        
        // Load home only if not already loaded
        let webView = webViews[currentProvider]!
        if webView.url == nil || !currentProvider.trustedHosts.contains(where: { webView.url?.host?.contains($0) ?? false }) {
            webView.load(URLRequest(url: currentProvider.url))
        }
    }

    func goBack() {
        isAtHome = false
        webViews[currentProvider]?.goBack()
    }

    func goForward() {
        webViews[currentProvider]?.goForward()
    }

    func reload() {
        webViews[currentProvider]?.reload()
    }

    // MARK: - Zoom

    func zoomIn() {
        guard let webView = webViews[currentProvider] else { return }
        let newZoom = min((webView.pageZoom * 100 + 1).rounded() / 100, Self.maxZoom)
        setZoom(newZoom)
    }

    func zoomOut() {
        guard let webView = webViews[currentProvider] else { return }
        let newZoom = max((webView.pageZoom * 100 - 1).rounded() / 100, Self.minZoom)
        setZoom(newZoom)
    }

    func resetZoom() {
        setZoom(Self.defaultPageZoom)
    }

    private func setZoom(_ zoom: Double) {
        webViews[currentProvider]?.pageZoom = zoom
        UserDefaults.standard.set(zoom, forKey: "\(currentProvider.rawValue)_zoom")
    }

    // MARK: - Private Setup

    private func createWebView(for provider: AIProvider) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        // Use default data store to share cookies/sessions between providers
        configuration.websiteDataStore = .default()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        // Add user scripts
        for script in UserScripts.createAllScripts() {
            configuration.userContentController.addUserScript(script)
        }

        // Register console log message handler (debug only)
        #if DEBUG
        configuration.userContentController.add(consoleLogHandler, name: UserScripts.consoleLogHandler)
        #endif

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        webView.customUserAgent = Self.userAgent

        // Set provider-specific zoom
        let savedZoom = UserDefaults.standard.double(forKey: "\(provider.rawValue)_zoom")
        webView.pageZoom = savedZoom > 0 ? savedZoom : Self.defaultPageZoom

        // Load initial URL if needed
        webView.load(URLRequest(url: provider.url))

        return webView
    }

    private func setupObservers(for provider: AIProvider, webView: WKWebView) {
        let backObs = webView.observe(\.canGoBack, options: [.new, .initial]) { [weak self] webView, _ in
            DispatchQueue.main.async {
                guard let self = self, self.currentProvider == provider else { return }
                self.canGoBack = !self.isAtHome && webView.canGoBack
            }
        }

        let forwardObs = webView.observe(\.canGoForward, options: [.new, .initial]) { [weak self] webView, _ in
            DispatchQueue.main.async {
                guard let self = self, self.currentProvider == provider else { return }
                self.canGoForward = webView.canGoForward
            }
        }

        let urlObs = webView.observe(\.url, options: .new) { [weak self] webView, _ in
            DispatchQueue.main.async {
                guard let self = self, self.currentProvider == provider else { return }
                guard let currentURL = webView.url else { return }

                let isProviderApp = provider.trustedHosts.contains { host in
                    currentURL.host?.contains(host) ?? false
                }

                if isProviderApp {
                    self.isAtHome = true
                    self.canGoBack = false
                } else {
                    self.isAtHome = false
                    self.canGoBack = webView.canGoBack
                }
            }
        }

        observers[provider] = [backObs, forwardObs, urlObs]
    }

    private func updateNavigationState(for provider: AIProvider) {
        guard let webView = webViews[provider] else { return }
        
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        
        if let currentURL = webView.url {
            let isProviderApp = provider.trustedHosts.contains { host in
                currentURL.host?.contains(host) ?? false
            }
            isAtHome = isProviderApp
        }
    }
}
