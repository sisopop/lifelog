# lifelog 앱 구조 및 전환 리스크 검토

검토일: 2026-09-26 · 기준 커밋: `24683f6` 및 현재 작업 트리

## 1. 결론과 검토 범위

현재 앱은 **Drift 기반 로컬 일기 앱에 Firebase 이메일 인증과 Firestore 공지·설정 읽기를 부분 연결한 구조**다. 일기 데이터의 Firebase 전환, 실제 다중 사용자 공유, 관리자 페이지, 꾸미기샵은 이 저장소에서 완성된 기능으로 확인되지 않는다. 특히 웹은 현재 Firebase 초기화 옵션부터 빠져 있다.

꾸미기 UI 확장이나 파일 분할보다 **계정별 데이터 격리 → 기존 기록의 보존·백업 → 사진 분리 → 동기화와 권한 → 관리자·샵** 순서가 우선이다. 로컬 저장소를 Firestore 호출로 단순 치환하면 계정 혼합, 사진 용량 초과, 충돌 시 기록 손실이 발생할 수 있다.

검토 대상은 `PROJECT_STATUS.md`, `lib/`의 인증·저장·일기장·편집·꾸미기·공유·설정 코드, Firestore 규칙, Firebase 설정, 관련 테스트 소스와 배포 워크플로다. 앱 코드·규칙·설정은 변경하지 않았으며 이 보고서만 추가했다. 실행 테스트, 실제 기기 재현, Firebase 운영 콘솔·배포 규칙·별도 관리자 저장소 확인은 수행하지 않았다. 아래의 “확인”은 정적 코드 근거를 뜻하며, 운영 데이터 유출이나 실제 장애 발생을 확인했다는 의미는 아니다.

우선순위: **P1**은 데이터 보존·격리 결함 또는 해당 기능 출시 전 필수 해결 사항, **P2**는 확장 전 설계·운영 보완 사항이다. 미구현 기능은 현재 취약점과 구분해 표기했다.

## 2. 현황 문서와 실제 구조의 차이

| 영역 | 코드에서 확인한 현재 상태 | 현황 문서에 보완할 내용 |
|---|---|---|
| Firebase | Android 초기화 옵션, 이메일 인증 래퍼, Firestore 설정·공지 구독 | 일기·일기장·멤버 동기화는 없음. 웹/iOS 옵션 미설정 |
| 관리자 페이지 | 공지·설정을 읽는 앱 코드와 공개 읽기/클라이언트 쓰기 금지 규칙 | 관리자 UI, 관리자 인증·인가 API, 게시·감사 흐름은 저장소에서 확인되지 않음 |
| 꾸미기샵 | 로컬 꾸미기 카탈로그, `skinShop` 더미 플래그, `/skins`·`/categories` 규칙 | 상품 조회·구매·보유권·배포 구현은 확인되지 않음. 꾸미기 도구와 상점은 별도 기능 |
| 커플·교환 일기장 | 로컬 가상 멤버 추가, 기기 내 차례 저장 | 실제 초대·동의·멀티디바이스 공유 완료로 해석하면 안 됨 |
| 링크·공개 공유 | 로컬 공개 범위 변경, 모의 URL 생성 | 공개 기록 제공·접근 통제·만료·취소 백엔드는 없음 |
| 전체 JSON 백업 | 활성 일기·일기장만 화면에서 전달 | 본문 서식, 멤버, 차례, 휴지통까지 보존하는 전체 백업이 아님 |
| 휴지통 | 삭제 시 소프트 삭제, 30일 초과 기록은 provider 초기화 때 물리 삭제 | “30일 후 소프트 삭제” 표현 수정 필요. 정확한 시각의 서버 자동 삭제도 아님 |

현재 데이터 흐름:

```text
Flutter 화면 → Riverpod → Diary/Journal/MembersRepository → 단일 Drift DB(lifelog)
로그인 화면 → Firebase Auth → SharedPreferences의 세션 표시 상태
홈 공지·설정 ← Firestore config/app, notices (초기화 실패 시 더미 폴백)
사진 선택 → Base64 문자열 → 일기 행/캔버스 JSON/인라인 사진 JSON
꾸미기 선택 → 앱에 포함된 카탈로그·에셋 → 일기장 컬럼/캔버스 JSON
```

화면·도메인 모델·repository를 분리한 점, 로컬 일기장 삭제를 트랜잭션으로 처리한 점은 유지할 가치가 있다. 다만 repository가 주석에서 “캐시”로 불려도 현재는 사실상 유일한 영속 저장소다.

