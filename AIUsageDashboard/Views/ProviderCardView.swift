//
//  ProviderCardView.swift
//  AIUsageDashboard
//
//  Created by Michael Lin on 2026/3/11.
//  Copyright © 2026 MacroVision Systems. All rights reserved.
//

import SwiftUI

struct ProviderCardView: View {
    let provider: AIProvider
    let usage: UsageSnapshot
    let isExpanded: Bool
    let isConnected: Bool
    
    private var statusColor: Color { isConnected ? .green : .red }
    private var statusLabel: String { isConnected ? "已連線" : "未連線" }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                HStack(spacing: 10) {
                    Text(provider.icon).font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(provider.name).font(.subheadline.bold())
                        HStack(spacing: 4) {
                            Circle().fill(statusColor).frame(width: 6, height: 6)
                            Text(isConnected ? usage.planName : "未設定 API Key")
                                .font(.caption2)
                                .foregroundStyle(isConnected ? .tertiary : .red.opacity(0.8))
                        }
                    }
                }
                .frame(width: 140, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(usage.used) / \(usage.total) \(usage.unit.rawValue)")
                            .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                        Spacer()
                        Text("\(usage.usedPercentage)%")
                            .font(.caption.monospacedDigit().bold())
                            .foregroundStyle(usage.alertLevel.color)
                    }
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(.quaternary).frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(LinearGradient(colors: progressColors, startPoint: .leading, endPoint: .trailing))
                                .frame(width: geometry.size.width * usage.usedFraction, height: 6)
                                .animation(.easeInOut(duration: 0.6), value: usage.usedFraction)
                        }
                    }
                    .frame(height: 6)
                }
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "$%.2f", usage.cost)).font(.subheadline.monospacedDigit().bold())
                    Text("本月花費").font(.caption2).foregroundStyle(.tertiary)
                }
                .frame(width: 80)
                
                // Connection status dot (green = connected, red = not connected)
                VStack(spacing: 2) {
                    Circle().fill(statusColor).frame(width: 10, height: 10)
                        .shadow(color: statusColor.opacity(0.6), radius: 4)
                    Text(statusLabel)
                        .font(.system(size: 8))
                        .foregroundStyle(statusColor)
                }
                .frame(width: 36)
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            
            if isExpanded {
                Divider().padding(.horizontal)
                
                if isConnected {
                    HStack(spacing: 12) {
                        detailTile(title: "今日使用", value: "\(usage.todayUsed) \(usage.unit.rawValue)")
                        detailTile(title: "日均使用", value: "\(usage.averageDaily) \(usage.unit.rawValue)")
                        detailTile(title: "預估耗盡", value: "\(usage.estimatedDaysLeft) 天",
                                 highlight: usage.estimatedDaysLeft < 5)
                    }
                    .padding()
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                        Text("請至設定頁面設定 API Key 以啟用即時數據")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isConnected ? provider.color.opacity(0.15) : Color.red.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var progressColors: [Color] {
        switch usage.alertLevel {
        case .exhausted: return [.orange, .red]
        case .critical: return [.yellow, .orange]
        case .warning: return [provider.color.opacity(0.7), .yellow]
        case .normal: return [provider.color.opacity(0.5), provider.color]
        }
    }
    
    private func detailTile(title: String, value: String, highlight: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption2).foregroundStyle(.tertiary)
            Text(value).font(.caption.monospacedDigit().bold()).foregroundStyle(highlight ? .red : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.background.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
