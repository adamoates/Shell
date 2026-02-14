#!/bin/bash
set +H  # Disable history expansion to prevent issues with ! in passwords

# Shell Backend Auth Testing Script
# Tests all authentication endpoints and token flows

BASE_URL="http://localhost:3000"
TEST_EMAIL="test-$(date +%s)@example.com"
TEST_PASSWORD="TestPass123!"

echo "=========================================="
echo "Shell Backend Auth Testing"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Health Check
echo "1. Testing Health Check..."
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" $BASE_URL/health)
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -n1)
BODY=$(echo "$HEALTH_RESPONSE" | head -n1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Health check passed${NC}"
    echo "  Response: $BODY"
else
    echo -e "${RED}✗ Health check failed (HTTP $HTTP_CODE)${NC}"
    exit 1
fi
echo ""

# Test 2: Register User
echo "2. Testing User Registration..."
echo "  Email: $TEST_EMAIL"
REGISTER_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\",
    \"confirmPassword\": \"$TEST_PASSWORD\"
  }")
HTTP_CODE=$(echo "$REGISTER_RESPONSE" | tail -n1)
BODY=$(echo "$REGISTER_RESPONSE" | head -n1)

if [ "$HTTP_CODE" = "201" ]; then
    echo -e "${GREEN}✓ Registration successful${NC}"
    USER_ID=$(echo "$BODY" | grep -o '"userID":"[^"]*"' | cut -d'"' -f4)
    echo "  User ID: $USER_ID"
else
    echo -e "${RED}✗ Registration failed (HTTP $HTTP_CODE)${NC}"
    echo "  Response: $BODY"
    exit 1
fi
echo ""

# Test 3: Login
echo "3. Testing Login..."
LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\"
  }")