## 3. Firebase 전환

### F1 · P1 · 계정 변경 시 기존 계정의 일기가 그대로 보이는 구조 [확인]

**근거:** [session.dart:35](/Users/papas/AI-Works/projects/lifelog/lib/features/auth/session.dart:35), [entries_provider.dart:14](/Users/papas/AI-Works/projects/lifelog/lib/features/entries/entries_provider.dart:14), [app_database.dart:155](/Users/papas/AI-Works/projects/lifelog/lib/core/db/app_database.dart:155), [app_database.dart:382](/Users/papas/AI-Works/projects/lifelog/lib/core/db/app_database.dart:382), [write_screen.dart:368](/Users/papas/AI-Works/projects/lifelog/lib/features/write/write_screen.dart:368).

세션에는 UID가 없고 로그인 표시 상태는 SharedPreferences에서 읽는다. DB 이름은 고정이며 조회 조건에 계정이 없다. 새 기록 작성자는 기본값 `me`, 일기장 소유자도 `me`다. 로그아웃은 DB·일기 provider를 교체하거나 격리하지 않는다. `AuthRepository.currentUid`는 선언되어 있지만 데이터 소유권에 사용되지 않는다.

**발생 시나리오:** 같은 앱 설치/브라우저에서 A가 기록 후 로그아웃하고 B 또는 게스트로 들어가면 동일한 로컬 데이터 집합을 읽는다. 이를 그대로 클라우드 업로드하면 기존 게스트/A의 기록을 B 계정에 잘못 귀속시킬 수 있다.

**제안:** Firebase 인증 상태와 UID를 세션 기준으로 삼고 게스트는 별도 로컬 식별자로 관리한다. UID별 DB 또는 모든 테이블·쿼리의 계정 범위를 강제하고, 전환 시 구독·비동기 작업·메모리 캐시도 격리한다. 기존 `me` 데이터를 어느 계정에 이관할지는 사용자에게 대상과 건수를 보여주는 일회성 절차로 처리한다. 기존 데이터를 자동 삭제하는 방식은 피한다.

### F2 · P1 · 웹 Firebase 초기화는 현재 소스에서 항상 실패 [확인]

**근거:** [firebase_options.dart:18](/Users/papas/AI-Works/projects/lifelog/lib/firebase_options.dart:18), [main.dart:24](/Users/papas/AI-Works/projects/lifelog/lib/main.dart:24), [auth_repository.dart:92](/Users/papas/AI-Works/projects/lifelog/lib/features/auth/auth_repository.dart:92).

`kIsWeb`이면 옵션 접근 자체가 `UnsupportedError`를 던진다. `main`은 이를 잡고 앱을 계속 실행한다. 웹의 별도 Firebase 초기화 경로도 발견되지 않았다. 따라서 **이 소스로 빌드한 웹은 Hosting에서 화면이 열려도 Firebase 로그인·원격 공지 연결이 정상이라는 뜻이 아니다.** iOS도 옵션 미설정 상태다. 기존 배포 산출물이 현재 소스와 동일한지는 미확인이다.

**제안:** 웹 앱 등록·옵션·인증 도메인을 확인하고 플랫폼별 시작 진단을 추가한다. 운영 빌드에서 Firebase 연결 실패와 로컬 모드를 명확히 구분한다. Hosting 배포 확인과 인증/Firestore 동작 확인을 별도 배포 검증으로 둔다.

### F3 · P1 · `syncStatus`만 있고 동기화 프로토콜이 없음 [전환 차단]

**근거:** [diary_repository.dart:9](/Users/papas/AI-Works/projects/lifelog/lib/features/entries/diary_repository.dart:9), [diary_entry.dart:36](/Users/papas/AI-Works/projects/lifelog/lib/shared/models/diary_entry.dart:36), [app_database.dart:409](/Users/papas/AI-Works/projects/lifelog/lib/core/db/app_database.dart:409), [firestore.rules:24](/Users/papas/AI-Works/projects/lifelog/firestore.rules:24).

일기의 기본 동기화 상태는 `synced`이며 저장·삭제 때 대기 상태로 바꾸는 흐름, 전송 큐, 재시도, 충돌 처리, 서버 확인이 없다. 일기장·멤버에는 일기와 같은 동기화 필드조차 없다. 규칙은 설정용 네 컬렉션 이외의 접근을 모두 거부한다. 이는 현재 안전한 차단 상태이지 일기용 권한 구현이 아니다.

