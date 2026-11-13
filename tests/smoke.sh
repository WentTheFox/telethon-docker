#!/usr/bin/env bash
# Smoke test of a built image, run in CI before the sha- tag exists and by hand: starts the sidecar the way the cluster does (read-only
# root, no capabilities, non-root) and checks that it refuses to start without its env, answers /healthz without auth, and refuses
# every other route without the bearer token (and with a wrong one).
#   tests/smoke.sh <image>
set -euo pipefail
IMAGE="${1:?usage: tests/smoke.sh <image>}"; NAME="tg-sidecar-smoke-$$"; PORT="${PORT:-18080}"
cleanup() { docker rm -f "$NAME" >/dev/null 2>&1 || true; }; trap cleanup EXIT
fail() { echo "FAIL: $*"; docker logs "$NAME" 2>&1 | tail -20; exit 1; }
RO=(--read-only --tmpfs /tmp --cap-drop ALL --security-opt no-new-privileges)
if docker run --rm "${RO[@]}" "$IMAGE" >/dev/null 2>&1; then echo "FAIL: started without TELEGRAM_* env"; exit 1; fi
docker run -d --name "$NAME" "${RO[@]}" -p "127.0.0.1:$PORT:8080" -e TELEGRAM_API_ID=1 -e TELEGRAM_API_HASH=x -e TELEGRAM_SIDECAR_TOKEN=smoke-token "$IMAGE" >/dev/null
for _ in $(seq 20); do [[ "$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/healthz")" == 200 ]] && break; sleep 1; done
code() { curl -s -o /dev/null -w '%{http_code}' "$@"; }
[[ "$(code "http://127.0.0.1:$PORT/healthz")" == 200 ]] || fail "/healthz did not answer 200"
[[ "$(code -X POST "http://127.0.0.1:$PORT/v1/contacts")" == 401 ]] || fail "route without a token was not refused"
[[ "$(code -X POST -H 'Authorization: Bearer wrong' "http://127.0.0.1:$PORT/v1/contacts")" == 401 ]] || fail "wrong token was not refused"
echo "smoke test passed"