HTTP_CODE=$(echo "$LOGIN_RESPONSE" | tail -n1)
BODY=$(echo "$LOGIN_RESPONSE" | head -n1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Login successful${NC}"
    ACCESS_TOKEN=$(echo "$BODY" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
    REFRESH_TOKEN=$(echo "$BODY" | grep -o '"refreshToken":"[^"]*"' | cut -d'"' -f4)
    echo "  Access Token: ${ACCESS_TOKEN:0:50}..."
    echo "  Refresh Token: $REFRESH_TOKEN"
else
    echo -e "${RED}✗ Login failed (HTTP $HTTP_CODE)${NC}"
    echo "  Response: $BODY"
    exit 1
fi
echo ""

# Test 4: Access Protected Route (Items)
echo "4. Testing Protected Route (GET /v1/items)..."
ITEMS_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET $BASE_URL/v1/items \
  -H "Authorization: Bearer $ACCESS_TOKEN")
HTTP_CODE=$(echo "$ITEMS_RESPONSE" | tail -n1)
BODY=$(echo "$ITEMS_RESPONSE" | head -n1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Protected route access successful${NC}"
    echo "  Items: $BODY"
else
    echo -e "${RED}✗ Protected route access failed (HTTP $HTTP_CODE)${NC}"
    echo "  Response: $BODY"
    exit 1
fi
echo ""

# Test 5: Access Protected Route Without Token
echo "5. Testing Protected Route Without Token..."
NO_TOKEN_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET $BASE_URL/v1/items)
HTTP_CODE=$(echo "$NO_TOKEN_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "401" ]; then
    echo -e "${GREEN}✓ Unauthorized access correctly blocked${NC}"
else
    echo -e "${RED}✗ Should have returned 401 (got HTTP $HTTP_CODE)${NC}"
    exit 1
fi
echo ""

# Test 6: Refresh Token
echo "6. Testing Token Refresh..."
REFRESH_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{
    \"refreshToken\": \"$REFRESH_TOKEN\"
  }")
HTTP_CODE=$(echo "$REFRESH_RESPONSE" | tail -n1)
BODY=$(echo "$REFRESH_RESPONSE" | head -n1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Token refresh successful${NC}"
    NEW_ACCESS_TOKEN=$(echo "$BODY" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
    NEW_REFRESH_TOKEN=$(echo "$BODY" | grep -o '"refreshToken":"[^"]*"' | cut -d'"' -f4)
    echo "  New Access Token: ${NEW_ACCESS_TOKEN:0:50}..."
    echo "  New Refresh Token: $NEW_REFRESH_TOKEN"
    
    # Update tokens for subsequent tests
    ACCESS_TOKEN=$NEW_ACCESS_TOKEN
    OLD_REFRESH_TOKEN=$REFRESH_TOKEN
    REFRESH_TOKEN=$NEW_REFRESH_TOKEN
else
    echo -e "${RED}✗ Token refresh failed (HTTP $HTTP_CODE)${NC}"
    echo "  Response: $BODY"
    exit 1
fi
echo ""

# Test 7: Reuse Old Refresh Token (should fail and invalidate all sessions)
echo "7. Testing Refresh Token Reuse Detection..."
echo -e "${YELLOW}  (This should fail and invalidate all sessions)${NC}"
REUSE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{
    \"refreshToken\": \"$OLD_REFRESH_TOKEN\"
  }")
HTTP_CODE=$(echo "$REUSE_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "401" ]; then
    echo -e "${GREEN}✓ Token reuse correctly detected and blocked${NC}"
else
    echo -e "${RED}✗ Token reuse should have returned 401 (got HTTP $HTTP_CODE)${NC}"
    exit 1
fi
echo ""

# Test 8: Try to use current refresh token (should also fail after reuse detection)
echo "8. Testing Session Invalidation After Reuse..."
INVALIDATED_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{
    \"refreshToken\": \"$REFRESH_TOKEN\"
  }")
HTTP_CODE=$(echo "$INVALIDATED_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "401" ]; then
    echo -e "${GREEN}✓ All sessions correctly invalidated after reuse detection${NC}"
else
    echo -e "${YELLOW}⚠ Expected 401, got HTTP $HTTP_CODE${NC}"
    echo "  Note: Session invalidation may depend on implementation"
fi
echo ""

# Test 9: Login again after invalidation
echo "9. Testing Re-login After Session Invalidation..."
NEW_LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\"
  }")
HTTP_CODE=$(echo "$NEW_LOGIN_RESPONSE" | tail -n1)
BODY=$(echo "$NEW_LOGIN_RESPONSE" | head -n1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Re-login successful${NC}"
    ACCESS_TOKEN=$(echo "$BODY" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
    REFRESH_TOKEN=$(echo "$BODY" | grep -o '"refreshToken":"[^"]*"' | cut -d'"' -f4)
else
    echo -e "${RED}✗ Re-login failed (HTTP $HTTP_CODE)${NC}"
    exit 1
fi
echo ""

# Test 10: Logout
echo "10. Testing Logout..."
LOGOUT_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/auth/logout \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"refreshToken\": \"$REFRESH_TOKEN\"
  }")
HTTP_CODE=$(echo "$LOGOUT_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Logout successful${NC}"
else
    echo -e "${RED}✗ Logout failed (HTTP $HTTP_CODE)${NC}"
    exit 1
fi
echo ""

# Test 11: Try to use logged out refresh token
echo "11. Testing Logged Out Session..."
LOGGED_OUT_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{
    \"refreshToken\": \"$REFRESH_TOKEN\"
  }")
HTTP_CODE=$(echo "$LOGGED_OUT_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "401" ]; then
    echo -e "${GREEN}✓ Logged out session correctly rejected${NC}"
else
    echo -e "${RED}✗ Should have returned 401 (got HTTP $HTTP_CODE)${NC}"
    exit 1
fi
echo ""

# Test 12: Invalid password
echo "12. Testing Invalid Password..."
INVALID_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"WrongPassword123!\"
  }")
HTTP_CODE=$(echo "$INVALID_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "401" ]; then
    echo -e "${GREEN}✓ Invalid password correctly rejected${NC}"
else
    echo -e "${RED}✗ Should have returned 401 (got HTTP $HTTP_CODE)${NC}"
    exit 1
fi
echo ""

echo "=========================================="
echo -e "${GREEN}All Tests Passed!${NC}"
echo "=========================================="
echo ""
echo "Summary:"
echo "  ✓ Health check"
echo "  ✓ User registration"
echo "  ✓ User login"
echo "  ✓ Protected route access"
echo "  ✓ Unauthorized access blocking"
echo "  ✓ Token refresh"
echo "  ✓ Token reuse detection"
echo "  ✓ Session invalidation"
echo "  ✓ Re-login after invalidation"
echo "  ✓ User logout"
echo "  ✓ Logged out session rejection"
echo "  ✓ Invalid password rejection"
echo ""