**제안:** Drift를 오프라인 저장소로 유지할지 먼저 결정한다. 유지한다면 로컬 변경과 outbox 등록을 같은 트랜잭션으로 묶고, 작업 ID·서버 revision·재시도·삭제 tombstone·계정별 큐를 둔다. 원격 반영이 확인되기 전에는 `synced`로 표시하지 않는다. 본문/캔버스 충돌은 오래된 전체 문서로 덮어쓰지 말고 충돌 사본 보존부터 제공한다. 즐겨찾기·기분 변경도 동기화 대상인지 명시한다. 일기장·멤버·사진까지 동일한 실패 복구 설계가 필요하다.

### F4 · P1 · 늦게 도착한 AI 요약이 수정·삭제를 되돌릴 수 있음 [확인]

**근거:** [entries_provider.dart:149](/Users/papas/AI-Works/projects/lifelog/lib/features/entries/entries_provider.dart:149), [app_database.dart:404](/Users/papas/AI-Works/projects/lifelog/lib/core/db/app_database.dart:404).

요약 함수는 호출 당시의 `DiaryEntry`를 보관했다가 응답 후 그 객체 전체를 upsert한다. 네트워크 응답을 기다리는 동안 본문을 수정하거나 즐겨찾기·공개 범위를 바꾸면 이전 값으로 덮어쓸 수 있다. 휴지통 이동 시 `deletedAt`이 다시 null이 되고, 영구 삭제 후에는 행이 재삽입될 수 있다. 클라우드 전환과 무관하게 현재 저장 경로의 데이터 보존 위험이다.

**제안:** AI 결과는 요약 필드만 조건부 갱신한다. 요청 당시 본문 revision/hash가 현재와 일치하고 기록이 존재하며 삭제되지 않았을 때만 적용한다. 계정 전환 후 결과도 거부한다. 네트워크 지연을 제어하는 테스트로 수정·삭제·로그아웃 경합을 확인한다.

추가로 [gemini_service.dart:25](/Users/papas/AI-Works/projects/lifelog/lib/features/entries/gemini_service.dart:25)는 키가 설정되면 일기 본문을 클라이언트에서 직접 전송한다. 사용 중인 키의 실제 값은 조사하지 않았다. `PROJECT_STATUS.md`에 기록된 노출 키의 폐기 여부를 확인하고, 운영에서는 서버 측 키 보관·호출량 제한·AI 사용 선택을 설계한다. Git ignore나 빌드 변수만으로 배포 앱에 포함된 서비스 키를 보호할 수 있다고 가정해서는 안 된다.

## 4. 관리자 페이지

### A1 · P1 · 관리자 작성 경로와 권한 경계 미구현 [출시 전제]

**근거:** [firestore.rules:4](/Users/papas/AI-Works/projects/lifelog/firestore.rules:4), [remote_config_provider.dart:9](/Users/papas/AI-Works/projects/lifelog/lib/features/config/remote_config_provider.dart:9), [app_router.dart:46](/Users/papas/AI-Works/projects/lifelog/lib/core/router/app_router.dart:46).

규칙의 “관리자 콘솔이 Admin SDK/Functions로 쓴다”는 주석은 의도 설명이다. 이 저장소에는 해당 UI·서버·관리자 인가·감사 로그가 확인되지 않는다. 현재 규칙으로 브라우저에서 관리자 로그인을 추가하기만 하면 쓰기가 허용되는 것도 아니다.

**제안:** 관리자 UI와 특권 작업 API를 구분한다. API는 요청자의 서버 검증된 역할, 변경 가능한 필드, 입력 스키마를 확인하고 작업자·이전값·새값·시간을 기록한다. 게시 전 미리보기, 게시 버전, 롤백을 갖춘다. 관리자 자격을 앱의 로컬 로그인 플래그나 숨겨진 URL로 판단하지 않는다. 초기 범위는 공지와 무료 카탈로그 게시로 제한하는 것이 적절하다.

### A2 · P2 · 비활성·예약 공지도 공개 읽기 가능 [규칙상 확인]

**근거:** [firestore.rules:9](/Users/papas/AI-Works/projects/lifelog/firestore.rules:9), [remote_config_provider.dart:24](/Users/papas/AI-Works/projects/lifelog/lib/features/config/remote_config_provider.dart:24), [remote_config.dart:41](/Users/papas/AI-Works/projects/lifelog/lib/features/config/remote_config.dart:41).

