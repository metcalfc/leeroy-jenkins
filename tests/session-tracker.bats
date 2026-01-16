#!/usr/bin/env bats

# Tests for hooks/session-tracker.sh

setup() {
    # Create temporary test directory
    TEST_DIR="$(mktemp -d)"
    export HOME="$TEST_DIR"
    mkdir -p "$HOME/.ai-attestation"

    # Path to session tracker script
    SESSION_TRACKER="${BATS_TEST_DIRNAME}/../hooks/session-tracker.sh"

    # Ensure script exists
    [ -f "$SESSION_TRACKER" ]
}

teardown() {
    # Clean up test directory
    rm -rf "$TEST_DIR"
}

@test "session-tracker.sh exists and is executable" {
    [ -x "$SESSION_TRACKER" ]
}

@test "init: creates new session with unique ID" {
    run "$SESSION_TRACKER" init
    [ "$status" -eq 0 ]

    # Check session file was created
    [ -f "$HOME/.ai-attestation/current-session.json" ]

    # Verify JSON structure
    session_id=$(jq -r '.session_id' "$HOME/.ai-attestation/current-session.json")
    [ -n "$session_id" ]
    [ "$session_id" != "null" ]

    # Verify started_at timestamp
    started_at=$(jq -r '.started_at' "$HOME/.ai-attestation/current-session.json")
    [ -n "$started_at" ]

    # Verify arrays are initialized
    files_count=$(jq '.files_modified | length' "$HOME/.ai-attestation/current-session.json")
    [ "$files_count" -eq 0 ]

    prompts_count=$(jq '.prompts | length' "$HOME/.ai-attestation/current-session.json")
    [ "$prompts_count" -eq 0 ]
}

@test "init: is idempotent (doesn't create new session if one exists)" {
    run "$SESSION_TRACKER" init
    [ "$status" -eq 0 ]
    session_id1=$(jq -r '.session_id' "$HOME/.ai-attestation/current-session.json")

    # Initialize again - should not change session
    run "$SESSION_TRACKER" init
    [ "$status" -eq 0 ]
    session_id2=$(jq -r '.session_id' "$HOME/.ai-attestation/current-session.json")

    # IDs should be the same (idempotent)
    [ "$session_id1" = "$session_id2" ]
}

@test "file: auto-initializes session if needed" {
    # Session doesn't exist yet
    [ ! -f "$HOME/.ai-attestation/current-session.json" ]

    # Log a file modification
    run "$SESSION_TRACKER" file "test.txt" modified
    [ "$status" -eq 0 ]

    # Session should now exist
    [ -f "$HOME/.ai-attestation/current-session.json" ]

    # File should be logged
    files_count=$(jq '.files_modified | length' "$HOME/.ai-attestation/current-session.json")
    [ "$files_count" -eq 1 ]
}

@test "file: logs modified file with timestamp" {
    "$SESSION_TRACKER" init

    run "$SESSION_TRACKER" file "src/main.rs" modified
    [ "$status" -eq 0 ]

    # Check file was added
    path=$(jq -r '.files_modified[0].path' "$HOME/.ai-attestation/current-session.json")
    [ "$path" = "src/main.rs" ]

    type=$(jq -r '.files_modified[0].type' "$HOME/.ai-attestation/current-session.json")
    [ "$type" = "modified" ]

    timestamp=$(jq -r '.files_modified[0].timestamp' "$HOME/.ai-attestation/current-session.json")
    [ -n "$timestamp" ]
}

@test "file: logs multiple files" {
    "$SESSION_TRACKER" init

    "$SESSION_TRACKER" file "file1.txt" created
    "$SESSION_TRACKER" file "file2.txt" modified
    "$SESSION_TRACKER" file "file3.txt" deleted

    files_count=$(jq '.files_modified | length' "$HOME/.ai-attestation/current-session.json")
    [ "$files_count" -eq 3 ]

    # Verify each file
    path1=$(jq -r '.files_modified[0].path' "$HOME/.ai-attestation/current-session.json")
    [ "$path1" = "file1.txt" ]

    path2=$(jq -r '.files_modified[1].path' "$HOME/.ai-attestation/current-session.json")
    [ "$path2" = "file2.txt" ]

    path3=$(jq -r '.files_modified[2].path' "$HOME/.ai-attestation/current-session.json")
    [ "$path3" = "file3.txt" ]
}

@test "file: supports different types (created, modified, deleted)" {
    "$SESSION_TRACKER" init

    "$SESSION_TRACKER" file "new.txt" created
    type=$(jq -r '.files_modified[0].type' "$HOME/.ai-attestation/current-session.json")
    [ "$type" = "created" ]

    "$SESSION_TRACKER" file "existing.txt" modified
    type=$(jq -r '.files_modified[1].type' "$HOME/.ai-attestation/current-session.json")
    [ "$type" = "modified" ]

    "$SESSION_TRACKER" file "old.txt" deleted
    type=$(jq -r '.files_modified[2].type' "$HOME/.ai-attestation/current-session.json")
    [ "$type" = "deleted" ]
}

@test "prompt: auto-initializes session if needed" {
    [ ! -f "$HOME/.ai-attestation/current-session.json" ]

    run "$SESSION_TRACKER" prompt "test prompt"
    [ "$status" -eq 0 ]

    [ -f "$HOME/.ai-attestation/current-session.json" ]

    prompts_count=$(jq '.prompts | length' "$HOME/.ai-attestation/current-session.json")
    [ "$prompts_count" -eq 1 ]
}

