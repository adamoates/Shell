# Schema-Driven UX (Ultimate Starter Kit Feature)

## The Core Idea

**Input fields are not hardcoded. They're generated, validated, persisted, and routed using a Form Schema + Field Mapping + Flow Coordinator.**

This is the killer feature that separates the Shell from toy starter kits. It demonstrates:
- Senior-level UX architecture
- All design patterns in practice
- Complete testability
- Feature-agnostic foundation

## Why This Matters

### Traditional Approach (Hardcoded)
```swift
// ❌ Every screen is custom-built
class LoginViewController {
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    // Validation hardcoded
    // Navigation hardcoded
    // No reusability
}

class SignupViewController {
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    // Duplicate validation logic
    // Duplicate navigation logic
}
```

### Schema-Driven Approach (Dynamic)
```swift
// ✅ Single engine, infinite forms
let loginSchema = FormSchema(
    sections: [
        FormSection(fields: [
            Field(id: .email, type: .email, required: true),
            Field(id: .password, type: .secureText, required: true)
        ])
    ]
)

let signupSchema = FormSchema(
    sections: [
        FormSection(fields: [
            Field(id: .email, type: .email, required: true),
            Field(id: .password, type: .secureText, required: true),
            Field(id: .name, type: .text, required: true)
        ])
    ]
)

// Same engine renders both
formEngine.render(schema: loginSchema)
formEngine.render(schema: signupSchema)
```

---

## 1) The Three Core Components

### A) Form Schema (What the User Sees)

Defines the structure and behavior of a form:

```swift
struct FormSchema {
    let id: String
    let title: String
    let sections: [FormSection]
    let submitLabel: String
    let validation: ValidationMode
}

struct FormSection {
    let id: String
    let title: String?
    let fields: [FormField]
    let visibilityRule: VisibilityRule?
}

struct FormField {
    let id: FieldID
    let label: String
    let placeholder: String?
    let type: FieldType
    let required: Bool
    let validation: [ValidationRule]
    let autoFillType: UITextContentType?
    let keyboardType: UIKeyboardType
    let returnKeyType: UIReturnKeyType
    let secureTextEntry: Bool
    let maxLength: Int?
    let visibilityRule: VisibilityRule?
    let accessibilityLabel: String
    let accessibilityHint: String?
}

enum FieldType {
    case text
    case email
    case phone
    case password
    case number
    case date
    case picker(options: [String])
    case toggle
}

enum FieldID: String, Hashable {
    case email
    case password
    case confirmPassword
    case name
    case phone
    case accountType
    case companyName
    case postalCode
    case country
    // ... extensible
}
```

**Example Schemas**:

```swift
// Login Schema
static let login = FormSchema(
    id: "login",
    title: "Welcome Back",
    sections: [
        FormSection(
            id: "credentials",
            fields: [
                FormField(
                    id: .email,
                    label: "Email",
                    placeholder: "you@example.com",
                    type: .email,
                    required: true,
                    validation: [.email, .notEmpty],
                    autoFillType: .emailAddress,
                    keyboardType: .emailAddress,
                    returnKeyType: .next,
                    accessibilityLabel: "Email address"
                ),
                FormField(
                    id: .password,
                    label: "Password",
                    type: .password,
                    required: true,
                    validation: [.minLength(6)],
                    autoFillType: .password,
                    returnKeyType: .go,
                    secureTextEntry: true,
                    accessibilityLabel: "Password",
                    accessibilityHint: "Enter your password"
                )
            ]
        )
    ],
    submitLabel: "Log In",
    validation: .onSubmit
)

// Signup Schema (Progressive Disclosure)
static let signup = FormSchema(
    id: "signup",
    title: "Create Account",
    sections: [
        FormSection(
            id: "personal",
            title: "Personal Information",
            fields: [
                FormField(id: .name, label: "Full Name", type: .text, required: true),
                FormField(id: .email, label: "Email", type: .email, required: true),
                FormField(id: .phone, label: "Phone", type: .phone, required: false)
            ]
        ),
        FormSection(
            id: "account",
            title: "Account Details",
            fields: [
                FormField(
                    id: .accountType,
                    label: "Account Type",
                    type: .picker(options: ["Personal", "Business"]),
                    required: true
                ),
                FormField(
                    id: .companyName,
                    label: "Company Name",
                    type: .text,
                    required: true,
                    visibilityRule: .whenFieldEquals(.accountType, "Business")
                )
            ]
        ),
        FormSection(
            id: "security",
            title: "Security",
            fields: [
                FormField(id: .password, label: "Password", type: .password, required: true),
                FormField(
                    id: .confirmPassword,
                    label: "Confirm Password",
                    type: .password,
                    required: true,
                    validation: [.matches(.password)]
                )
            ]
        )
    ],
    submitLabel: "Create Account",
    validation: .live
)
```

