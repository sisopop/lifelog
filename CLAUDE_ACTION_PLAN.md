# CLAUDE_ACTION_PLAN.md — ARCHITECTURE_RISK_REVIEW_2026-09-26 반영 계획

기준: `docs/ARCHITECTURE_RISK_REVIEW_2026-09-26.md` (Codex 리뷰) vs 현재 코드(커밋 `24683f6` + 작업트리).
**이 문서는 계획만 담는다. 코드는 수정하지 않았다.**

검증 방법: 리뷰가 인용한 핵심 파일(session.dart, entries_provider.dart, firebase_options.dart, main.dart,
firestore.rules, backup_json.dart, gemini_service.dart, members_repository.dart, turn_provider.dart,
share_screen.dart, app_database.dart, settings_screen.dart)을 직접 열어 코드로 재확인했다. 아래 표기 중
**[코드확인]**은 이번에 직접 읽고 맞다고 검증한 항목, **[리뷰인용]**은 리뷰의 근거 인용을 신뢰하되 이번에
직접 재확인하지 않은 항목이다.

---

## 1. Codex 리뷰 중 동의하는 항목

전부 동의한다. 특히 아래는 코드로 직접 재확인해 확신도가 높다.

- **F1 [코드확인]** `Session`에 UID 없음, `sessionProvider`는 SharedPreferences의 `loggedIn/email`만 읽음. `DiaryEntry.userId` 기본값 `'me'`, DB는 단일 고정 이름. 계정 전환 시 데이터가 섞이는 구조 100% 맞다.
- **F2 [코드확인]** `firebase_options.dart`가 `kIsWeb`이면 무조건 `UnsupportedError`를 던지고, `main.dart`는 이를 catch만 하고 계속 진행. **웹 빌드는 지금 소스 기준 Firebase가 항상 초기화 실패한다.**
- **F3 [코드확인]** `syncStatus` 필드는 있으나 이를 쓰는 큐/재시도/충돌 코드가 어디에도 없다. `firestore.rules`는 `config/notices/categories/skins` 4개 컬렉션만 열려있고 나머지는 전체 거부 — 안전한 차단 상태이지 권한 구현이 아니라는 리뷰 해석에 동의.
- **F4 [코드확인]** `EntriesNotifier._generateSummary(entry)`는 호출 당시 캡처한 `entry` 스냅샷 전체를 `await` 이후 그대로 `_repo.save()`한다. 응답 대기 중 사용자가 본문 수정/즐겨찾기/휴지통 이동을 하면 그 스냅샷이 최신 상태를 덮어쓴다. **실제로 재현 가능한 데이터 손실 버그**이며 클라우드 전환과 무관하게 지금도 위험하다.
- **J1 [코드확인]** `MembersRepository.addPartner`는 `partner_${microsecondsSinceEpoch}`로 가짜 userId를 생성하고, `turn_provider.dart`는 SharedPreferences에 차례를 저장한다. `isMe`는 계산값이 아니라 저장된 bool. 실사용자 공유로 확장 불가.
- **J2 [코드확인]** `backup_json.dart`의 `_entryToJson`/`_entryFromJson`에 `contentRich` 키가 아예 없다 → 백업/복원하면 본문 리치서식이 소실된다. 또한 `settings_screen.dart`의 백업 버튼은 `entriesProvider`(=`getAllEntries()`, `deletedAt.isNull()` 필터)만 사용해 **휴지통 기록이 백업에서 빠진다** — 파일 상단 주석("Trashed records are included")과 실제 UI 동작이 다르다.
- **P1 [리뷰인용]** 사진 Base64 경로 3곳(mediaUrls/캔버스/flowPhotos), Firestore 1MB 문서 한도 초과 논리는 타당. 로컬 Drift라 지금 당장 깨지진 않지만 "그대로 Firestore 이관" 자체가 불가능한 설계인 것은 맞다.
- 나머지 A1–A3(관리자), S1–S2(샵), J3/J4, P2도 근거 인용 방식이 이번에 확인한 항목들과 동일하게 신중하고, 과장된 결론("~일 수 있다"만 씀)이 없어 신뢰한다.

