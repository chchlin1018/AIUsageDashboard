//
//  AIUsageDashboardApp.swift
//  AIUsageDashboard
//
//  Created by Michael Lin on 2026/3/11.
//  Copyright © 2026 MacroVision Systems. All rights reserved.
//

import SwiftUI

@main
struct AIUsageDashboardApp: App {
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
            #if os(macOS)
                .frame(minWidth: 900, minHeight: 600)
            #endif
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        .defaultSize(width: 1100, height: 750)
        
        // macOS Menu Bar Extra (optional widget)
        MenuBarExtra("AI Usage", systemImage: "cpu.fill") {
            MenuBarView()
                .environmentObject(viewModel)
        }
        .menuBarExtraStyle(.window)
        #endif
    }
}

// MARK: - macOS Menu Bar Widget
#if os(macOS)
struct MenuBarView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Usage Overview")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(viewModel.providers) { provider in
                if let usage = viewModel.currentUsage[provider.id] {
                    HStack {
                        Text(provider.icon)
                        Text(provider.name)
                            .font(.caption)
                        Spacer()
                        Text("\(usage.usedPercentage)%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(usage.alertLevel.color)
                    }
                }
            }
            
            Divider()
            
            HStack {
                Text("本月花費")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(viewModel.totalCostFormatted)
                    .font(.caption.monospacedDigit().bold())
            }
            
            Divider()
            
            Button("開啟 Dashboard") {
                NSApplication.shared.activate(ignoringOtherApps: true)
                if let window = NSApplication.shared.windows.first {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            
            Button("結束") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 240)
    }
}
#endif