앱은 공지 전체를 받아 `active/startAt/endAt`을 기기에서 걸러낸다. 규칙은 인증 없이 모든 notice를 읽게 한다. 따라서 비활성·미래 공지가 같은 컬렉션에 저장되면 UI에서 숨겨져도 내용은 비공개가 아니다. 카테고리·스킨 역시 공개 읽기이므로 내부 초안·원가·운영 메모를 함께 넣으면 안 된다.

**제안:** 관리자 전용 초안과 공개 게시본을 분리하고 공개 문서에는 노출 가능한 필드만 둔다. 클라이언트 쿼리 필터만 추가하는 것으로 비밀성이 해결되지는 않는다. 예약 게시의 기준 시각과 실제 게시 처리는 서버에 둔다.

### A3 · P2 · 연결 실패가 성공처럼 보일 수 있는 폴백 [확인]

**근거:** [remote_config_provider.dart:61](/Users/papas/AI-Works/projects/lifelog/lib/features/config/remote_config_provider.dart:61), [remote_config.dart:130](/Users/papas/AI-Works/projects/lifelog/lib/features/config/remote_config.dart:130).

초기 로딩/오류로 두 stream 값이 없으면 “리모트 설정이 연결됐어요”라는 더미 공지와 `limitedSales: true`를 반환한다. 현재 판매 소비 코드는 없으므로 실제 판매가 열리는 결함은 아니다. 다만 이를 향후 판매·점검 제어에 재사용하면 장애 시 관리자가 내린 설정과 달라질 위험이 있다.

**제안:** 로딩·오프라인·오류를 관찰 가능하게 하고 운영용 기본값과 데모 공지를 분리한다. 정상 수신한 마지막 설정 버전을 보존하되 판매/권한 결정은 서버에서 한다. 긴급 중지 기능은 클라이언트 플래그에만 의존하지 않는다.

## 5. 꾸미기샵

### S1 · P1(유료 출시 시) · 꾸미기 기능은 있으나 상품·보유권 모델이 없음 [미구현]

**근거:** [sticker_catalog.dart:16](/Users/papas/AI-Works/projects/lifelog/lib/features/decorate/sticker_catalog.dart:16), [cover_texture_images.dart:18](/Users/papas/AI-Works/projects/lifelog/lib/features/decorate/cover_texture_images.dart:18), [remote_config.dart:134](/Users/papas/AI-Works/projects/lifelog/lib/features/config/remote_config.dart:134).

현재 스티커·재질은 앱 내 상수/에셋이다. `skinShop` 플래그를 읽어 상점을 여는 코드, `/skins` 조회 repository, 가격·주문·구매 검증·보유 목록은 확인되지 않는다. 무료 꾸미기에는 문제가 없지만 선택 UI에 가격이나 잠금만 붙이는 것으로 유료 상품을 구현할 수 없다.

**제안:** 무료 원격 카탈로그와 유료 상거래를 별도 단계로 진행한다. 유료 도입 시 상품 정의, 사용자 보유권, 주문/거래 기록, 꾸미기에 사용된 에셋 참조를 분리한다. 가격·지급·중복 구매·환불은 서버가 검증하며 재시도해도 지급이 중복되지 않아야 한다. 포인트를 쓸 계획이라면 잔액만 두지 말고 거래 원장을 함께 설계한다. 결제 플랫폼과 판매 모델은 아직 결정이 필요하다.

### S2 · P2 · 카탈로그 변경이 과거 일기의 외관을 바꿀 수 있음 [확장 위험]

**근거:** [cover_texture.dart:33](/Users/papas/AI-Works/projects/lifelog/lib/features/decorate/cover_texture.dart:33), [page_canvas.dart:74](/Users/papas/AI-Works/projects/lifelog/lib/features/decorate/page_canvas.dart:74), [app_database.dart:35](/Users/papas/AI-Works/projects/lifelog/lib/core/db/app_database.dart:35).

꾸미기 값은 문자열 ID/이모지 중심이며 알 수 없는 재질은 `none`으로 정규화된다. 상품 버전·에셋 버전·구매 당시 구성이 분리되어 있지 않다. 향후 동일 ID의 자산 교체·삭제나 구버전 앱에서 새 항목을 열 때 기존 기록이 달라지거나 꾸밈이 사라질 수 있다.

