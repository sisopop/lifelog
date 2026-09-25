# lifelog 프로젝트 현황 (2026-09-25 기준)

Flutter 기반 개인 일기(다이어리/다꾸) 앱. Riverpod 3 + Drift(SQLite) + Firebase Auth/Firestore + Gemini AI.
버전: `1.0.0+1` / Dart SDK `^3.12.1` / DB 스키마 `v29`.

---

## 1. 구현 완료 기능

### 글쓰기 (write)
- 본문 작성 + **리치텍스트**(굵게/기울임/밑줄/취소선/형광펜/글자색/글꼴/크기, flutter_quill 기반, `contentRich` Delta JSON 저장)
- 자판이 올라오면 커서를 자판 위 남은 공간 중앙에 유지(타이프라이터 스크롤), 네이티브·모바일웹 모두 대응
- 감정(mood)·날씨(weather)·장소·태그·날짜 입력
- 사진 첨부 + 본문 흐름 삽입(flowPhotos), 이모지 삽입, 글쓰기 프롬프트 카드
- 저장 가드(빈 본문+캔버스 있으면 저장 허용), 나가기 확인 다이얼로그
- 일기장(journal) 선택/전환

### 꾸미기 (decorate) — 가장 큰 모듈(57개 파일)
- 캔버스 기반 자유 배치 편집(사진/스티커/테이프/텍스트/텍스트박스 레이어)
- 텍스트박스 **인라인 리치텍스트 편집**(선택 영역 서식, 서식 편집바, 폰트/크기/색상 피커)
- 글자넣기(텍스트 레이어): 텍스트박스와 같은 부분 서식(드래그 선택→굵게/기울임/밑줄/취소선/크기/글꼴/글자색/형광펜, 선택 없으면 전체) + 글자크기·자간 프리셋·그림자
- 손잡이 1개(우하)로 좌상 고정 비율 미유지 확대축소 + 좌하 회전
- 사진 꾸미기: 프레임, 스티커, 테이프, 메모, 종횡비, 색필터, 크롭
- 일기장 표지 커스터마이징: 패턴/제본/모서리/밴드/리본/집게/인덱스탭/텍스처/폰트, 속지(내지) 스타일·색상
- 자판 위로 텍스트박스 중앙 정렬(네이티브+모바일웹)

### 읽기/상세 (entry_detail)
- 리치텍스트 렌더링, 갤러리(사진 여러 장), 답장(reply) 스레드
- 이전/다음 기록 탐색, 관련 기록 추천, 읽기 시간 표시
- 제목/날짜 헤더를 카드 밖으로 분리, 속지 카드는 내용만 감쌈

### 홈/타임라인/리뷰
- 홈: 일기장 목록, 인사말, 오늘의 프롬프트, 주간 스트립
- 타임라인: 전체 기록 시간순 목록 + 필터
- 리뷰(하루 단위): 날짜별 기록 묶어보기
- 추억: 오늘의 과거 기록(on this day), 랜덤 추억

### 검색/분류
- 전문 검색(본문 + **캔버스 텍스트박스/글자넣기까지 인덱싱**), 최근 검색어
- 태그 관리/브라우징, 장소 디렉터리, 기분(mood) 디렉터리
- 즐겨찾기, 휴지통(소프트 삭제, 30일 경과 후 앱 실행 시 자동 영구삭제 — 정확한 시각의 서버 자동삭제는 아님)

### 통계 (stats) — *자율 루프에서는 작업 금지 상태*
- 평생 통계(단어 수, 감정 추이, 연속 기록 스트릭), 인사이트, 공유 카드
- 작성 시간대 배지(새벽/아침/오후/저녁)

### 공유/일기장
> ⚠️ **아래는 전부 기기 내 로컬 모의(mock)다.** Firebase 실서버 연동·실사용자 초대·멀티기기 동기화는
> 구현되어 있지 않다 (근거: `docs/ARCHITECTURE_RISK_REVIEW_2026-09-26.md` F1/F3/J1).
- 개인/커플/교환 일기장 — 파트너는 로컬에서 생성한 가상 계정, 멤버는 이 기기의 Drift DB에만 존재
- 턴제(교환일기 순서) — SharedPreferences에 로컬 저장, 실시간 동기화 없음
- 백업(JSON, 클립보드) — 리치서식·휴지통 포함(J2 수정 완료), 다만 멤버/차례 상태는 미포함
- 마크다운 내보내기
- 링크/공개 공유 화면 — `entryId.hashCode` 기반 **모의 URL**만 생성, 실제로 열리는 공개 링크가 아님

