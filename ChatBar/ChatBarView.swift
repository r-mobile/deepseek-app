//
//  ChatBarView.swift
//  AIChat Desktop
//

import SwiftUI
import WebKit

struct ChatBarView: View {
    @State private var isLoading = false
    @State private var loadingProvider: AIProvider?
    @State private var currentProvider: AIProvider = AppCoordinator.shared.currentProvider

    /// Calculate button offset based on screen height
    /// MacBook Air 13" (~900pt): (-6, -2), 1080p (1080pt): (-4, 0)
    private var buttonOffset: CGSize {
        let screenHeight = NSScreen.main?.frame.height ?? 900
        // Interpolate: 900pt -> (-6, -2), 1080pt -> (-4, 0)
        let t = (screenHeight - 900) / 180  // 0 at 900pt, 1 at 1080pt
        let xOffset = -6.0 + t * 2.0
        let yOffset = -2.0 + t * 2.0
        return CGSize(width: xOffset, height: yOffset)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Используем id для переключения между WebView разных провайдеров
            AIWebView(webView: AppCoordinator.shared.currentWebView)
                .id(currentProvider)
            
            // Loading overlay
            if let provider = loadingProvider, isLoading {
                LoadingOverlayView(provider: provider)
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }

            // Expand button (скрыт во время загрузки)
            if !isLoading {
                Button(action: {
                    AppCoordinator.shared.expandToMainWindow()
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial, in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(16)
                .offset(buttonOffset)
                .transition(.opacity.animation(.easeInOut(duration: 0.15)))
            }
        }
        .onAppear {
            // Подписываемся на уведомления об изменении провайдера
            NotificationCenter.default.addObserver(
                forName: .providerChanged,
                object: nil,
                queue: .main
            ) { notification in
                if let newProvider = notification.object as? AIProvider {
                    if newProvider != currentProvider {
                        // Show loading for new provider
                        loadingProvider = newProvider
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isLoading = true
                        }
                        
                        // Hide loading after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isLoading = false
                            }
                        }
                        
                        currentProvider = newProvider
                    }
                }
            }
        }
    }
}
