# Identity Sandbox Module

## Purpose

Demonstrates the Schema-Driven Form Engine through **real-world profile fields** that manipulate user flow and UX:

- **Avatar**: Image pick → crop → upload → cache → display everywhere
- **Birthday/Age**: DOB input → derive age → gating → locale formatting
- **Screen Name**: Availability check → suggestions → uniqueness → profanity rules

**Why these fields?** They force you to solve every hard problem:
- Progressive disclosure
- Async validation with debouncing
- Conditional routing (age gating)
- Media handling (upload, cache, retry)
- Complex edge cases (Unicode, timezones, permissions)

## Philosophy

**This is NOT a "profile app."** It's infrastructure demonstration through identity fields that:
- Are feature-agnostic (every app has profiles)
- Prove the FormEngine handles real complexity
- Show all UX manipulation patterns
- Remain testable and maintainable

---

## 1) How These Fields Manipulate User Flow/UX

### A) Progressive Disclosure

**Don't show everything at once. Build trust incrementally.**

```swift
// Step 1: Screen name (fast, fun, establishes identity)
let screenNameStep = FormSchema(
    id: "screenName",
    title: "Choose Your Name",
    sections: [
        FormSection(fields: [
            FormField(
                id: .screenName,
                label: "Screen Name",
                type: .text,
                required: true,
                validation: [
                    .minLength(3),
                    .maxLength(20),
                    .alphanumericWithUnderscore,
                    .asyncAvailability  // Debounced server check
                ]
            )
        ])
    ]
)

// Step 2: Birthday (only after screen name valid - trust/safety gating)
let birthdayStep = FormSchema(
    id: "birthday",
    title: "When's Your Birthday?",
    sections: [
        FormSection(fields: [
            FormField(
                id: .dateOfBirth,
                label: "Date of Birth",
                type: .date,
                required: true,
                validation: [.validDate, .ageEligibility(minimum: 13)]
            )
        ])
    ]
)

// Step 3: Avatar (only after birthday passes - higher effort step)
let avatarStep = FormSchema(
    id: "avatar",
    title: "Add Your Photo",
    sections: [
        FormSection(fields: [
            FormField(
                id: .avatar,
                label: "Profile Picture",
                type: .image,
                required: false,  // Can skip
                validation: [.imageSizeLimit, .imageAspectRatio]
            )
        ])
    ]
)
```

**UX Effect**:
- Fast early steps (screen name) build momentum
- Trust established before asking birthday
- Effort increases gradually (avatar is optional, last)
- Users less likely to abandon

### B) Validation Timing as UX

**When you validate matters as much as what you validate.**

```swift
// Screen Name: Multi-tier validation
struct ScreenNameValidationStrategy: ValidationStrategy {
    enum ValidationTiming {
        case instant    // Local rules (length, chars)
        case debounced  // Server rules (availability)
        case onSubmit   // Final check before commit
    }

    func validate(value: String, timing: ValidationTiming) -> ValidationResult {
        switch timing {
        case .instant:
            // Fast, local checks
            guard value.count >= 3 else {
                return .invalid("At least 3 characters")
            }
            guard value.isAlphanumericWithUnderscore else {
                return .invalid("Letters, numbers, and underscore only")
            }
            return .valid

        case .debounced:
            // Async availability check (debounced 500ms)
            return await checkAvailability(value)

        case .onSubmit:
            // Final reservation + profanity check
            return await reserveScreenName(value)
        }
    }
}

// Birthday: Validate on submit (less annoying)
struct BirthdayValidationStrategy: ValidationStrategy {
    func validate(value: Date, timing: ValidationTiming) -> ValidationResult {
        switch timing {
        case .instant:
            // Don't show errors while typing date
            return .pending

        case .onSubmit:
            // Validate once when user finishes
            let age = Calendar.current.dateComponents([.year], from: value, to: Date()).year ?? 0

            if age < 13 {
                return .invalid("You must be at least 13 years old")
            }

            if age > 120 {
                return .invalid("Please enter a valid birth date")
            }

            return .valid
        }
    }
}
```

**UX Effect**:
- Screen name feels responsive (instant feedback)
- Birthday doesn't interrupt typing
- Age-based messaging appears at right time
- Reduces validation noise

### C) Conditional Routing (Coordinator-Controlled)

**The Coordinator decides next screen based on typed results, not hardcoded navigation.**

```swift
final class IdentityFlowCoordinator: FormFlowCoordinator {
    func formDidSubmit(result: FormSubmissionResult) {
        switch result {
        // Screen name taken → stay on step, show suggestions
        case .validationFailed(.screenNameTaken(let suggestions)):
            showInlineError(
                message: "That name is taken",
                suggestions: suggestions
            )

        // Birthday indicates underage → route to ineligible screen
        case .success(.ageGatingFailed(let age)):
            showIneligibleScreen(age: age, requirement: 13)

        // Avatar upload failed → allow skip with retry banner
        case .failure(.uploadFailed(let error)):
            showSkipOption(
                message: "Upload failed. Try again later?",
                error: error
            )

        // Birthday in valid range but needs guardian consent
        case .success(.requiresGuardianConsent):
            showGuardianConsentFlow()

        // All steps complete → success
        case .success(.completed(let profile)):
            navigateToMain(profile: profile)
        }
    }
}
```

