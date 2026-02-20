//
//  LoadingOverlayView.swift
//  AIChat Desktop
//

import SwiftUI

struct LoadingOverlayView: View {
    let provider: AIProvider
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background blur
            Color(NSColor.windowBackgroundColor)
                .opacity(0.95)
            
            VStack(spacing: 24) {
                // Animated icon
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(provider.color.opacity(0.2), lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    // Spinning ring
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(provider.color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 1.2)
                                .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                    
                    // Provider icon
                    Image(systemName: provider.icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(provider.color)
                }
                
                // Loading text
                VStack(spacing: 8) {
                    Text("Switching to \(provider.displayName)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Loading your conversation...")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                // Progress dots
                HStack(spacing: 6) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(provider.color)
                            .frame(width: 8, height: 8)
                            .opacity(isAnimating ? 1 : 0.3)
                            .scaleEffect(isAnimating ? 1 : 0.8)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            isAnimating = true
        }
        .onDisappear {
            isAnimating = false
        }
    }
}

// MARK: - Transition Modifier
struct LoadingOverlayModifier: ViewModifier {
    let isLoading: Bool
    let provider: AIProvider
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isLoading {
                LoadingOverlayView(provider: provider)
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
    }
}

extension View {
    func loadingOverlay(isLoading: Bool, provider: AIProvider) -> some View {
        modifier(LoadingOverlayModifier(isLoading: isLoading, provider: provider))
    }
}
