#!/usr/bin/env bash
set -euo pipefail

MARKDOWNLINT_CLI2_VERSION="0.22.1"
fix=false
paths=()

usage() {
    echo "Usage: $0 [--fix] <path-to-file.md> [...]" >&2
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fix)
            fix=true
            shift
            ;;
        -h | --help)
            usage
            ;;
        *)
            paths+=("$1")
            shift
            ;;
    esac
done

[[ ${#paths[@]} -gt 0 ]] || usage

if [[ "$fix" == true ]]; then
    exec npx --yes "markdownlint-cli2@${MARKDOWNLINT_CLI2_VERSION}" --fix "${paths[@]}"
else
    exec npx --yes "markdownlint-cli2@${MARKDOWNLINT_CLI2_VERSION}" "${paths[@]}"
fi
