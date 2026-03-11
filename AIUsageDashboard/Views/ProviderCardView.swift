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
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                HStack(spacing: 10) {
                    Text(provider.icon).font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(provider.name).font(.subheadline.bold())
                        Text(usage.planName).font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                .frame(width: 120, alignment: .leading)
                
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
                
                Circle().fill(usage.alertLevel.color).frame(width: 8, height: 8)
                    .shadow(color: usage.alertLevel.color.opacity(0.5), radius: 4)
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            
            if isExpanded {
                Divider().padding(.horizontal)
                HStack(spacing: 12) {
                    detailTile(title: "今日使用", value: "\(usage.todayUsed) \(usage.unit.rawValue)")
                    detailTile(title: "日均使用", value: "\(usage.averageDaily) \(usage.unit.rawValue)")
                    detailTile(title: "預估耗盡", value: "\(usage.estimatedDaysLeft) 天",
                             highlight: usage.estimatedDaysLeft < 5)
                }
                .padding()
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(provider.color.opacity(0.15), lineWidth: 1))
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