@test "prompt: logs prompt with timestamp" {
    "$SESSION_TRACKER" init

    run "$SESSION_TRACKER" prompt "Fix the bug in main.rs"
    [ "$status" -eq 0 ]

    text=$(jq -r '.prompts[0].text' "$HOME/.ai-attestation/current-session.json")
    [ "$text" = "Fix the bug in main.rs" ]

    timestamp=$(jq -r '.prompts[0].timestamp' "$HOME/.ai-attestation/current-session.json")
    [ -n "$timestamp" ]
}

@test "prompt: logs multiple prompts in order" {
    "$SESSION_TRACKER" init

    "$SESSION_TRACKER" prompt "First prompt"
    "$SESSION_TRACKER" prompt "Second prompt"
    "$SESSION_TRACKER" prompt "Third prompt"

    prompts_count=$(jq '.prompts | length' "$HOME/.ai-attestation/current-session.json")
    [ "$prompts_count" -eq 3 ]

    text1=$(jq -r '.prompts[0].text' "$HOME/.ai-attestation/current-session.json")
    [ "$text1" = "First prompt" ]

    text2=$(jq -r '.prompts[1].text' "$HOME/.ai-attestation/current-session.json")
    [ "$text2" = "Second prompt" ]

    text3=$(jq -r '.prompts[2].text' "$HOME/.ai-attestation/current-session.json")
    [ "$text3" = "Third prompt" ]
}

@test "prompt: appends to prompts.log" {
    "$SESSION_TRACKER" init

    "$SESSION_TRACKER" prompt "Test prompt 1"
    "$SESSION_TRACKER" prompt "Test prompt 2"

    # Check prompts.log exists and has content
    [ -f "$HOME/.ai-attestation/prompts.log" ]

    # Should contain both prompts
    grep -q "Test prompt 1" "$HOME/.ai-attestation/prompts.log"
    grep -q "Test prompt 2" "$HOME/.ai-attestation/prompts.log"
}

@test "get: returns session JSON" {
    "$SESSION_TRACKER" init
    "$SESSION_TRACKER" file "test.txt" modified
    "$SESSION_TRACKER" prompt "test prompt"

    run "$SESSION_TRACKER" get
    [ "$status" -eq 0 ]

    # Output should be valid JSON
    echo "$output" | jq . > /dev/null

    # Should contain session data
    echo "$output" | jq -e '.session_id' > /dev/null
    echo "$output" | jq -e '.files_modified[0]' > /dev/null
    echo "$output" | jq -e '.prompts[0]' > /dev/null
}

@test "get: returns empty object if no session" {
    run "$SESSION_TRACKER" get
    [ "$status" -eq 0 ]
    [ "$output" = "{}" ]
}

@test "clear: removes session file" {
    "$SESSION_TRACKER" init
    [ -f "$HOME/.ai-attestation/current-session.json" ]

    run "$SESSION_TRACKER" clear
    [ "$status" -eq 0 ]

    [ ! -f "$HOME/.ai-attestation/current-session.json" ]
}

@test "clear: preserves prompts.log" {
    "$SESSION_TRACKER" init
    "$SESSION_TRACKER" prompt "test prompt"

    [ -f "$HOME/.ai-attestation/prompts.log" ]

    "$SESSION_TRACKER" clear

    # prompts.log should still exist
    [ -f "$HOME/.ai-attestation/prompts.log" ]
    grep -q "test prompt" "$HOME/.ai-attestation/prompts.log"
}

@test "clear: succeeds even if no session" {
    [ ! -f "$HOME/.ai-attestation/current-session.json" ]

    run "$SESSION_TRACKER" clear
    [ "$status" -eq 0 ]
}

@test "captures CLAUDE_CODE_VERSION if set" {
    export CLAUDE_CODE_VERSION="1.2.3"

    "$SESSION_TRACKER" init

    version=$(jq -r '.tool_version' "$HOME/.ai-attestation/current-session.json")
    [ "$version" = "1.2.3" ]
}

@test "captures CLAUDE_MODEL if set" {
    export CLAUDE_MODEL="claude-sonnet-4"

    "$SESSION_TRACKER" init

    model=$(jq -r '.model' "$HOME/.ai-attestation/current-session.json")
    [ "$model" = "claude-sonnet-4" ]
}

@test "handles missing environment variables gracefully" {
    unset CLAUDE_CODE_VERSION
    unset CLAUDE_MODEL

    run "$SESSION_TRACKER" init
    [ "$status" -eq 0 ]

    # Should have "unknown" as default value
    version=$(jq -r '.tool_version' "$HOME/.ai-attestation/current-session.json")
    [ "$version" = "unknown" ]

    model=$(jq -r '.model' "$HOME/.ai-attestation/current-session.json")
    [ "$model" = "unknown" ]
}

@test "full workflow: init -> file -> prompt -> get -> clear" {
    # Initialize
    "$SESSION_TRACKER" init
    session_id=$(jq -r '.session_id' "$HOME/.ai-attestation/current-session.json")

    # Log files
    "$SESSION_TRACKER" file "main.rs" modified
    "$SESSION_TRACKER" file "lib.rs" created

    # Log prompts
    "$SESSION_TRACKER" prompt "Add error handling"
    "$SESSION_TRACKER" prompt "Add tests"

    # Get session
    session_json=$("$SESSION_TRACKER" get)

    # Verify complete session
    echo "$session_json" | jq -e ".session_id == \"$session_id\"" > /dev/null
    echo "$session_json" | jq -e '.files_modified | length == 2' > /dev/null
    echo "$session_json" | jq -e '.prompts | length == 2' > /dev/null

    # Clear
    "$SESSION_TRACKER" clear
    [ ! -f "$HOME/.ai-attestation/current-session.json" ]

    # Verify prompts.log preserved
    [ -f "$HOME/.ai-attestation/prompts.log" ]
}