**Key Principle**: UI is dumb, Coordinator routes based on typed outcomes.

---

## 2) Data Mapping: UI → Domain (The Senior Way)

### Principle

**Keep raw input separate from parsed domain values.**

```
UI Layer              Presentation Layer       Domain Layer
-----------          ------------------       -------------
UITextField          String (raw)             ScreenName (typed)
UIDatePicker         Date                     DateOfBirth (validated)
UIImagePickerResult  UIImage                  AvatarAsset (uploaded)
```

### Mapping Pipeline

```swift
// 1. FieldID identifies UI control (stable identity)
enum FieldID: String, Hashable {
    case screenName
    case dateOfBirth
    case avatarImage
}

// 2. ViewModel stores raw values
final class IdentityFormViewModel: ObservableObject {
    @Published private(set) var rawValues: [FieldID: Any] = [:]

    func updateField(_ fieldID: FieldID, value: Any) {
        rawValues[fieldID] = value

        // Trigger validation based on timing strategy
        validateField(fieldID, timing: .instant)
    }
}

// 3. On submit: normalize → validate → map
struct IdentityProfileMapping: FieldMapping {
    typealias DomainModel = IdentityProfile

    func map(from rawValues: [FieldID: Any]) throws -> IdentityProfile {
        // Screen name: normalize
        guard let rawScreenName = rawValues[.screenName] as? String else {
            throw MappingError.missingField(.screenName)
        }

        let normalized = rawScreenName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }

        guard normalized.count >= 3 else {
            throw MappingError.invalidValue(.screenName, "Too short")
        }

        let screenName = ScreenName(value: normalized)

        // Date of birth: validate and wrap
        guard let dob = rawValues[.dateOfBirth] as? Date else {
            throw MappingError.missingField(.dateOfBirth)
        }

        // Store as date-only (no time component)
        let dateOnly = Calendar.current.startOfDay(for: dob)
        let dateOfBirth = DateOfBirth(date: dateOnly)

        // Derive age
        let age = Calendar.current.dateComponents(
            [.year],
            from: dateOfBirth.date,
            to: Date()
        ).year ?? 0

        // Avatar: optional
        let avatarAsset: AvatarAsset?
        if let image = rawValues[.avatarImage] as? UIImage {
            avatarAsset = AvatarAsset(localImage: image)
        } else {
            avatarAsset = nil
        }

        return IdentityProfile(
            screenName: screenName,
            dateOfBirth: dateOfBirth,
            age: age,
            avatar: avatarAsset
        )
    }
}

// 4. Use case runs
protocol CreateIdentityProfileUseCase {
    func execute(_ profile: IdentityProfile) async throws -> ProfileResult
}

enum ProfileResult {
    case completed(profile: UserProfile)
    case requiresGuardianConsent(age: Int)
    case ageGatingFailed(age: Int, minimum: Int)
    case screenNameReserved(suggestions: [String])
}
```

**Benefits**:
- Deterministic UX (same input → same output)
- Easy testing (pure functions)
- Easy flow branching (typed results)
- Clear separation of concerns

---

## 3) Use Cases for These Fields

### A) UpdateScreenName

```swift
protocol UpdateScreenNameUseCase {
    func execute(_ screenName: String) async throws -> ScreenNameResult
}

enum ScreenNameResult {
    case available
    case taken(suggestions: [String])
    case invalid(reason: String)
    case reservationFailed(error: Error)
}

final class DefaultUpdateScreenNameUseCase: UpdateScreenNameUseCase {
    private let repository: ScreenNameRepository
    private let suggestionGenerator: ScreenNameSuggestionGenerator
    private let validator: ScreenNameValidator

    func execute(_ screenName: String) async throws -> ScreenNameResult {
        // 1. Local validation
        guard validator.isValid(screenName) else {
            return .invalid(reason: validator.errorMessage)
        }

        // 2. Check availability (debounced by ViewModel)
        let isAvailable = try await repository.checkAvailability(screenName)

        guard isAvailable else {
            // Generate suggestions
            let suggestions = await suggestionGenerator.generate(basedOn: screenName)
            return .taken(suggestions: suggestions)
        }

        // 3. Reserve name (temporary hold)
        try await repository.reserve(screenName)

        return .available
    }
}
```

**Edge Cases Handled**:
- Rapid typing → ViewModel debounces, cancels previous requests
- Network offline → Return `.invalid(reason: "Check your connection")`
- Unicode/emoji → Validator strips or rejects
- Case-insensitive collisions → Repository handles normalization

### B) UpdateDateOfBirth

