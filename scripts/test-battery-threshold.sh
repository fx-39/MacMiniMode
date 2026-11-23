#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TEST_BUILD=$(mktemp -d "${TMPDIR:-/tmp}/macminimode-battery-tests.XXXXXX")
daemon_pid=
cleanup() {
    if [[ -n "$daemon_pid" ]]; then
        kill "$daemon_pid" 2>/dev/null || true
        wait "$daemon_pid" 2>/dev/null || true
    fi
    rm -rf "$TEST_BUILD"
}
trap cleanup EXIT
swiftc Sources/daemon/BatteryThreshold.swift Tests/BatteryThresholdTests.swift -o "$TEST_BUILD/test-battery"
"$TEST_BUILD/test-battery"

swiftc Sources/daemon/*.swift -o "$TEST_BUILD/daemon"
"$TEST_BUILD/daemon" --dry-run --isolated-notifications --simulate-power=battery --simulate-battery=45 --simulate-closed-lid \
    >"$TEST_BUILD/daemon.log" 2>&1 &
daemon_pid=$!
prefix="com.macminimode.dryrun.$daemon_pid"

expect_state() {
    local key=$1 expected=$2 actual
    for ((attempt = 0; attempt < 50; attempt++)); do
        actual=$(/usr/bin/notifyutil -g "$prefix.$key" | awk '{print $2}')
        [[ "$actual" == "$expected" ]] && return 0
        sleep 0.05
    done
    echo "$key: expected $expected, observed $actual" >&2
    cat "$TEST_BUILD/daemon.log" >&2
    return 1
}

threshold() {
    /usr/bin/notifyutil -s "$prefix.set-threshold" "$1" -p "$prefix.set-threshold"
    expect_state threshold "$1"
}

sleep_requests() {
    awk '/\[dry-run\] pmset sleepnow/ {n++} END {print n+0}' "$TEST_BUILD/daemon.log"
}

expect_sleep_requests() {
    for ((attempt = 0; attempt < 80; attempt++)); do
        [[ "$(sleep_requests)" == "$1" ]] && return 0
        sleep 0.05
    done
    cat "$TEST_BUILD/daemon.log" >&2
    return 1
}

expect_state threshold 10
expect_sleep_requests 1
threshold 50
/usr/bin/notifyutil -p "$prefix.set-on"
expect_state low-battery 1
# 此时 disablesleep 已是 0；进入保护仍须重新检查合盖情况。重复检查不能再请求睡眠。
expect_sleep_requests 2
threshold 49
threshold 50
sleep 2.3
[[ "$(sleep_requests)" == 2 ]] || { cat "$TEST_BUILD/daemon.log" >&2; exit 1; }
threshold 44
expect_state low-battery 0
threshold 45
expect_state low-battery 1
/usr/bin/notifyutil -p "$prefix.set-off"
expect_state low-battery 0
/usr/bin/notifyutil -p "$prefix.set-on"
expect_state low-battery 1
# 两秒内再次进入保护，两个请求共用一个合盖检查。
sleep 2.3
[[ "$(sleep_requests)" == 3 ]] || { cat "$TEST_BUILD/daemon.log" >&2; exit 1; }
/usr/bin/notifyutil -p "$prefix.set-off"
expect_state low-battery 0
expect_state state 2

# 启动时允许睡眠，阈值降至 44 时保持清醒，升回 45 时再次允许睡眠。
transitions=$(awk '/\[dry-run\] pmset -a disablesleep/ {print $NF}' "$TEST_BUILD/daemon.log")
[[ "$transitions" == $'0\n1\n0' ]] || { cat "$TEST_BUILD/daemon.log" >&2; exit 1; }
echo "PASS: simulated daemon applies mode switches and threshold changes to its sleep policy"
