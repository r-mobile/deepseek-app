//
//  MainWindowView.swift
//  AIChat Desktop
//

import SwiftUI
import AppKit
import WebKit

struct MainWindowView: View {
    @Environment(\.openWindow) private var openWindow
    @State private var isLoading = false
    @State private var loadingProvider: AIProvider?

    var body: some View {
        VStack(spacing: 0) {
            // Provider Selector Bar
            HStack {
                Spacer()
                
                ProviderSelectorView(selectedProvider: Binding(
                    get: { AppCoordinator.shared.currentProvider },
                    set: { newProvider in
                        if newProvider != AppCoordinator.shared.currentProvider {
                            // Show loading for new provider
                            loadingProvider = newProvider
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isLoading = true
                            }
                            
                            // Perform switch
                            AppCoordinator.shared.switchToProvider(newProvider)
                            
                            // Hide loading after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isLoading = false
                                }
                            }
                        }
                    }
                ))
                
                Spacer()
            }
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(NSColor.separatorColor)),
                alignment: .bottom
            )
            
            // WebView with loading overlay
            ZStack {
                AIWebView(webView: AppCoordinator.shared.currentWebView)
                    .id(AppCoordinator.shared.currentProvider)
                
                // Loading overlay
                if let provider = loadingProvider, isLoading {
                    LoadingOverlayView(provider: provider)
                        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                }
            }
        }
        .onAppear {
            AppCoordinator.shared.openWindowAction = { id in
                openWindow(id: id)
            }
        }
        .toolbar {
            if AppCoordinator.shared.canGoBack {
                ToolbarItem(placement: .navigation) {
                    Button {
                        AppCoordinator.shared.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .help("Back")
                }
            }

            ToolbarItem(placement: .principal) {
                Spacer()
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    minimizeToPrompt()
                } label: {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                }
                .help("Minimize to Prompt Panel")
            }
        }
    }

    private func minimizeToPrompt() {
        // Close main window and show chat bar
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == AppCoordinator.Constants.mainWindowIdentifier || $0.title == AppCoordinator.Constants.mainWindowTitle }) {
            if !(window is NSPanel) {
                window.orderOut(nil)
            }
        }
        AppCoordinator.shared.showChatBar()
    }
}
