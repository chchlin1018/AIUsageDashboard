//
//  AIProvider.swift
//  AIUsageDashboard
//
//  Created by Michael Lin on 2026/3/11.
//  Copyright © 2026 MacroVision Systems. All rights reserved.
//

import SwiftUI

// MARK: - AI Provider Definition

struct AIProvider: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let icon: String
    let colorHex: String
    var plans: [Plan]
    var apiKeyConfigured: Bool
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    struct Plan: Codable, Hashable, Identifiable {
        var id: String { name }
        let name: String
        let monthlyQuota: Int
        let unit: UsageUnit
        let costPerMonth: Double?
        let costPerUnit: Double?
    }
}

// MARK: - Usage Unit

enum UsageUnit: String, Codable, Hashable {
    case messages = "msgs"
    case tokens = "tokens"
    case credits = "credits"
    case dollars = "USD"
    
    var displayName: String {
        switch self {
        case .messages: return "訊息"
        case .tokens: return "Tokens"
        case .credits: return "點數"
        case .dollars: return "美元"
        }
    }
}

// MARK: - Alert Level

enum AlertLevel: Int, Comparable {
    case normal = 0
    case warning = 1
    case critical = 2
    case exhausted = 3
    
    static func < (lhs: AlertLevel, rhs: AlertLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    var color: Color {
        switch self {
        case .normal: return .green
        case .warning: return .yellow
        case .critical: return .orange
        case .exhausted: return .red
        }
    }
    
    var label: String {
        switch self {
        case .normal: return "正常"
        case .warning: return "注意"
        case .critical: return "警告"
        case .exhausted: return "耗盡"
        }
    }
    
    static func from(percentage: Double) -> AlertLevel {
        switch percentage {
        case 95...Double.infinity: return .exhausted
        case 85..<95: return .critical
        case 75..<85: return .warning
        default: return .normal
        }
    }
}

// MARK: - Provider Configuration

struct ProviderConfig: Codable, Identifiable {
    var id: String { providerId }
    let providerId: String
    var monthlyQuota: Int
    var monthlyBudget: Double
    var alertThreshold: Double
    var apiKey: String?
    var isEnabled: Bool
}

// MARK: - Dashboard Configuration

struct DashboardConfig: Codable, Equatable {
    var providers: [ProviderConfig]
    var refreshInterval: TimeInterval
    var enableNotifications: Bool
    var currency: String
    
    static func == (lhs: DashboardConfig, rhs: DashboardConfig) -> Bool {
        lhs.refreshInterval == rhs.refreshInterval &&
        lhs.enableNotifications == rhs.enableNotifications &&
        lhs.currency == rhs.currency
    }
    
    static let `default` = DashboardConfig(
        providers: [
            ProviderConfig(providerId: "claude", monthlyQuota: 100, monthlyBudget: 20, alertThreshold: 0.75, isEnabled: true),
            ProviderConfig(providerId: "chatgpt", monthlyQuota: 80, monthlyBudget: 20, alertThreshold: 0.75, isEnabled: true),
            ProviderConfig(providerId: "gemini", monthlyQuota: 120, monthlyBudget: 20, alertThreshold: 0.75, isEnabled: true),
            ProviderConfig(providerId: "manus", monthlyQuota: 500, monthlyBudget: 50, alertThreshold: 0.75, isEnabled: true),
        ],
        refreshInterval: 300,
        enableNotifications: true,
        currency: "USD"
    )
}

// MARK: - Default Providers

extension AIProvider {
    static let allProviders: [AIProvider] = [
        AIProvider(
            id: "claude", name: "Claude", icon: "🧠", colorHex: "#D4A574",
            plans: [
                Plan(name: "Pro", monthlyQuota: 100, unit: .messages, costPerMonth: 20, costPerUnit: nil),
                Plan(name: "API (Opus)", monthlyQuota: 1_000_000, unit: .tokens, costPerMonth: nil, costPerUnit: 0.015),
                Plan(name: "API (Sonnet)", monthlyQuota: 5_000_000, unit: .tokens, costPerMonth: nil, costPerUnit: 0.003),
            ],
            apiKeyConfigured: false
        ),
        AIProvider(
            id: "chatgpt", name: "ChatGPT", icon: "💬", colorHex: "#10A37F",
            plans: [
                Plan(name: "Plus", monthlyQuota: 80, unit: .messages, costPerMonth: 20, costPerUnit: nil),
                Plan(name: "API (GPT-4o)", monthlyQuota: 2_000_000, unit: .tokens, costPerMonth: nil, costPerUnit: 0.005),
            ],
            apiKeyConfigured: false
        ),
        AIProvider(
            id: "gemini", name: "Gemini", icon: "✨", colorHex: "#4285F4",
            plans: [
                Plan(name: "Advanced", monthlyQuota: 120, unit: .messages, costPerMonth: 20, costPerUnit: nil),
                Plan(name: "API (Pro)", monthlyQuota: 3_000_000, unit: .tokens, costPerMonth: nil, costPerUnit: 0.00125),
            ],
            apiKeyConfigured: false
        ),
        AIProvider(
            id: "manus", name: "Manus", icon: "🤖", colorHex: "#A855F7",
            plans: [
                Plan(name: "Credits", monthlyQuota: 500, unit: .credits, costPerMonth: nil, costPerUnit: 0.10),
            ],
            apiKeyConfigured: false
        ),
    ]
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