```swift
protocol UpdateDateOfBirthUseCase {
    func execute(_ dateOfBirth: Date) async throws -> AgeEligibilityResult
}

enum AgeEligibilityResult {
    case eligible(age: Int)
    case requiresGuardianConsent(age: Int)
    case ineligible(age: Int, minimum: Int)
}

final class DefaultUpdateDateOfBirthUseCase: UpdateDateOfBirthUseCase {
    private let eligibilityPolicy: AgeEligibilityPolicy
    private let calendar: Calendar

    func execute(_ dateOfBirth: Date) async throws -> AgeEligibilityResult {
        // 1. Derive age (locale-safe)
        let age = calendar.dateComponents(
            [.year],
            from: dateOfBirth,
            to: Date()
        ).year ?? 0

        // 2. Apply eligibility policy (Strategy pattern)
        return eligibilityPolicy.evaluate(age: age)
    }
}

// Strategy: Different markets have different rules
protocol AgeEligibilityPolicy {
    func evaluate(age: Int) -> AgeEligibilityResult
}

struct USAgeEligibilityPolicy: AgeEligibilityPolicy {
    func evaluate(age: Int) -> AgeEligibilityResult {
        if age >= 18 {
            return .eligible(age: age)
        } else if age >= 13 {
            return .requiresGuardianConsent(age: age)
        } else {
            return .ineligible(age: age, minimum: 13)
        }
    }
}

struct EUAgeEligibilityPolicy: AgeEligibilityPolicy {
    func evaluate(age: Int) -> AgeEligibilityResult {
        // GDPR: 16 is common threshold
        if age >= 16 {
            return .eligible(age: age)
        } else if age >= 13 {
            return .requiresGuardianConsent(age: age)
        } else {
            return .ineligible(age: age, minimum: 13)
        }
    }
}
```

**Edge Cases Handled**:
- Invalid dates (Feb 30) → Parser rejects
- Timezone edge around midnight → Store as date-only, not datetime
- Leap day DOB → Calendar handles correctly
- User changes DOB after commit → Use case re-evaluates

### C) UpdateAvatar

```swift
protocol UpdateAvatarUseCase {
    func execute(_ image: UIImage) async throws -> AvatarResult
}

enum AvatarResult {
    case uploaded(url: URL)
    case cached(localURL: URL)
    case failed(error: AvatarError, canRetry: Bool)
}

enum AvatarError: Error {
    case tooLarge
    case invalidFormat
    case uploadFailed(underlyingError: Error)
    case permissionDenied
}

final class DefaultUpdateAvatarUseCase: UpdateAvatarUseCase {
    private let imageProcessor: ImageProcessor
    private let uploader: MediaUploader
    private let cache: MediaCache

    func execute(_ image: UIImage) async throws -> AvatarResult {
        // 1. Resize/compress (avoid memory pressure)
        let processed = try imageProcessor.process(
            image,
            targetSize: CGSize(width: 512, height: 512),
            compressionQuality: 0.8
        )

        // 2. Cache locally first (optimistic UI)
        let localURL = try cache.store(processed, for: "avatar_pending")

        // 3. Upload in background
        do {
            let remoteURL = try await uploader.upload(
                processed,
                to: "/profile/avatar"
            )

            // 4. Update cache with remote URL
            try cache.updateRemoteURL(localURL, remoteURL: remoteURL)

            return .uploaded(url: remoteURL)
        } catch {
            // Upload failed but we have local cache
            return .failed(
                error: .uploadFailed(underlyingError: error),
                canRetry: true
            )
        }
    }
}
```

**Edge Cases Handled**:
- Permission denied → Return `.failed(.permissionDenied, canRetry: false)`
- Huge images → `ImageProcessor` downscales to manageable size
- Upload fails → Cache local, show retry banner
- Slow network → Show progress, allow skip
- Cached old avatar after update → Cache invalidation strategy

### D) SubmitIdentityProfile

```swift
protocol SubmitIdentityProfileUseCase {
    func execute(_ profile: IdentityProfile) async throws -> ProfileSubmissionResult
}

enum ProfileSubmissionResult {
    case completed(userProfile: UserProfile)
    case requiresVerification(method: VerificationMethod)
    case requiresGuardianConsent
    case failed(error: Error)
}

final class DefaultSubmitIdentityProfileUseCase: SubmitIdentityProfileUseCase {
    private let repository: ProfileRepository
    private let screenNameReservation: ScreenNameReservation
    private let avatarUploader: MediaUploader

    func execute(_ profile: IdentityProfile) async throws -> ProfileSubmissionResult {
        // 1. Finalize screen name reservation
        try await screenNameReservation.commit(profile.screenName)

        // 2. Upload avatar if present
        var avatarURL: URL?
        if let avatar = profile.avatar {
            avatarURL = try? await avatarUploader.upload(avatar.image)
        }

        // 3. Create profile DTO
        let dto = ProfileCreationDTO(
            screenName: profile.screenName.value,
            dateOfBirth: profile.dateOfBirth.date.iso8601String,
            avatarURL: avatarURL?.absoluteString
        )

        // 4. Submit to server
        let response = try await repository.createProfile(dto)

        // 5. Map response to result
        switch response {
        case .success(let userProfile):
            return .completed(userProfile: userProfile)

        case .requiresGuardianConsent:
            return .requiresGuardianConsent

        case .requiresVerification(let method):
            return .requiresVerification(method: method)
        }
    }
}
```

