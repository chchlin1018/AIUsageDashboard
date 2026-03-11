//
//  UsageChartView.swift
//  AIUsageDashboard
//
//  Created by Michael Lin on 2026/3/11.
//  Copyright © 2026 MacroVision Systems. All rights reserved.
//

import SwiftUI
import Charts

struct UsageChartView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @State private var selectedChart: ChartType = .dailyTrend
    
    enum ChartType: String, CaseIterable {
        case dailyTrend = "30日趨勢"
        case costBreakdown = "花費比例"
        case hourlyActivity = "每小時活動"
        case providerComparison = "平台比較"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("圖表類型", selection: $selectedChart) {
                    ForEach(ChartType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented).padding(.horizontal)
                
                Group {
                    switch selectedChart {
                    case .dailyTrend: dailyTrendChart
                    case .costBreakdown: costBreakdownChart
                    case .hourlyActivity: hourlyActivityChart
                    case .providerComparison: providerComparisonChart
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("趨勢分析")
    }
    
    // MARK: - 30 Day Trend
    private var dailyTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("30 日用量趨勢").font(.headline)
            Chart(viewModel.dailyRecords) { record in
                LineMark(x: .value("日期", record.date, unit: .day), y: .value("用量", record.usage))
                    .foregroundStyle(by: .value("平台", record.providerId))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
            .chartForegroundStyleScale([
                "claude": Color(hex: "#D4A574"), "chatgpt": Color(hex: "#10A37F"),
                "gemini": Color(hex: "#4285F4"), "manus": Color(hex: "#A855F7"),
            ])
            .chartLegend(position: .bottom)
            .chartYAxisLabel("使用量")
            .frame(height: 280)
        }
    }
    
    // MARK: - Cost Breakdown
    private var costBreakdownChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("花費比例").font(.headline)
            Chart(viewModel.costBreakdown, id: \.providerId) { item in
                SectorMark(angle: .value("花費", item.cost), innerRadius: .ratio(0.6), angularInset: 2)
                    .foregroundStyle(Color(hex: item.colorHex))
                    .annotation(position: .overlay) {
                        VStack(spacing: 2) {
                            Text(item.providerName).font(.caption2.bold())
                            Text(String(format: "$%.1f", item.cost)).font(.caption2.monospacedDigit())
                        }.foregroundStyle(.white)
                    }
            }
            .frame(height: 280)
            
            HStack(spacing: 16) {
                ForEach(viewModel.costBreakdown, id: \.providerId) { item in
                    HStack(spacing: 6) {
                        Circle().fill(Color(hex: item.colorHex)).frame(width: 8, height: 8)
                        Text(item.providerName).font(.caption).foregroundStyle(.secondary)
                        Text(String(format: "$%.2f", item.cost)).font(.caption.monospacedDigit().bold())
                    }
                }
            }
        }
    }
    
    // MARK: - Hourly Activity
    private var hourlyActivityChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日每小時請求量").font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(.green).frame(width: 6, height: 6)
                    Text("LIVE").font(.caption2.bold()).foregroundStyle(.green)
                }
            }
            Chart(viewModel.hourlyRecords) { record in
                BarMark(x: .value("小時", record.hourLabel), y: .value("請求", record.requests))
                    .foregroundStyle(LinearGradient(colors: [.green.opacity(0.5), .green], startPoint: .bottom, endPoint: .top))
                    .cornerRadius(3)
            }
            .chartXAxisLabel("時間").chartYAxisLabel("請求數")
            .frame(height: 280)
        }
    }
    
    // MARK: - Provider Comparison
    private var providerComparisonChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("平台使用量排名").font(.headline)
            let data = viewModel.providers.compactMap { p -> (String, Int, Color)? in
                guard let u = viewModel.currentUsage[p.id] else { return nil }
                return (p.name, u.used, p.color)
            }
            Chart(data, id: \.0) { item in
                BarMark(x: .value("使用量", item.1), y: .value("平台", item.0))
                    .foregroundStyle(item.2)
                    .annotation(position: .trailing) {
                        Text("\(item.1)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    }
            }
            .chartXAxisLabel("使用量").frame(height: 220)
        }
    }
}

#Preview {
    NavigationStack { UsageChartView().environmentObject(DashboardViewModel()) }
}
