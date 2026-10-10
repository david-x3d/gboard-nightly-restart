#!/system/bin/sh
# Gboard Nightly Restart
# Force-stops the patched Gboard once per day at RESTART_TIME (HHMM, 24h),
# using the device's current time zone. Android restarts the keyboard
# automatically the next time it is needed.

PKG="dev.jason.com.google.android.inputmethod.latin"
RESTART_TIME=400   # 04:00, compared as a decimal number (HHMM)
CHECK_INTERVAL=60  # seconds between checks

LOG="/data/adb/gboard-nightly-restart.log"
LAST_RUN_FILE="/data/adb/gboard-nightly-restart.last"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"
    # Keep the log small
    if [ "$(wc -c < "$LOG")" -gt 102400 ]; then
        tail -n 100 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
    fi
}

now_hhmm() { date +%H%M; }
today() { date +%Y%m%d; }

# Wait until Android has fully booted
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 5
done
sleep 60

# After a reboot the keyboard is fresh anyway, so don't restart it again today
# if 04:00 has already passed.
if [ "$(now_hhmm)" -ge "$RESTART_TIME" ]; then
    today > "$LAST_RUN_FILE"
fi

log "Started. Package: $PKG, restart time: $RESTART_TIME, time zone: $(getprop persist.sys.timezone)"

while true; do
    # Re-read time every iteration so time zone changes (travel) are respected.
    # "Time passed and not yet done today" also catches up when the device was
    # in deep sleep at 04:00.
    if [ "$(now_hhmm)" -ge "$RESTART_TIME" ] && [ "$(cat "$LAST_RUN_FILE" 2>/dev/null)" != "$(today)" ]; then
        today > "$LAST_RUN_FILE"
        if am force-stop "$PKG" >/dev/null 2>&1; then
            log "Force-stopped $PKG"
        else
            log "Failed to force-stop $PKG"
        fi
    fi
    sleep "$CHECK_INTERVAL"
done
