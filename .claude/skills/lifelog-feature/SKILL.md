---
name: lifelog-feature
description: Ship one small lifelog feature end-to-end following the project's fixed rhythm — pure function + Riverpod provider/widget, unit tests, flutter analyze, flutter test, debug APK build, on-device verification on the SM A520S, commit + push, and a terse MEMORY.md entry. Use whenever adding a new insight/card/screen/stat to the lifelog Flutter diary app, or when continuing the autonomous "계속" feature loop.
---

# lifelog-feature

Builds **one** small, fully-verified feature for the lifelog Flutter diary app and ships it. Follow every step in order — do not skip device verification or the MEMORY.md entry.

## Conventions (hard rules)

- **Respond in Korean.** Keep replies concise (user is on mobile).
- **500-line file limit** per file. If a file approaches the limit, split with `part`/`part of` (e.g. `review_widgets.dart` is `part of 'review_screen.dart'`). Prefer adding features to files NOT near the limit (avoid entry_detail ~482, write_screen ~472).
- **Statistics exclude replies** — top-level only: `if (e.replyToEntryId != null) continue;`.
- **Riverpod 3**: `Notifier.state` is PROTECTED. Put logic in a **pure top-level function** so it is unit-testable; the provider/widget just calls it.
- **go_router + Unicode**: never put Korean in a path param (crashes). Use query params: `/tag?t=`, `/place?l=`, `/mood?m=`. Day route is `/day/:date` with `date = yyyy-MM-dd`.
- ISO date helper: `'${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}'`.
- **Do NOT import `package:characters`** when the file also imports flutter/material — material re-exports it (`unnecessary_import` lint). `.characters.length` still works.
- Null-aware list element `?emoji` is preferred over `if (emoji != null) emoji`.
- Mood enum order: good → neutral → hard. Ties in "dominant"/"most active" resolve to the earlier enum / earlier month.
- AppColors: primary, primaryDark, primarySoft, surface, background, textPrimary, textSecondary, textHint, divider, moodHard. `moodColor()` lives in `shared/widgets/month_calendar.dart`.
- Reusable `relativeDayLabel(DateTime, DateTime)` in `lib/features/home/journal_activity.dart`.
- **Never commit secrets**: `lib/.../api_keys.dart` is gitignored. The Gemini-key web build is LOCAL port 8091 ONLY — never deploy it publicly.
- Git: SSH remote `git@github.com:sisopop/lifelog.git`. Never `--force` / `reset --hard` / amend / skip hooks without explicit request. Use the `Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>` trailer.
- Long tasks (>30s, e.g. builds) MUST use `nohup`. Never use ScheduleWakeup / Workflow / background agents (they never fire in ttapp).

## DiaryEntry model

Immutable. Fields: `entryId, userId, journalId, replyToEntryId, lang('ko'), title?, content, aiSummary?, aiStatus, mood (Mood?), visibility, location (String?), createdAt, updatedAt, mediaUrls, tags (List<String>), isFavorite, syncStatus`. `copyWith` has a `clearMood` flag.

## Step-by-step

1. **Pick a feature** small enough to verify on-device. Favor a pure stat/insight or a tappable card. Decide which file gets the pure function (often `lib/features/stats/lifetime_stats.dart` or `stats_provider.dart`) and which screen renders it.

2. **Write the pure function** (top-level, replies excluded, ties documented). Reuse existing helpers where possible (e.g. `longestEntryOfMonth` reuses `longestEntry`).

3. **Wire it into the screen** — a `Builder` watching the relevant provider (`reviewEntriesProvider`, `entriesProvider`, etc.), returning `const SizedBox.shrink()` when null/below threshold.

4. **Unit tests** — add a `group('<fnName>')` to the matching test file. Cover: normal case, replies ignored, empty/null edge. Match the file's existing `_entry`/`_e` factory signature.

5. **Analyze + test** (expect clean / all pass):
   ```bash
   flutter analyze 2>&1 | tail -2 && echo "===TEST===" && flutter test 2>&1 | tail -3
   ```
   Expect `No issues found!` and `All tests passed!`. Fix anything before proceeding.

6. **Build the debug APK** (nohup + poll):
   ```bash
   nohup flutter build apk --debug > /tmp/lg_<name>.log 2>&1 &
   echo "Started PID=$! — log: /tmp/lg_<name>.log"
   ```
   Then wait:
   ```bash
   until grep -qE "Built|error|Error|FAILURE" /tmp/lg_<name>.log; do sleep 5; done; tail -2 /tmp/lg_<name>.log
   ```

7. **Install + launch on device** (see references/device.md for nav coords):
   ```bash
   adb -s 521092f04689c3e5 install -r build/app/outputs/flutter-apk/app-debug.apk 2>&1 | tail -1 \
   && adb -s 521092f04689c3e5 shell am force-stop org.onmdlab.lifelog \
   && adb -s 521092f04689c3e5 shell am start -n org.onmdlab.lifelog/.MainActivity 2>&1 | tail -1 \
   && sleep 16 && echo READY
   ```

8. **Navigate + screenshot + verify visually**. Tap to the right screen, scroll if needed, then:
   ```bash
   adb -s 521092f04689c3e5 shell screencap -p /sdcard/v.png && adb -s 521092f04689c3e5 pull /sdcard/v.png /tmp/v.png
   ```
   **Read /tmp/v.png** and confirm the new UI renders correctly with real data. If a tap misses, use `adb shell uiautomator dump /sdcard/ui.xml` to get exact bounds (Korean text input via adb does NOT work).

9. **Commit + push**:
   ```bash
   git add <only the touched files> && git commit -m "$(cat <<'EOF'
   <imperative English summary>

   Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
   EOF
   )" && git push origin main 2>&1 | tail -2
   ```

10. **Prepend a terse Korean MEMORY.md entry** to the `## Recent Changes` list at
    `~/.claude/projects/-Users-papas-AI-Works-projects-lifelog/memory/MEMORY.md`.
    One line, under ~200 chars: `**<기능명>(<commit>)**: <순수함수 시그니처+규칙> ... 기기 검증(SM A520S): <실제 데이터 결과> 정상. 테스트 N(총 M). analyze 0`.
    Read the file first. ⚠️ It is over the size limit — keep entries terse; consider moving detail to topic files when cleaning up.

11. **Report concisely in Korean**: feature name, commit hash, test count, analyze 0.

## References

- `references/device.md` — emulator/device control: serial, package, screen coords, nav bar, settings path, screenshot loop.
