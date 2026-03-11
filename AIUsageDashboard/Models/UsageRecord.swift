//
//  UsageRecord.swift
//  AIUsageDashboard
//
//  Created by Michael Lin on 2026/3/11.
//  Copyright © 2026 MacroVision Systems. All rights reserved.
//

import Foundation

// MARK: - Current Usage Snapshot

struct UsageSnapshot: Identifiable {
    var id: String { providerId }
    let providerId: String
    let planName: String
    let used: Int
    let total: Int
    let unit: UsageUnit
    let cost: Double
    let todayUsed: Int
    let averageDaily: Int
    let estimatedDaysLeft: Int
    let lastUpdated: Date
    
    var usedPercentage: Int {
        guard total > 0 else { return 0 }
        return min(Int(Double(used) / Double(total) * 100), 100)
    }
    
    var usedFraction: Double {
        guard total > 0 else { return 0 }
        return min(Double(used) / Double(total), 1.0)
    }
    
    var alertLevel: AlertLevel {
        AlertLevel.from(percentage: Double(usedPercentage))
    }
    
    var remaining: Int { max(total - used, 0) }
}

// MARK: - Daily Usage Record

struct DailyUsageRecord: Identifiable {
    let id = UUID()
    let date: Date
    let providerId: String
    let usage: Int
    let cost: Double
    
    var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

// MARK: - Hourly Usage Record

struct HourlyUsageRecord: Identifiable {
    let id = UUID()
    let hour: Int
    let requests: Int
    let tokens: Int
    
    var hourLabel: String {
        String(format: "%02d:00", hour)
    }
}

// MARK: - Dashboard Alert

struct DashboardAlert: Identifiable {
    let id = UUID()
    let level: AlertLevel
    let providerName: String
    let providerIcon: String
    let message: String
    let timestamp: Date
    var isRead: Bool = false
    
    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 { return "剛剛" }
        if interval < 3600 { return "\(Int(interval / 60)) 分鐘前" }
        if interval < 86400 { return "\(Int(interval / 3600)) 小時前" }
        return "\(Int(interval / 86400)) 天前"
    }
}

// MARK: - Chart Data Point

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let category: String
}

// MARK: - Cost Summary

struct CostSummary {
    let providerId: String
    let providerName: String
    let cost: Double
    let colorHex: String
    let percentage: Double
}
