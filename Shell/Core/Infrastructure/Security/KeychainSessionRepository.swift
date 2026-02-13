//
//  KeychainSessionRepository.swift
//  Shell
//
//  Created by Shell on 2026-02-12.
//

import Foundation
import Security

/// Secure implementation of SessionRepository using iOS Keychain Services
///
/// Security Features:
/// - Stores tokens in encrypted Keychain (not plain memory)
/// - Uses kSecAttrAccessibleWhenUnlockedThisDeviceOnly for maximum security
/// - Persists sessions across app launches
/// - Thread-safe with actor isolation
actor KeychainSessionRepository: SessionRepository {
    // MARK: - Properties

    private let service: String
    private let account: String

    // MARK: - Initialization

    init(service: String = "com.shell.app", account: String = "userSession") {
        self.service = service
        self.account = account
    }

    // MARK: - SessionRepository

    func getCurrentSession() async throws -> UserSession? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status != errSecItemNotFound else {
            // No session stored
            return nil
        }

        guard status == errSecSuccess else {
            throw SessionRepositoryError.keychainAccessFailed(status: status)
        }

        guard let data = result as? Data else {
            throw SessionRepositoryError.invalidSessionData
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(UserSession.self, from: data)
        } catch {
            throw SessionRepositoryError.decodingFailed(error)
        }
    }

    func saveSession(_ session: UserSession) async throws {
        // Encode session to Data
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let data: Data
        do {
            data = try encoder.encode(session)
        } catch {
            throw SessionRepositoryError.encodingFailed(error)
        }

        // Check if session already exists
        let existingSession = try? await getCurrentSession()

        if existingSession != nil {
            // Update existing session
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]

            let attributes: [String: Any] = [
                kSecValueData as String: data
            ]

            let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

            guard status == errSecSuccess else {
                throw SessionRepositoryError.keychainUpdateFailed(status: status)
            }
        } else {
            // Create new session
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]

            let status = SecItemAdd(query as CFDictionary, nil)

            guard status == errSecSuccess else {
                throw SessionRepositoryError.keychainAddFailed(status: status)
            }
        }
    }

    func clearSession() async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        // Success if deleted or item didn't exist
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SessionRepositoryError.keychainDeleteFailed(status: status)
        }
    }
}

// MARK: - Error Types

enum SessionRepositoryError: Error, LocalizedError {
    case keychainAccessFailed(status: OSStatus)
    case keychainAddFailed(status: OSStatus)
    case keychainUpdateFailed(status: OSStatus)
    case keychainDeleteFailed(status: OSStatus)
    case invalidSessionData
    case encodingFailed(Error)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .keychainAccessFailed(let status):
            return "Failed to access keychain (status: \(status))"
        case .keychainAddFailed(let status):
            return "Failed to add session to keychain (status: \(status))"
        case .keychainUpdateFailed(let status):
            return "Failed to update session in keychain (status: \(status))"
        case .keychainDeleteFailed(let status):
            return "Failed to delete session from keychain (status: \(status))"
        case .invalidSessionData:
            return "Invalid session data in keychain"
        case .encodingFailed(let error):
            return "Failed to encode session: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode session: \(error.localizedDescription)"
        }
    }
}
