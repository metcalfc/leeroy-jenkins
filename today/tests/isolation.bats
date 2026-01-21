#!/usr/bin/env bats
#
# Tests for per-repo session isolation

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
SESSION_TRACKER="${SCRIPT_DIR}/../hooks/session-tracker.sh"

setup() {
    # Create two separate git repos
    export REPO_A=$(mktemp -d)
    export REPO_B=$(mktemp -d)
    git -C "${REPO_A}" init --quiet
    git -C "${REPO_B}" init --quiet

    # Use a shared temp directory for sessions
    export TEST_SESSIONS_DIR=$(mktemp -d)
    mkdir -p "${TEST_SESSIONS_DIR}/sessions"

    # Compute expected session file paths
    export HASH_A=$(echo -n "${REPO_A}" | openssl dgst -sha256 | awk '{print $2}' | cut -c1-16)
    export HASH_B=$(echo -n "${REPO_B}" | openssl dgst -sha256 | awk '{print $2}' | cut -c1-16)
    export SESSION_A="${TEST_SESSIONS_DIR}/sessions/${HASH_A}.json"
    export SESSION_B="${TEST_SESSIONS_DIR}/sessions/${HASH_B}.json"
}

teardown() {
    rm -rf "${REPO_A}" "${REPO_B}" "${TEST_SESSIONS_DIR}"
}

@test "different repos get different session paths" {
    cd "${REPO_A}"
    local path_a=$("${SESSION_TRACKER}" path)

    cd "${REPO_B}"
    local path_b=$("${SESSION_TRACKER}" path)

    [ "${path_a}" != "${path_b}" ]
}

@test "different repos get different session hashes" {
    [ "${HASH_A}" != "${HASH_B}" ]
}

@test "sessions are isolated between repos" {
    # Add prompt in repo A
    cd "${REPO_A}"
    LEEROY_SESSION_FILE="${SESSION_A}" "${SESSION_TRACKER}" prompt "Working in repo A"

    # Add prompt in repo B
    cd "${REPO_B}"
    LEEROY_SESSION_FILE="${SESSION_B}" "${SESSION_TRACKER}" prompt "Working in repo B"

    # Verify repo A has only its prompt
    local prompt_a=$(jq -r '.prompts[0].text' "${SESSION_A}")
    [ "${prompt_a}" = "Working in repo A" ]
    local count_a=$(jq '.prompts | length' "${SESSION_A}")
    [ "${count_a}" -eq 1 ]

    # Verify repo B has only its prompt
    local prompt_b=$(jq -r '.prompts[0].text' "${SESSION_B}")
    [ "${prompt_b}" = "Working in repo B" ]
    local count_b=$(jq '.prompts | length' "${SESSION_B}")
    [ "${count_b}" -eq 1 ]
}

@test "files are isolated between repos" {
    # Add file in repo A
    cd "${REPO_A}"
    LEEROY_SESSION_FILE="${SESSION_A}" "${SESSION_TRACKER}" file "repo_a_file.txt" modified

    # Add file in repo B
    cd "${REPO_B}"
    LEEROY_SESSION_FILE="${SESSION_B}" "${SESSION_TRACKER}" file "repo_b_file.txt" created

    # Verify isolation
    local file_a=$(jq -r '.files_modified[0].path' "${SESSION_A}")
    local file_b=$(jq -r '.files_modified[0].path' "${SESSION_B}")

    [ "${file_a}" = "repo_a_file.txt" ]
    [ "${file_b}" = "repo_b_file.txt" ]
}

@test "clearing one repo session does not affect other" {
    # Create sessions in both repos
    cd "${REPO_A}"
    LEEROY_SESSION_FILE="${SESSION_A}" "${SESSION_TRACKER}" prompt "Repo A prompt"

    cd "${REPO_B}"
    LEEROY_SESSION_FILE="${SESSION_B}" "${SESSION_TRACKER}" prompt "Repo B prompt"

    # Clear repo A
    cd "${REPO_A}"
    LEEROY_SESSION_FILE="${SESSION_A}" "${SESSION_TRACKER}" clear

    # Verify repo A is cleared
    [ ! -f "${SESSION_A}" ]

    # Verify repo B still has its session
    [ -f "${SESSION_B}" ]
    local prompt_b=$(jq -r '.prompts[0].text' "${SESSION_B}")
    [ "${prompt_b}" = "Repo B prompt" ]
}

@test "session IDs are unique per repo" {
    cd "${REPO_A}"
    LEEROY_SESSION_FILE="${SESSION_A}" "${SESSION_TRACKER}" init

    cd "${REPO_B}"
    LEEROY_SESSION_FILE="${SESSION_B}" "${SESSION_TRACKER}" init

    local id_a=$(jq -r '.session_id' "${SESSION_A}")
    local id_b=$(jq -r '.session_id' "${SESSION_B}")

    [ "${id_a}" != "${id_b}" ]
}

@test "same repo path always gets same hash" {
    local hash1=$(echo -n "${REPO_A}" | openssl dgst -sha256 | awk '{print $2}' | cut -c1-16)
    local hash2=$(echo -n "${REPO_A}" | openssl dgst -sha256 | awk '{print $2}' | cut -c1-16)

    [ "${hash1}" = "${hash2}" ]
}

@test "non-git directory gets default session" {
    local non_git_dir=$(mktemp -d)

    cd "${non_git_dir}"
    local path=$("${SESSION_TRACKER}" path)

    [[ "${path}" == *"/default.json" ]]

    rm -rf "${non_git_dir}"
}