**제안:** 불변 `assetId + version`을 저장하고 판매 중단과 기존 사용본 삭제를 분리한다. 묶음 상품과 개별 에셋을 구분한다. 구매 권한은 새 적용 여부에 쓰고 기존 일기 열람 보존 정책은 별도로 정한다. 에셋 누락 시 원본 참조를 보존한 채 대체 표시하고, 저장할 때 모르는 값을 조용히 제거하지 않는다. `JournalStyle` 값 객체로 표지/속지를 묶되 기존 컬럼을 한 번에 제거하는 재작성은 피한다.

## 6. 일기장·기록 구조

### J1 · P1 · 실제 공유를 보장하지 않는 로컬 멤버·차례·작성자 [전환 차단]

**근거:** [members_repository.dart:51](/Users/papas/AI-Works/projects/lifelog/lib/features/journals/members_repository.dart:51), [turn_provider.dart:71](/Users/papas/AI-Works/projects/lifelog/lib/features/journals/turn_provider.dart:71), [app_router.dart:56](/Users/papas/AI-Works/projects/lifelog/lib/core/router/app_router.dart:56), [write_screen.dart:396](/Users/papas/AI-Works/projects/lifelog/lib/features/write/write_screen.dart:396).

파트너는 로컬에서 생성한 가상 userId이고, `isMe`는 저장된 bool, 차례는 SharedPreferences다. 작성자도 URL 파라미터를 통해 지정할 수 있다. 기록 저장과 차례 넘김은 서로 다른 저장소에 순차 실행된다. 실제 여러 사용자가 연결되면 작성자 위조를 막는 경계나 동시 작성 시 차례를 보장하는 경계로 사용할 수 없다.

**제안:** 일기장을 접근 제어 단위로 삼고 UID 기반 멤버십·초대 수락·탈퇴/해제 정책을 먼저 정의한다. 작성자는 인증된 UID에서 결정하고 서버가 멤버·역할·차례를 검증한다. 기록 생성과 차례 변경은 서버의 원자적 작업으로 처리한다. 오프라인 교환 글은 임시 저장과 서버 승인 완료를 구분한다. `isMe`는 현재 UID에서 계산하는 화면 속성으로 전환한다.

공개 공유도 [share_screen.dart:10](/Users/papas/AI-Works/projects/lifelog/lib/features/share/share_screen.dart:10)의 hash 기반 모의 URL뿐이다. 실제 출시 전 서버 발급 공유 식별자, 공개 필드 범위, 만료·취소, 사진 접근까지 구현해야 한다. 현재 링크가 외부에서 작동한다고 안내하면 안 된다.

### J2 · P1 · 전체 백업이 기록을 완전히 복원하지 못함 [확인]

**근거:** [backup_json.dart:157](/Users/papas/AI-Works/projects/lifelog/lib/features/export/backup_json.dart:157), [backup_json.dart:215](/Users/papas/AI-Works/projects/lifelog/lib/features/export/backup_json.dart:215), [settings_screen.dart:298](/Users/papas/AI-Works/projects/lifelog/lib/features/settings/settings_screen.dart:298), [settings_screen.dart:397](/Users/papas/AI-Works/projects/lifelog/lib/features/settings/settings_screen.dart:397).

확인된 누락과 복구 위험:

- `contentRich`가 JSON 직렬화·역직렬화 양쪽에 없어 복원 시 본문 서식이 사라진다. 로컬 DB의 서식 보존 테스트가 있어도 JSON 백업 보존을 보장하지 않는다.
- “전체 백업” 화면은 `getAll()` 기반 provider만 사용하므로 휴지통 일기·일기장을 포함하지 않는다. 백업 함수가 `deletedAt`을 지원하는 것과 실제 UI가 삭제 기록을 넘기는 것은 다르다.
- 멤버·교환 차례는 백업 형식에 없어 새 기기에서 공유 일기장 상태가 복구되지 않는다.
- 복원은 여러 행을 트랜잭션 없이 순차 upsert한다. 중간 실패 시 일부만 덮어쓴 상태가 남는다. 버전 숫자는 읽지만 지원 가능한 버전인지 검사하지 않는다.

**제안:** Firebase 이관에 앞서 백업 계약부터 수정한다. 활성/휴지통, 본문 서식, 모든 사진 경로, 멤버와 필요한 로컬 상태를 포함하고 미래 버전은 안전하게 거부한다. 원격 권한은 백업의 role/owner 값을 그대로 신뢰해 복구하지 않는다. 파싱·관계 검증·미리보기 후 로컬 복원을 트랜잭션으로 실행한다. 기존 `jr_default` 같은 고정 ID는 다른 기기 백업 병합 시 매핑 정책이 필요하다.

