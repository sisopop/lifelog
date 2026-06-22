# Device / emulator control (ttapp feature)

Test device: **Samsung SM A520S**, serial **`521092f04689c3e5`**.
- Package: `org.onmdlab.lifelog`, activity `.MainActivity`
- Screen: **1080 x 1920**
- App cold-load: **~16 seconds** (always `sleep 16` after launch)
- Korean text input via `adb shell input text` does NOT work — verify Korean-dependent features with unit tests instead.

## Restart the app after install
```bash
adb -s 521092f04689c3e5 install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s 521092f04689c3e5 shell am force-stop org.onmdlab.lifelog
adb -s 521092f04689c3e5 shell am start -n org.onmdlab.lifelog/.MainActivity
sleep 16
```

## Bottom nav bar (y ≈ 1830)
| tab | x |
|-----|---|
| 홈   | 108 |
| 기록 | 324 |
| ＋   | 540 |
| 회고 | 756 |
| 사람 | 972 |

## Common navigation
- **Settings**: home top-right person icon ≈ `(960, 215)`.
- **내 기록 요약** tile (from settings): bounds `[60,888]–[1020,1134]`, center `(540, 1011)`.
- **회고 calendar**: requires swiping up to reveal; insight lines are above it.
- Calendar day cells expose `content-desc` = the day number (e.g. day 13 → `content-desc="13"`). Use uiautomator dump to get exact bounds before tapping a day.

## Screenshot + read
```bash
adb -s 521092f04689c3e5 shell screencap -p /sdcard/v.png
adb -s 521092f04689c3e5 pull /sdcard/v.png /tmp/v.png
# then Read /tmp/v.png
```

## Get exact tap coordinates (never guess)
```bash
adb -s 521092f04689c3e5 shell uiautomator dump /sdcard/ui.xml
adb -s 521092f04689c3e5 pull /sdcard/ui.xml /tmp/ui.xml
# grep the node, read its bounds="[x1,y1][x2,y2]", tap the center
```

## Scroll
```bash
adb -s 521092f04689c3e5 shell input swipe 540 1400 540 600 400   # scroll down
adb -s 521092f04689c3e5 shell input swipe 540 600 540 1400 400   # scroll up
```