### B) Field Mapping (How UI → Domain)

Maps UI field IDs to domain model properties with transformations:

```swift
protocol FieldMapping {
    associatedtype DomainModel

    func map(from rawValues: [FieldID: String]) throws -> DomainModel
    func reverseMap(from model: DomainModel) -> [FieldID: String]
}

// Example: Login credentials mapping
struct LoginCredentialsMapping: FieldMapping {
    func map(from rawValues: [FieldID: String]) throws -> LoginCredentials {
        guard let email = rawValues[.email]?.trimmed().lowercased() else {
            throw MappingError.missingField(.email)
        }

        guard let password = rawValues[.password] else {
            throw MappingError.missingField(.password)
        }

        return LoginCredentials(
            email: email,
            password: password
        )
    }

    func reverseMap(from model: LoginCredentials) -> [FieldID: String] {
        [
            .email: model.email,
            .password: "" // Never populate password
        ]
    }
}

// Example: User profile mapping with transformations
struct UserProfileMapping: FieldMapping {
    func map(from rawValues: [FieldID: String]) throws -> UserProfile {
        let name = rawValues[.name]?.trimmed() ?? ""
        let email = rawValues[.email]?.trimmed().lowercased() ?? ""

        // Phone: strip non-digits, format E.164
        let phone = rawValues[.phone]?
            .filter { $0.isNumber }
            .e164Formatted()

        // Account type: map string to enum
        let accountTypeString = rawValues[.accountType] ?? "Personal"
        let accountType = AccountType(rawValue: accountTypeString) ?? .personal

        // Company name: only if business account
        let companyName: String? = accountType == .business
            ? rawValues[.companyName]?.trimmed()
            : nil

        return UserProfile(
            name: name,
            email: email,
            phone: phone,
            accountType: accountType,
            companyName: companyName
        )
    }
}
```

**Transformation Strategies**:

```swift
protocol FieldTransform {
    func transform(_ input: String) -> String
}

struct TrimTransform: FieldTransform {
    func transform(_ input: String) -> String {
        input.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct LowercaseTransform: FieldTransform {
    func transform(_ input: String) -> String {
        input.lowercased()
    }
}

struct PhoneE164Transform: FieldTransform {
    func transform(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        // Format to E.164 based on country
        return "+1\(digits)" // Example for US
    }
}

// Composable transforms
struct CompositeTransform: FieldTransform {
    let transforms: [FieldTransform]

    func transform(_ input: String) -> String {
        transforms.reduce(input) { $1.transform($0) }
    }
}
```

### C) Flow Coordinator (What Happens Next)

Coordinator decides navigation based on validation and business logic:

```swift
protocol FormFlowCoordinator: AnyObject {
    func formDidSubmit(result: FormSubmissionResult)
    func formDidCancel()
    func formNeedsNavigation(to route: FormRoute)
}

enum FormSubmissionResult {
    case success(response: FormResponse)
    case failure(error: FormError)
    case validationFailed([FieldID: String])
}

enum FormResponse {
    case completed
    case requiresMFA(method: MFAMethod)
    case requiresAdditionalInfo(schema: FormSchema)
    case requiresUpgrade
}

enum FormRoute {
    case nextField(FieldID)
    case previousField(FieldID)
    case mfa(method: MFAMethod)
    case additionalInfo(FormSchema)
    case success
    case error(Error)
}

// Example coordinator
final class AuthFormCoordinator: FormFlowCoordinator {
    private let navigationController: UINavigationController
    private let dependencies: AppDependencies

    func formDidSubmit(result: FormSubmissionResult) {
        switch result {
        case .success(.completed):
            navigateToMain()

        case .success(.requiresMFA(let method)):
            showMFAScreen(method: method)

        case .success(.requiresAdditionalInfo(let schema)):
            showAdditionalInfoForm(schema: schema)

        case .failure(let error):
            showError(error)

        case .validationFailed(let errors):
            // Handled by form view
            break
        }
    }
}
```