리뷰 전체에서 사실과 다르거나 과장된 부분은 발견하지 못했다. 다만 **PROJECT_STATUS.md(내가 직전에 작성한 문서)가 "커플/교환 일기장", "링크/공개 공유", "멤버 관리"를 "구현 완료"로 적어 리뷰가 지적한 것과 같은 오해를 만들고 있다** — 이건 리뷰가 아니라 내 문서의 실수이므로 5번 항목에서 다룬다.

---

## 2. 현재 코드 기준으로 반영 가능한 항목 (설계 변경 없이 국소 수정)

작은 범위, 기존 동작을 넓히지 않고 좁히기만 하는 수정들. 회귀 위험 낮음.

1. **F4 AI 요약 조건부 갱신** — `_generateSummary`가 저장 직전 DB에서 현재 행을 다시 읽어 `updatedAt`이 스냅샷과 같고 `deletedAt == null`일 때만 `aiSummary/aiStatus`만 patch. 본문 전체 upsert가 아니라 두 필드만 갱신하도록 축소.
2. **J2 백업 완전성** — `_entryToJson/_entryFromJson`에 `contentRich` 추가(round-trip), `settings_screen.dart` 백업 버튼이 `entriesProvider` + `trashProvider`(또는 `diaryRepository.getTrashed()`) 둘 다 모아 넘기도록 수정. `kBackupFormatVersion`은 유지(스키마 자체는 안 바뀜, 필드만 추가).
3. **백업 버전 가드** — `parseBackupJson`이 `version > kBackupFormatVersion`이면 명시적으로 거부(현재는 읽기만 하고 검사 안 함).
4. **PROJECT_STATUS.md 정정** — "구현 완료" 표에서 커플/교환 일기장·멤버·공유·백업 항목에 "로컬 모의/기기 내 전용" 단서 추가. 코드는 안 건드리므로 위험 없음.
5. **F2 최소 진단** — 웹에서 Firebase 초기화 실패를 `debugPrint`가 아니라 앱 내 상태(예: `firebaseAvailableProvider`)로 노출해, 이후 "로그인/공지 기능 웹에서 비활성" UI 분기를 걸 수 있게 함. (웹 FlutterFire 앱 자체 등록은 3번 항목—사람 작업 필요.)

이 5개는 이번 대화에서 바로 착수해도 되는 범위다(사용자가 "코드 수정 아직 하지 마"라 했으므로 지금은 계획만).

---

## 3. 지금 반영하면 위험한 항목 (선행 결정 없이 손대면 위험)

- **F1 계정별 데이터 격리** — UID 기준으로 바꾸는 순간 기존 `userId='me'` 데이터를 "누구 것으로 볼지" 결정해야 한다. 성급히 스키마를 바꾸면 기존 사용자(SM-A520S 등 실기기)의 실제 일기가 로그인 즉시 안 보이거나 잘못 귀속될 수 있다. **사람의 결정(게스트 데이터 이관 정책) 없이 착수 금지.**
- **F3 동기화 프로토콜 도입** — outbox/큐/충돌 해결은 Drift 스키마·리포지토리 계층을 광범위하게 건드린다. 지금 하면 지난 세션에서 쌓은 30여 개의 순수함수·위젯 전부와 상호작용해야 해서 회귀 범위가 너무 크다. Phase 2로 미룬다.
- **J1 실제 공유(초대/멀티기기)** — 서버(Functions/Firestore 규칙) 없이 클라이언트만 바꾸면 "됐다"는 착각만 만든다. 백엔드 설계 없이 절대 먼저 하지 않는다.
- **P1 사진 Base64→Storage 이관** — 기존 기록의 사진 참조 방식 자체가 바뀌므로, 이관 스크립트가 실패하면 사진이 통째로 날아갈 수 있다. 반드시 "기존 Base64는 새 참조 검증 전까지 보존" 원칙(리뷰 §7 제안)을 지킨 다음 단계로만 진행.
- **S1 유료 상점/결제** — 결제·보유권·환불 모델이 전혀 없는 상태에서 UI만 먼저 만들면 나중에 뜯어고쳐야 한다. 비즈니스 결정(무료/유료 범위, 결제 플랫폼) 전엔 손대지 않는다.
- **A1 관리자 API** — 지금 추가하면 "임시로 앱에 로그인 플래그로 관리자 판정"하는 유혹이 생기기 쉽다. 서버 역할 검증 없이 관리자 기능을 추가하는 것 자체가 새로운 취약점이 되므로 보류.

