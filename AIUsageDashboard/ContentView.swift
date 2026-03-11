//
//  ContentView.swift
//  AIUsageDashboard
//
//  Created by Michael Lin on 2026/3/11.
//  Copyright © 2026 MacroVision Systems. All rights reserved.
//

import SwiftUI

enum NavigationTab: String, CaseIterable, Identifiable {
    case dashboard = "總覽"
    case trends = "趨勢"
    case alerts = "警報"
    case settings = "設定"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .trends: return "chart.xyaxis.line"
        case .alerts: return "bell.badge.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @State private var selectedTab: NavigationTab = .dashboard
    
    var body: some View {
        #if os(macOS)
        macOSLayout
        #else
        iOSLayout
        #endif
    }
    
    // MARK: - macOS Sidebar Layout
    #if os(macOS)
    private var macOSLayout: some View {
        NavigationSplitView {
            List(NavigationTab.allCases, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
            .listStyle(.sidebar)
        } detail: {
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    #endif
    
    // MARK: - iOS TabView Layout
    #if os(iOS)
    private var iOSLayout: some View {
        TabView(selection: $selectedTab) {
            ForEach(NavigationTab.allCases) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
    }
    
    @ViewBuilder
    private func tabContent(for tab: NavigationTab) -> some View {
        switch tab {
        case .dashboard:
            NavigationStack { DashboardView() }
        case .trends:
            NavigationStack { UsageChartView() }
        case .alerts:
            NavigationStack { AlertsView() }
        case .settings:
            NavigationStack { SettingsView() }
        }
    }
    #endif
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .dashboard:
            DashboardView()
        case .trends:
            UsageChartView()
        case .alerts:
            AlertsView()
        case .settings:
            SettingsView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DashboardViewModel())
}