---

## 2) Design Patterns in Action

### Coordinator (Flow Control)
- **Owns navigation rules**: Where to go after submit?
- **Supports conditional flows**: A/B tests, feature flags, auth state
- **Handles responses**: MFA required, profile incomplete, upgrade needed

### MVVM (State Projection)
```swift
final class FormViewModel: ObservableObject {
    @Published private(set) var formState: FormState
    @Published private(set) var fieldErrors: [FieldID: String] = [:]
    @Published private(set) var isSubmitting = false

    struct FormState {
        var fields: [FieldID: FieldState]
        var visibleFields: Set<FieldID>
        var enabledFields: Set<FieldID>
    }

    struct FieldState {
        var value: String
        var isValid: Bool
        var error: String?
        var isFocused: Bool
    }

    func updateField(_ fieldID: FieldID, value: String) {
        formState.fields[fieldID]?.value = value

        // Live validation if enabled
        if schema.validation == .live {
            validateField(fieldID)
        }

        // Update visibility of dependent fields
        updateVisibility()
    }

    func submit() async {
        guard validateAll() else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let rawValues = formState.fields.mapValues { $0.value }
            let domainModel = try mapping.map(from: rawValues)
            let response = try await submitUseCase.execute(domainModel)
            coordinator.formDidSubmit(result: .success(response: response))
        } catch {
            coordinator.formDidSubmit(result: .failure(error: error))
        }
    }
}
```

### Strategy (Behavior Swapping)

**ValidationStrategy**:
```swift
protocol ValidationStrategy {
    func validate(field: FormField, value: String) -> ValidationResult
}

struct StrictValidationStrategy: ValidationStrategy {
    func validate(field: FormField, value: String) -> ValidationResult {
        // All rules enforced, no warnings
    }
}

struct LenientValidationStrategy: ValidationStrategy {
    func validate(field: FormField, value: String) -> ValidationResult {
        // Some rules as warnings instead of errors
    }
}
```

**FormattingStrategy**:
```swift
protocol FormattingStrategy {
    func format(value: String, for field: FormField) -> String
}

struct PhoneFormattingStrategy: FormattingStrategy {
    let locale: Locale

    func format(value: String, for field: FormField) -> String {
        // Format based on locale
        // US: (555) 123-4567
        // UK: 020 7123 4567
    }
}
```

### Adapter (System Integration)
```swift
// Keychain adapter for secure draft storage
protocol SecureFieldStorage {
    func save(fieldID: FieldID, value: String) throws
    func retrieve(fieldID: FieldID) throws -> String?
    func clear(fieldID: FieldID) throws
}

final class KeychainFieldStorageAdapter: SecureFieldStorage {
    private let keychain: KeychainWrapper

    func save(fieldID: FieldID, value: String) throws {
        try keychain.set(value, forKey: fieldID.rawValue)
    }
}

// Date/Number parsing adapter
protocol ValueParsingAdapter {
    func parseDate(_ string: String) -> Date?
    func parseNumber(_ string: String) -> Decimal?
}
```