---

## 4) Edge Cases That Force Great UX

### Screen Name

**Edge Case: Taken / Reserved Words**
```swift
struct ScreenNameValidator {
    private let reservedWords = ["admin", "root", "system", "support"]

    func validate(_ name: String) -> ValidationResult {
        let normalized = name.lowercased()

        if reservedWords.contains(normalized) {
            return .invalid("That name is reserved")
        }

        // Check profanity list
        if containsProfanity(normalized) {
            return .invalid("Please choose a different name")
        }

        return .valid
    }
}
```

**Edge Case: Rapid Typing → Multiple Availability Calls**
```swift
final class ScreenNameViewModel: ObservableObject {
    @Published var screenName: String = ""
    private var availabilityTask: Task<Void, Never>?

    func updateScreenName(_ value: String) {
        screenName = value

        // Cancel previous availability check
        availabilityTask?.cancel()

        // Debounce 500ms
        availabilityTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)

            guard !Task.isCancelled else { return }

            await checkAvailability(value)
        }
    }
}
```

**Edge Case: Network Offline**
```swift
func checkAvailability(_ name: String) async -> ScreenNameResult {
    guard networkMonitor.isConnected else {
        // Fallback: allow continue but mark as unverified
        return .availabilityUnknown(
            message: "We'll check this name when you're online"
        )
    }

    // Normal flow
    return try await repository.checkAvailability(name)
}
```

**Edge Case: Unicode, Emoji, RTL, Diacritics**
```swift
struct ScreenNameNormalizer {
    func normalize(_ input: String) -> String {
        return input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .applyingTransform(.stripDiacritics, reverse: false) ?? input
            .filter { char in
                char.isLetter || char.isNumber || char == "_"
            }
    }
}

// Test cases
func testNormalization() {
    XCTAssertEqual(normalize("Café"), "cafe")
    XCTAssertEqual(normalize("Test🎉"), "test")
    XCTAssertEqual(normalize("مرحبا"), "")  // Arabic -> empty (Latin only)
}
```

**Edge Case: Case-Insensitive Collisions**
```swift
// Server-side (or local check)
func isAvailable(_ screenName: String) async throws -> Bool {
    let normalized = screenName.lowercased()

    // Check case-insensitive
    let existing = try await repository.findScreenName(normalized)
    return existing == nil
}
```

### Birthday / Age

**Edge Case: Invalid Dates**
```swift
func validateDate(_ components: DateComponents) -> ValidationResult {
    guard let date = Calendar.current.date(from: components) else {
        return .invalid("That's not a valid date")
    }

    // Feb 30, etc. will fail above
    return .valid
}
```

**Edge Case: Timezone Edge Around Midnight**
```swift
// ALWAYS store DOB as date-only, not datetime
struct DateOfBirth {
    let date: Date  // Stored as start of day in UTC

    init(year: Int, month: Int, day: Int) {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.timeZone = TimeZone(secondsFromGMT: 0)  // UTC

        self.date = Calendar.current.date(from: components)!
    }
}
```

**Edge Case: Leap Day DOB**
```swift
func calculateAge(from dob: DateOfBirth, to today: Date = Date()) -> Int {
    // Calendar handles leap years correctly
    let components = Calendar.current.dateComponents(
        [.year],
        from: dob.date,
        to: today
    )

    return components.year ?? 0
}

// Test
func testLeapDayAge() {
    let leapDayDOB = DateOfBirth(year: 2000, month: 2, day: 29)
    let age2024 = calculateAge(from: leapDayDOB, to: Date(year: 2024, month: 2, day: 28))
    XCTAssertEqual(age2024, 23)  // Not 24 yet

    let age2024AfterBirthday = calculateAge(from: leapDayDOB, to: Date(year: 2024, month: 3, day: 1))
    XCTAssertEqual(age2024AfterBirthday, 24)  // Now 24
}
```

**Edge Case: User Changes DOB After Commit**
```swift
func updateDateOfBirth(_ newDOB: DateOfBirth) async throws {
    // Re-evaluate eligibility
    let result = try await eligibilityPolicy.evaluate(age: newDOB.age)

    switch result {
    case .ineligible:
        // User was eligible but changed to ineligible DOB
        // Policy decision: lock account, require support
        throw ProfileError.ineligibleAfterChange

    case .requiresGuardianConsent:
        // Trigger guardian consent flow again
        try await requestGuardianConsent()

    case .eligible:
        // All good
        try await repository.updateDOB(newDOB)
    }
}
```

### Avatar

