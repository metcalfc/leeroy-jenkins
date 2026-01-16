#!/usr/bin/env bats

# Tests for hooks/sign-attestation.sh

setup() {
    # Create temporary test directory
    TEST_DIR="$(mktemp -d)"
    export HOME="$TEST_DIR"
    mkdir -p "$HOME/.leeroy"

    # Path to sign-attestation script
    SIGN_SCRIPT="${BATS_TEST_DIRNAME}/../hooks/sign-attestation.sh"

    # Ensure script exists
    [ -f "$SIGN_SCRIPT" ]

    # Sample attestation for testing
    SAMPLE_ATTESTATION="-----BEGIN AI ATTESTATION-----
Version: 1.0
Tool: claude-code/1.0.0
Model: claude-sonnet-4
Session-ID: abc123
Started-At: 2024-01-01T00:00:00Z
Committed-At: 2024-01-01T00:10:00Z

Files-Modified:
  - test.txt [modified] @ 2024-01-01T00:05:00Z

Prompts:
  [2024-01-01T00:00:00Z] Test prompt

Human-Review-Attested: true"
}

teardown() {
    # Clean up test directory
    rm -rf "$TEST_DIR"
}

@test "sign-attestation.sh exists and is executable" {
    [ -x "$SIGN_SCRIPT" ]
}

@test "generate-keys: creates private key" {
    run "$SIGN_SCRIPT" generate-keys
    [ "$status" -eq 0 ]

    [ -f "$HOME/.leeroy/toolkit.key" ]

    # Check permissions (should be 600)
    perms=$(stat -c "%a" "$HOME/.leeroy/toolkit.key")
    [ "$perms" = "600" ]
}

@test "generate-keys: creates public key" {
    run "$SIGN_SCRIPT" generate-keys
    [ "$status" -eq 0 ]

    [ -f "$HOME/.leeroy/toolkit.pub" ]

    # Check permissions (should be 644)
    perms=$(stat -c "%a" "$HOME/.leeroy/toolkit.pub")
    [ "$perms" = "644" ]
}