### Facade (Simple Surface)
```swift
final class FormEngine {
    private let renderer: FormRenderer
    private let validator: FormValidator
    private let mapper: AnyFieldMapping
    private let coordinator: FormFlowCoordinator

    // Simple API
    func render(schema: FormSchema) {
        renderer.render(schema)
    }

    func update(field: FieldID, value: String) {
        validator.validate(field: field, value: value)
        renderer.update(field: field, value: value)
    }

    func submit() async {
        let rawValues = renderer.currentValues()

        guard validator.validateAll(rawValues) else {
            renderer.showErrors(validator.errors)
            return
        }

        do {
            let model = try mapper.map(from: rawValues)
            let response = try await submitForm(model)
            coordinator.formDidSubmit(result: .success(response: response))
        } catch {
            coordinator.formDidSubmit(result: .failure(error: error))
        }
    }
}
```

---

## 3) Practical Pipeline: UI → Domain

**Step-by-step flow**:

```
1. Schema → Renderer
   FormSchema → FormRenderer → UIKit/SwiftUI views

2. User Input → Raw Values
   User types "  Test@Email.COM  "
   → Stored as raw: "  Test@Email.COM  "

3. On Submit → Normalize
   Raw: "  Test@Email.COM  "
   → Trim: "Test@Email.COM"
   → Lowercase: "test@email.com"

4. Validate
   "test@email.com" → ValidationRule.email → ✅ Valid

5. Map to Domain
   [.email: "test@email.com", .password: "secret123"]
   → LoginCredentials(email: "test@email.com", password: "secret123")

6. Use Case
   LoginUseCase.execute(credentials)
   → Result<User, AuthError>

7. Coordinator Routes
   Success → MainCoordinator
   MFA Required → MFACoordinator
   Error → Show error
```

**Senior Rule**: Keep UI raw values separate from parsed domain values.
- Raw input is for UX (what the user typed)
- Parsed is for correctness (what the system understands)

---

## 4) How This Manipulates UX

### A) Progressive Disclosure
**Show fields only when needed**:

```swift
// Schema with conditional visibility
FormField(
    id: .companyName,
    label: "Company Name",
    type: .text,
    required: true,
    visibilityRule: .whenFieldEquals(.accountType, "Business")
)

// ViewModel evaluates rules
func updateVisibility() {
    for field in schema.fields {
        let isVisible = evaluateVisibilityRule(field.visibilityRule)
        formState.visibleFields.insert(field.id) // or remove
    }
}
```

**UX Effect**: Fewer fields, faster completion, less overwhelming.

### B) Inline Validation
**Control when and how validation runs**:

```swift
enum ValidationMode {
    case onSubmit       // Validate only on submit
    case live           // Validate on every change
    case onBlur         // Validate when field loses focus
    case hybrid         // Lenient live, strict on submit
}

enum ValidationSeverity {
    case error          // Blocks submission
    case warning        // Shows but allows submission
    case hint           // Informational only
}
```

**UX Effect**: Fewer "submit → big error page" moments, instant feedback.

### C) Smart Defaults & Autofill
```swift
protocol AutofillStrategy {
    func prefillValues(for schema: FormSchema) -> [FieldID: String]
}

struct ProfileCacheAutofillStrategy: AutofillStrategy {
    let cache: ProfileCache

    func prefillValues(for schema: FormSchema) -> [FieldID: String] {
        guard let profile = cache.lastUsedProfile else {
            return [:]
        }

        return [
            .email: profile.email,
            .name: profile.name,
            .phone: profile.phone ?? ""
        ]
    }
}
```

**UX Effect**: Dramatically reduces friction, feels personalized.

### D) Field-to-Field Behavior
**One field drives another**:

```swift
func updateField(_ fieldID: FieldID, value: String) {
    formState.fields[fieldID]?.value = value

    // Trigger side effects
    switch fieldID {
    case .postalCode:
        lookupCityAndState(postalCode: value)

    case .country:
        updatePhoneFormatting(country: value)

    case .accountType:
        updateVisibility() // Show/hide company field
    }
}
```

**UX Effect**: Feels "magical" but deterministic and testable.

### E) Flow Branching
**Coordinator decides next screen based on response**:

```swift
func formDidSubmit(result: FormSubmissionResult) {
    switch result {
    case .success(.requiresMFA(let method)):
        // Server says "MFA required"
        showMFAScreen(method: method)

    case .success(.requiresAdditionalInfo(let schema)):
        // Profile incomplete
        showAdditionalInfoForm(schema: schema)

    case .success(.requiresUpgrade):
        // Guest user, needs upgrade
        showUpgradeScreen()

    case .success(.completed):
        // All done
        navigateToMain()
    }
}
```

