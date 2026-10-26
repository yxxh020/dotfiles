---
name: playwright-user-data-dir
description: Playwright E2E/웹 자동화 시 시스템 Chrome의 프로필 오염을 방지하고 계정별/프로젝트별 전용 user_data 경로를 고정하여 로그인 세션을 보존하며 Chrome 프로필 정렬, 동기화 트러블슈팅 및 계정 안전성을 관리하는 스킬.
---

# Playwright 전용 user_data 세션 관리 및 Chrome 프로필 정렬/동기화 관리 스킬 (`playwright-user-data-dir`)

이 스킬은 Playwright, Puppeteer, Chrome DevTools 등의 웹 자동화 도구를 실행할 때 매번 시스템 Chrome 사용자 설정 디렉터리(`~/.config/google-chrome/`)에 무분별한 `Profile XX`가 지속해서 생성되는 현상을 막고, **특정 크롬 프로필 디렉터리(`user_data`)**를 통해 로그인 세션(쿠키, 스토리지)을 영구 보존하며, Chrome 프로필 정렬 및 계정 동기화(Sync) 안전성을 관리하기 위한 가이드이다.

## 🎯 트리거 조건
- 사용자가 특정 계정/프로젝트 전용 크롬 프로필 세션 유지를 요청할 때 (예: "0번 계정 세션 유지해서 지시해줘", "stu 계정 전용 폴더로 자동화해줘" 등)
- Playwright 테스트나 브라우저 자동화 스크립트 작성/수정 시 시스템 기본 `google-chrome` 디렉터리 오염을 원천 방지해야 할 때
- Chrome 프로필 목록(`chls`), GUI 팝업 메뉴의 프로필 정렬/이름 변경, 또는 계정 동기화(Sync) 먹통 트러블슈팅이 필요할 때

---

## 🛠 핵심 동작 지침

### 1. 특정 크롬 프로필 디렉터리 고정 (`launchPersistentContext`)
Playwright 스크립트 작성 시 `chromium.launch()` 대신 `chromium.launchPersistentContext(userDataDir, ...)`를 사용하여 특정 크롬 프로필 디렉터리 경로를 고정 지정한다.

```typescript
import { chromium } from 'playwright';

// 1) 특정 프로젝트 전용 크롬 프로필 (예: 프로젝트 디렉터리 하위 user_data)
const userDataDir = '/home/hyuk/prj/<project-name>/user_data';

// 2) 특정 계정 전용 크롬 프로필 (예: ~/.config/playwright-profiles/<account_name>_user_data)
// const userDataDir = '/home/hyuk/.config/playwright-profiles/<account_name>_user_data';

const context = await chromium.launchPersistentContext(userDataDir, {
  headless: false,
  executablePath: '/usr/bin/google-chrome', // 또는 channel: 'chrome'
  viewport: { width: 1280, height: 800 },
  args: [
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--disable-blink-features=AutomationControlled'
  ]
});

const page = context.pages()[0] || await context.newPage();
```

### 2. 세션 활용 및 자동화 수행 규칙
- **최초 1회 로그인 세션 보존**: 해당 특정 크롬 프로필 디렉터리(`userDataDir`)로 브라우저를 구동 후 1회 로그인하면 세션 쿠키가 해당 폴더에 영구 보관됩니다.
- **로그인 단계 생략**: 자동화 작업(예: 성적 입력, 커리큘럼 등록, 데이터 수집) 진행 시 별도 로그인 절차 없이 목적 URL로 직접 접근하여 즉시 동작을 수행한다.
- **전체 Chrome 프로세스 완전 종료 원칙 (SingletonLock 해제)**: 크롬(Chromium)은 단일 마스터 프로세스 구조상 모든 프로필이 동일한 `SingletonLock`을 공유한다. 따라서 시스템 크롬 세션이나 특정 프로필(`Profile X`)을 연동할 때는 **단지 해당 프로필 창 하나만 닫는 것으로는 불충분하며, 시스템 전체 크롬 프로세스를 완전히 종료(`pkill -TERM chrome`)**해야 프로세스 충돌(ProcessSingleton 에러) 없이 정상 동작한다.
- **시스템 Chrome 오염 방지**: `~/.config/google-chrome/Local State`에 `Profile 11`, `12` 등이 지속 추가되는 것을 원천 차단한다.

