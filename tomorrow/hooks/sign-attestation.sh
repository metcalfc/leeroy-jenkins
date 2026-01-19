#!/usr/bin/env bash
set -euo pipefail

# Sign Leeroy attestations with ed25519 toolkit key

LEEROY_DIR="${HOME}/.leeroy"
PRIVATE_KEY="${LEEROY_DIR}/toolkit.key"
PUBLIC_KEY="${LEEROY_DIR}/toolkit.pub"
FINGERPRINT_FILE="${LEEROY_DIR}/toolkit.fingerprint"

# Generate ed25519 keypair if it doesn't exist
generate_keys() {
    if [[ -f "$PRIVATE_KEY" ]]; then
        return 0
    fi

    echo "🔐 Generating toolkit signing key..." >&2

    # Generate private key
    openssl genpkey -algorithm ed25519 -out "$PRIVATE_KEY" 2>/dev/null
    chmod 600 "$PRIVATE_KEY"

    # Extract public key
    openssl pkey -in "$PRIVATE_KEY" -pubout -out "$PUBLIC_KEY" 2>/dev/null
    chmod 644 "$PUBLIC_KEY"

    # Generate fingerprint (SHA256 of public key)
    fingerprint=$(openssl dgst -sha256 -binary "$PUBLIC_KEY" | openssl base64 -A)
    echo "$fingerprint" > "$FINGERPRINT_FILE"
    chmod 644 "$FINGERPRINT_FILE"

    echo "✓ Toolkit key generated" >&2
    echo "  Fingerprint: $fingerprint" >&2
}

# Sign attestation text
# Input: attestation text on STDIN
# Output: signed attestation with signature block on STDOUT
# Signing boundary: Everything from BEGIN through "Human-Review-Attested: true" line
sign_attestation() {
    local attestation
    attestation=$(cat)

    # Ensure keys exist
    generate_keys

    # Get fingerprint
    local fingerprint
    fingerprint=$(cat "$FINGERPRINT_FILE")

    # Extract content to sign: BEGIN through "Human-Review-Attested: true" (inclusive)
    local content_to_sign
    content_to_sign=$(echo "$attestation" | sed -n '/^-----BEGIN AI ATTESTATION-----$/,/^Human-Review-Attested: true$/p')

    # Sign with ed25519 private key (use temp file for reliable binary handling)
    local tmpfile
    tmpfile=$(mktemp -t leeroy-sign.XXXXXX)

    # Ensure cleanup on exit
    cleanup_sign() {
        [[ -n "${tmpfile:-}" ]] && rm -f "$tmpfile"
        return 0
    }
    trap cleanup_sign RETURN EXIT

    printf "%s" "$content_to_sign" > "$tmpfile"

    local signature
    signature=$(openssl pkeyutl -sign -inkey "$PRIVATE_KEY" -rawin -in "$tmpfile" 2>/dev/null | openssl base64 -A)

    # Output signed attestation: original content + signature block + END
    echo "$content_to_sign"
    echo ""
    echo "Tool-Signature: ed25519:$signature"
    echo "Tool-Key-Fingerprint: $fingerprint"
    echo "-----END AI ATTESTATION-----"
}

# Verify attestation signature
# Input: signed attestation text on STDIN
# Output: exit 0 if valid, exit 1 if invalid
# Verification boundary: Same as signing - BEGIN through "Human-Review-Attested: true"
verify_attestation() {
    local attestation
    attestation=$(cat)

    # Extract signature and fingerprint
    local signature
    local fingerprint
    signature=$(echo "$attestation" | grep "^Tool-Signature: ed25519:" | sed 's/^Tool-Signature: ed25519://' | xargs || true)
    fingerprint=$(echo "$attestation" | grep "^Tool-Key-Fingerprint:" | sed 's/^Tool-Key-Fingerprint: //' | xargs || true)

    if [[ -z "$signature" ]] || [[ -z "$fingerprint" ]]; then
        echo "⚠️  No tool signature found (unsigned attestation)" >&2
        return 1
    fi

    # Extract content to verify: BEGIN through "Human-Review-Attested: true" (same as signing)
    local content_to_verify
    content_to_verify=$(echo "$attestation" | sed -n '/^-----BEGIN AI ATTESTATION-----$/,/^Human-Review-Attested: true$/p')

    # Verify signature using public key (use temp files for reliable binary handling)
    local content_file sig_file
    content_file=$(mktemp -t leeroy-verify-content.XXXXXX)
    sig_file=$(mktemp -t leeroy-verify-sig.XXXXXX)

    # Ensure cleanup on exit
    cleanup_verify() {
        [[ -n "${content_file:-}" ]] && rm -f "$content_file"
        [[ -n "${sig_file:-}" ]] && rm -f "$sig_file"
        return 0
    }
    trap cleanup_verify RETURN EXIT

    printf "%s" "$content_to_verify" > "$content_file"
    echo "$signature" | openssl base64 -d > "$sig_file" 2>/dev/null

    if openssl pkeyutl -verify -pubin -inkey "$PUBLIC_KEY" -rawin -in "$content_file" -sigfile "$sig_file" 2>/dev/null; then
        echo "✓ Tool signature valid (fingerprint: ${fingerprint:0:16}...)" >&2
        return 0
    else
        echo "✗ Tool signature INVALID" >&2
        return 1
    fi
}

# Main command dispatcher
case "${1:-}" in
    sign)
        sign_attestation
        ;;
    verify)
        verify_attestation
        ;;
    generate-keys)
        generate_keys
        ;;
    fingerprint)
        if [[ -f "$FINGERPRINT_FILE" ]]; then
            cat "$FINGERPRINT_FILE"
        else
            echo "No toolkit key found. Run 'generate-keys' first." >&2
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {sign|verify|generate-keys|fingerprint}" >&2
        echo "" >&2
        echo "Commands:" >&2
        echo "  sign              Sign attestation from STDIN, output signed attestation" >&2
        echo "  verify            Verify signed attestation from STDIN" >&2
        echo "  generate-keys     Generate toolkit signing key if not present" >&2
        echo "  fingerprint       Show toolkit key fingerprint" >&2
        exit 1
        ;;
esac
