#!/usr/bin/env bats

# Integration tests for full AI attestation workflow

setup() {
    # Create temporary test directory
    TEST_DIR="$(mktemp -d)"
    export HOME="$TEST_DIR"

    # Setup AI attestation directory
    mkdir -p "$HOME/.leeroy"
    mkdir -p "$HOME/.leeroy/bin"
    mkdir -p "$HOME/.leeroy/hooks"
    mkdir -p "$HOME/.leeroy/git-hooks"

    # Copy scripts to test home
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    cp "$REPO_ROOT"/hooks/*.sh "$HOME/.leeroy/hooks/"
    chmod +x "$HOME/.leeroy/hooks/"*.sh

    # Create test git repository
    TEST_REPO="$TEST_DIR/test-repo"
    mkdir -p "$TEST_REPO"
    cd "$TEST_REPO"
    git init
    git config user.email "test@example.com"
    git config user.name "Test User"

    # Install the leeroy CLI tool (simplified version for testing)
    cat > "$HOME/.leeroy/bin/leeroy" << 'EOF'
#!/usr/bin/env bash
case "${1:-}" in
    list)
        git log --all --pretty=format:"%H" | while read sha; do
            if git notes --ref=leeroy show "$sha" &>/dev/null; then
                echo "$sha"
            fi
        done
        ;;
    show)
        git notes --ref=leeroy show "${2:-HEAD}"
        ;;
    verify)
        attestation=$(git notes --ref=leeroy show "${2:-HEAD}" 2>/dev/null || echo "")
        if [[ -z "$attestation" ]]; then
            echo "No attestation found"
            exit 1
        fi
        echo "$attestation" | ~/.leeroy/hooks/sign-attestation.sh verify
        ;;
    stats)
        total=$(git log --all --pretty=format:"%H" | wc -l)
        attested=0
        git log --all --pretty=format:"%H" | while read sha; do
            if git notes --ref=leeroy show "$sha" &>/dev/null; then
                attested=$((attested + 1))
            fi
        done
        echo "Total commits: $total"
        echo "AI-attested: ${attested:-0}"
        ;;
    *)
        echo "Usage: leeroy {list|show|verify|stats}"
        exit 1
        ;;
esac
EOF
    chmod +x "$HOME/.leeroy/bin/leeroy"

    # Add to PATH
    export PATH="$HOME/.leeroy/bin:$PATH"
}

teardown() {
    # Clean up test directory
    cd /
    rm -rf "$TEST_DIR"
}

@test "integration: full workflow from session to attestation" {
    cd "$TEST_REPO"

    # Step 1: Initialize session (simulating Claude Code hook)
    "$HOME/.leeroy/hooks/session-tracker.sh" init
    [ -f "$HOME/.leeroy/current-session.json" ]

    # Step 2: Simulate file modifications (Claude Code editing files)
    echo "test content" > test.txt
    git add test.txt
    "$HOME/.leeroy/hooks/session-tracker.sh" file "test.txt" created

    echo "more content" > test2.txt
    git add test2.txt
    "$HOME/.leeroy/hooks/session-tracker.sh" file "test2.txt" created

    # Step 3: Log prompts
    "$HOME/.leeroy/hooks/session-tracker.sh" prompt "Add test files"
    "$HOME/.leeroy/hooks/session-tracker.sh" prompt "Add more content"

    # Verify session has data
    session=$("$HOME/.leeroy/hooks/session-tracker.sh" get)
    echo "$session" | jq -e '.files_modified | length == 2'
    echo "$session" | jq -e '.prompts | length == 2'

    # Step 4: Make commit
    git commit -m "Test commit"

    # Step 5: Create attestation (simulating post-commit hook)
    "$HOME/.leeroy/hooks/post-commit-attestation.sh"

    # Step 6: Verify attestation was attached as git note
    attestation=$(git notes --ref=leeroy show HEAD)
    [ -n "$attestation" ]

    # Verify attestation structure
    echo "$attestation" | grep -q "BEGIN AI ATTESTATION"
    echo "$attestation" | grep -q "Version: 1.0"
    echo "$attestation" | grep -q "test.txt"
    echo "$attestation" | grep -q "test2.txt"
    echo "$attestation" | grep -q "Add test files"
    echo "$attestation" | grep -q "Add more content"
    echo "$attestation" | grep -q "Human-Review-Attested: true"
    echo "$attestation" | grep -q "Tool-Signature: ed25519:"
    echo "$attestation" | grep -q "END AI ATTESTATION"

    # Step 7: Verify session was cleared after commit
    [ ! -f "$HOME/.leeroy/current-session.json" ]

    # Step 8: Verify prompts.log was preserved
    [ -f "$HOME/.leeroy/prompts.log" ]
}

@test "integration: CLI list command shows attested commits" {
    cd "$TEST_REPO"

    # Create first commit with attestation
    echo "file1" > file1.txt
    git add file1.txt
    git commit -m "Commit 1"

    # No attestation yet
    list_output=$(leeroy list)
    [ -z "$list_output" ]

    # Add attestation
    "$HOME/.leeroy/hooks/session-tracker.sh" init
    "$HOME/.leeroy/hooks/session-tracker.sh" file "file1.txt" modified
    "$HOME/.leeroy/hooks/session-tracker.sh" prompt "test"

    echo "modified" >> file1.txt
    git add file1.txt
    git commit -m "Commit 2"
    "$HOME/.leeroy/hooks/post-commit-attestation.sh"

    # Should now show one commit
    list_output=$(leeroy list)
    [ -n "$list_output" ]
    [[ "$list_output" =~ [0-9a-f]{40} ]]
}

@test "integration: CLI show command displays attestation" {
    cd "$TEST_REPO"

    # Create attested commit
    "$HOME/.leeroy/hooks/session-tracker.sh" init
    "$HOME/.leeroy/hooks/session-tracker.sh" file "test.txt" created
    "$HOME/.leeroy/hooks/session-tracker.sh" prompt "Create test file"

    echo "content" > test.txt
    git add test.txt
    git commit -m "Add test file"
    "$HOME/.leeroy/hooks/post-commit-attestation.sh"

    # Show attestation
    run leeroy show HEAD
    [ "$status" -eq 0 ]
    [[ "$output" == *"BEGIN AI ATTESTATION"* ]]
    [[ "$output" == *"Create test file"* ]]
}

@test "integration: CLI verify command validates signatures" {
    cd "$TEST_REPO"

    # Create attested commit
    "$HOME/.leeroy/hooks/session-tracker.sh" init
    "$HOME/.leeroy/hooks/session-tracker.sh" file "test.txt" created
    "$HOME/.leeroy/hooks/session-tracker.sh" prompt "test"

    echo "content" > test.txt
    git add test.txt
    git commit -m "Test"
    "$HOME/.leeroy/hooks/post-commit-attestation.sh"

    # Verify should pass
    run leeroy verify HEAD
    [ "$status" -eq 0 ]
    [[ "$output" == *"Tool signature valid"* ]]
}

@test "integration: multiple commits with different sessions" {
    cd "$TEST_REPO"

    # First commit with attestation
    "$HOME/.leeroy/hooks/session-tracker.sh" init
    session_id1=$(jq -r '.session_id' "$HOME/.leeroy/current-session.json")
    "$HOME/.leeroy/hooks/session-tracker.sh" file "file1.txt" created
    "$HOME/.leeroy/hooks/session-tracker.sh" prompt "First prompt"

    echo "content1" > file1.txt
    git add file1.txt
    git commit -m "Commit 1"
    "$HOME/.leeroy/hooks/post-commit-attestation.sh"

    # Session should be cleared
    [ ! -f "$HOME/.leeroy/current-session.json" ]

    # Second commit with new session
    "$HOME/.leeroy/hooks/session-tracker.sh" init
    session_id2=$(jq -r '.session_id' "$HOME/.leeroy/current-session.json")
    "$HOME/.leeroy/hooks/session-tracker.sh" file "file2.txt" created
    "$HOME/.leeroy/hooks/session-tracker.sh" prompt "Second prompt"

    echo "content2" > file2.txt
    git add file2.txt
    git commit -m "Commit 2"
    "$HOME/.leeroy/hooks/post-commit-attestation.sh"

    # Verify both commits have attestations
    attestation1=$(git notes --ref=leeroy show HEAD~1)
    attestation2=$(git notes --ref=leeroy show HEAD)

    [ -n "$attestation1" ]
    [ -n "$attestation2" ]

    # Verify different session IDs
    [ "$session_id1" != "$session_id2" ]

    echo "$attestation1" | grep -q "First prompt"
    echo "$attestation2" | grep -q "Second prompt"

    # Verify each has different content
    echo "$attestation1" | grep -q "file1.txt"
    echo "$attestation2" | grep -q "file2.txt"
}

@test "integration: attestation appending (multiple prompts over time)" {
    cd "$TEST_REPO"

    # Start session and add first file
    "$HOME/.leeroy/hooks/session-tracker.sh" init
    "$HOME/.leeroy/hooks/session-tracker.sh" file "file1.txt" created
    "$HOME/.leeroy/hooks/session-tracker.sh" prompt "Add file1"

    # Later, add another file to same session
    "$HOME/.leeroy/hooks/session-tracker.sh" file "file2.txt" created
    "$HOME/.leeroy/hooks/session-tracker.sh" prompt "Add file2"

    # Even later, add third file
    "$HOME/.leeroy/hooks/session-tracker.sh" file "file3.txt" created
    "$HOME/.leeroy/hooks/session-tracker.sh" prompt "Add file3"

    # Commit everything
    echo "c1" > file1.txt
    echo "c2" > file2.txt
    echo "c3" > file3.txt
    git add .
    git commit -m "Add multiple files"
    "$HOME/.leeroy/hooks/post-commit-attestation.sh"

    # Verify attestation has all files and prompts
    attestation=$(git notes --ref=leeroy show HEAD)

    echo "$attestation" | grep -q "file1.txt"
    echo "$attestation" | grep -q "file2.txt"
    echo "$attestation" | grep -q "file3.txt"

    echo "$attestation" | grep -q "Add file1"
    echo "$attestation" | grep -q "Add file2"
    echo "$attestation" | grep -q "Add file3"
}

@test "integration: attestation with environment variables captured" {
    cd "$TEST_REPO"

    # Set environment variables
    export CLAUDE_CODE_VERSION="1.2.3"
    export CLAUDE_MODEL="claude-sonnet-4"

    # Create session and commit
    "$HOME/.leeroy/hooks/session-tracker.sh" init
    "$HOME/.leeroy/hooks/session-tracker.sh" file "test.txt" created
    "$HOME/.leeroy/hooks/session-tracker.sh" prompt "test"

    echo "content" > test.txt
    git add test.txt
    git commit -m "Test"
    "$HOME/.leeroy/hooks/post-commit-attestation.sh"

    # Verify attestation includes environment data
    attestation=$(git notes --ref=leeroy show HEAD)
    echo "$attestation" | grep -q "Tool: claude-code/1.2.3"
    echo "$attestation" | grep -q "Model: claude-sonnet-4"
}

@test "integration: prompts.log accumulates across sessions" {
    cd "$TEST_REPO"

    # First session
    "$HOME/.leeroy/hooks/session-tracker.sh" init
    "$HOME/.leeroy/hooks/session-tracker.sh" prompt "First session prompt 1"
    "$HOME/.leeroy/hooks/session-tracker.sh" prompt "First session prompt 2"

    echo "f1" > f1.txt
    git add f1.txt
    git commit -m "C1"
    "$HOME/.leeroy/hooks/post-commit-attestation.sh"

    # Second session
    "$HOME/.leeroy/hooks/session-tracker.sh" init
    "$HOME/.leeroy/hooks/session-tracker.sh" prompt "Second session prompt 1"
    "$HOME/.leeroy/hooks/session-tracker.sh" prompt "Second session prompt 2"

    echo "f2" > f2.txt
    git add f2.txt
    git commit -m "C2"
    "$HOME/.leeroy/hooks/post-commit-attestation.sh"

    # Verify prompts.log has all prompts
    [ -f "$HOME/.leeroy/prompts.log" ]

    grep -q "First session prompt 1" "$HOME/.leeroy/prompts.log"
    grep -q "First session prompt 2" "$HOME/.leeroy/prompts.log"
    grep -q "Second session prompt 1" "$HOME/.leeroy/prompts.log"
    grep -q "Second session prompt 2" "$HOME/.leeroy/prompts.log"

    # Should have 4 total prompts
    prompt_count=$(grep -c "^\[" "$HOME/.leeroy/prompts.log")
    [ "$prompt_count" -eq 4 ]
}

@test "integration: signature verification fails on tampered attestation" {
    cd "$TEST_REPO"

    # Create valid attested commit
    "$HOME/.leeroy/hooks/session-tracker.sh" init
    "$HOME/.leeroy/hooks/session-tracker.sh" file "test.txt" created
    "$HOME/.leeroy/hooks/session-tracker.sh" prompt "test"

    echo "content" > test.txt
    git add test.txt
    git commit -m "Test"
    "$HOME/.leeroy/hooks/post-commit-attestation.sh"

    # Tamper with the attestation
    attestation=$(git notes --ref=leeroy show HEAD)
    tampered=$(echo "$attestation" | sed 's/test.txt/hacked.txt/')

    # Replace note with tampered version
    git notes --ref=leeroy add -f -m "$tampered" HEAD

    # Verification should now fail
    run leeroy verify HEAD
    [ "$status" -eq 1 ]
}

@test "integration: works without environment variables" {
    cd "$TEST_REPO"

    # Ensure no env vars
    unset CLAUDE_CODE_VERSION
    unset CLAUDE_MODEL

    # Should still work
    "$HOME/.leeroy/hooks/session-tracker.sh" init
    "$HOME/.leeroy/hooks/session-tracker.sh" file "test.txt" created
    "$HOME/.leeroy/hooks/session-tracker.sh" prompt "test"

    echo "content" > test.txt
    git add test.txt
    git commit -m "Test"
    "$HOME/.leeroy/hooks/post-commit-attestation.sh"

    # Should have attestation
    attestation=$(git notes --ref=leeroy show HEAD)
    [ -n "$attestation" ]
    echo "$attestation" | grep -q "BEGIN AI ATTESTATION"
}
