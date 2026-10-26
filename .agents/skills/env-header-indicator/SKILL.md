---
name: env-header-indicator
description: 개발(dev), 테스트(test), 운영(prod) 환경을 헤더 환경 뱃지와 브라우저 탭 제목으로 시각 구분하는 UI 패턴 스킬. 헤더 배경색을 변경하지 않고 여러 환경 탭이 동시에 열릴 때 오조작을 방지한다.
---

# 환경별 헤더 인디케이터 스킬

여러 환경(dev/test/staging/prod)의 웹 앱이 동시에 브라우저에 열려 있을 때, **어느 환경에서 작업 중인지 한눈에 구분**할 수 있도록 헤더 환경 뱃지와 브라우저 탭 제목을 자동으로 분기하는 UI 패턴이다 (헤더 배경색은 변경하지 않음).

---

## 1. 핵심 원칙

1. **운영 환경(prod)은 변경 없음**: 기존 디자인(색상, 타이틀)을 그대로 유지한다. 사용자에게 노출되는 prod UI에 `[PROD]` 뱃지를 붙이지 않는다.
2. **비운영 환경만 시각 표시**: dev, test, staging 등 비운영 환경에서만 뱃지와 탭 제목 접두어를 적용한다.
3. **⚠️ 헤더 배경색 변경 절대 금지**: 환경 구분을 위해 헤더 배경색을 변경하지 않는다. 기존 디자인의 색상을 그대로 유지하고, 환경 구분은 **뱃지 텍스트(DEV/TEST/STG)와 브라우저 탭 제목 접두어**로만 수행한다. `headerBg`, `headerBgHex` 등 배경색 관련 속성을 사용하지 않는다.
4. **기존 환경변수 재활용 우선**: `NODE_ENV`, `NEXT_PUBLIC_APP_URL` 등 프로젝트에 이미 존재하는 환경변수로 환경을 판별할 수 있으면 새 환경변수를 만들지 않는다. 기존 수단으로 구분이 불가능할 때만 `NEXT_PUBLIC_APP_ENV` 같은 전용 변수를 도입한다. 미설정 시 `production`으로 간주한다.
5. **중앙 집중 설정**: 환경별 레이블/타이틀 접두어를 하나의 설정 파일(예: `src/lib/env-config.ts`)에서 관리한다. 컴포넌트마다 분기 로직을 반복하지 않는다.

---

## 2. 환경 설정 테이블

| 환경 | `NEXT_PUBLIC_APP_ENV` | 뱃지 | 탭 제목 접두어 |
|---|---|---|---|
| 개발 (로컬) | `dev` 또는 `development` | `DEV` | `[DEV]` |
| 테스트 | `test` | `TEST` | `[TEST]` |
| 스테이징 | `staging` | `STG` | `[STG]` |
| 운영 | `production` 또는 미설정 | 없음 | 없음 |

> **헤더 배경색은 변경하지 않는다.** 환경 구분은 뱃지와 탭 제목만으로 충분하며, 기존 디자인의 색상을 유지해야 한다.

---

## 3. 구현 패턴 (Next.js App Router + Tailwind CSS)

### 3-1. 환경 설정 유틸리티

```typescript
// src/lib/env-config.ts

type AppEnv = 'dev' | 'test' | 'staging' | 'production';

interface EnvConfig {
  env: AppEnv;
  label: string | null;       // 헤더 뱃지 텍스트 (prod는 null)
  titlePrefix: string;        // 브라우저 탭 제목 접두어
}

const ENV_MAP: Record<AppEnv, Omit<EnvConfig, 'env'>> = {
  dev: {
    label: 'DEV',
    titlePrefix: '[DEV] ',
  },
  test: {
    label: 'TEST',
    titlePrefix: '[TEST] ',
  },
  staging: {
    label: 'STG',
    titlePrefix: '[STG] ',
  },
  production: {
    label: null,
    titlePrefix: '',
  },
};

function resolveEnv(): AppEnv {
  const raw = process.env.NEXT_PUBLIC_APP_ENV?.toLowerCase() || '';
  if (raw === 'dev' || raw === 'development') return 'dev';
  if (raw === 'test') return 'test';
  if (raw === 'staging' || raw === 'stg') return 'staging';
  return 'production';
}

export const envConfig: EnvConfig = {
  env: resolveEnv(),
  ...ENV_MAP[resolveEnv()],
};
```

