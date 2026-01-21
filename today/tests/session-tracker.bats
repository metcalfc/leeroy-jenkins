#!/usr/bin/env bats
#
# Tests for session-tracker.sh

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
SESSION_TRACKER="${SCRIPT_DIR}/../hooks/session-tracker.sh"

# Use a temp directory for test sessions
setup() {
    export TEST_LEEROY_DIR=$(mktemp -d)
    export TEST_SESSIONS_DIR="${TEST_LEEROY_DIR}/sessions"
    mkdir -p "${TEST_SESSIONS_DIR}"

    # Create a fake git repo for testing
    export TEST_REPO=$(mktemp -d)
    git -C "${TEST_REPO}" init --quiet

    # Override session file location for tests
    local hash=$(echo -n "${TEST_REPO}" | openssl dgst -sha256 | awk '{print $2}' | cut -c1-16)
    export LEEROY_SESSION_FILE="${TEST_SESSIONS_DIR}/${hash}.json"
}

teardown() {
    rm -rf "${TEST_LEEROY_DIR}" "${TEST_REPO}"
}

@test "session-tracker init creates session file" {
    cd "${TEST_REPO}"
    run "${SESSION_TRACKER}" init
    [ "$status" -eq 0 ]
    [ -f "${LEEROY_SESSION_FILE}" ]
}

@test "session-tracker init generates valid JSON" {
    cd "${TEST_REPO}"
    "${SESSION_TRACKER}" init
    run jq -e '.session_id' "${LEEROY_SESSION_FILE}"
    [ "$status" -eq 0 ]
}

@test "session-tracker init sets session_id" {
    cd "${TEST_REPO}"
    "${SESSION_TRACKER}" init
    local session_id=$(jq -r '.session_id' "${LEEROY_SESSION_FILE}")
    [ -n "${session_id}" ]
    [ "${session_id}" != "null" ]
}

@test "session-tracker init sets started_at timestamp" {
    cd "${TEST_REPO}"
    "${SESSION_TRACKER}" init
    local started_at=$(jq -r '.started_at' "${LEEROY_SESSION_FILE}")
    [[ "${started_at}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

@test "session-tracker init only runs once" {
    cd "${TEST_REPO}"
    "${SESSION_TRACKER}" init
    local first_id=$(jq -r '.session_id' "${LEEROY_SESSION_FILE}")
    "${SESSION_TRACKER}" init
    local second_id=$(jq -r '.session_id' "${LEEROY_SESSION_FILE}")
    [ "${first_id}" = "${second_id}" ]
}

@test "session-tracker file logs modification" {
    cd "${TEST_REPO}"
    "${SESSION_TRACKER}" file "test.txt" modified
    local count=$(jq '.files_modified | length' "${LEEROY_SESSION_FILE}")
    [ "${count}" -eq 1 ]
}

@test "session-tracker file records path and type" {
    cd "${TEST_REPO}"
    "${SESSION_TRACKER}" file "src/main.py" created
    local path=$(jq -r '.files_modified[0].path' "${LEEROY_SESSION_FILE}")
    local type=$(jq -r '.files_modified[0].type' "${LEEROY_SESSION_FILE}")
    [ "${path}" = "src/main.py" ]
    [ "${type}" = "created" ]
}

@test "session-tracker file appends multiple files" {
    cd "${TEST_REPO}"
    "${SESSION_TRACKER}" file "file1.txt" modified
    "${SESSION_TRACKER}" file "file2.txt" created
    "${SESSION_TRACKER}" file "file3.txt" modified
    local count=$(jq '.files_modified | length' "${LEEROY_SESSION_FILE}")
    [ "${count}" -eq 3 ]
}

@test "session-tracker prompt logs prompt text" {
    cd "${TEST_REPO}"
    "${SESSION_TRACKER}" prompt "Add a new feature"
    local count=$(jq '.prompts | length' "${LEEROY_SESSION_FILE}")
    [ "${count}" -eq 1 ]
}

@test "session-tracker prompt records text and timestamp" {
    cd "${TEST_REPO}"
    "${SESSION_TRACKER}" prompt "Fix the bug"
    local text=$(jq -r '.prompts[0].text' "${LEEROY_SESSION_FILE}")
    local timestamp=$(jq -r '.prompts[0].timestamp' "${LEEROY_SESSION_FILE}")
    [ "${text}" = "Fix the bug" ]
    [[ "${timestamp}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

@test "session-tracker prompt handles special characters" {
    cd "${TEST_REPO}"
    "${SESSION_TRACKER}" prompt 'Add "quotes" and $variables'
    local text=$(jq -r '.prompts[0].text' "${LEEROY_SESSION_FILE}")
    [ "${text}" = 'Add "quotes" and $variables' ]
}

@test "session-tracker get returns session JSON" {
    cd "${TEST_REPO}"
    "${SESSION_TRACKER}" init
    run "${SESSION_TRACKER}" get
    [ "$status" -eq 0 ]
    echo "${output}" | jq -e '.session_id'
}

@test "session-tracker get returns empty object when no session" {
    cd "${TEST_REPO}"
    run "${SESSION_TRACKER}" get
    [ "$status" -eq 0 ]
    [ "${output}" = "{}" ]
}

@test "session-tracker clear removes session file" {
    cd "${TEST_REPO}"
    "${SESSION_TRACKER}" init
    [ -f "${LEEROY_SESSION_FILE}" ]
    "${SESSION_TRACKER}" clear
    [ ! -f "${LEEROY_SESSION_FILE}" ]
}

@test "session-tracker clear-files clears only files" {
    cd "${TEST_REPO}"
    "${SESSION_TRACKER}" file "test.txt" modified
    "${SESSION_TRACKER}" prompt "Test prompt"
    "${SESSION_TRACKER}" clear-files
    local files=$(jq '.files_modified | length' "${LEEROY_SESSION_FILE}")
    local prompts=$(jq '.prompts | length' "${LEEROY_SESSION_FILE}")
    [ "${files}" -eq 0 ]
    [ "${prompts}" -eq 1 ]
}

@test "session-tracker path returns session file path" {
    cd "${TEST_REPO}"
    run "${SESSION_TRACKER}" path
    [ "$status" -eq 0 ]
    [[ "${output}" == *"/sessions/"* ]]
    [[ "${output}" == *".json" ]]
}

@test "session-tracker requires valid command" {
    cd "${TEST_REPO}"
    run "${SESSION_TRACKER}" invalid
    [ "$status" -eq 1 ]
}
