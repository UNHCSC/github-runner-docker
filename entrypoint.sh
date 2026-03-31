#!/bin/bash

set -euo pipefail

echo "env.REPOSITORY_URL: ${REPOSITORY_URL}"

repo_slug() {
    local slug="${REPOSITORY_URL#https://github.com/}"
    slug="${slug#http://github.com/}"
    slug="${slug%.git}"
    slug="${slug%/}"
    printf '%s\n' "${slug}"
}

get_reg_token() {
    curl --fail --silent --show-error -X POST \
        -H "Authorization: Bearer ${RUNNER_TOKEN}" \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2026-03-10" \
        "https://api.github.com/repos/$(repo_slug)/actions/runners/registration-token" \
        | jq --exit-status --raw-output '.token'
}

get_remove_token() {
    curl --fail --silent --show-error -X POST \
        -H "Authorization: Bearer ${RUNNER_TOKEN}" \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2026-03-10" \
        "https://api.github.com/repos/$(repo_slug)/actions/runners/remove-token" \
        | jq --exit-status --raw-output '.token'
}

ensure_directories() {
    mkdir -p /home/docker/actions-runner
}

configure_runner() {
    local reg_token
    reg_token="$(get_reg_token)"
    cd /home/docker/actions-runner
    ./config.sh \
        --url "${REPOSITORY_URL}" \
        --token "${reg_token}" \
        --name "$(hostname)" \
        --replace \
        --unattended
}

cleanup() {
    local reg_token

    echo "Removing runner..."

    if ! reg_token="$(get_remove_token)"; then
        echo "Failed to fetch a removal token; skipping runner removal."
        return
    fi

    cd /home/docker/actions-runner
    ./config.sh remove --unattended --token "${reg_token}" || true
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

main() {
    ensure_directories
    configure_runner
    ./run.sh & wait $!
}

main