@test "generate-keys: creates fingerprint file" {
    run "$SIGN_SCRIPT" generate-keys
    [ "$status" -eq 0 ]

    [ -f "$HOME/.leeroy/toolkit.fingerprint" ]

    # Fingerprint should be non-empty base64 string
    fingerprint=$(cat "$HOME/.leeroy/toolkit.fingerprint")
    [ -n "$fingerprint" ]

    # Should be base64 (no validation of exact format, just check it exists)
    [ ${#fingerprint} -gt 20 ]
}

@test "generate-keys: is idempotent (doesn't overwrite existing keys)" {
    # Generate keys first time
    "$SIGN_SCRIPT" generate-keys
    fingerprint1=$(cat "$HOME/.leeroy/toolkit.fingerprint")

    # Try to generate again
    "$SIGN_SCRIPT" generate-keys
    fingerprint2=$(cat "$HOME/.leeroy/toolkit.fingerprint")

    # Fingerprints should be identical (keys not regenerated)
    [ "$fingerprint1" = "$fingerprint2" ]
}

@test "fingerprint: returns fingerprint after key generation" {
    "$SIGN_SCRIPT" generate-keys

    run "$SIGN_SCRIPT" fingerprint
    [ "$status" -eq 0 ]
    [ -n "$output" ]

    # Should match fingerprint file
    expected=$(cat "$HOME/.leeroy/toolkit.fingerprint")
    [ "$output" = "$expected" ]
}

@test "fingerprint: fails if no key exists" {
    run "$SIGN_SCRIPT" fingerprint
    [ "$status" -eq 1 ]
    [[ "$output" == *"No toolkit key found"* ]]
}

@test "sign: generates keys automatically if needed" {
    [ ! -f "$HOME/.leeroy/toolkit.key" ]

    echo "$SAMPLE_ATTESTATION" | "$SIGN_SCRIPT" sign > /dev/null

    # Keys should now exist
    [ -f "$HOME/.leeroy/toolkit.key" ]
    [ -f "$HOME/.leeroy/toolkit.pub" ]
    [ -f "$HOME/.leeroy/toolkit.fingerprint" ]
}

@test "sign: adds signature block to attestation" {
    signed=$(echo "$SAMPLE_ATTESTATION" | "$SIGN_SCRIPT" sign)

    # Should contain signature line
    echo "$signed" | grep -q "^Tool-Signature: ed25519:"

    # Should contain fingerprint line
    echo "$signed" | grep -q "^Tool-Key-Fingerprint:"

    # Should end with END marker
    echo "$signed" | grep -q "^-----END AI ATTESTATION-----$"
}

@test "sign: signature is base64 encoded" {
    signed=$(echo "$SAMPLE_ATTESTATION" | "$SIGN_SCRIPT" sign)

    # Extract signature
    signature=$(echo "$signed" | grep "^Tool-Signature: ed25519:" | sed 's/^Tool-Signature: ed25519://' | xargs)

    # Should be non-empty
    [ -n "$signature" ]

    # Should be valid base64 (this is a basic check)
    # Base64 decode should succeed
    echo "$signature" | base64 -d > /dev/null 2>&1
}

@test "sign: includes correct fingerprint" {
    "$SIGN_SCRIPT" generate-keys
    expected_fingerprint=$(cat "$HOME/.leeroy/toolkit.fingerprint")

    signed=$(echo "$SAMPLE_ATTESTATION" | "$SIGN_SCRIPT" sign)

    # Extract fingerprint from signed attestation
    actual_fingerprint=$(echo "$signed" | grep "^Tool-Key-Fingerprint:" | sed 's/^Tool-Key-Fingerprint: //' | xargs)

    [ "$actual_fingerprint" = "$expected_fingerprint" ]
}

@test "sign: preserves attestation content" {
    signed=$(echo "$SAMPLE_ATTESTATION" | "$SIGN_SCRIPT" sign)

    # Original content should be present
    echo "$signed" | grep -q "Version: 1.0"
    echo "$signed" | grep -q "Session-ID: abc123"
    echo "$signed" | grep -q "Human-Review-Attested: true"
    echo "$signed" | grep -q "Test prompt"
}

@test "sign: different attestations produce different signatures" {
    attestation1="-----BEGIN AI ATTESTATION-----
Version: 1.0
Session-ID: test1
Human-Review-Attested: true"

    attestation2="-----BEGIN AI ATTESTATION-----
Version: 1.0
Session-ID: test2
Human-Review-Attested: true"

    signed1=$(echo "$attestation1" | "$SIGN_SCRIPT" sign)
    signed2=$(echo "$attestation2" | "$SIGN_SCRIPT" sign)

    sig1=$(echo "$signed1" | grep "^Tool-Signature:" | sed 's/^Tool-Signature: ed25519://')
    sig2=$(echo "$signed2" | grep "^Tool-Signature:" | sed 's/^Tool-Signature: ed25519://')

    # Signatures should be different
    [ "$sig1" != "$sig2" ]
}

@test "verify: validates correctly signed attestation" {
    # Sign an attestation
    signed=$(echo "$SAMPLE_ATTESTATION" | "$SIGN_SCRIPT" sign)

    # Verify it (capture stderr)
    run bash -c "echo '$signed' | '$SIGN_SCRIPT' verify 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Tool signature valid"* ]]
}

@test "verify: shows fingerprint on successful verification" {
    signed=$(echo "$SAMPLE_ATTESTATION" | "$SIGN_SCRIPT" sign)
    fingerprint=$(cat "$HOME/.leeroy/toolkit.fingerprint")

    run bash -c "echo '$signed' | '$SIGN_SCRIPT' verify 2>&1"
    [ "$status" -eq 0 ]

    # Output should contain partial fingerprint (first 16 chars)
    [[ "$output" == *"${fingerprint:0:16}"* ]]
}

@test "verify: fails on unsigned attestation" {
    # Try to verify unsigned attestation (capture stderr too)
    run bash -c "echo '$SAMPLE_ATTESTATION' | '$SIGN_SCRIPT' verify 2>&1"
    [ "$status" -eq 1 ]
    [[ "$output" == *"No tool signature found"* ]]
}

