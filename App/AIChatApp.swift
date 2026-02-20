//
//  AIChatApp.swift
//  AIChat Desktop
//

import SwiftUI
import KeyboardShortcuts
import AppKit
import Combine

// MARK: - Main App
@main
struct AIChatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        Window(AppCoordinator.Constants.mainWindowTitle, id: Constants.mainWindowID) {
            MainWindowView()
                .toolbarBackground(Color(nsColor: Constants.toolbarColor), for: .windowToolbar)
                .frame(minWidth: Constants.mainWindowMinWidth, minHeight: Constants.mainWindowMinHeight)
        }
        .defaultSize(width: Constants.mainWindowDefaultWidth, height: Constants.mainWindowDefaultHeight)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(after: .toolbar) {
                Button {
                    AppCoordinator.shared.goBack()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .keyboardShortcut("[", modifiers: .command)
                .disabled(!AppCoordinator.shared.canGoBack)

                Button {
                    AppCoordinator.shared.goForward()
                } label: {
                    Label("Forward", systemImage: "chevron.right")
                }
                .keyboardShortcut("]", modifiers: .command)
                .disabled(!AppCoordinator.shared.canGoForward)

                Button {
                    AppCoordinator.shared.goHome()
                } label: {
                    Label("Go Home", systemImage: "house")
                }
                .keyboardShortcut("h", modifiers: [.command, .shift])

                Divider()

                Button {
                    AppCoordinator.shared.reload()
                } label: {
                    Label("Reload Page", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)

                Divider()

                Button {
                    AppCoordinator.shared.zoomIn()
                } label: {
                    Label("Zoom In", systemImage: "plus.magnifyingglass")
                }
                .keyboardShortcut("+", modifiers: .command)

                Button {
                    AppCoordinator.shared.zoomOut()
                } label: {
                    Label("Zoom Out", systemImage: "minus.magnifyingglass")
                }
                .keyboardShortcut("-", modifiers: .command)

                Button {
                    AppCoordinator.shared.resetZoom()
                } label: {
                    Label("Actual Size", systemImage: "1.magnifyingglass")
                }
                .keyboardShortcut("0", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
        }
        .defaultSize(width: Constants.settingsWindowDefaultWidth, height: Constants.settingsWindowDefaultHeight)

        MenuBarExtra {
            MenuBarView()
        } label: {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .onAppear {
                    let hideWindowAtLaunch = UserDefaults.standard.bool(forKey: UserDefaultsKeys.hideWindowAtLaunch.rawValue)
                    let hideDockIcon = UserDefaults.standard.bool(forKey: UserDefaultsKeys.hideDockIcon.rawValue)

                    if hideDockIcon || hideWindowAtLaunch {
                        NSApp.setActivationPolicy(.accessory)
                        if hideWindowAtLaunch {
                            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.hideWindowDelay) {
                                for window in NSApp.windows {
                                    if window.identifier?.rawValue == Constants.mainWindowID || window.title == AppCoordinator.Constants.mainWindowTitle {
                                        window.orderOut(nil)
                                    }
                                }
                            }
                        }
                    } else {
                        NSApp.setActivationPolicy(.regular)
                    }
                }
        }
        .menuBarExtraStyle(.menu)
    }

    init() {
        KeyboardShortcuts.onKeyDown(for: .bringToFront) {
            AppCoordinator.shared.toggleChatBar()
        }
    }
}

// MARK: - Constants
extension AIChatApp {
    struct Constants {
        // Main Window
        static let mainWindowMinWidth: CGFloat = 400
        static let mainWindowMinHeight: CGFloat = 300
        static let mainWindowDefaultWidth: CGFloat = 1000
        static let mainWindowDefaultHeight: CGFloat = 700

        // Settings Window
        static let settingsWindowDefaultWidth: CGFloat = 700
        static let settingsWindowDefaultHeight: CGFloat = 600

        static let mainWindowID = "main"

        // Appearance
        static let toolbarColor: NSColor = NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(red: 43.0/255.0, green: 43.0/255.0, blue: 43.0/255.0, alpha: 1.0)
            } else {
                return NSColor(red: 238.0/255.0, green: 241.0/255.0, blue: 247.0/255.0, alpha: 1.0)
            }
        }

        // Timing
        static let hideWindowDelay: TimeInterval = 0.1
    }
}