### J3 · P2 · 본문·캔버스·인라인 사진이 독립 경로라 서식 일관성이 깨짐 [확인]

**근거:** [entry_detail_screen.dart:156](/Users/papas/AI-Works/projects/lifelog/lib/features/entry_detail/entry_detail_screen.dart:156), [content_flow.dart:15](/Users/papas/AI-Works/projects/lifelog/lib/features/decorate/content_flow.dart:15), [page_canvas.dart:317](/Users/papas/AI-Works/projects/lifelog/lib/features/decorate/page_canvas.dart:317).

상세 화면의 합성 페이지 분기는 `content`만 전달하고, `flowPhotos` 분기도 평문 흐름을 사용한다. `contentRich`는 그 두 분기에 들어가지 않을 때만 렌더된다. 따라서 본문 서식이 있는 기록에 꾸미기/인라인 사진을 함께 쓰면 저장된 서식이 상세 화면에서 반영되지 않을 수 있다. 갤러리 사진의 장식은 별도 인덱스 배열이고, 인라인 사진은 문단 번호, 캔버스는 자유 좌표이므로 이동·삭제·버전 변경의 결합 비용도 크다.

**제안:** 단기에는 모든 읽기 분기가 동일한 리치텍스트 렌더러를 사용하게 한다. 중기에는 안정적인 블록/미디어 ID를 기준으로 본문과 사진을 참조하고, 검색용 평문은 원본 문서에서 파생한다. 캔버스에는 이미 `version`이 있지만 버전별 이행/거부 처리가 없다. 알 수 없는 미래 버전이나 파싱 실패를 빈 캔버스로 표시한 뒤 저장해 원본을 잃지 않도록 원본 보존·오류 상태를 둔다.

### J4 · P2 · 관계·복구 불변식이 repository 밖에 흩어짐 [확인]

**근거:** [app_database.dart:75](/Users/papas/AI-Works/projects/lifelog/lib/core/db/app_database.dart:75), [app_database.dart:95](/Users/papas/AI-Works/projects/lifelog/lib/core/db/app_database.dart:95), [app_database.dart:421](/Users/papas/AI-Works/projects/lifelog/lib/core/db/app_database.dart:421), [app_database.dart:353](/Users/papas/AI-Works/projects/lifelog/lib/core/db/app_database.dart:353).

일기장/답장 참조의 FK와 `(journalId, userId)` 멤버 유일성 제약이 없고, 단일 일기 영구 삭제는 해당 행만 지운다. 답장이 있는 부모 삭제 시 자식의 보존·숨김·연쇄 삭제 정책이 구현상 명확하지 않다. 누락 컬럼 복구는 일부 실패를 무시해 운영 원인을 관찰하기 어렵다.

**제안:** 일기장 삭제·복원, 부모 기록 삭제, 멤버 해제의 불변식을 서비스/repository 계층에 명시하고 가능한 관계 제약을 둔다. 컬럼 복구 후 재검증과 오류 보고를 추가한다. 데모 데이터는 `count == 0` 때마다 재주입하기보다 별도의 데모 모드나 최초 실행 표식으로 제한한다.

## 7. 사진 저장 정책

### P1 · P1 · Base64를 포함한 일기 행을 그대로 Firestore에 옮길 수 없음 [확인·전환 차단]

**근거:** [write_screen.dart:241](/Users/papas/AI-Works/projects/lifelog/lib/features/write/write_screen.dart:241), [page_deco_editor.dart:302](/Users/papas/AI-Works/projects/lifelog/lib/features/decorate/page_deco_editor.dart:302), [inline_photo_editor.dart:45](/Users/papas/AI-Works/projects/lifelog/lib/features/decorate/inline_photo_editor.dart:45).

사진 바이트가 Base64로 변환되어 `mediaUrls`, 캔버스 photo layer의 `value`, `flowPhotos.path`에 저장된다. 첨부 갤러리는 크기 옵션 없이 다중 선택하고, 캔버스는 최대 너비 1200, 인라인은 1600을 요청해 경로별 정책도 다르다. 최종 바이트 수·장수·총용량을 공통으로 제한하는 계층은 없다.

