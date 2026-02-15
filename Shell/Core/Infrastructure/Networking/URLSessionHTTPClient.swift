//
//  URLSessionHTTPClient.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation
import CryptoKit

/// URLSession-based implementation of HTTPClient with certificate pinning
///
/// Security Features:
/// - Public key pinning for production API endpoints
/// - TLS certificate validation
/// - Protection against MITM attacks
final class URLSessionHTTPClient: NSObject, HTTPClient {
    private var session: URLSession?
    private let pinnedDomains: Set<String>
    private let trustedPublicKeyHashes: Set<String>

    /// Safe accessor for session (guaranteed non-nil after init)
    private var urlSession: URLSession {
        guard let session = session else {
            preconditionFailure("URLSession accessed before initialization")
        }
        return session
    }

    /// Initialize with optional certificate pinning configuration
    /// - Parameters:
    ///   - pinnedDomains: Domains to apply certificate pinning (e.g., ["api.shell.app"])
    ///   - publicKeyHashes: Base64-encoded SHA256 hashes of trusted public keys
    ///   - configuration: Optional URLSessionConfiguration (for testing)
    init(
        pinnedDomains: Set<String> = [],
        publicKeyHashes: Set<String> = [],
        configuration: URLSessionConfiguration? = nil
    ) {
        self.pinnedDomains = pinnedDomains
        self.trustedPublicKeyHashes = publicKeyHashes

        super.init()

        // Create ephemeral session configuration to prevent caching sensitive data
        let sessionConfig = configuration ?? {
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 60
            return config
        }()

        // Create session with self as delegate for certificate validation
        // (must be after super.init() to pass self as delegate)
        self.session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
    }

    func perform(_ request: HTTPRequest) async throws -> HTTPResponse {
        // Create URLRequest
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body

        // Add headers
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        // Perform request
        do {
            let (data, response) = try await urlSession.data(for: urlRequest)

            // Validate response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HTTPClientError.invalidResponse
            }

            // Extract headers
            var headers: [String: String] = [:]
            for (key, value) in httpResponse.allHeaderFields {
                if let keyString = key as? String, let valueString = value as? String {
                    headers[keyString] = valueString
                }
            }

            // Check for HTTP errors
            if !(200...299).contains(httpResponse.statusCode) {
                throw HTTPClientError.httpError(statusCode: httpResponse.statusCode, data: data)
            }

            return HTTPResponse(
                statusCode: httpResponse.statusCode,
                data: data,
                headers: headers
            )
        } catch let error as HTTPClientError {
            throw error
        } catch {
            throw HTTPClientError.networkError(error)
        }
    }
}

// MARK: - URLSessionDelegate (Certificate Pinning)

extension URLSessionHTTPClient: URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Only handle server trust challenges
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host

        // If this domain is not pinned, use default validation
        guard pinnedDomains.contains(host) else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // If no public key hashes configured, reject (fail-secure)
        guard !trustedPublicKeyHashes.isEmpty else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Validate certificate chain (iOS 13+)
        var error: CFError?
        guard SecTrustEvaluateWithError(serverTrust, &error) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Extract public key from server certificate
        guard let serverPublicKey = SecTrustCopyKey(serverTrust) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Get public key data and hash it
        guard let serverPublicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil) as Data? else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let serverKeyHash = sha256(data: serverPublicKeyData)
        let serverKeyHashBase64 = serverKeyHash.base64EncodedString()

        // Check if server's public key hash matches any trusted hash
        if trustedPublicKeyHashes.contains(serverKeyHashBase64) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            // Public key mismatch - potential MITM attack
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    /// Compute SHA256 hash of data using CryptoKit
    private func sha256(data: Data) -> Data {
        let hash = SHA256.hash(data: data)
        return Data(hash)
    }
}