---

## 4. 보류할 항목 (지금 단계에서 의도적으로 안 함)

- **A2/A3 (공지 비공개 필드 분리, 폴백 관측성)** — 현재 공지 콘텐츠에 민감정보가 없다면 급하지 않다. 관리자 페이지 자체가 없는 지금은 우선순위 낮음. Phase 3에서 관리자 UI와 함께.
- **S1/S2 (샵 상품 모델, 자산 버전 고정)** — 유료화 자체가 미정. 결정 전 설계에 리소스 쓰지 않음.
- **J3 (본문/캔버스/인라인사진 렌더 통합)** — 실사용에 지금 당장 문제(리치서식+캔버스 동시사용 시 렌더 누락)를 일으킬 수 있으나, 이건 사용자가 최근 요청한 "통계 제외 작은 기능 하나씩" 자율 루프의 스코프를 넘는 중간 규모 리팩터라 별도 지시 필요.
- **J4 (FK/유니크 제약, 데모 재주입 조건)** — 데이터 무결성 문제지만 현재 단일기기·소량 데이터에선 실제 사고 사례가 없다. Drift 유지 여부가 정해진 뒤(Phase 1 결정) 스키마를 같이 정리하는 게 효율적.
- **F2의 웹 FlutterFire 앱 등록 자체** — Firebase 콘솔에서 웹 앱 추가는 사람이 해야 하는 작업(`firebase apps:create web` 또는 콘솔). 코드 쪽 진단 로직만 이번에 반영하고 실제 등록은 사람 작업으로 남겨둔다.

---

## 5. Claude Code 판단으로 수정이 필요한 추가 항목

리뷰에는 없지만 이번에 코드를 직접 읽다가 발견/재확인한 것들:

1. **PROJECT_STATUS.md의 낙관적 서술 자체가 문제** — 지난 세션에 내가 작성한 문서가 "구현 완료" 섹션에 커플/교환 일기장, 공유, 멤버 관리를 넣었다. 이건 리뷰가 정확히 지적한 "현황 문서와 실제 구조의 차이"의 원인 제공자가 나 자신이었다는 뜻. → 2번 항목에서 정정 예정.
2. **`shareUrlFor`가 `entryId.hashCode` 사용** — `Object.hashCode`는 Dart에서 플랫폼(VM vs 웹)·실행마다 값이 다를 수 있어(특히 web compiler의 hashCode 구현이 네이티브와 다름) 같은 entryId라도 안드로이드에서 만든 링크와 웹에서 만든 링크가 다른 코드를 낼 수 있다. 지금은 어차피 모의 URL이라 실피해는 없지만, 실제 서버 발급 전까지는 이 함수를 신뢰 지표로 쓰면 안 된다는 점을 J1 제안에 추가.
3. **`GeminiService`가 클라이언트에서 키를 URL 쿼리로 직접 전송** (`?key=${ApiKeys.gemini}`) — 리뷰 F4 후반부와 동일 지적이지만, 코드로 보니 각 요청 로그(프록시, 브라우저 네트워크 탭 등)에 키가 노출되는 구체적 경로까지 확인됨. 서버 프록시 없이는 웹 배포에서 키를 완전히 숨길 방법이 없다(현재는 웹은 키 없이 빌드해서 회피 중 — 이 우회책 자체가 "임시방편"임을 문서에 명시할 필요).
4. **`turn_provider.dart`의 `exchangeTurnTimeout = Duration(hours: 6)` 주석에 "데모용, 실서비스는 24~48h 권장"** — 이미 셀프 인지된 임시값. J1 재설계 시 같이 정리 대상으로 명시.