**UX Effect**: Personalized flows without spaghetti code.

### F) Accessibility as First-Class Data
```swift
FormField(
    id: .email,
    label: "Email",
    accessibilityLabel: "Email address",
    accessibilityHint: "Enter your email address for login",
    autoFillType: .emailAddress,
    keyboardType: .emailAddress,
    returnKeyType: .next,
    focusOrder: 1
)
```

**UX Effect**: Consistent accessibility, proper keyboard navigation, VoiceOver support.

---

## 5) Minimal "Ultimate" Components

### Domain Layer
```swift
// Schema definition (pure data)
struct FormSchema { }
struct FormField { }
struct FormSection { }

// Field identity (stable)
enum FieldID: String, Hashable { }

// Validation rules
enum ValidationRule {
    case required
    case email
    case minLength(Int)
    case maxLength(Int)
    case matches(FieldID)
    case regex(String)
    case custom((String) -> Bool)
}

// Field mapping protocol
protocol FieldMapping {
    associatedtype DomainModel
    func map(from: [FieldID: String]) throws -> DomainModel
}

// Use case
protocol SubmitFormUseCase {
    func execute<T>(_ model: T) async throws -> FormResponse
}
```

### Data Layer
```swift
// Form endpoint client
protocol FormSubmissionClient {
    func submit(endpoint: String, data: Data) async throws -> FormResponse
}

// Draft storage (optional)
protocol DraftStorage {
    func saveDraft(formID: String, values: [FieldID: String]) throws
    func loadDraft(formID: String) throws -> [FieldID: String]?
    func clearDraft(formID: String) throws
}

// Secure field storage (Keychain for sensitive fields)
protocol SecureFieldStorage {
    func save(fieldID: FieldID, value: String) throws
    func retrieve(fieldID: FieldID) throws -> String?
}
```

### Presentation Layer
```swift
// ViewModel
final class FormViewModel: ObservableObject {
    @Published var formState: FormState
    @Published var fieldErrors: [FieldID: String]
    @Published var isSubmitting: Bool

    func updateField(_ fieldID: FieldID, value: String)
    func validateField(_ fieldID: FieldID) -> Bool
    func submit() async
}

// Renderer (UIKit and SwiftUI versions)
protocol FormRenderer {
    func render(schema: FormSchema)
    func update(field: FieldID, value: String)
    func showErrors(_ errors: [FieldID: String])
    func setLoading(_ isLoading: Bool)
}

final class UIKitFormRenderer: FormRenderer { }
final class SwiftUIFormRenderer: FormRenderer { }

// Coordinator
protocol FormFlowCoordinator: AnyObject {
    func formDidSubmit(result: FormSubmissionResult)
    func formDidCancel()
}
```

---

## 6) Tests That Prove It Works

### Unit Tests (Highest Value)

**Mapping Tests**:
```swift
func testLoginCredentialsMapping_normalizesEmail() throws {
    let mapping = LoginCredentialsMapping()
    let raw: [FieldID: String] = [
        .email: "  Test@Email.COM  ",
        .password: "secret123"
    ]

    let credentials = try mapping.map(from: raw)

    XCTAssertEqual(credentials.email, "test@email.com")
}

func testUserProfileMapping_stripsPhoneFormatting() throws {
    let mapping = UserProfileMapping()
    let raw: [FieldID: String] = [
        .name: "John Doe",
        .email: "john@example.com",
        .phone: "(555) 123-4567"
    ]

    let profile = try mapping.map(from: raw)

    XCTAssertEqual(profile.phone, "+15551234567")
}
```