**Edge Case: Permission Denied**
```swift
func pickAvatar() async throws -> UIImage {
    let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)

    guard status == .authorized else {
        throw AvatarError.permissionDenied
    }

    // Continue with picker
    return try await presentImagePicker()
}

// Coordinator handles error
func handleAvatarError(_ error: AvatarError) {
    switch error {
    case .permissionDenied:
        showPermissionAlert(
            message: "We need photo access to set your avatar",
            settingsAction: true
        )

    case .tooLarge:
        showError("Image too large. Try a smaller photo.")

    case .uploadFailed:
        showRetryBanner("Upload failed. Try again?")
    }
}
```

**Edge Case: Huge Images → Memory Pressure**
```swift
protocol ImageProcessor {
    func process(
        _ image: UIImage,
        targetSize: CGSize,
        compressionQuality: CGFloat
    ) throws -> UIImage
}

final class DefaultImageProcessor: ImageProcessor {
    func process(
        _ image: UIImage,
        targetSize: CGSize,
        compressionQuality: CGFloat
    ) throws -> UIImage {
        // Check input size
        let inputSize = image.size
        let inputPixels = inputSize.width * inputSize.height

        // Reject if > 25 megapixels (memory safety)
        guard inputPixels < 25_000_000 else {
            throw AvatarError.tooLarge
        }

        // Downscale if needed
        let scale = min(
            targetSize.width / inputSize.width,
            targetSize.height / inputSize.height,
            1.0  // Never upscale
        )

        let newSize = CGSize(
            width: inputSize.width * scale,
            height: inputSize.height * scale
        )

        // Render at smaller size
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: newSize))
        guard let processed = UIGraphicsGetImageFromCurrentImageContext() else {
            throw AvatarError.processingFailed
        }

        return processed
    }
}
```

**Edge Case: Upload Fails/Retries**
```swift
final class RetryableMediaUploader: MediaUploader {
    private let baseUploader: MediaUploader
    private let retryStrategy: RetryStrategy

    func upload(_ image: UIImage, to endpoint: String) async throws -> URL {
        var attempt = 0

        while true {
            do {
                return try await baseUploader.upload(image, to: endpoint)
            } catch {
                attempt += 1

                guard retryStrategy.shouldRetry(attempt: attempt, error: error) else {
                    throw error
                }

                let delay = retryStrategy.delayBeforeRetry(attempt: attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }
}
```

**Edge Case: Cached Old Avatar After Update**
```swift
protocol MediaCache {
    func store(_ image: UIImage, for key: String) throws -> URL
    func retrieve(for key: String) throws -> UIImage?
    func invalidate(for key: String) throws
}

final class AvatarCacheManager {
    private let cache: MediaCache

    func updateAvatar(_ newImage: UIImage, userID: String) async throws {
        // 1. Invalidate old cache
        try cache.invalidate(for: "avatar_\(userID)")

        // 2. Store new image
        let localURL = try cache.store(newImage, for: "avatar_\(userID)")

        // 3. Upload
        let remoteURL = try await uploader.upload(newImage)

        // 4. Broadcast update event
        NotificationCenter.default.post(
            name: .avatarUpdated,
            object: nil,
            userInfo: ["userID": userID, "url": remoteURL]
        )
    }
}
```

---

## 5) Third-Party Libraries (Lean But Quality)

### Strategy: Keep It Lean

**Criteria for inclusion**:
1. ✅ Solves real maintenance cost (not trivial to implement correctly)
2. ✅ Well-maintained (active development, SPM support)
3. ✅ Widely adopted (de facto standard)
4. ✅ Replaceable (not too magical, clear boundaries)

### Recommended Libraries

#### 1. Code Quality: SwiftLint
**Purpose**: Enforce conventions, catch common pitfalls
**Why**: Team-wide consistency, automated code review
**Install**: SPM
```swift
dependencies: [
    .package(url: "https://github.com/realm/SwiftLint", from: "0.54.0")
]
```

**Config**: `.swiftlint.yml` (already created in starter kit)

---

#### 2. Testing: SnapshotTesting (Point-Free)
**Purpose**: Lock in UI states for forms
**Why**: Catch visual regressions, document UI states
**Install**: SPM
```swift
dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.15.0")
]
```

**Usage**:
```swift
func testScreenNameStep_takenState() {
    let viewModel = ScreenNameViewModel(/* ... */)
    viewModel.showError("That name is taken", suggestions: ["john_doe2", "john_doe_23"])

    let view = ScreenNameStepView(viewModel: viewModel)

    assertSnapshot(matching: view, as: .image(on: .iPhone13))
}
```

---

#### 3. DI: Swinject (Optional, for Large Projects)
**Purpose**: Formal DI container for module wiring
**Why**: Avoids manual factory sprawl in large starter kits
**Install**: SPM
```swift
dependencies: [
    .package(url: "https://github.com/Swinject/Swinject", from: "2.8.0")
]
```

