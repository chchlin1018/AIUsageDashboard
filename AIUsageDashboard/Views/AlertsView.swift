//
//  AlertsView.swift
//  AIUsageDashboard
//
//  Created by Michael Lin on 2026/3/11.
//  Copyright © 2026 MacroVision Systems. All rights reserved.
//

import SwiftUI

struct AlertsView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        List {
            if viewModel.alerts.isEmpty {
                ContentUnavailableView {
                    Label("沒有警報", systemImage: "checkmark.circle.fill")
                } description: {
                    Text("所有 AI 平台運作正常，配額使用量在安全範圍內。")
                }
            } else {
                Section {
                    ForEach(viewModel.alerts) { alert in
                        AlertRow(alert: alert)
                    }
                } header: {
                    Text("目前警報 (\(viewModel.alerts.count))")
                } footer: {
                    Text("當配額使用超過 75% 時會觸發警報，可在設定中調整閾值。")
                }
                
                Section("快速操作") {
                    Button { } label: { Label("調整配額設定", systemImage: "slider.horizontal.3") }
                    Button { Task { await viewModel.refresh() } } label: { Label("重新檢查", systemImage: "arrow.clockwise") }
                }
            }
        }
        .navigationTitle("警報中心")
        .refreshable { await viewModel.refresh() }
    }
}

struct AlertRow: View {
    let alert: DashboardAlert
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2).fill(alert.level.color).frame(width: 4, height: 40)
            Text(alert.providerIcon).font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alert.providerName).font(.subheadline.bold())
                    Text(alert.level.label).font(.caption2.bold())
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(alert.level.color.opacity(0.15))
                        .foregroundStyle(alert.level.color)
                        .clipShape(Capsule())
                }
                Text(alert.message).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(alert.timeAgo).font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack { AlertsView().environmentObject(DashboardViewModel()) }
}