**Validation Tests**:
```swift
func testEmailValidation_rejectsInvalidEmail() {
    let rule = ValidationRule.email
    let result = rule.validate("not-an-email")

    XCTAssertFalse(result.isValid)
    XCTAssertEqual(result.error, "Invalid email address")
}

func testPasswordMatch_detectsMismatch() {
    let rule = ValidationRule.matches(.password)
    let values: [FieldID: String] = [
        .password: "secret123",
        .confirmPassword: "secret456"
    ]

    let result = rule.validate(values[.confirmPassword]!, context: values)

    XCTAssertFalse(result.isValid)
}
```

**Visibility/Dependency Tests**:
```swift
func testProgressiveDisclosure_showsCompanyFieldWhenBusiness() {
    let schema = FormSchema.signup
    let viewModel = FormViewModel(schema: schema, /* ... */)

    // Set account type to Business
    viewModel.updateField(.accountType, value: "Business")

    // Company name field should be visible
    XCTAssertTrue(viewModel.formState.visibleFields.contains(.companyName))
}

func testProgressiveDisclosure_hidesCompanyFieldWhenPersonal() {
    let schema = FormSchema.signup
    let viewModel = FormViewModel(schema: schema, /* ... */)

    // Set account type to Personal
    viewModel.updateField(.accountType, value: "Personal")

    // Company name field should NOT be visible
    XCTAssertFalse(viewModel.formState.visibleFields.contains(.companyName))
}
```

**Flow Routing Tests**:
```swift
func testFormCoordinator_whenMFARequired_showsMFAScreen() {
    let coordinator = SpyFormCoordinator()
    let response = FormResponse.requiresMFA(method: .sms)

    coordinator.formDidSubmit(result: .success(response: response))

    XCTAssertEqual(coordinator.lastRoute, .mfa(method: .sms))
}

func testFormCoordinator_whenCompleted_navigatesToMain() {
    let coordinator = SpyFormCoordinator()
    let response = FormResponse.completed

    coordinator.formDidSubmit(result: .success(response: response))

    XCTAssertEqual(coordinator.lastRoute, .success)
}
```

**Draft Persistence Tests**:
```swift
func testDraftStorage_savesAndRestoresValues() throws {
    let storage = InMemoryDraftStorage()
    let values: [FieldID: String] = [
        .email: "test@example.com",
        .name: "John Doe"
    ]

    try storage.saveDraft(formID: "signup", values: values)
    let restored = try storage.loadDraft(formID: "signup")

    XCTAssertEqual(restored, values)
}
```

### Integration Tests

**Submission with URLProtocol Stub**:
```swift
func testFormSubmission_sendsCorrectJSON() async throws {
    let stubClient = StubHTTPClient()
    let mapping = LoginCredentialsMapping()
    let useCase = DefaultSubmitFormUseCase(
        client: stubClient,
        endpoint: "/auth/login"
    )

    let raw: [FieldID: String] = [
        .email: "test@example.com",
        .password: "secret123"
    ]
    let credentials = try mapping.map(from: raw)

    _ = try await useCase.execute(credentials)

    // Verify JSON structure
    let sentJSON = stubClient.lastRequestBody as? [String: String]
    XCTAssertEqual(sentJSON?["email"], "test@example.com")
    XCTAssertEqual(sentJSON?["password"], "secret123")
}
```

### UI Tests (Minimal)

**Field Visibility Test**:
```swift
func testProgressiveDisclosure_UI() {
    let app = XCUIApplication()
    app.launch()

    // Select Business account type
    app.pickers["accountTypePicker"].adjust(toPickerWheelValue: "Business")

    // Company name field should appear
    XCTAssertTrue(app.textFields["companyNameField"].exists)

    // Select Personal account type
    app.pickers["accountTypePicker"].adjust(toPickerWheelValue: "Personal")

    // Company name field should disappear
    XCTAssertFalse(app.textFields["companyNameField"].exists)
}
```

---

## 7) Shell App Implementation

### "Sandbox" Feature Module

The Shell demonstrates the Form Engine through a **Sandbox** feature:

