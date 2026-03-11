//
//  APIService.swift
//  AIUsageDashboard
//
//  Created by Michael Lin on 2026/3/11.
//  Copyright © 2026 MacroVision Systems. All rights reserved.
//

import Foundation

// MARK: - API Service

actor APIService {
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.httpAdditionalHeaders = ["Content-Type": "application/json"]
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Unified Fetch
    
    func fetchUsage(for providerId: String, apiKey: String) async throws -> UsageSnapshot {
        switch providerId {
        case "claude": return try await fetchClaudeUsage(apiKey: apiKey)
        case "chatgpt": return try await fetchOpenAIUsage(apiKey: apiKey)
        case "gemini": return try await fetchGeminiUsage(apiKey: apiKey)
        case "manus": return try await fetchManusUsage(apiKey: apiKey)
        default: throw APIError.unsupportedProvider(providerId)
        }
    }
    
    // =========================================================================
    // MARK: - Claude (Anthropic Admin API)
    // =========================================================================
    //
    // Requires: Admin API Key (sk-ant-admin-...)
    // Get it: https://console.anthropic.com → Settings → Admin API Keys
    // Docs: https://platform.claude.com/docs/en/build-with-claude/usage-cost-api
    //
    // Two endpoints:
    //   1. Usage Report: GET /v1/organizations/usage_report/messages
    //      → Token counts by model, workspace, API key
    //   2. Cost Report: GET /v1/organizations/cost_report
    //      → USD cost breakdowns
    //
    // =========================================================================
    
    struct AnthropicUsageResponse: Decodable {
        let data: [AnthropicUsageBucket]?
        let hasMore: Bool?
        let nextPage: String?
        
        enum CodingKeys: String, CodingKey {
            case data
            case hasMore = "has_more"
            case nextPage = "next_page"
        }
    }
    
    struct AnthropicUsageBucket: Decodable {
        let inputTokens: Int?
        let outputTokens: Int?
        let cacheCreationInputTokens: Int?
        let cacheReadInputTokens: Int?
        let model: String?
        let snapshotAt: String?
        
        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
            case cacheCreationInputTokens = "cache_creation_input_tokens"
            case cacheReadInputTokens = "cache_read_input_tokens"
            case model
            case snapshotAt = "snapshot_at"
        }
    }
    
    struct AnthropicCostResponse: Decodable {
        let data: [AnthropicCostBucket]?
        
        struct AnthropicCostBucket: Decodable {
            let cost: String?  // Cost in cents as decimal string
            let description: String?
        }
    }
    
    private func fetchClaudeUsage(apiKey: String) async throws -> UsageSnapshot {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let startOfDay = calendar.startOfDay(for: now)
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        let startingAt = isoFormatter.string(from: startOfMonth)
        let endingAt = isoFormatter.string(from: now)
        let todayStart = isoFormatter.string(from: startOfDay)
        
        // --- 1. Fetch monthly usage (token counts) ---
        let usageURL = "https://api.anthropic.com/v1/organizations/usage_report/messages"
            + "?starting_at=\(startingAt)"
            + "&ending_at=\(endingAt)"
            + "&group_by[]=model"
            + "&bucket_width=1M"  // 1 month bucket
            + "&limit=100"
        
        var usageRequest = URLRequest(url: URL(string: usageURL)!)
        usageRequest.httpMethod = "GET"
        usageRequest.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        usageRequest.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let (usageData, usageResponse) = try await session.data(for: usageRequest)
        guard let usageHttp = usageResponse as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard usageHttp.statusCode == 200 else {
            // Parse error message if available
            if let errorJson = try? JSONSerialization.jsonObject(with: usageData) as? [String: Any],
               let errorMsg = errorJson["error"] as? [String: Any],
               let message = errorMsg["message"] as? String {
                throw APIError.apiMessage("Claude: \(message)")
            }
            throw APIError.httpError(usageHttp.statusCode)
        }
        
        let usageResult = try JSONDecoder().decode(AnthropicUsageResponse.self, from: usageData)
        
        // Sum all tokens across models
        var totalInput = 0
        var totalOutput = 0
        var totalCacheWrite = 0
        var totalCacheRead = 0
        
        for bucket in usageResult.data ?? [] {
            totalInput += bucket.inputTokens ?? 0
            totalOutput += bucket.outputTokens ?? 0
            totalCacheWrite += bucket.cacheCreationInputTokens ?? 0
            totalCacheRead += bucket.cacheReadInputTokens ?? 0
        }
        
        let totalTokens = totalInput + totalOutput + totalCacheWrite + totalCacheRead
        
        // --- 2. Fetch monthly cost ---
        let costURL = "https://api.anthropic.com/v1/organizations/cost_report"
            + "?starting_at=\(startingAt)"
            + "&ending_at=\(endingAt)"
            + "&bucket_width=1M"
            + "&limit=100"
        
        var costRequest = URLRequest(url: URL(string: costURL)!)
        costRequest.httpMethod = "GET"
        costRequest.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        costRequest.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        var totalCostCents: Double = 0
        if let (costData, costResponse) = try? await session.data(for: costRequest),
           let costHttp = costResponse as? HTTPURLResponse, costHttp.statusCode == 200,
           let costResult = try? JSONDecoder().decode(AnthropicCostResponse.self, from: costData) {
            for bucket in costResult.data ?? [] {
                if let costStr = bucket.cost, let cents = Double(costStr) {
                    totalCostCents += cents
                }
            }
        }
        let totalCostUSD = totalCostCents / 100.0
        
        // --- 3. Fetch today's usage ---
        let todayURL = "https://api.anthropic.com/v1/organizations/usage_report/messages"
            + "?starting_at=\(todayStart)"
            + "&ending_at=\(endingAt)"
            + "&bucket_width=1d"
            + "&limit=100"
        
        var todayRequest = URLRequest(url: URL(string: todayURL)!)
        todayRequest.httpMethod = "GET"
        todayRequest.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        todayRequest.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        var todayTokens = 0
        if let (todayData, todayResponse) = try? await session.data(for: todayRequest),
           let todayHttp = todayResponse as? HTTPURLResponse, todayHttp.statusCode == 200,
           let todayResult = try? JSONDecoder().decode(AnthropicUsageResponse.self, from: todayData) {
            for bucket in todayResult.data ?? [] {
                todayTokens += (bucket.inputTokens ?? 0) + (bucket.outputTokens ?? 0)
            }
        }
        
        // Calculate daily average
        let dayOfMonth = max(calendar.component(.day, from: now), 1)
        let avgDaily = totalTokens / dayOfMonth
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let daysLeft = daysInMonth - dayOfMonth
        
        return UsageSnapshot(
            providerId: "claude",
            planName: "Admin API",
            used: totalTokens,
            total: totalTokens + (avgDaily * daysLeft), // Projected monthly total
            unit: .tokens,
            cost: totalCostUSD,
            todayUsed: todayTokens,
            averageDaily: avgDaily,
            estimatedDaysLeft: daysLeft,
            lastUpdated: Date()
        )
    }
    
    // =========================================================================
    // MARK: - ChatGPT (OpenAI)
    // =========================================================================
    
    private func fetchOpenAIUsage(apiKey: String) async throws -> UsageSnapshot {
        let calendar = Calendar.current
        let today = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        
        let urlStr = "https://api.openai.com/v1/usage?start_date=\(fmt.string(from: startOfMonth))&end_date=\(fmt.string(from: today))"
        var request = URLRequest(url: URL(string: urlStr)!)
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let totalTokens = (json?["total_usage"] as? Double) ?? 0
        
        let dayOfMonth = max(calendar.component(.day, from: today), 1)
        let daysInMonth = calendar.range(of: .day, in: .month, for: today)?.count ?? 30
        
        return UsageSnapshot(
            providerId: "chatgpt", planName: "API",
            used: Int(totalTokens / 1000), total: 2_000_000, unit: .tokens,
            cost: totalTokens * 0.000005,
            todayUsed: 0, averageDaily: Int(totalTokens / 1000) / dayOfMonth,
            estimatedDaysLeft: daysInMonth - dayOfMonth, lastUpdated: Date()
        )
    }
    
    // MARK: - Gemini (Google)
    
    private func fetchGeminiUsage(apiKey: String) async throws -> UsageSnapshot {
        // Google AI Studio does not yet provide a public usage/billing API
        // Workaround: use Google Cloud Billing API if using Vertex AI
        return UsageSnapshot(
            providerId: "gemini", planName: "API",
            used: 0, total: 120, unit: .messages, cost: 0,
            todayUsed: 0, averageDaily: 0, estimatedDaysLeft: 30, lastUpdated: Date()
        )
    }
    
    // MARK: - Manus
    
    private func fetchManusUsage(apiKey: String) async throws -> UsageSnapshot {
        // Manus does not yet provide a public usage API
        return UsageSnapshot(
            providerId: "manus", planName: "Credits",
            used: 0, total: 500, unit: .credits, cost: 0,
            todayUsed: 0, averageDaily: 0, estimatedDaysLeft: 30, lastUpdated: Date()
        )
    }
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case unsupportedProvider(String)
    case httpError(Int)
    case invalidResponse
    case decodingError(Error)
    case networkError(Error)
    case apiMessage(String)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedProvider(let id): return "不支援的平台: \(id)"
        case .httpError(let code): return "HTTP 錯誤: \(code)"
        case .invalidResponse: return "無效的回應"
        case .decodingError(let e): return "解析錯誤: \(e.localizedDescription)"
        case .networkError(let e): return "網路錯誤: \(e.localizedDescription)"
        case .apiMessage(let msg): return msg
        }
    }
}
