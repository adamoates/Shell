---
name: http-repo
description: Standardize how HTTP-based repositories are implemented and tested in Shell (e.g., HTTPItemsRepository, HTTPUserProfileRepository). Use when creating new HTTP repositories or during Epic 3 API integration.
argument-hint: [feature-name]
---

# HTTP Repository Skill

Standardize how HTTP-based repositories are implemented and tested in Shell
(e.g., `HTTPItemsRepository`, `HTTPUserProfileRepository`).

## When to use

- When creating a new HTTP repository.
- When refactoring network code into repository implementations.
- During Epic 3 (API integration) and beyond.

## Design principles

- Repositories:
  - Implement existing repository protocols from Domain/Contracts.
  - Use a shared `HTTPClient` abstraction (e.g., based on `URLSession`).
  - Map raw JSON to domain models via dedicated mappers/adapters.
  - Handle error mapping (status codes → domain errors) consistently.

## Steps

1. Ask the user which repository to create or update:

   - Examples: "Items", "UserProfile", "Auth".

2. Identify or create the protocol in Domain:

   - Locate `Shell/Features/<Feature>/Domain/Contracts/*Repository.swift`.
   - If missing, define a protocol with async methods aligned to domain needs.

3. Create the HTTP repository file:

   - Path: `Shell/Features/<Feature>/Infrastructure/Repositories/HTTP<Feature>Repository.swift`

   - Structure:

     ```swift
     actor HTTP<Feature>Repository: <Feature>Repository {
         private let httpClient: HTTPClient
         private let baseURL: URL

         init(httpClient: HTTPClient, baseURL: URL) {
             self.httpClient = httpClient
             self.baseURL = baseURL
         }

         // Implement protocol methods: fetch, create, update, delete, etc.
     }
     ```

4. Define DTOs and mappers:

   - Create a `DTOs` or `RemoteModels` namespace/file if appropriate.
   - Map between JSON and domain types using small, pure mappers.
   - Keep mapping logic out of ViewModels and controllers.

5. Implement error handling:

   - Map HTTP status codes and network failures to domain-specific errors.
   - Example mapping:
     - 400 → `.invalidRequest`
     - 401/403 → `.unauthorized`
     - 404 → `.notFound`
     - 500+ or connectivity issues → `.serverError` / `.networkError(underlying:)`

6. Wire repository into `AppDependencyContainer`:

   - Add configuration to select between in-memory and HTTP repos.
   - Example:

     ```swift
     if environment.useHTTPItems {
         itemsRepository = HTTPItemsRepository(httpClient: httpClient, baseURL: baseURL)
     } else {
         itemsRepository = InMemoryItemsRepository()
     }
     ```

7. Generate tests using `URLProtocol` stubs:

   - Path: `ShellTests/Features/<Feature>/Infrastructure/Repositories/HTTP<Feature>RepositoryTests.swift`
   - Use a custom `URLProtocol` subclass to:
     - Intercept requests.
     - Provide canned responses and errors.
   - Test:
     - Success paths (correct JSON → correct domain objects).
     - Error mapping (status codes → domain errors).
     - Edge cases (empty responses, invalid JSON).

8. Summarize:

   - Files created/updated.
   - Next steps (e.g., "Update use cases or feature flags to use this repository").
