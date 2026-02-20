//
//  AIProvider.swift
//  AIChat Desktop
//

import Foundation
import SwiftUI

enum AIProvider: String, CaseIterable, Identifiable, Codable {
    case deepseek = "deepseek"
    case kimi = "kimi"
    case gemini = "gemini"
    case zai = "zai"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .deepseek:
            return "DeepSeek"
        case .kimi:
            return "Kimi"
        case .gemini:
            return "Gemini"
        case .zai:
            return "Z.ai"
        }
    }
    
    var url: URL {
        switch self {
        case .deepseek:
            return URL(string: "https://chat.deepseek.com")!
        case .kimi:
            return URL(string: "https://kimi.com")!
        case .gemini:
            return URL(string: "https://gemini.google.com")!
        case .zai:
            return URL(string: "https://chat.z.ai")!
        }
    }
    
    var icon: String {
        switch self {
        case .deepseek:
            return "bubble.left.fill"
        case .kimi:
            return "moon.fill"
        case .gemini:
            return "sparkles"
        case .zai:
            return "z.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .deepseek:
            return Color(red: 0.2, green: 0.6, blue: 1.0)
        case .kimi:
            return Color(red: 0.4, green: 0.3, blue: 0.9)
        case .gemini:
            return Color(red: 0.9, green: 0.3, blue: 0.5)
        case .zai:
            return Color(red: 0.95, green: 0.5, blue: 0.1)
        }
    }
    
    var host: String {
        switch self {
        case .deepseek:
            return "chat.deepseek.com"
        case .kimi:
            return "kimi.com"
        case .gemini:
            return "gemini.google.com"
        case .zai:
            return "chat.z.ai"
        }
    }
    
    var trustedHosts: [String] {
        switch self {
        case .deepseek:
            return ["chat.deepseek.com", "www.deepseek.com", "deepseek.com"]
        case .kimi:
            return ["kimi.com", "www.kimi.com", "kimi.moonshot.cn"]
        case .gemini:
            return ["gemini.google.com", "google.com", "www.google.com"]
        case .zai:
            return ["chat.z.ai", "z.ai", "www.z.ai"]
        }
    }
    
    var userAgent: String {
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
    }
}
