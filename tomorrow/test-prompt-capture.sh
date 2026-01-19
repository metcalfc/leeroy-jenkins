#!/usr/bin/env bash
# Test script for automatic prompt capture

set -euo pipefail

echo "🧪 Testing Automatic Prompt Capture"
echo ""

# Clear any existing session
./hooks/session-tracker.sh clear 2>/dev/null || true

# Test 1: JSON with .text field
echo "Test 1: Capturing prompt with .text field"
echo '{"text": "fix the authentication bug"}' | ./hooks/capture-prompt.sh
result=$(./hooks/session-tracker.sh get | jq -r '.prompts[-1].text')
if [[ "$result" == "fix the authentication bug" ]]; then
    echo "✓ Test 1 passed"
else
    echo "✗ Test 1 failed: expected 'fix the authentication bug', got '$result'"
    exit 1
fi

# Test 2: JSON with .message field
echo "Test 2: Capturing prompt with .message field"
echo '{"message": "add unit tests"}' | ./hooks/capture-prompt.sh
result=$(./hooks/session-tracker.sh get | jq -r '.prompts[-1].text')
if [[ "$result" == "add unit tests" ]]; then
    echo "✓ Test 2 passed"
else
    echo "✗ Test 2 failed: expected 'add unit tests', got '$result'"
    exit 1
fi

# Test 3: JSON with .content field
echo "Test 3: Capturing prompt with .content field"
echo '{"content": "refactor the parser module"}' | ./hooks/capture-prompt.sh
result=$(./hooks/session-tracker.sh get | jq -r '.prompts[-1].text')
if [[ "$result" == "refactor the parser module" ]]; then
    echo "✓ Test 3 passed"
else
    echo "✗ Test 3 failed: expected 'refactor the parser module', got '$result'"
    exit 1
fi

# Test 4: Invalid JSON (should not log)
echo "Test 4: Gracefully handling invalid JSON"
prompt_count_before=$(./hooks/session-tracker.sh get | jq '.prompts | length')
echo '{"irrelevant": "data"}' | ./hooks/capture-prompt.sh
prompt_count_after=$(./hooks/session-tracker.sh get | jq '.prompts | length')
if [[ "$prompt_count_before" == "$prompt_count_after" ]]; then
    echo "✓ Test 4 passed (no prompt logged)"
else
    echo "✗ Test 4 failed: prompt count changed"
    exit 1
fi

# Clean up
./hooks/session-tracker.sh clear

echo ""
echo "✅ All tests passed!"
echo ""
echo "The automatic prompt capture feature is working correctly."