**Usage**:
```swift
let container = Container()

// Register dependencies
container.register(ScreenNameRepository.self) { _ in
    DefaultScreenNameRepository()
}

container.register(UpdateScreenNameUseCase.self) { resolver in
    DefaultUpdateScreenNameUseCase(
        repository: resolver.resolve(ScreenNameRepository.self)!
    )
}

// Resolve
let useCase = container.resolve(UpdateScreenNameUseCase.self)!
```

**Alternative**: Lightweight factories (no library) work fine for smaller projects.

---

#### 4. Image Loading: Nuke
**Purpose**: Avatar caching, resizing, prefetching
**Why**: Robust pipeline, handles memory/cache correctly
**Install**: SPM
```swift
dependencies: [
    .package(url: "https://github.com/kean/Nuke", from: "12.0.0")
]
```

**Usage**:
```swift
import Nuke

// Load and cache avatar
func loadAvatar(url: URL, into imageView: UIImageView) {
    let request = ImageRequest(
        url: url,
        processors: [
            .resize(size: CGSize(width: 200, height: 200)),
            .circle
        ]
    )

    Nuke.loadImage(with: request, into: imageView)
}

// Prefetch for smooth scrolling
let prefetcher = ImagePrefetcher()
prefetcher.startPrefetching(with: avatarURLs)
```

**Alternative**: Kingfisher (also widely adopted, similar quality)

---

#### 5. Animations: Lottie (Optional)
**Purpose**: Success/error animations (onboarding, profile complete)
**Why**: Standardized animations, designer-friendly
**Install**: SPM
```swift
dependencies: [
    .package(url: "https://github.com/airbnb/lottie-ios", from: "4.3.0")
]
```

**Usage**:
```swift
import Lottie

let animationView = LottieAnimationView(name: "success")
animationView.loopMode = .playOnce
animationView.play()
```

**Note**: Only if you have animations. Skip if not needed.

---

### Dependencies Summary

**Minimal (Required)**:
- SwiftLint (code quality)
- SnapshotTesting (UI testing)

**Standard (Recommended)**:
- Nuke (image loading/caching)

**Optional (Large Projects)**:
- Swinject (DI container)
- Lottie (animations, if needed)

**Total**: 2-5 dependencies (lean!)

---

## 6) Identity Sandbox Module Structure

### Purpose

**NOT a "profile app."** It's infrastructure demonstration.

### Module Structure

```
Features/IdentitySandbox/
├── Domain/
│   ├── Entities/
│   │   ├── ScreenName.swift
│   │   ├── DateOfBirth.swift
│   │   ├── AvatarAsset.swift
│   │   └── IdentityProfile.swift
│   ├── UseCases/
│   │   ├── UpdateScreenNameUseCase.swift
│   │   ├── UpdateDateOfBirthUseCase.swift
│   │   ├── UpdateAvatarUseCase.swift
│   │   └── SubmitIdentityProfileUseCase.swift
│   ├── Repositories/
│   │   ├── ScreenNameRepository.swift (protocol)
│   │   └── ProfileRepository.swift (protocol)
│   └── Strategies/
│       ├── AgeEligibilityPolicy.swift
│       ├── ScreenNamePolicy.swift
│       └── ValidationStrategy.swift
├── Data/
│   ├── Repositories/
│   │   ├── DefaultScreenNameRepository.swift
│   │   └── DefaultProfileRepository.swift
│   ├── DataSources/
│   │   ├── RemoteScreenNameDataSource.swift
│   │   └── MediaUploadDataSource.swift
│   ├── DTOs/
│   │   ├── ProfileCreationDTO.swift
│   │   └── ScreenNameCheckDTO.swift
│   └── Caching/
│       ├── AvatarCacheManager.swift
│       └── MediaCache.swift
└── Presentation/
    ├── ScreenNameStep/
    │   ├── ScreenNameStepViewController.swift
    │   ├── ScreenNameStepViewModel.swift
    │   └── ScreenNameSuggestionView.swift
    ├── BirthdayStep/
    │   ├── BirthdayStepViewController.swift
    │   └── BirthdayStepViewModel.swift
    ├── AvatarStep/
    │   ├── AvatarStepViewController.swift
    │   ├── AvatarStepViewModel.swift
    │   └── ImagePickerCoordinator.swift
    ├── ReviewStep/
    │   ├── ReviewStepViewController.swift
    │   └── ReviewStepViewModel.swift
    ├── IneligibleScreen/
    │   └── IneligibleViewController.swift
    └── Coordinator/
        └── IdentityFlowCoordinator.swift
```

### Screens

**1. ScreenNameStep**
```swift
// User picks screen name
// Shows:
// - Input field with instant validation
// - "Checking availability..." indicator (debounced)
// - Inline errors + suggestions if taken
// - Green checkmark if available
```

**2. BirthdayStep** (only shown after screen name valid)
```swift
// User enters birthday
// Shows:
// - Date picker (or text fields for day/month/year)
// - Age-based messaging ("You'll need guardian consent")
// - Error if ineligible
```

**3. AvatarStep** (only shown after birthday passes)
```swift
// User picks avatar (optional)
// Shows:
// - "Add Photo" button
// - Image picker → crop → preview
// - Upload progress
// - "Skip for now" option
// - Retry banner if upload fails
```

