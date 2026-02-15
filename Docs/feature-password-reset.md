# Feature: Password Reset (Mailgun)

## 1. Backend (Node/Express)
- **Library:** Use `form-data` and `mailgun.js` (Official SDK).
- **Env Vars:** Require `MAILGUN_API_KEY`, `MAILGUN_DOMAIN`, and `FROM_EMAIL`.
- **Endpoints:**
  1. `POST /auth/forgot-password`:
     - Input: `{ "email": "user@example.com" }`
     - Action: Generate crypto token (1hr expiry), save hash to DB, send email via Mailgun.
     - Email Content: Must contain Deep Link `shell://reset-password?token=...`
     - Response (200): `{ "message": "Password reset email sent" }`
     - Error (404): `{ "error": "not_found", "message": "Email not found" }`
     - Error (429): `{ "error": "rate_limit_exceeded", "message": "Too many reset attempts" }`
  2. `POST /auth/reset-password`:
     - Input: `{ "token": "...", "newPassword": "SecurePass123@" }`
     - Action: Validate token, hash new password (Argon2id), invalidate token.
     - Response (200): `{ "message": "Password reset successful" }`
     - Error (400): `{ "error": "invalid_token", "message": "Token is invalid or expired" }`
     - Error (400): `{ "error": "weak_password", "message": "Password does not meet requirements" }`

## 2. iOS Client (Shell App)
- **Deep Link:** Update `SceneDelegate` to handle `shell://reset-password?token=...`.
- **UI:** Connect `forgotPasswordButton` in `LoginViewController`.
- **Screens:** Create `ResetPasswordViewController` (New password input + confirmation).
- **Flow:**
  1. User taps "Forgot Password?" → Shows email input alert
  2. User enters email → Calls `POST /auth/forgot-password`
  3. User receives email → Taps deep link in email
  4. App opens to `ResetPasswordViewController` with token
  5. User enters new password + confirmation → Calls `POST /auth/reset-password`
  6. Success → Returns to login screen with success message

## 3. Database Schema
Add to existing `users` table:
```sql
ALTER TABLE users ADD COLUMN reset_token_hash VARCHAR(255);
ALTER TABLE users ADD COLUMN reset_token_expires_at TIMESTAMP;
```

## 4. Security Requirements
- **Token Generation:** Use `crypto.randomBytes(32)` for token generation
- **Token Storage:** Store SHA-256 hash of token in database (never plaintext)
- **Token Expiry:** 1 hour from generation
- **Rate Limiting:** Max 3 reset attempts per email per 15 minutes
- **Email Validation:** Must match existing user in database
- **Password Requirements:** Same as registration (min 8 chars, 1 uppercase, 1 number, 1 special char)
- **Token Invalidation:** Single-use tokens (invalidate after successful reset)

## 5. Email Template
**Subject:** Reset Your Shell Password

**Body:**
```
Hello,

You requested to reset your password for your Shell account.

Tap the link below to reset your password:
shell://reset-password?token={TOKEN}

This link will expire in 1 hour.

If you didn't request this, please ignore this email.

Thanks,
The Shell Team
```

## 6. Verification Checklist
- [ ] Backend: Mailgun integration working (check logs for 200 OK)
- [ ] Backend: Token generation and storage (check DB for hashed token)
- [ ] Backend: Token expiry validation (test with expired token)
- [ ] Backend: Rate limiting (test 4 consecutive requests)
- [ ] iOS: Deep link handling (test with `xcrun simctl openurl`)
- [ ] iOS: ResetPasswordViewController displays correctly
- [ ] iOS: Password validation (test weak password)
- [ ] iOS: Success flow (reset → login with new password)
- [ ] iOS: Error handling (invalid token, expired token, network errors)

## 7. Testing Commands

### Backend Health Check
```bash
curl http://localhost:3000/health
```

### Test Forgot Password
```bash
curl -X POST http://localhost:3000/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'
```

### Test Reset Password
```bash
curl -X POST http://localhost:3000/auth/reset-password \
  -H "Content-Type: application/json" \
  -d '{"token":"test-token-here","newPassword":"NewPass123@"}'
```

### Test Deep Link (iOS Simulator)
```bash
xcrun simctl openurl booted "shell://reset-password?token=test-token"
```

### Check Backend Logs
```bash
cd backend && docker compose logs -f backend
```

## 8. Environment Variables Required

Backend `.env` file must include:
```
MAILGUN_API_KEY=your-mailgun-api-key
MAILGUN_DOMAIN=your-domain.mailgun.org
FROM_EMAIL=noreply@your-domain.com
```

## 9. Dependencies

### Backend
- `mailgun.js` - Official Mailgun SDK
- `form-data` - Required for Mailgun SDK

### iOS
- No new dependencies (uses existing URLSession)

## 10. Error Scenarios to Handle

**Backend:**
- Email not found in database → 404 Not Found
- Mailgun API failure → Log error, return 500 (but don't expose Mailgun error to client)
- Invalid token format → 400 Bad Request
- Expired token → 400 Bad Request (with clear message)
- Token already used → 400 Bad Request
- Weak password → 400 Bad Request

**iOS:**
- Network failure → Show retry button
- Invalid deep link format → Show error alert
- Token expired → Show alert with option to request new reset
- Mailgun rate limit → Show appropriate message

## 11. Privacy & Compliance

- Do not reveal whether email exists in database (return same message for existing/non-existing emails to prevent email enumeration)
- Log all password reset attempts to `auth_logs` table for audit trail
- Clear reset token from database after successful reset
- Never log plaintext tokens or passwords

## 12. Future Enhancements (Out of Scope)

- Email templates with HTML formatting
- Multiple email providers (SendGrid, AWS SES)
- SMS-based password reset
- Magic link authentication (passwordless)
- Account recovery with security questions
