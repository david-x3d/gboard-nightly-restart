#!/system/bin/sh
# Gboard Nightly Restart
# Force-stops the patched Gboard once per day at RESTART_TIME (HHMM, 24h),
# using the device's current time zone. Android restarts the keyboard
# automatically the next time it is needed.
#
# Battery: the loop never holds a wakelock and cannot wake the device (sleep
# does not advance while the CPU is suspended). It forks one `date` per check
# and checks rarely: every 30 min while nothing is due, every 5 min close to
# the restart time.

PKG="dev.jason.com.google.android.inputmethod.latin"
RESTART_TIME=400   # 04:00, compared as a decimal number (HHMM)
EARLY_TIME=300     # start checking more often from 03:00
SLOW_INTERVAL=1800 # seconds between checks while nothing is due
FAST_INTERVAL=300  # seconds between checks shortly before/after the restart time

LOG="/data/adb/gboard-nightly-restart.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG" 2>/dev/null
    # Keep the log small
    if [ "$(wc -c < "$LOG" 2>/dev/null)" -gt 102400 ] 2>/dev/null; then
        tail -n 100 "$LOG" > "$LOG.tmp" 2>/dev/null && mv "$LOG.tmp" "$LOG"
    fi
}

# Wait until Android has fully booted
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 10
done
sleep 60

# The last day the restart ran is kept in memory only: it cannot fail to be
# written, so the restart can never repeat more than once per day. After a
# reboot the keyboard is fresh anyway, so don't restart again today if 04:00
# has already passed.
LAST_RUN=""
now=$(date +%Y%m%d%H%M)
if [ "${now#????????}" -ge "$RESTART_TIME" ] 2>/dev/null; then
    LAST_RUN="${now%????}"
fi

log "Started. Package: $PKG, restart time: $RESTART_TIME, time zone: $(getprop persist.sys.timezone)"

restart_keyboard() {
    # Force-stopping the active keyboard makes Android pick a new default one
    # (possibly a system keyboard). Remember ours and put it back afterwards.
    current_ime=$(settings get secure default_input_method 2>/dev/null)
    if am force-stop "$PKG" >/dev/null 2>&1; then
        log "Force-stopped $PKG"
    else
        log "Failed to force-stop $PKG"
    fi
    case "$current_ime" in
        "$PKG"/*)
            sleep 3
            if [ "$(settings get secure default_input_method 2>/dev/null)" != "$current_ime" ]; then
                ime set "$current_ime" >/dev/null 2>&1 && log "Restored input method $current_ime"
            fi
            ;;
    esac
}

while true; do
    # Re-read the time every iteration so time zone changes (travel) are
    # respected. "Time passed and not yet done today" also catches up when the
    # device was in deep sleep at 04:00.
    now=$(date +%Y%m%d%H%M)
    day="${now%????}"
    hhmm="${now#????????}"

    interval="$SLOW_INTERVAL"
    if [ "$LAST_RUN" != "$day" ]; then
        if [ "$hhmm" -ge "$RESTART_TIME" ] 2>/dev/null; then
            LAST_RUN="$day"
            restart_keyboard
        elif [ "$hhmm" -ge "$EARLY_TIME" ] 2>/dev/null; then
            interval="$FAST_INTERVAL"
        fi
    fi
    sleep "$interval"
done