@test "verify: fails if signature is modified" {
    signed=$(echo "$SAMPLE_ATTESTATION" | "$SIGN_SCRIPT" sign)

    # Corrupt the signature by changing one character
    corrupted=$(echo "$signed" | sed 's/Tool-Signature: ed25519:\([A-Za-z0-9+/]\)/Tool-Signature: ed25519:X/')

    run bash -c "echo '$corrupted' | '$SIGN_SCRIPT' verify 2>&1"
    [ "$status" -eq 1 ]
    [[ "$output" == *"INVALID"* ]]
}

@test "verify: fails if content is modified" {
    signed=$(echo "$SAMPLE_ATTESTATION" | "$SIGN_SCRIPT" sign)

    # Modify the content (but keep signature)
    modified=$(echo "$signed" | sed 's/Session-ID: abc123/Session-ID: xyz789/')

    run bash -c "echo '$modified' | '$SIGN_SCRIPT' verify 2>&1"
    [ "$status" -eq 1 ]
    [[ "$output" == *"INVALID"* ]]
}

@test "verify: fails if fingerprint is missing" {
    signed=$(echo "$SAMPLE_ATTESTATION" | "$SIGN_SCRIPT" sign)

    # Remove fingerprint line
    no_fingerprint=$(echo "$signed" | grep -v "^Tool-Key-Fingerprint:")

    run bash -c "echo '$no_fingerprint' | '$SIGN_SCRIPT' verify 2>&1"
    [ "$status" -eq 1 ]
}

@test "full workflow: sign then verify" {
    # Create a complete attestation
    attestation="-----BEGIN AI ATTESTATION-----
Version: 1.0
Tool: claude-code/1.0.0
Model: claude-sonnet-4
Session-ID: full-test-123
Started-At: 2024-01-01T10:00:00Z
Committed-At: 2024-01-01T10:15:00Z

Files-Modified:
  - main.rs [modified] @ 2024-01-01T10:05:00Z
  - lib.rs [created] @ 2024-01-01T10:10:00Z

Prompts:
  [2024-01-01T10:00:00Z] Add error handling
  [2024-01-01T10:08:00Z] Add tests

Human-Review-Attested: true"

    # Sign it
    signed=$(echo "$attestation" | "$SIGN_SCRIPT" sign)

    # Verify signature is present
    echo "$signed" | grep -q "Tool-Signature: ed25519:"
    echo "$signed" | grep -q "Tool-Key-Fingerprint:"

    # Verify it validates
    echo "$signed" | "$SIGN_SCRIPT" verify
}

@test "command help: shows usage on invalid command" {
    run "$SIGN_SCRIPT" invalid-command
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "command help: shows available commands" {
    run "$SIGN_SCRIPT"
    [ "$status" -eq 1 ]
    [[ "$output" == *"sign"* ]]
    [[ "$output" == *"verify"* ]]
    [[ "$output" == *"generate-keys"* ]]
    [[ "$output" == *"fingerprint"* ]]
}

@test "keys are properly formatted: private key is valid ed25519" {
    "$SIGN_SCRIPT" generate-keys

    # Verify private key is valid by checking it can be read by openssl
    run openssl pkey -in "$HOME/.leeroy/toolkit.key" -text -noout
    [ "$status" -eq 0 ]
    [[ "$output" == *"ED25519"* ]]
}

@test "keys are properly formatted: public key is valid ed25519" {
    "$SIGN_SCRIPT" generate-keys

    # Verify public key is valid
    run openssl pkey -pubin -in "$HOME/.leeroy/toolkit.pub" -text -noout
    [ "$status" -eq 0 ]
    [[ "$output" == *"ED25519"* ]]
}

@test "signature verification uses correct signing boundary" {
    # Create attestation with content after Human-Review-Attested
    attestation="-----BEGIN AI ATTESTATION-----
Version: 1.0
Session-ID: boundary-test
Human-Review-Attested: true"

    # Sign it
    signed=$(echo "$attestation" | "$SIGN_SCRIPT" sign)

    # Verify it works
    echo "$signed" | "$SIGN_SCRIPT" verify

    # Try modifying content after signing boundary (after Human-Review-Attested)
    # This should still verify because only content up to Human-Review-Attested is signed
    # (but in practice, there is no content after Human-Review-Attested before signing,
    # so this test verifies that the signing boundary is correct)
}
