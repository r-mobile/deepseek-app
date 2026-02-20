import SwiftUI
import KeyboardShortcuts
import WebKit
import ServiceManagement

struct SettingsView: View {
    @AppStorage(UserDefaultsKeys.pageZoom.rawValue) private var pageZoom: Double = Constants.defaultPageZoom
    @AppStorage(UserDefaultsKeys.hideWindowAtLaunch.rawValue) private var hideWindowAtLaunch: Bool = false
    @AppStorage(UserDefaultsKeys.hideDockIcon.rawValue) private var hideDockIcon: Bool = false
    @State private var visibleProviders: Set<AIProvider> = Set(AIProvider.allCases)

    @State private var showingResetAlert = false
    @State private var isClearing = false
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch MenuBar at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            try newValue ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                        } catch { launchAtLogin = !newValue }
                    }
                Toggle("Hide Desktop Window at Launch", isOn: $hideWindowAtLaunch)
                Toggle("Hide Dock Icon", isOn: $hideDockIcon)
                    .onChange(of: hideDockIcon) { _, newValue in
                        NSApp.setActivationPolicy(newValue ? .accessory : .regular)
                    }
            }
            Section("Visible Providers") {
                ForEach(AIProvider.allCases) { provider in
                    HStack {
                        Image(systemName: provider.icon)
                            .foregroundColor(provider.color)
                            .frame(width: 20)
                        Text(provider.displayName)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { visibleProviders.contains(provider) },
                            set: { isVisible in
                                if isVisible {
                                    visibleProviders.insert(provider)
                                } else {
                                    visibleProviders.remove(provider)
                                }
                                saveVisibleProviders()
                            }
                        ))
                        .toggleStyle(.switch)
                        .labelsHidden()
                    }
                }
            }
            Section("Keyboard Shortcuts") {
                HStack {
                    Text("Toggle Chat Bar:")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .bringToFront)
                }
            }
            Section("Appearance") {
                HStack {
                    Text("Text Size: \(Int((pageZoom * 100).rounded()))%")
                    Spacer()
                    Stepper("",
                            value: $pageZoom,
                            in: Constants.minPageZoom...Constants.maxPageZoom,
                            step: Constants.pageZoomStep)
                        .onChange(of: pageZoom) { AppCoordinator.shared.currentWebView.pageZoom = CGFloat($1) }
                        .labelsHidden()
                }
            }
            Section("Privacy") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Reset Website Data")
                        Text("Clears cookies, cache, and login sessions")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Reset", role: .destructive) { showingResetAlert = true }
                        .disabled(isClearing)
                        .overlay { if isClearing { ProgressView().scaleEffect(0.7) } }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            loadVisibleProviders()
        }
        .alert("Reset Website Data?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) { clearWebsiteData() }
        } message: {
            Text("This will clear all cookies, cache, and login sessions for all AI providers. You will need to sign in again.")
        }
    }

    private func clearWebsiteData() {
        isClearing = true
        let dataStore = WKWebsiteDataStore.default()
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        dataStore.fetchDataRecords(ofTypes: types) { records in
            dataStore.removeData(ofTypes: types, for: records) {
                DispatchQueue.main.async { isClearing = false }
            }
        }
    }
    
    private func loadVisibleProviders() {
        if let savedVisible = UserDefaults.standard.stringArray(forKey: UserDefaultsKeys.visibleProviders.rawValue) {
            visibleProviders = Set(savedVisible.compactMap { AIProvider(rawValue: $0) })
        } else {
            visibleProviders = Set(AIProvider.allCases)
        }
    }
    
    private func saveVisibleProviders() {
        let rawValues = Array(visibleProviders.map { $0.rawValue })
        UserDefaults.standard.set(rawValues, forKey: UserDefaultsKeys.visibleProviders.rawValue)
        
        // Notify other views that visible providers changed
        NotificationCenter.default.post(name: Notification.Name("VisibleProvidersChanged"), object: nil)
    }
}

extension SettingsView {

    struct Constants {
        static let defaultPageZoom: Double = 1.0
        static let minPageZoom: Double = 0.6
        static let maxPageZoom: Double = 1.4
        static let pageZoomStep: Double = 0.01
    }

}
