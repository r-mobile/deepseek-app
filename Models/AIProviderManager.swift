//
//  AIProviderManager.swift
//  AIChat Desktop
//

import Foundation
import SwiftUI
import Combine
import WebKit

@Observable
class AIProviderManager: ObservableObject {
    var currentProvider: AIProvider {
        didSet {
            if oldValue != currentProvider {
                UserDefaults.standard.set(currentProvider.rawValue, forKey: UserDefaultsKeys.currentProvider.rawValue)
                onProviderChanged?(oldValue, currentProvider)
            }
        }
    }
    
    var visibleProviders: Set<AIProvider> {
        didSet {
            let rawValues = Array(visibleProviders.map { $0.rawValue })
            UserDefaults.standard.set(rawValues, forKey: UserDefaultsKeys.visibleProviders.rawValue)
        }
    }
    
    var onProviderChanged: ((AIProvider, AIProvider) -> Void)?
    
    init() {
        // Используем последний выбранный провайдер
        let savedProvider = UserDefaults.standard.string(forKey: UserDefaultsKeys.currentProvider.rawValue)
        self.currentProvider = AIProvider(rawValue: savedProvider ?? "") ?? .deepseek
        
        // Загружаем видимые провайдеры (по умолчанию все видимы)
        if let savedVisible = UserDefaults.standard.stringArray(forKey: UserDefaultsKeys.visibleProviders.rawValue) {
            self.visibleProviders = Set(savedVisible.compactMap { AIProvider(rawValue: $0) })
        } else {
            self.visibleProviders = Set(AIProvider.allCases)
        }
    }
    
    func switchToProvider(_ provider: AIProvider) {
        guard provider != currentProvider else { return }
        currentProvider = provider
    }
    
    func getProviderURL(for provider: AIProvider) -> URL {
        provider.url
    }
    
    func isProviderVisible(_ provider: AIProvider) -> Bool {
        visibleProviders.contains(provider)
    }
    
    func setProviderVisible(_ provider: AIProvider, visible: Bool) {
        if visible {
            visibleProviders.insert(provider)
        } else {
            visibleProviders.remove(provider)
            // Если текущий провайдер стал невидимым, переключаемся на первый видимый
            if currentProvider == provider && !visibleProviders.isEmpty {
                currentProvider = visibleProviders.first!
            }
        }
    }
    
    var visibleProvidersList: [AIProvider] {
        AIProvider.allCases.filter { visibleProviders.contains($0) }
    }
}
