//
//  MenuBarView.swift
//  AIChat Desktop
//

import SwiftUI
import AppKit

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    
    // Используем вычисляемое свойство вместо @State
    // чтобы получать актуальное значение при каждом открытии меню
    private var currentProvider: AIProvider {
        AppCoordinator.shared.currentProvider
    }

    var body: some View {
        Group {
            // Provider Selection Section
            VStack(alignment: .leading, spacing: 4) {
                Text("Current AI")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                
                ForEach(AIProvider.allCases) { provider in
                    Button {
                        AppCoordinator.shared.switchToProvider(provider)
                        AppCoordinator.shared.openMainWindow()
                    } label: {
                        HStack {
                            Image(systemName: provider.icon)
                                .foregroundColor(provider.color)
                                .frame(width: 20)
                            Text(provider.displayName)
                            Spacer()
                            if currentProvider == provider {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        currentProvider == provider ?
                        Color.accentColor.opacity(0.1) : Color.clear
                    )
                }
            }
            
            Divider()

            Button {
                AppCoordinator.shared.openMainWindow()
            } label: {
                Label("Open AI Chat", systemImage: "macwindow")
            }

            Button {
                AppCoordinator.shared.toggleChatBar()
            } label: {
                Label("Toggle Chat Bar", systemImage: "rectangle.bottomhalf.inset.filled")
            }

            Divider()

            SettingsLink {
                Label("Settings...", systemImage: "gearshape")
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button {
                NSApp.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .onAppear {
            AppCoordinator.shared.openWindowAction = { id in
                openWindow(id: id)
            }
        }
    }
}