---

## 6. Phase 0 / Phase 1 / Phase 2 / Phase 3 실행 계획

### Phase 0 — 기존 기록 보호 (즉시, 이번~다음 세션)
- F4: AI 요약 조건부 갱신(필드 단위 patch)
- J2: 백업에 `contentRich` 포함 + 휴지통 포함 + 버전 가드
- PROJECT_STATUS.md 표현 정정
- F2: 웹 Firebase 사용 가능 여부를 앱 상태로 노출(진단만, 등록은 사람)
- 완료 기준: 지연 AI 응답이 최신 수정/삭제를 되돌리지 않음(테스트로 검증), 백업→복원 왕복 시 리치서식·휴지통 보존(테스트로 검증)

### Phase 1 — Firebase 기반 정비 (설계 결정 필요, 사람 참여)
- 결정 필요: 게스트 기존 데이터 귀속 정책, Drift를 오프라인 캐시로 유지할지 여부
- UID 기반 세션으로 전환(`Session`에 uid 추가, DB 쿼리에 계정 스코프 적용)
- 웹 Firebase 앱 등록(사람) + `firebase_options.dart` 웹 옵션 채우기
- Firestore 규칙에 일기/일기장/멤버 컬렉션 추가(읽기/쓰기 소유자·멤버십 검증)
- 완료 기준: 계정 A→로그아웃→B 전환 시 데이터 격리 확인(수동 테스트 시나리오, 리뷰 §9-1)

### Phase 2 — 사진과 동기화 (중대형, Phase 1 이후)
- Drift outbox(작업ID/revision/재시도) 설계 및 구현
- MediaRepository: Base64 → Firebase Storage 이관, 참조 카운팅, 원본 보존
- 캔버스/일기장 스타일에 asset version 고정
- 완료 기준: 오프라인 편집 후 재접속 동기화, 사진 이관 재실행 가능(멱등), 원본 손실 없음

### Phase 3 — 실제 공유 / 관리자 / 샵 (사업 결정 이후)
- J1: 서버 검증 멤버십·차례·작성자, 실제 공유 링크 발급/만료/취소
- A1: 관리자 API(역할 검증, 감사 로그, 게시/롤백)
- S1/S2: 상품·보유권·거래 원장, 자산 버전 고정
- 완료 기준: 두 계정·두 기기 교차 테스트, 관리자 게시 롤백, 중복 구매/환불 방지 검증

---

## 7. 이번에 바로 작업할 최소 범위 (제안)

**Phase 0의 앞 2개만, 이번 턴에서 바로 진행 가능:**

1. **F4 fix** — `entries_provider.dart`의 `_generateSummary`를 조건부 patch로 변경 (순수함수로 분리해 유닛테스트 추가 가능: "최근 변경 있으면 스킵", "삭제됐으면 스킵" 두 케이스)
2. **J2 fix** — `backup_json.dart`에 `contentRich` 필드 추가 + `settings_screen.dart` 백업 트리거가 휴지통 포함하도록 수정 + 버전 가드

두 항목 모두: ①국소적 순수함수/직렬화 수정이라 회귀 범위가 좁음 ②기존 `lifelog-feature` 스킬 리듬(순수함수→테스트→analyze→기기검증→커밋)을 그대로 적용 가능 ③사용자의 "통계 금지" 지시와 무관 ④데이터 손실 버그를 실제로 막는 항목이라 우선순위가 명확함.

**진행 승인 시 순서**: F4 → 단위테스트 → J2 → 단위테스트 → `flutter analyze`/`flutter test` → 기기 검증(백업 JSON 복원 왕복 확인) → 커밋.

나머지(Phase 1 이후)는 사람의 정책 결정(게스트 데이터 이관, Drift 유지 여부, 유료화 범위)이 선행되어야 하므로 이번 턴 범위에서 제외한다.
