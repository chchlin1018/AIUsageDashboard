//
//  DashboardViewModel.swift
//  AIUsageDashboard
//
//  Created by Michael Lin on 2026/3/11.
//  Copyright © 2026 MacroVision Systems. All rights reserved.
//

import SwiftUI
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    
    // MARK: - Published State
    @Published var providers: [AIProvider] = AIProvider.allProviders
    @Published var currentUsage: [String: UsageSnapshot] = [:]
    @Published var dailyRecords: [DailyUsageRecord] = []
    @Published var hourlyRecords: [HourlyUsageRecord] = []
    @Published var alerts: [DashboardAlert] = []
    @Published var config: DashboardConfig = .default
    @Published var isLoading = false
    @Published var lastRefreshDate = Date()
    @Published var errorMessage: String?
    
    // MARK: - Services
    private let apiService = APIService()
    private let storageService = StorageService()
    private var refreshTimer: Timer?
    
    // MARK: - Computed
    var totalCost: Double { currentUsage.values.reduce(0) { $0 + $1.cost } }
    var totalCostFormatted: String { String(format: "$%.2f", totalCost) }
    var totalBudget: Double { config.providers.reduce(0) { $0 + $1.monthlyBudget } }
    var todayTotalRequests: Int { currentUsage.values.reduce(0) { $0 + $1.todayUsed } }
    var activeProviderCount: Int { config.providers.filter(\.isEnabled).count }
    var criticalAlertCount: Int { alerts.filter { $0.level >= .critical }.count }
    
    // MARK: - Connection Status
    
    /// Check if a specific provider has an API key configured
    func isProviderConnected(_ providerId: String) -> Bool {
        config.providers.first { $0.providerId == providerId }?.apiKey != nil
    }
    
    /// Number of providers with API keys configured
    var connectedProviderCount: Int {
        config.providers.filter { $0.apiKey != nil && $0.isEnabled }.count
    }
    
    var costBreakdown: [CostSummary] {
        let total = totalCost
        guard total > 0 else { return [] }
        return providers.compactMap { provider in
            guard let usage = currentUsage[provider.id] else { return nil }
            return CostSummary(providerId: provider.id, providerName: provider.name,
                             cost: usage.cost, colorHex: provider.colorHex,
                             percentage: usage.cost / total * 100)
        }
    }
    
    // MARK: - Init
    init() {
        loadConfig()
        loadSimulatedData()
        startAutoRefresh()
    }
    
    deinit { refreshTimer?.invalidate() }
    
    // MARK: - Data Loading
    func refresh() async {
        isLoading = true
        errorMessage = nil
        let hasAPIKeys = config.providers.contains { $0.apiKey != nil }
        if hasAPIKeys {
            for providerConfig in config.providers where providerConfig.isEnabled {
                guard let apiKey = providerConfig.apiKey else { continue }
                do {
                    let usage = try await apiService.fetchUsage(for: providerConfig.providerId, apiKey: apiKey)
                    currentUsage[providerConfig.providerId] = usage
                } catch {
                    errorMessage = "\(providerConfig.providerId): \(error.localizedDescription)"
                }
            }
        } else {
            loadSimulatedData()
        }
        generateAlerts()
        lastRefreshDate = Date()
        isLoading = false
    }
    
    func loadSimulatedData() {
        currentUsage = [
            "claude": UsageSnapshot(providerId: "claude", planName: "Pro + API", used: 73,
                total: config.providers.first { $0.providerId == "claude" }?.monthlyQuota ?? 100,
                unit: .messages, cost: 18.40, todayUsed: 12, averageDaily: 15,
                estimatedDaysLeft: 2, lastUpdated: Date()),
            "chatgpt": UsageSnapshot(providerId: "chatgpt", planName: "Plus + API", used: 52,
                total: config.providers.first { $0.providerId == "chatgpt" }?.monthlyQuota ?? 80,
                unit: .messages, cost: 14.20, todayUsed: 8, averageDaily: 11,
                estimatedDaysLeft: 3, lastUpdated: Date()),
            "gemini": UsageSnapshot(providerId: "gemini", planName: "Advanced", used: 45,
                total: config.providers.first { $0.providerId == "gemini" }?.monthlyQuota ?? 120,
                unit: .messages, cost: 12.00, todayUsed: 6, averageDaily: 9,
                estimatedDaysLeft: 8, lastUpdated: Date()),
            "manus": UsageSnapshot(providerId: "manus", planName: "Credits", used: 312,
                total: config.providers.first { $0.providerId == "manus" }?.monthlyQuota ?? 500,
                unit: .credits, cost: 31.20, todayUsed: 18, averageDaily: 22,
                estimatedDaysLeft: 9, lastUpdated: Date()),
        ]
        dailyRecords = generateDailyHistory(days: 30)
        hourlyRecords = generateHourlyData()
        generateAlerts()
    }
    
    // MARK: - Alerts
    private func generateAlerts() {
        var newAlerts: [DashboardAlert] = []
        for provider in providers {
            guard let usage = currentUsage[provider.id] else { continue }
            let pct = Double(usage.usedPercentage)
            if pct >= 95 {
                newAlerts.append(DashboardAlert(level: .exhausted, providerName: provider.name,
                    providerIcon: provider.icon, message: "配額已使用 \(usage.usedPercentage)%，即將耗盡！", timestamp: Date()))
            } else if pct >= 85 {
                newAlerts.append(DashboardAlert(level: .critical, providerName: provider.name,
                    providerIcon: provider.icon, message: "配額已使用 \(usage.usedPercentage)%，請注意用量", timestamp: Date()))
            } else if pct >= 75 {
                newAlerts.append(DashboardAlert(level: .warning, providerName: provider.name,
                    providerIcon: provider.icon, message: "配額已使用 \(usage.usedPercentage)%", timestamp: Date()))
            }
        }
        if totalBudget > 0 && totalCost / totalBudget > 0.85 {
            newAlerts.append(DashboardAlert(level: .warning, providerName: "總預算",
                providerIcon: "💰", message: "本月花費已達預算 \(Int(totalCost / totalBudget * 100))%", timestamp: Date()))
        }
        alerts = newAlerts
    }
    
    // MARK: - Config
    func saveConfig() { storageService.saveConfig(config) }
    func loadConfig() { if let saved = storageService.loadConfig() { config = saved } }
    
    func updateProviderConfig(_ providerConfig: ProviderConfig) {
        if let index = config.providers.firstIndex(where: { $0.providerId == providerConfig.providerId }) {
            config.providers[index] = providerConfig
            saveConfig()
        }
    }
    
    // MARK: - Auto Refresh
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: config.refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.refresh() }
        }
    }
    
    // MARK: - Data Generators
    private func generateDailyHistory(days: Int) -> [DailyUsageRecord] {
        var records: [DailyUsageRecord] = []
        let calendar = Calendar.current
        let now = Date()
        for provider in providers {
            for dayOffset in (0..<days).reversed() {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
                let weekday = calendar.component(.weekday, from: date)
                let mult: Double = (weekday == 1 || weekday == 7) ? 0.4 : 1.0
                let (baseUsage, baseCost): (Double, Double) = {
                    switch provider.id {
                    case "claude": return (12, 0.60)
                    case "chatgpt": return (8, 0.45)
                    case "gemini": return (5, 0.30)
                    case "manus": return (15, 1.50)
                    default: return (5, 0.20)
                    }
                }()
                records.append(DailyUsageRecord(date: date, providerId: provider.id,
                    usage: Int((baseUsage + .random(in: 0...baseUsage)) * mult),
                    cost: (baseCost + .random(in: 0...baseCost)) * mult))
            }
        }
        return records
    }
    
    private func generateHourlyData() -> [HourlyUsageRecord] {
        (0..<24).map { hour in
            let peak: Double = (9...18).contains(hour) ? 1.5 : (hour >= 22 || hour <= 6) ? 0.3 : 0.8
            return HourlyUsageRecord(hour: hour,
                requests: Int((5.0 + .random(in: 0...20)) * peak),
                tokens: Int((2000.0 + .random(in: 0...15000)) * peak))
        }
    }
}