Base64의 크기는 대략 원본의 4/3이다. 예를 들어 800 KiB 사진 하나는 문자열만 약 1.04 MiB가 되어 본문 없이도 Firestore의 문서 한도 1 MiB를 넘는다. 이는 현재 Drift 저장 오류를 뜻하는 것이 아니라 **한 일기를 그대로 한 Firestore 문서로 이관하는 방식을 차단하는 조건**이다. [Firebase 문서 크기 제한](https://firebase.google.com/docs/firestore/quotas)

현재도 전체 일기 조회·갱신 때 사진 문자열까지 읽고, 백업은 이를 거대한 JSON/클립보드로 복사한다. 누적 사진량에 비례해 메모리·처리 시간·로컬 저장 공간 부담이 커진다. 정량 성능은 기기에서 별도 측정이 필요하다.

**제안:** 사진 바이트는 파일/Cloud Storage로 분리하고, 일기에는 `mediaId`를 저장한다. `mediaUrls`만 바꾸지 말고 캔버스와 인라인 사진도 함께 이관해야 한다. 메타데이터에는 소유/일기장 범위, storage path, 형식, 크기, 해상도, checksum, 업로드 상태를 둔다. 목록에는 썸네일과 가벼운 기록 요약만 읽는다.

### P2 · P1(클라우드 사진 출시 시) · 사진 접근·보존·삭제 정책 없음 [설계 공백]

`firebase_options.dart`의 bucket 이름은 Storage 구현을 의미하지 않는다. 이 저장소에는 Storage SDK 의존성·업로더·Storage 규칙·미디어 삭제 작업이 확인되지 않는다. 아래는 승인 전 정책 초안이다.

| 항목 | 제안 정책 | 정해야 할 값/검증 |
|---|---|---|
| 원본 | 일기 열람용 최적화본과 썸네일 저장. 원본 보관은 별도 선택 | 원본 보관 여부·비용·다운로드 기대치 |
| 입력 | 세 사진 경로를 하나의 수집/검증 서비스로 통합 | 장당 바이트·픽셀·일기당 장수·계정 총량 |
| 형식 | 실제 디코딩 가능 여부 검증, 방향 정규화, 지원 형식 통일 | HEIC/GIF/투명도 처리. GPS 등 EXIF 제거 여부 |
| 접근 | 일기장 멤버와 소유권에 연동. 공개 공유는 별도 허용 경로 | 탈퇴/공유 취소 후 신규 접근 차단, 로컬 캐시 처리 |
| 저장 순서 | 로컬 초안 → 업로드 → 확인 → 기록 참조 확정 | 중단·재시도·중복 업로드·업로드만 성공한 고아 파일 |
| 휴지통 | 복원 기간 동안 참조된 사진 보존 | 30일 기준 시각, 삭제 중 복원 경합 |
| 영구 삭제 | 모든 갤러리/인라인/캔버스 참조가 없어졌을 때 비동기 삭제 | 다른 기록에서 재사용하는 파일의 참조 추적 |
| 공유 URL | 영구 공개 URL을 비공개 사진 접근 통제의 대용으로 사용하지 않음 | 취소·만료가 가능한 전달 방식, 취소 전 다운로드본은 회수 불가 |
| 백업 | JSON manifest와 미디어 파일을 묶은 이식 가능한 내보내기 | URL만 백업하지 않기, 누락/해시 검증, 파일 저장 방식 |

Storage 규칙은 인증·파일 크기·콘텐츠 타입 검사와 Firestore 문서를 통한 권한 검사를 지원한다. 구체적인 제한은 앱의 선택 화면뿐 아니라 서버/규칙에서도 집행해야 한다. [Firebase Storage 규칙](https://firebase.google.com/docs/storage/security/rules-conditions)

기존 Base64 이관은 계정 귀속 확정 후 모든 저장 위치를 순회하고, 동일 사진을 계정 범위에서 식별해 업로드한 뒤 해시/개수를 검증하는 방식이 적절하다. 새 참조의 열람과 백업 복구를 확인하기 전에는 기존 Base64를 제거하지 않는다. 재실행해도 중복되지 않는 진행 기록과 실패 목록을 남긴다.

## 8. 권장 목표 구조와 작업 순서

화면과 도메인 모델은 최대한 유지하고 데이터 경계를 보강하는 점진 전환을 권한다.

```text
UI / Riverpod
  └─ 기록·일기장 서비스 (현재 UID, 멤버 권한, 문서 revision 검증)
       ├─ 계정별 로컬 repository + 변경 outbox
       ├─ Firestore 동기화 (일기장 / 멤버 / 기록 / 삭제 이력)
       └─ MediaRepository (로컬 파일 / Storage / 썸네일 / 업로드 큐)

관리자 UI → 관리자 API → 초안 / 게시본 / 감사 기록
꾸미기 UI → 상품 카탈로그 + 사용자 보유권 + 버전 고정 에셋
```

클라우드 모델의 후보는 `journals/{journalId}`를 권한 단위로 두고 멤버십·기록·미디어를 연결하는 방식이다. 개인 즐겨찾기 등 사용자별 상태는 공유 기록 본문과 분리하는 편이 안전하다. 작성자가 고른 일기 날짜와 실제 서버 생성 시각도 분리해야 현재 `createdAt` 역일자 기능이 동기화/교환 차례 기준을 오염시키지 않는다. 최종 경로는 홈·검색·공유의 쿼리 요구와 규칙 검증 후 확정한다.

| 단계 | 범위 | 완료 기준 |
|---|---|---|
| 1. 현재 기록 보호 | F1, F4, J2 및 상태 문서의 구현 범위 정정 | 계정 교체 시 격리, 지연 AI가 최신 기록/삭제를 되돌리지 않음, 완전한 백업 왕복 |
| 2. Firebase 기반 | F2, UID/게스트 이관, 규칙, 진단 | 웹/Android 인증·설정 검증, 비멤버 접근 거부, 기존 데이터 귀속 명확화 |
| 3. 사진과 동기화 | F3, P1/P2, 문서 버전·변경 큐 | 오프라인/재시작/부분 실패 복구, 사진 이관 재실행 가능, 원본 보존 검증 |
| 4. 실제 공유 | J1, 답장·삭제 정책, 공유 링크 | 두 계정·두 기기 테스트, 동시 작성 원자성, 해제/취소 반영 |
| 5. 운영과 샵 | 관리자 게시 흐름, 원격 무료 카탈로그, 이후 유료 보유권 | 게시 롤백, 과거 꾸미기 보존, 중복 구매·환불 검증 |

1단계가 안정화되기 전 대규모 DB 교체나 기능을 넓히는 리팩터링은 권하지 않는다. 관리자·샵의 UI 시안은 병행할 수 있지만 운영 쓰기·유료 판매는 데이터/권한 모델 이후에 연결해야 한다.

## 9. 후속 검증 계획과 한계

기존 테스트 소스에는 repository의 `contentRich` 보존, 로컬 일기장 연쇄 삭제, JSON 일부 필드 왕복, 게스트 세션 테스트가 있다. 이번 검토에서는 테스트를 실행하지 않았으므로 통과 여부를 주장하지 않는다. 특히 다음은 기존 단위 함수 테스트와 별도로 필요하다.

1. A 로그인 → 작성 → 로그아웃 → B/게스트 로그인: 일기·휴지통·사진·진행 중 작업의 격리.
2. AI 응답 지연 중 수정·공개 범위 변경·소프트/영구 삭제: 오래된 응답이 어떤 상태도 복구하지 않는지 확인.
3. 리치텍스트·세 사진 경로·휴지통·멤버를 담은 백업을 빈 DB에 복원하여 필드/파일 비교. 복원 중 실패의 원자성 확인.
4. 본문 서식과 캔버스/인라인 사진 조합의 편집→읽기→백업 왕복 확인.
5. Firebase Emulator에서 소유자·파트너·비멤버·익명·일반 관리자 역할별 일기/공지 초안/사진/상품 권한 확인.
6. 두 클라이언트의 오프라인 수정·동시 교환 글·멤버 해제·삭제/복원 경합과 재시도 확인.
7. 사진 대량 누적 시 저사양 Android/모바일 웹의 메모리·응답 시간·저장 실패 측정.

운영 Firebase 프로젝트의 실제 규칙, 데이터 유무, 인증 설정, 별도 관리자 저장소, 배포 버전, 노출 키 폐기 여부는 미확인이다. `PROJECT_STATUS.md`의 Hosting 최신 반영 및 GitHub Pages 실패 이력도 이번 코드 검토로 재확인하지 않았다. 구현을 시작하기 전 결정할 사항은 **기존 게스트 데이터 귀속, Drift 유지 여부, 원본 사진 보관, 공유 종료 후 기록 소유·열람, 샵 무료/유료 범위**다.