**4. ReviewStep**
```swift
// Shows final profile before submit
// Shows:
// - Screen name (with edit button)
// - Age (derived from birthday)
// - Avatar preview (or placeholder)
// - Sanitized DTO output (for demo)
// - Submit button
```

**5. IneligibleScreen** (if age < minimum)
```swift
// Shows:
// - "Sorry, you must be at least 13"
// - Explanation
// - Contact support option
```

### Coordinator Routing

```swift
final class IdentityFlowCoordinator: Coordinator {
    func start() {
        showScreenNameStep()
    }

    func screenNameStepCompleted(screenName: ScreenName) {
        showBirthdayStep()
    }

    func birthdayStepCompleted(result: AgeEligibilityResult) {
        switch result {
        case .eligible:
            showAvatarStep()

        case .requiresGuardianConsent:
            showGuardianConsentFlow()

        case .ineligible(let age, let minimum):
            showIneligibleScreen(age: age, minimum: minimum)
        }
    }

    func avatarStepCompleted(avatar: AvatarAsset?) {
        showReviewStep(avatar: avatar)
    }

    func reviewStepSubmitted(profile: IdentityProfile) async {
        do {
            let result = try await submitUseCase.execute(profile)

            switch result {
            case .completed:
                navigateToMain()

            case .requiresVerification:
                showVerificationFlow()
            }
        } catch {
            showError(error)
        }
    }
}
```

---

## 7) Tests That Guarantee UX

### Unit Tests

**Screen Name: Normalization + Validation**
```swift
func testScreenNameNormalization_trimsAndLowercases() {
    let normalizer = ScreenNameNormalizer()
    let result = normalizer.normalize("  John_Doe  ")

    XCTAssertEqual(result, "john_doe")
}

func testScreenNameValidation_rejectsEmoji() {
    let validator = ScreenNameValidator()
    let result = validator.validate("john🎉")

    XCTAssertFalse(result.isValid)
}

func testScreenNameValidation_acceptsValid() {
    let validator = ScreenNameValidator()
    let result = validator.validate("john_doe_123")

    XCTAssertTrue(result.isValid)
}
```

**Availability: Debouncing + Cancellation**
```swift
func testScreenNameAvailability_debouncesRapidTyping() async {
    let mockRepo = MockScreenNameRepository()
    let viewModel = ScreenNameViewModel(repository: mockRepo)

    // Rapid typing
    viewModel.updateScreenName("j")
    viewModel.updateScreenName("jo")
    viewModel.updateScreenName("joh")
    viewModel.updateScreenName("john")

    // Wait for debounce
    try await Task.sleep(nanoseconds: 600_000_000)

    // Should only check "john", not "j", "jo", "joh"
    XCTAssertEqual(mockRepo.checkCallCount, 1)
    XCTAssertEqual(mockRepo.lastCheckedName, "john")
}

func testScreenNameAvailability_cancelsPreviousCheck() async {
    let mockRepo = MockScreenNameRepository()
    mockRepo.checkDelay = 1.0  // Slow check

    let viewModel = ScreenNameViewModel(repository: mockRepo)

    // Start first check
    viewModel.updateScreenName("john")

    // Immediately type more (should cancel first)
    try await Task.sleep(nanoseconds: 100_000_000)
    viewModel.updateScreenName("jane")

    // Wait for second check
    try await Task.sleep(nanoseconds: 1_500_000_000)

    // First check should be cancelled
    XCTAssertEqual(mockRepo.checkCallCount, 2)
    XCTAssertEqual(mockRepo.lastCheckedName, "jane")
}
```

**DOB: Parsing + Age + Eligibility**
```swift
func testDateOfBirthParsing_handlesLeapDay() {
    let dob = DateOfBirth(year: 2000, month: 2, day: 29)
    XCTAssertNotNil(dob)
}

func testAgeCalculation_leapDay() {
    let dob = DateOfBirth(year: 2000, month: 2, day: 29)
    let age = calculateAge(from: dob, to: Date(year: 2024, month: 2, day: 28))

    XCTAssertEqual(age, 23)
}

func testAgeEligibility_under13_ineligible() {
    let policy = USAgeEligibilityPolicy()
    let result = policy.evaluate(age: 12)

    XCTAssertEqual(result, .ineligible(age: 12, minimum: 13))
}

func testAgeEligibility_13to17_requiresConsent() {
    let policy = USAgeEligibilityPolicy()
    let result = policy.evaluate(age: 15)

    XCTAssertEqual(result, .requiresGuardianConsent(age: 15))
}
```

