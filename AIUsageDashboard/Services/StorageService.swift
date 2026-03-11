//
//  StorageService.swift
//  AIUsageDashboard
//
//  Created by Michael Lin on 2026/3/11.
//  Copyright © 2026 MacroVision Systems. All rights reserved.
//

import Foundation
import Security

// MARK: - Storage Service

class StorageService {
    
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private enum Keys {
        static let config = "dashboard_config"
        static let usageHistory = "usage_history"
        static let lastSync = "last_sync_date"
    }
    
    // MARK: - Config Persistence
    
    func saveConfig(_ config: DashboardConfig) {
        do {
            let data = try encoder.encode(config)
            defaults.set(data, forKey: Keys.config)
        } catch {
            print("[StorageService] Failed to save config: \(error)")
        }
    }
    
    func loadConfig() -> DashboardConfig? {
        guard let data = defaults.data(forKey: Keys.config) else { return nil }
        do {
            return try decoder.decode(DashboardConfig.self, from: data)
        } catch {
            print("[StorageService] Failed to load config: \(error)")
            return nil
        }
    }
    
    // MARK: - Keychain (API Keys)
    
    private let service = "com.macrovision.AIUsageDashboard"
    
    func saveAPIKey(_ key: String, for providerId: String) throws {
        let data = key.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "apikey_\(providerId)",
            kSecValueData as String: data,
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw StorageError.keychainError(status) }
    }
    
    func loadAPIKey(for providerId: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "apikey_\(providerId)",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            if status == errSecItemNotFound { return nil }
            throw StorageError.keychainError(status)
        }
        return String(data: data, encoding: .utf8)
    }
    
    func deleteAPIKey(for providerId: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "apikey_\(providerId)",
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw StorageError.keychainError(status)
        }
    }
}

// MARK: - Storage Errors

enum StorageError: LocalizedError {
    case keychainError(OSStatus)
    case encodingError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .keychainError(let status): return "Keychain 錯誤: \(status)"
        case .encodingError(let e): return "編碼錯誤: \(e.localizedDescription)"
        case .decodingError(let e): return "解碼錯誤: \(e.localizedDescription)"
        }
    }
}
