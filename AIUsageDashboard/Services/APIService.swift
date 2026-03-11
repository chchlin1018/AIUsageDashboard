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
    
    // MARK: - Claude (Anthropic)
    
    private func fetchClaudeUsage(apiKey: String) async throws -> UsageSnapshot {
        // Anthropic Admin API: GET /v1/organizations/{org_id}/usage
        // Requires admin API key with organization access
        // Docs: https://docs.anthropic.com/en/docs/administration/admin-api
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages/count_tokens")!)
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        // TODO: Implement actual usage endpoint when available
        return UsageSnapshot(
            providerId: "claude", planName: "API",
            used: 0, total: 100, unit: .messages, cost: 0,
            todayUsed: 0, averageDaily: 0, estimatedDaysLeft: 30, lastUpdated: Date()
        )
    }
    
    // MARK: - ChatGPT (OpenAI)
    
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
        
        return UsageSnapshot(
            providerId: "chatgpt", planName: "API",
            used: Int(totalTokens / 1000), total: 2_000_000, unit: .tokens,
            cost: totalTokens * 0.000005,
            todayUsed: 0, averageDaily: 0, estimatedDaysLeft: 30, lastUpdated: Date()
        )
    }
    
    // MARK: - Gemini (Google)
    
    private func fetchGeminiUsage(apiKey: String) async throws -> UsageSnapshot {
        // TODO: Implement Google AI Studio usage API
        return UsageSnapshot(
            providerId: "gemini", planName: "API",
            used: 0, total: 120, unit: .messages, cost: 0,
            todayUsed: 0, averageDaily: 0, estimatedDaysLeft: 30, lastUpdated: Date()
        )
    }
    
    // MARK: - Manus
    
    private func fetchManusUsage(apiKey: String) async throws -> UsageSnapshot {
        // TODO: Implement Manus usage API
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
    
    var errorDescription: String? {
        switch self {
        case .unsupportedProvider(let id): return "不支援的平台: \(id)"
        case .httpError(let code): return "HTTP 錯誤: \(code)"
        case .invalidResponse: return "無效的回應"
        case .decodingError(let e): return "解析錯誤: \(e.localizedDescription)"
        case .networkError(let e): return "網路錯誤: \(e.localizedDescription)"
        }
    }
}
