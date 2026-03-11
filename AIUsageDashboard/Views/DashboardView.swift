//
//  DashboardView.swift
//  AIUsageDashboard
//
//  Created by Michael Lin on 2026/3/11.
//  Copyright © 2026 MacroVision Systems. All rights reserved.
//

import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @State private var expandedProvider: String?
    
    private var gridColumns: [GridItem] {
        #if os(macOS)
        [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        #else
        [GridItem(.flexible()), GridItem(.flexible())]
        #endif
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                alertBanner
                statsGrid
                providerSection
            }
            .padding()
        }
        .background(Color(platformBackground))
        .navigationTitle("AI Usage Dashboard")
        .refreshable { await viewModel.refresh() }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { Task { await viewModel.refresh() } } label: {
                    Label("重新整理", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
    }
    
    private var platformBackground: String {
        #if os(macOS)
        "windowBackgroundColor"
        #else
        "systemBackground"
        #endif
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("MacroVision Systems")
                    .font(.caption).foregroundStyle(.secondary)
                Text("即時 AI 用量監控")
                    .font(.headline)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.isLoading ? .orange : (viewModel.connectedProviderCount > 0 ? .green : .red))
                        .frame(width: 6, height: 6)
                    Text(viewModel.isLoading ? "更新中..." : "\(viewModel.connectedProviderCount)/\(viewModel.providers.count) 已連線")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Text(viewModel.lastRefreshDate, style: .time)
                    .font(.caption2.monospacedDigit()).foregroundStyle(.tertiary)
            }
        }
    }
    
    // MARK: - Alert Banner
    @ViewBuilder
    private var alertBanner: some View {
        if !viewModel.alerts.isEmpty {
            VStack(spacing: 8) {
                ForEach(viewModel.alerts) { alert in
                    HStack(spacing: 10) {
                        Image(systemName: alert.level >= .critical ? "exclamationmark.triangle.fill" : "bell.fill")
                            .foregroundStyle(alert.level.color).font(.caption)
                        Text("\(alert.providerIcon) **\(alert.providerName)** — \(alert.message)")
                            .font(.caption)
                        Spacer()
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(alert.level.color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(alert.level.color.opacity(0.2), lineWidth: 1))
                }
            }
        }
    }
    
    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            StatCardView(icon: "dollarsign.circle.fill", label: "本月花費",
                value: viewModel.totalCostFormatted,
                subtitle: "預算 $\(String(format: "%.0f", viewModel.totalBudget))",
                trendValue: "+12%", trendUp: true, accentColor: .green)
            StatCardView(icon: "bolt.fill", label: "今日請求",
                value: "\(viewModel.todayTotalRequests)", subtitle: "較昨日",
                trendValue: "+8%", trendUp: true, accentColor: .blue)
            StatCardView(icon: "link.circle.fill", label: "連線狀態",
                value: "\(viewModel.connectedProviderCount)/\(viewModel.providers.count)",
                subtitle: viewModel.connectedProviderCount == viewModel.providers.count ? "全部已連線" : "\(viewModel.providers.count - viewModel.connectedProviderCount) 個未連線",
                accentColor: viewModel.connectedProviderCount == viewModel.providers.count ? .green : .orange)
            StatCardView(icon: "bell.badge.fill", label: "警報",
                value: "\(viewModel.alerts.count)",
                subtitle: "\(viewModel.criticalAlertCount) 個嚴重",
                accentColor: viewModel.alerts.isEmpty ? .green : .orange)
        }
    }
    
    // MARK: - Provider Section
    private var providerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("各平台用量").font(.headline)
            ForEach(viewModel.providers) { provider in
                if let usage = viewModel.currentUsage[provider.id] {
                    let isConnected = viewModel.isProviderConnected(provider.id)
                    ProviderCardView(
                        provider: provider,
                        usage: usage,
                        isExpanded: expandedProvider == provider.id,
                        isConnected: isConnected
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            expandedProvider = expandedProvider == provider.id ? nil : provider.id
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Stat Card

struct StatCardView: View {
    let icon: String
    let label: String
    let value: String
    let subtitle: String
    var trendValue: String? = nil
    var trendUp: Bool = false
    var accentColor: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Image(systemName: icon).font(.caption).foregroundStyle(accentColor.opacity(0.7))
            }
            Text(value).font(.title2.monospacedDigit().bold())
            HStack {
                Text(subtitle).font(.caption2).foregroundStyle(.tertiary)
                Spacer()
                if let trend = trendValue {
                    HStack(spacing: 2) {
                        Image(systemName: trendUp ? "arrow.up.right" : "arrow.down.right").font(.caption2)
                        Text(trend).font(.caption2.bold())
                    }
                    .foregroundStyle(trendUp ? .red : .green)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accentColor.opacity(0.15), lineWidth: 1))
    }
}

#Preview {
    NavigationStack {
        DashboardView().environmentObject(DashboardViewModel())
    }
}
