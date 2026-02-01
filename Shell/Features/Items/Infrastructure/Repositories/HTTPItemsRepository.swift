//
//  HTTPItemsRepository.swift
//  Shell
//
//  Created by Shell on 2026-02-01.
//

import Foundation

/// HTTP-based implementation of ItemsRepository
/// Communicates with the backend Items API
actor HTTPItemsRepository: ItemsRepository {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    // MARK: - ItemsRepository

    func fetchAll() async throws -> [Item] {
        let endpoint = HTTPEndpoint(
            path: "/items",
            method: .get
        )

        do {
            let dtos = try await httpClient.request(endpoint, responseType: [ItemDTO].self)
            return dtos.map { $0.toDomain() }
        } catch let error as HTTPError {
            throw mapHTTPError(error, operation: .fetch)
        } catch {
            throw ItemError.createFailed
        }
    }

    func create(_ item: Item) async throws -> Item {
        let requestDTO = ItemRequestDTO.fromDomain(item)

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        let body = try encoder.encode(requestDTO)

        let endpoint = HTTPEndpoint(
            path: "/items",
            method: .post,
            body: body
        )

        do {
            let dto = try await httpClient.request(endpoint, responseType: ItemDTO.self)
            return dto.toDomain()
        } catch let error as HTTPError {
            throw mapHTTPError(error, operation: .create)
        } catch {
            throw ItemError.createFailed
        }
    }

    func update(_ item: Item) async throws -> Item {
        let requestDTO = ItemRequestDTO.fromDomain(item)

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        let body = try encoder.encode(requestDTO)

        let endpoint = HTTPEndpoint(
            path: "/items/\(item.id)",
            method: .put,
            body: body
        )

        do {
            let dto = try await httpClient.request(endpoint, responseType: ItemDTO.self)
            return dto.toDomain()
        } catch let error as HTTPError {
            throw mapHTTPError(error, operation: .update)
        } catch {
            throw ItemError.updateFailed
        }
    }

    func delete(id: String) async throws {
        let endpoint = HTTPEndpoint(
            path: "/items/\(id)",
            method: .delete
        )

        do {
            try await httpClient.request(endpoint)
        } catch let error as HTTPError {
            throw mapHTTPError(error, operation: .delete)
        } catch {
            throw ItemError.deleteFailed
        }
    }

    // MARK: - Error Mapping

    private enum Operation {
        case fetch, create, update, delete
    }

    private func mapHTTPError(_ error: HTTPError, operation: Operation) -> ItemError {
        switch error {
        case .httpError(let statusCode, _):
            switch statusCode {
            case 400:
                return .validationFailed("Invalid request")
            case 404:
                return .notFound
            case 500...599:
                switch operation {
                case .fetch:
                    return .createFailed // Generic failure for fetch
                case .create:
                    return .createFailed
                case .update:
                    return .updateFailed
                case .delete:
                    return .deleteFailed
                }
            default:
                switch operation {
                case .fetch:
                    return .createFailed
                case .create:
                    return .createFailed
                case .update:
                    return .updateFailed
                case .delete:
                    return .deleteFailed
                }
            }
        case .decodingError, .invalidResponse, .networkError:
            switch operation {
            case .fetch:
                return .createFailed
            case .create:
                return .createFailed
            case .update:
                return .updateFailed
            case .delete:
                return .deleteFailed
            }
        }
    }
}