### 인증/설정
- Firebase Auth 로그인 — **Android만 유효.** 웹은 `firebase_options.dart`에 web 앱 설정이 없어
  초기화가 항상 실패(F2, `firebaseAvailableProvider`로 진단 가능하게 만듦, 2026-09-26)
- 로그인 세션은 UID가 아니라 기기 SharedPreferences 플래그 기준 — 계정 전환 시 데이터 격리 안 됨(F1)
- 설정 화면, 읽기 텍스트 크기 조절, 원격 설정(remote config) + 공지 배너

### 배포
- Android APK(디버그 빌드-설치-검증 루프 확립)
- 웹: `https://ableflow-lifelog.web.app` (Firebase Hosting, 최신 반영)
- GitHub: `git@github.com:sisopop/lifelog.git`

---

## 2. 미완성/보류 기능

| 항목 | 상태 |
|---|---|
| **Firebase 실전환(계정격리·동기화·실공유)** | `docs/ARCHITECTURE_RISK_REVIEW_2026-09-26.md`(F1/F3/J1) 참조 — Phase 0(데이터 보호)만 완료, Phase 1 이후는 사람의 정책 결정 대기(`CLAUDE_ACTION_PLAN.md`) |
| **글쓰기/꾸미기 탭 병합** | 논의만 됨, 미착수 |
| **통계(stats) 기능 추가** | 사용자 지시로 자율 루프에서 작업 금지 — 현재 통계는 기존 구현 유지만 |
| **소셜 로그인(카카오/네이버/구글/애플)** | 준비물 미발급 — 카카오 REST API키, 네이버 Client ID/Secret, 구글 릴리즈 키스토어 SHA-1 Firebase 등록, (iOS) Apple 개발자 계정+Apple 로그인 필요. 사람이 직접 발급해야 진행 가능 |
| **GitHub Pages 배포 파이프라인** | 2026-07-05 08:59 UTC 이후 계속 실패 중, 최근 커밋 미반영(단, Firebase Hosting은 정상 반영됨) |
| **iOS 빌드/배포** | 미착수(개발 환경이 전부 안드로이드 기기) |
| **노출된 시크릿 폐기** | GitHub 토큰(ghp_.../github_pat_11B73...), Gemini API 키(AQ.Ab8RN6...) — 채팅에 실수 노출되어 폐기·재발급 필요 |

---

## 3. 주요 파일 구조

```
lib/
├── core/
│   ├── config/        api_keys.dart(gitignored), api_keys.example.dart
│   ├── db/            app_database.dart(560줄, 스키마 v29), app_database.g.dart(생성 코드, 4925줄)
│   ├── i18n/          locale_provider.dart
│   ├── router/        app_router.dart (go_router)
│   ├── theme/         app_colors.dart, app_theme.dart
│   └── utils/         keyboard_edit.dart (자판/웹 편집 판정 순수함수)
├── shared/
│   ├── models/        diary_entry.dart, enums.dart, journal.dart, journal_member.dart
│   └── widgets/       entry_card.dart, month_calendar.dart, mood_chip.dart, photo.dart 등
├── features/  (22개 모듈)
│   ├── write/         18개 파일 — 글쓰기 화면·본문 리치에디터·캔버스 탭
│   ├── decorate/      57개 파일 — 꾸미기 캔버스·텍스트박스·사진효과·표지 커스텀 (최대 모듈)
│   ├── entry_detail/  9개 파일 — 상세 읽기·갤러리·답장·관련기록
│   ├── stats/         11개 파일 — 평생통계·인사이트·기분/스트릭
│   ├── journals/      10개 파일 — 일기장 CRUD·멤버·턴제
│   ├── home, timeline, review, search, tags, places, favorites,
│   │   settings, memories, people, calendar, share, export, auth, config
└── l10n/              *.arb 다국어 리소스
```

