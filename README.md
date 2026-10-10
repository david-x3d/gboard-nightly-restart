# Gboard Nightly Restart

A KernelSU module (also works with Magisk/APatch) that force-stops the patched
**GboardWu** keyboard every night at **04:00 in the device's current time zone**.

## Why

Intended for Gboard patched with [jasonwu1994/Gboard-patches](https://github.com/jasonwu1994/Gboard-patches)
via [Morphe](https://morphe.software/add-source?github=jasonwu1994/Gboard-patches)
(e.g. the *Advanced Voice Typing* patch). With these patches, AI dictation works
for the first two to three days and then stops until the app is force-stopped
and restarted. This module does that automatically, so you don't have to.

The package name below is the one produced by the *Package Rename* patch. If
your patched build uses a different package name, change `PKG` (see
Configuration).

## Target app

| Field        | Value                                            |
|--------------|--------------------------------------------------|
| App name     | GboardWu                                         |
| Version      | 18.0.3.954559732-release-arm64-v8a               |
| Package name | `dev.jason.com.google.android.inputmethod.latin` |

## Install

1. Download `gboard-nightly-restart.zip` from the [latest release](../../releases/latest).
2. Open the KernelSU manager → **Modules** → **Install** and select the zip.
3. Reboot.

## How it works

`service.sh` runs at boot (late start service), waits for boot to complete, then
checks the time every 60 seconds. Once the local time is 04:00 or later and the
restart hasn't happened yet today, it runs `am force-stop <package>`. Android
starts the keyboard again the next time it is needed.

- **Time zone:** the time is re-read on every check, so traveling to another
  time zone just works.
- **Deep sleep:** if the phone was asleep at 04:00, the restart happens as soon as
  it wakes up (once per day).
- **Reboot:** after a reboot past 04:00, no extra restart is done that day.
- **Log:** `/data/adb/gboard-nightly-restart.log`

## Configuration

Edit the variables at the top of
`/data/adb/modules/gboard_nightly_restart/service.sh` and reboot:

- `PKG` – package name to restart
- `RESTART_TIME` – time as `HHMM` with no leading zero, e.g. `400` for 04:00, `1330` for 13:30

## Build

```sh
./build.sh   # creates gboard-nightly-restart.zip
```

## License

MIT