### 3-2. 헤더 컴포넌트 적용

> [!CAUTION]
> 헤더 배경색은 **절대 변경하지 않는다.** `headerBg`, `headerBgHex` 등 배경색 속성을 `env-config`에 추가하지 않는다. 환경 구분은 뱃지와 탭 제목만으로 충분하다.

```tsx
// Header.tsx 내부
import { envConfig } from '@/lib/env-config';

// ✅ 기존 헤더 배경색 클래스를 그대로 유지한다. style 속성으로 배경색을 덮지 않는다.
<header className="... 기존-배경색-클래스 ...">
  {/* 환경 뱃지 (dev/test/staging만 표시, prod는 숨김) */}
  {envConfig.label && (
    <span className="ml-1.5 px-1.5 py-0.5 text-[10px] font-black rounded bg-slate-700 text-white leading-none">
      {envConfig.label}
    </span>
  )}
  <h1>서비스 이름</h1>
  ...
</header>
```

### 3-3. 브라우저 탭 제목 (layout.tsx)

Next.js App Router에서는 `metadata`가 정적이므로, 동적 제목이 필요하면 `generateMetadata`를 사용하거나 클라이언트에서 `document.title`을 설정한다.

**방법 A — 정적 metadata + 빌드 시 접두어 주입**:
```typescript
// layout.tsx
import { envConfig } from '@/lib/env-config';

export const metadata: Metadata = {
  title: `${envConfig.titlePrefix}향린교회 주일 출석부`,
};
```

> `NEXT_PUBLIC_*`는 빌드 시 인라인되므로 정적 metadata에서도 사용 가능하다.

**방법 B — 클라이언트 동적 제목** (SSR 후 hydration 시 적용):
```tsx
// EnvTitleUpdater.tsx (layout에 포함)
'use client';
import { useEffect } from 'react';
import { envConfig } from '@/lib/env-config';

export function EnvTitleUpdater() {
  useEffect(() => {
    if (envConfig.titlePrefix) {
      document.title = `${envConfig.titlePrefix}${document.title}`;
    }
  }, []);
  return null;
}
```

### 3-4. 로그인 페이지

로그인 페이지에도 같은 `envConfig`를 사용하여 브라우저 탭 타이틀과 뱃지를 분기한다 (배경색은 유지).

---

## 4. 환경변수 설정 위치

| 환경 | 설정 파일 | 값 |
|---|---|---|
| 로컬 개발 | `.env` 또는 `.env.local` | `NEXT_PUBLIC_APP_ENV=dev` |
| 테스트 서버 | `.env.test` 또는 CI 환경변수 | `NEXT_PUBLIC_APP_ENV=test` |
| 스테이징 | Docker env / 배포 설정 | `NEXT_PUBLIC_APP_ENV=staging` |
| 운영 | 설정하지 않거나 `production` | (미설정 → 자동 production) |

---

## 5. 체크리스트

- [ ] `NEXT_PUBLIC_APP_ENV` 환경변수가 비운영 환경에만 설정되어 있는가?
- [ ] prod에서는 헤더 뱃지/탭 제목이 기존과 동일한가? (회귀 없음, 뱃지 미노출)
- [ ] dev/test에서 헤더 배경색이 변경되지 않고 기존 디자인을 온전히 유지하는가?
- [ ] dev/test에서 헤더 뱃지와 브라우저 탭 제목(`[DEV]`, `[TEST]`)이 정상 표시되는가?
- [ ] 환경 뱃지 텍스트가 최소 10px 이상이고 명확히 읽히는가?
- [ ] 환경 설정이 `env-config.ts` 한 곳에서만 관리되고 있는가?

---

## 6. 적용 범위

이 패턴은 프레임워크에 독립적이다. Next.js 외에도:
- **React SPA**: `REACT_APP_ENV` + `public/index.html` title 분기
- **Vue/Nuxt**: `NUXT_PUBLIC_APP_ENV` + `useHead()` 분기
- **정적 HTML**: 빌드 스크립트에서 환경별 HTML 생성

핵심은 **"환경변수 1개 → 중앙 설정 → 탭 제목 및 헤더 뱃지 반영"** 구조를 유지하는 것이다 (헤더 배경색 유지).