**500줄 임계 근접/초과 파일**(분할 후보): `review_screen.dart`(693), `lifetime_stats.dart`(575), `app_database.dart`(560), `settings_screen.dart`(558), `entry_detail_screen.dart`(558), `lifetime_stats_screen.dart`(555), `stats_provider.dart`(553), `journal_detail_screen.dart`(500).

---

## 4. DB 구조 (Drift/SQLite, 스키마 v29)

### `DiaryEntries`
`entryId`(PK) · `userId` · `journalId` · `replyToEntryId`(nullable) · `lang`(기본 ko) · `title?` · `content` · `contentRich?`(Quill Delta JSON) · `aiSummary?` · `aiStatus`(none/pending/done/failed) · `mood?`(good/neutral/hard) · `weather?`(sunny/cloudy/overcast/rainy/snowy/windy) · `visibility`(private/link/public) · `location?` · `pageCanvas?`(캔버스 JSON) · `flowPhotos?` · `photoFrames?/Stickers?/Tapes?/Memos?/Aspects?/Filters?/Crops?`(사진별 JSON 배열) · `tags`(JSON 배열) · `mediaUrls`(JSON 배열) · `isFavorite` · `deletedAt?`(30일 소프트삭제) · `createdAt` · `updatedAt` · `syncStatus`(synced/pendingCreate/Update/Delete)

### `Journals`
`journalId`(PK) · `ownerId` · `type`(personal/couple/exchange) · `title` · `coverColor` · `coverPattern/Binding/Corner/Band/Ribbon/Clip/Tab/Texture/Font`(표지 커스텀 각 ID) · `innerPaper/innerPaperColor`(속지) · `icon?/iconX/iconY` · `status`(active/ended/hidden) · `spaceId?`(공유 커플/교환용) · `createdAt` · `deletedAt?`

### `JournalMembers`
`memberId`(PK) · `journalId` · `userId` · `displayName` · `role`(owner/partner) · `isMe` · `joinedAt`

**마이그레이션**: v1(단일 entries)→v2(journals)→v3(members)→v4~15(표지 다꾸 컬럼 대량 추가)→v16~18(소프트삭제+아이콘 위치)→v19~28(사진 꾸밈+인라인사진+캔버스)→v29(contentRich). `beforeOpen`에서 `ensureJournalColumns`/`ensureEntryColumns`로 누락 컬럼 자동 보정(웹 Drift WASM 중단 복구용).

---

## 5. 다음 작업 우선순위 (제안)

1. ~~글자넣기 리치텍스트~~ — 완료
2. **노출된 시크릿 폐기** — GitHub 토큰·Gemini API 키 재발급 (보안, 사람 작업)
3. **500줄 초과 파일 리팩터링** — `review_screen.dart`(693줄) 등 `part`/`part of`로 분할 (코드 품질, 회귀 위험 낮음)
4. **GitHub Pages 파이프라인 점검** — Settings→Pages 배포 설정 확인(단, Firebase Hosting이 주 배포처라 급하지 않음)
5. **소셜 로그인 준비** — 카카오/네이버/구글/애플 자격 발급은 사람이 선행해야 진행 가능 (블로커, 사람 대기)
6. **글쓰기/꾸미기 탭 병합 여부 결정** — 방향 논의 필요(사용자 의사결정 대기)
7. **iOS 대응** — 기기·계정 준비되면 착수

---

## 6. 알려진 이슈

- 웹 키보드 감지: Flutter 웹은 소프트 키보드 높이를 보고하지 않음 → `isWebMobileViewport`(창 높이<720)로 우회 판정 중 (해결됨, 향후 유사 웹 이슈 시 참고)
- 텍스트박스 손잡이 UX는 여러 차례 실험 후 "우하 1개, 비율 미유지" 형태로 확정 — 재변경 시도 자제(사용자 불만 이력)
- 키보드 닫힘 직후 스크롤 위치 글리치 1회 관찰(재현성 미확인, 낮은 확신)
