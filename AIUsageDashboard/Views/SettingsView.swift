//
//  SettingsView.swift
//  AIUsageDashboard
//
//  Created by Michael Lin on 2026/3/11.
//  Copyright © 2026 MacroVision Systems. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @State private var showingAPIKeyInput = false
    @State private var selectedProvider: String?
    @State private var apiKeyInput = ""
    
    var body: some View {
        Form {
            Section("AI 平台設定") {
                ForEach(viewModel.providers) { provider in
                    if let idx = viewModel.config.providers.firstIndex(where: { $0.providerId == provider.id }) {
                        ProviderSettingsRow(
                            provider: provider,
                            config: $viewModel.config.providers[idx],
                            onAPIKeyTap: {
                                selectedProvider = provider.id
                                apiKeyInput = viewModel.config.providers[idx].apiKey ?? ""
                                showingAPIKeyInput = true
                            }
                        )
                    }
                }
            }
            
            Section("一般設定") {
                HStack {
                    Label("自動重新整理", systemImage: "arrow.clockwise")
                    Spacer()
                    Picker("", selection: $viewModel.config.refreshInterval) {
                        Text("1 分鐘").tag(TimeInterval(60))
                        Text("5 分鐘").tag(TimeInterval(300))
                        Text("15 分鐘").tag(TimeInterval(900))
                        Text("30 分鐘").tag(TimeInterval(1800))
                    }
                    .labelsHidden()
                    #if os(macOS)
                    .frame(width: 120)
                    #endif
                }
                Toggle(isOn: $viewModel.config.enableNotifications) {
                    Label("推播通知", systemImage: "bell.badge")
                }
            }
            
            Section("資料管理") {
                Button { viewModel.loadSimulatedData() } label: { Label("重置為模擬資料", systemImage: "arrow.counterclockwise") }
                Button { Task { await viewModel.refresh() } } label: { Label("立即同步", systemImage: "arrow.triangle.2.circlepath") }
            }
            
            Section("關於") {
                LabeledContent("版本", value: "1.0.0")
                LabeledContent("開發者", value: "MacroVision Systems")
                Link(destination: URL(string: "https://github.com/chchlin1018/AIUsageDashboard")!) {
                    Label("GitHub 專案", systemImage: "link")
                }
            }
        }
        .navigationTitle("設定")
        .onChange(of: viewModel.config) { _, _ in viewModel.saveConfig() }
        .alert("設定 API Key", isPresented: $showingAPIKeyInput) {
            SecureField("API Key", text: $apiKeyInput)
            Button("儲存") {
                if let id = selectedProvider,
                   let idx = viewModel.config.providers.firstIndex(where: { $0.providerId == id }) {
                    viewModel.config.providers[idx].apiKey = apiKeyInput.isEmpty ? nil : apiKeyInput
                    viewModel.saveConfig()
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("輸入 \(selectedProvider ?? "") 的 API Key 以啟用即時資料。")
        }
    }
}

struct ProviderSettingsRow: View {
    let provider: AIProvider
    @Binding var config: ProviderConfig
    let onAPIKeyTap: () -> Void
    
    var body: some View {
        DisclosureGroup {
            VStack(spacing: 12) {
                HStack {
                    Text("月配額").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    TextField("配額", value: $config.monthlyQuota, format: .number)
                        .textFieldStyle(.roundedBorder)
                        #if os(macOS)
                        .frame(width: 100)
                        #else
                        .frame(width: 80).keyboardType(.numberPad)
                        #endif
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("月預算 (USD)").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    TextField("預算", value: $config.monthlyBudget, format: .currency(code: "USD"))
                        .textFieldStyle(.roundedBorder)
                        #if os(macOS)
                        .frame(width: 100)
                        #else
                        .frame(width: 80).keyboardType(.decimalPad)
                        #endif
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("警報閾值").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(config.alertThreshold * 100))%").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
                Slider(value: $config.alertThreshold, in: 0.5...0.95, step: 0.05)
                Button(action: onAPIKeyTap) {
                    HStack {
                        Image(systemName: config.apiKey != nil ? "key.fill" : "key")
                        Text(config.apiKey != nil ? "已設定 API Key" : "設定 API Key").font(.caption)
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption2)
                    }
                    .foregroundStyle(config.apiKey != nil ? .green : .secondary)
                }
                Toggle("啟用監控", isOn: $config.isEnabled).font(.caption)
            }
            .padding(.vertical, 4)
        } label: {
            HStack(spacing: 10) {
                Text(provider.icon)
                Text(provider.name).font(.subheadline.bold())
                Spacer()
                if config.isEnabled { Circle().fill(.green).frame(width: 6, height: 6) }
            }
        }
    }
}

#Preview {
    NavigationStack { SettingsView().environmentObject(DashboardViewModel()) }
}