**Screen 1: Dynamic Form Playground**
```swift
final class FormSandboxViewController: UIViewController {
    private let viewModel: FormSandboxViewModel

    // User can choose a schema
    private let schemaSelector: UISegmentedControl

    // Available schemas
    enum SandboxSchema: String, CaseIterable {
        case login = "Login"
        case signup = "Signup"
        case profile = "Profile"
        case payment = "Payment (Fake)"
    }

    func schemaSelected(_ schema: SandboxSchema) {
        let formSchema: FormSchema

        switch schema {
        case .login:
            formSchema = .login
        case .signup:
            formSchema = .signup
        case .profile:
            formSchema = .profile
        case .payment:
            formSchema = .fakePayment
        }

        viewModel.loadSchema(formSchema)
    }
}
```

**Screen 2: Review / Confirmation**
```swift
final class FormReviewViewController: UIViewController {
    // Shows the mapped output (sanitized)

    func displayMappedValues(_ values: [String: Any]) {
        // Show domain model as JSON (for demo)
        // Sanitize sensitive fields (passwords hidden)
        let sanitized = values.filter { $0.key != "password" }
        displayJSON(sanitized)
    }
}
```

**Debug Menu**:
```swift
final class FormDebugMenuViewController: UIViewController {
    // Toggle strict validation
    @IBAction func toggleStrictValidation() {
        formEngine.setValidationMode(isStrict ? .strict : .lenient)
    }

    // Simulate offline mode
    @IBAction func simulateOfflineMode() {
        networkSimulator.setOffline(true)
    }

    // Inject server errors
    @IBAction func injectServerError() {
        apiSimulator.setNextResponse(.error(.serverError))
    }

    // Clear all drafts
    @IBAction func clearAllDrafts() {
        draftStorage.clearAll()
    }
}
```

---

## Benefits for the Shell Starter Kit

### 1. Demonstrates All Patterns
- ✅ Coordinator (flow control)
- ✅ MVVM (state projection)
- ✅ Strategy (validation, formatting, autofill)
- ✅ Adapter (keychain, parsing, formatting)
- ✅ Facade (FormEngine simple API)
- ✅ Mapping (DTO ↔ Domain)

### 2. Highly Testable
- ✅ Mapping tests (raw → domain)
- ✅ Validation tests (rules, cross-field)
- ✅ Visibility tests (progressive disclosure)
- ✅ Flow tests (coordinator routing)
- ✅ Integration tests (submission)
- ✅ UI tests (field behavior)

### 3. Feature-Agnostic
- Not tied to Notes, Tasks, or any domain
- Works for ANY form-based flow
- Drop in real features later

### 4. Practical & Reusable
- Real problem: every app needs forms
- Solves it once, correctly
- Extensible for any schema

### 5. Proves Senior Skills
- Schema-driven architecture
- Dynamic UI generation
- Smart UX manipulation
- Production-ready patterns
- Complete test coverage

---

## Implementation Order

### Phase 1: Core Schema System
- FormSchema data structures
- FieldID enum
- ValidationRule enum
- Basic mapping protocol

### Phase 2: Form Engine
- FormViewModel (MVVM)
- FormRenderer (UIKit version)
- Simple form rendering

### Phase 3: Validation
- ValidationStrategy
- Field validation
- Cross-field validation
- Error messaging

### Phase 4: Mapping & Submission
- FieldMapping implementations
- SubmitFormUseCase
- HTTPClient integration

### Phase 5: Advanced Features
- Progressive disclosure (visibility rules)
- Field-to-field behavior
- Draft storage
- Autofill

### Phase 6: Flow Coordination
- FormFlowCoordinator
- Response-based routing
- MFA flow
- Additional info flow

### Phase 7: Sandbox UI
- Schema selector
- Dynamic form display
- Review screen
- Debug menu

---

## Success Criteria

The Schema-Driven UX succeeds when:

1. ✅ Any form can be defined in < 50 lines of schema
2. ✅ Adding a new form requires ZERO new UI code
3. ✅ All validation logic is reusable and testable
4. ✅ Flow routing is data-driven, not hardcoded
5. ✅ UX improvements (autofill, smart defaults) work for ALL forms
6. ✅ Every component is unit tested
7. ✅ Engineers understand it in 30 minutes

**This is the killer feature. Schema-driven UX proves ultimate starter kit status.**
