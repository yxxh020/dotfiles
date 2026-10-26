---
name: playwright-safe-setup
description: Playwright 신규 설정 시 시스템 Chrome 대량 로그아웃을 방지하고, 메인 크롬 무간섭(Zero-Interference) 원칙에 따라 독립 전용 프로필을 안전하게 초기화 및 실행하는 가이드 스킬.
---

# Playwright 안전 설정 및 실행 스킬 (`playwright-safe-setup`)

Playwright, Puppeteer 등 브라우저 자동화를 신규 프로젝트나 새로운 환경에 도입할 때, **사용자의 일상 업무용 메인 크롬 세션을 100% 안전하게 보호하고 무간섭(Zero-Interference) 원칙으로 독립 프로필을 설정**하는 표준 가이드이다.

---

## 🎯 트리거 조건

- 새로운 프로젝트나 작업에서 Playwright/Puppeteer 브라우저 자동화를 처음 도입하거나 스크립트를 작성할 때
- "Playwright로 로그인 세션 보존해서 자동화해줘", "전용 크롬 프로필로 스크립트 작성해줘" 등의 요청이 있을 때
- 브라우저 자동화 도중 기존 사용자 크롬의 세션 풀림이나 프로세스 충돌(SingletonLock)을 원천 방지해야 할 때

---

## ⛔ [절대 금지] 메인 크롬 대량 로그아웃을 유발하는 안티패턴

과거 발생했던 "모든 크롬 계정 강제 로그아웃 대참사"는 아래 3가지 잘못된 시도로 인해 발생한다. **어떤 상황에서도 아래 행동은 절대 수행하지 마십시오.**

1. **기존 메인 크롬 프로필 디렉터리 복사 금지 (`cp -r ~/.config/google-chrome ...`)**:
   - 크롬은 리눅스 키링(`Secret Service`/`gnome-keyring`)을 통해 프로필의 **절대 경로** 및 시스템 머신 ID와 결합하여 쿠키 및 로그인 토큰을 암호화한다.
   - 프로필 폴더를 다른 위치로 복사하여 구동하면 크롬 보안 엔진이 **"토큰 탈취 시도(경로 불일치)"**로 감지하여 **모든 구글 계정 및 웹사이트 세션을 즉시 강제 파기(로그아웃)**한다.
2. **전체 크롬 강제 종료 금지 (`pkill chrome`, `killall chrome`)**:
   - 크롬의 `SingletonLock` 에러를 피하겠다고 백그라운드에서 실행 중인 사용자의 크롬을 강제 종료하면, 정상 종료 루틴을 타지 못해 프로필 계정 동기화 락(Sync Lock)이 걸리거나 세션이 유실됩니다.
3. **메인 크롬 경로 직접 지정 금지 (`user_data_dir="~/.config/google-chrome"`)**:
   - 자동화 스크립트와 사용자의 일상 브라우징이 충돌하여 프로세스 락 에러가 발생하고, 자동화 플래그(`AutomationControlled`)로 인해 메인 프로필에 유령 프로필(`Profile 11` 등)이 증식한다.

---

## ✅ [정석 절차] 완전 격리된 Playwright 프로필 구축 4단계

### 1단계: 프로젝트 전용 독립 디렉터리 경로 정의
사용자의 메인 크롬(`~/.config/google-chrome`)과 완전히 분리된 전용 디렉터리를 지정한다.

* **권장 경로 패턴**: `~/.config/<프로젝트명-용도>` (또는 프로젝트 디렉터리 내부 `user_data/`)
* **예시**: `~/.config/stu-admin-attendance`, `~/.config/my-project-crawler`
* **규칙**: 디렉터리를 미리 복사하지 않고, **비어 있는 상태**로 둡니다. (Playwright가 실행 시 필요한 구조만 자동 생성함)

---

### 2단계: `launch_persistent_context` 표준 코드 작성

일회용 `launch()`가 아닌 `launch_persistent_context()`를 사용해야 쿠키와 세션이 해당 폴더에 영구 보존됩니다.

#### Python 표준 코드
```python
import os
from playwright.async_api import async_playwright

# 1. 독립된 전용 프로필 경로 지정 (기존 크롬과 무관한 새 경로)
USER_DATA_DIR = os.path.expanduser("~/.config/my-project-automation")

async def run_safe_automation():
    async with async_playwright() as p:
        # launch_persistent_context로 독립 브라우저 구동
        # 사용자의 메인 크롬이 실행 중이어도 아무 영향 없이 동시 실행됨
        async with await p.chromium.launch_persistent_context(
            user_data_dir=USER_DATA_DIR,
            headless=False,  # 최초 1회 수동 로그인 시 False, 자동화 시 True
            executable_path="/usr/bin/google-chrome",  # 시스템 크롬 바이너리 사용
            args=[
                "--no-sandbox",
                "--disable-setuid-sandbox",
                "--disable-blink-features=AutomationControlled",
            ]
        ) as context:
            page = context.pages[0] if context.pages else await context.new_page()
            
            await page.goto("https://target-portal.example.com")
            # 세션은 USER_DATA_DIR 내부에만 안전하게 저장됨
            # 작업 완료 후 async with 블록을 빠져나가면서 해당 컨텍스트만 안전 종료됨
```

#### TypeScript / Node.js 표준 코드
```typescript
import { chromium } from 'playwright';
import path from 'path';
import os from 'os';

const userDataDir = path.join(os.homedir(), '.config', 'my-project-automation');

const context = await chromium.launchPersistentContext(userDataDir, {
  headless: false,
  executablePath: '/usr/bin/google-chrome',
  args: [
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--disable-blink-features=AutomationControlled'
  ]
});

const page = context.pages()[0] || await context.newPage();
await page.goto('https://target-portal.example.com');
// 작업 완료 후 context만 종료
await context.close();
```

---

### 3단계: 최초 1회 로그인 및 세션 안착 (헤드풀 모드)
1. 최초 1회만 `headless=False`로 실행하여 전용 브라우저 창을 띄웁니다.
2. 해당 전용 창에서 사용자가 아이디/비밀번호 입력 및 2차 인증(OTP)을 완료한다.
3. 브라우저 창을 정상적으로 닫으면, 로그인 쿠키 및 세션 정보가 `USER_DATA_DIR/Default/Network/Cookies`에 영구 보존됩니다.
4. **이 모든 과정 중 사용자의 원래 업무용 크롬 창은 켜두어도 상관없으며, 아무런 영향도 받지 않다.**

---

### 4단계: 무중단 백그라운드 자동화 전환 (헤드리스 모드)
1. 이후 일상적인 스크립트 실행이나 크론탭(crontab) 스케줄러 등록 시에는 `headless=True`로 실행한다.
2. 이미 3단계에서 저장된 세션을 그대로 불러오므로, 재로그인 없이 즉시 대상 페이지로 접근할 수 있다.

---

## 📋 신규 자동화 구축 시 안전 체크리스트

| 점검 항목 | 올바른 상태 | 위험 상태 (즉시 중단) |
| :--- | :--- | :--- |
| **`user_data_dir` 경로** | `~/.config/<전용폴더>` 또는 `prj/user_data` | `~/.config/google-chrome` |
| **디렉터리 생성 방식** | 비어있는 디렉터리에서 자동 생성 | 기존 프로필 폴더 복사(`cp -r`) |
| **프로세스 관리** | `context.close()` 또는 `async with` 정상 종료 | `pkill chrome` 등 강제 종료 명령어 |
| **메인 크롬 공존 여부** | 메인 크롬을 띄워둔 상태에서 동시 실행 가능 | 메인 크롬을 꺼야만 실행되는 상태 |