---

## ⚠️ Chrome 프로필 정렬 및 계정 동기화(Sync) 안전 관리 및 트러블슈팅

### 🚨 [최우선 수칙] Google 계정 동기화 락(Lock) 방지 (`gaia_name` 보호)
- **절대 금지**: Chrome 프로필 순서나 표시 이름을 변경할 때 **`gaia_name` 및 `gaia_given_name` 필드를 수정하지 마십시오.**
- **원인**: `gaia_name`이 구글 서버상의 원래 계정 실명과 다르면 Chrome 보안 엔진이 OAuth2 계정 토큰 불일치로 감지하여 **동기화 버튼 클릭 먹통 및 탭 그룹/방문기록 동기화 차단 현상**이 발생한다.
- **올바른 수정 대상**: 프로필 표기명이나 순서 변경 시에는 **오직 `name` 필드만 수정**해야 한다.
  - 예: `info_cache["Profile 2"].name = "02. sqlroad.com"` (O)
  - 예: `info_cache["Profile 2"].gaia_name = "02. sqlroad"` (X - 절대 금지)

### 🛠️ [동기화 먹통 트러블슈팅] Sync-to-Signin 팝업 먹통 해결법
- **현상**: Chrome 프로필 팝업창에서 [사용] 또는 [동기화 켜기] 버튼을 클릭해도 아무런 반응이 없는 경우 (Sync-to-Signin 락).
- **해결책**: 팝업 버튼 대신 해당 크롬 창의 주소창에 아래 전용 설정 주소를 직접 입력하여 진입한 후 **[동기화 켜기]**를 클릭한다.
  ```text
  chrome://settings/syncSetup
  ```
- **탭 그룹 데이터 검증 팁**: 탭 그룹이나 세션이 사라진 것처럼 보일 경우, 프로필 폴더 내의 `Sessions` 디렉터리 바이너리 파일(`strings "$HOME/.config/google-chrome/<Profile>/Sessions/"*`)을 검색하여 탭 그룹 키워드를 수동 검증할 수 있다.

### 1) 터미널 목록(`chls`) 자연어 버전 정렬
- 터미널에서 프로필 목록을 조회할 때 단순 `sort` 대신 **`sort -V`** (Natural Version Sort)를 사용하여 `Profile 1`, `Profile 2` ... `Profile 10` 순으로 숫자 오름차순 정렬을 보장한다.

### 2) Chrome GUI 팝업 메뉴 오름차순 정렬 패턴
- Chrome 브라우저 GUI 우측 상단의 "기타 Chrome 프로필" 팝업 메뉴는 런타임에서 표시되는 프로필 이름(Display Name)을 기준으로 가나다/알파벳순으로 정렬한다.
- GUI 팝업 메뉴에서 번호 오름차순 정렬을 유지하려면 **`name` 필드 맨 앞에만 `01. `, `02. `, `03. `... 접두어를 명시**한다.
  - 예: `01. dplus.jeju.kr`, `02. sqlroad.com`, `03. ads`, `10. playwright`

---

## 📌 주요 개념 정의
- **특정 크롬 프로필 디렉터리 (`user_data`)**: 프로젝트 내 독립 폴더(`~/prj/<current-project>/user_data`) 또는 계정별 지정 전용 데이터 폴더 (`~/.config/playwright-profiles/<account>_user_data`)
- **계정별 전용 프로필**: 특정 로그인 세션을 100% 독립 보관하기 위해 분리된 크롬 사용자 데이터 폴더 (예: `stu_user_data`, `ads_user_data`)
