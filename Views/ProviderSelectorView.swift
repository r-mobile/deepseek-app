//
//  ProviderSelectorView.swift
//  AIChat Desktop
//

import SwiftUI

struct ProviderSelectorView: View {
    @Binding var selectedProvider: AIProvider
    @State private var visibleProviders: Set<AIProvider> = []
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(visibleProvidersList) { provider in
                ProviderButton(
                    provider: provider,
                    isSelected: selectedProvider == provider,
                    namespace: animation
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedProvider = provider
                    }
                }
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .onAppear {
            updateVisibleProviders()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("VisibleProvidersChanged"))) { _ in
            updateVisibleProviders()
        }
    }
    
    private var visibleProvidersList: [AIProvider] {
        AIProvider.allCases.filter { visibleProviders.contains($0) }
    }
    
    private func updateVisibleProviders() {
        if let savedVisible = UserDefaults.standard.stringArray(forKey: UserDefaultsKeys.visibleProviders.rawValue) {
            visibleProviders = Set(savedVisible.compactMap { AIProvider(rawValue: $0) })
        } else {
            visibleProviders = Set(AIProvider.allCases)
        }
    }
}

struct ProviderButton: View {
    let provider: AIProvider
    let isSelected: Bool
    var namespace: Namespace.ID
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: provider.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .white : provider.color)
                    .frame(width: 20, height: 20)
                
                Text(provider.displayName)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(provider.color)
                            .matchedGeometryEffect(id: "background", in: namespace)
                    } else if isHovered {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(provider.color.opacity(0.1))
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

struct CompactProviderSelector: View {
    @Binding var selectedProvider: AIProvider
    @State private var visibleProviders: Set<AIProvider> = []
    
    var body: some View {
        Menu {
            ForEach(visibleProvidersList) { provider in
                Button {
                    selectedProvider = provider
                } label: {
                    Label(provider.displayName, systemImage: provider.icon)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: selectedProvider.icon)
                    .foregroundColor(selectedProvider.color)
                Text(selectedProvider.displayName)
                    .font(.system(size: 12))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .onAppear {
            updateVisibleProviders()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("VisibleProvidersChanged"))) { _ in
            updateVisibleProviders()
        }
    }
    
    private var visibleProvidersList: [AIProvider] {
        AIProvider.allCases.filter { visibleProviders.contains($0) }
    }
    
    private func updateVisibleProviders() {
        if let savedVisible = UserDefaults.standard.stringArray(forKey: UserDefaultsKeys.visibleProviders.rawValue) {
            visibleProviders = Set(savedVisible.compactMap { AIProvider(rawValue: $0) })
        } else {
            visibleProviders = Set(AIProvider.allCases)
        }
    }
}