**Mapping: Raw → DTO**
```swift
func testIdentityProfileMapping_correctKeys() throws {
    let mapper = IdentityProfileMapping()
    let raw: [FieldID: Any] = [
        .screenName: "john_doe",
        .dateOfBirth: Date(year: 2000, month: 1, day: 15)
    ]

    let profile = try mapper.map(from: raw)

    XCTAssertEqual(profile.screenName.value, "john_doe")
    XCTAssertEqual(profile.age, 24)
}

func testIdentityProfileMapping_normalizesScreenName() throws {
    let mapper = IdentityProfileMapping()
    let raw: [FieldID: Any] = [
        .screenName: "  John_DOE  ",
        .dateOfBirth: Date(year: 2000, month: 1, day: 15)
    ]

    let profile = try mapper.map(from: raw)

    XCTAssertEqual(profile.screenName.value, "john_doe")
}
```

### Integration Tests

**URLProtocol Stub: Availability Endpoint**
```swift
func testScreenNameAvailability_integration() async throws {
    let stubClient = StubHTTPClient()
    stubClient.stubbedResponse = HTTPResponse(
        statusCode: 200,
        data: """
        {"available": false, "suggestions": ["john_doe2", "john_doe_23"]}
        """.data(using: .utf8)!
    )

    let dataSource = RemoteScreenNameDataSource(client: stubClient)
    let result = try await dataSource.checkAvailability("john_doe")

    XCTAssertEqual(result.available, false)
    XCTAssertEqual(result.suggestions.count, 2)
}
```

**Upload Endpoint: Success/Fail**
```swift
func testAvatarUpload_success() async throws {
    let stubClient = StubHTTPClient()
    stubClient.stubbedResponse = HTTPResponse(
        statusCode: 200,
        data: """
        {"url": "https://cdn.example.com/avatars/123.jpg"}
        """.data(using: .utf8)!
    )

    let uploader = MediaUploader(client: stubClient)
    let image = UIImage(systemName: "person.circle")!
    let result = try await uploader.upload(image, to: "/profile/avatar")

    XCTAssertEqual(result.absoluteString, "https://cdn.example.com/avatars/123.jpg")
}

func testAvatarUpload_failure_retries() async throws {
    let stubClient = StubHTTPClient()
    stubClient.stubbedError = URLError(.networkConnectionLost)

    let retryUploader = RetryableMediaUploader(
        baseUploader: MediaUploader(client: stubClient),
        retryStrategy: ExponentialBackoffStrategy(maxAttempts: 3)
    )

    let image = UIImage(systemName: "person.circle")!

    do {
        _ = try await retryUploader.upload(image, to: "/profile/avatar")
        XCTFail("Should throw after retries")
    } catch {
        // Expected
        XCTAssertEqual(stubClient.uploadCallCount, 3)
    }
}
```

### UI Tests

**Taken Name: Inline Error + Suggestions**
```swift
func testScreenNameStep_takenName_showsSuggestions() {
    let app = XCUIApplication()
    app.launch()

    let screenNameField = app.textFields["screenNameField"]
    screenNameField.tap()
    screenNameField.typeText("john_doe")

    // Wait for availability check
    sleep(1)

    // Error should appear
    XCTAssertTrue(app.staticTexts["That name is taken"].exists)

    // Suggestions should appear
    XCTAssertTrue(app.buttons["john_doe2"].exists)
    XCTAssertTrue(app.buttons["john_doe_23"].exists)

    // Tap suggestion
    app.buttons["john_doe2"].tap()

    // Field should update
    XCTAssertEqual(screenNameField.value as? String, "john_doe2")
}
```

**Underage Birthday: Routes to Ineligible**
```swift
func testBirthdayStep_underage_showsIneligible() {
    let app = XCUIApplication()
    app.launchArguments = ["UI_TESTING_SCREEN_NAME_COMPLETE"]
    app.launch()

    // Set birthday to 10 years old
    let today = Date()
    let tenYearsAgo = Calendar.current.date(byAdding: .year, value: -10, to: today)!

    app.datePickers["birthdayPicker"].adjust(to: tenYearsAgo)
    app.buttons["continueButton"].tap()

    // Should route to ineligible screen
    XCTAssertTrue(app.staticTexts["Sorry, you must be at least 13"].exists)
}
```

**Avatar Skip: Works, Review Shows Placeholder**
```swift
func testAvatarStep_skip_showsPlaceholder() {
    let app = XCUIApplication()
    app.launchArguments = ["UI_TESTING_BIRTHDAY_COMPLETE"]
    app.launch()

    // Tap skip
    app.buttons["skipAvatarButton"].tap()

    // Review step should show placeholder avatar
    XCTAssertTrue(app.images["placeholderAvatar"].exists)
}
```

---

## Success Criteria

The Identity Sandbox Module succeeds when:

1. ✅ Any form can add these fields with < 10 lines of schema
2. ✅ All validation logic is reusable and tested
3. ✅ Progressive disclosure works perfectly
4. ✅ Conditional routing (age gating) is data-driven
5. ✅ All edge cases handled gracefully
6. ✅ Zero hardcoded screens (all schema-driven)
7. ✅ Third-party libs are lean, replaceable, well-tested
8. ✅ Engineers understand the flow in 30 minutes

**This module proves the Shell can handle real-world complexity.**
