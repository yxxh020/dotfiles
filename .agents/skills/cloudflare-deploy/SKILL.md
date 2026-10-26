---
name: cloudflare-deploy
description: >
  Next.js 프로젝트를 Cloudflare Workers(OpenNext 어댑터)로 빌드·배포하는 전문가 스킬.
  배포 전 확인 사항, 명령, 계정 정보 구성, 환경변수 관리법을 다룹니다.
  배포 관련 작업 전 반드시 이 스킬을 숙지해야 한다.
---

# Cloudflare 배포 스킬

## 🔑 계정 & 인증 정보 위치

| 항목 | 위치 | 비고 |
|---|---|---|
| **wrangler OAuth 토큰** | `~/.config/.wrangler/config/default.toml` | 자동 관리됨, 만료 시 `npx wrangler login` 재실행 |
| **Cloudflare 계정 이메일** | `[CF_EMAIL]` | 실제 클라우드플레어 계정 이메일 |
| **Account ID** | `[CF_ACCOUNT_ID]` | Cloudflare 대시보드에서 확인 가능 |
| **Worker 이름** | `[WORKER_NAME]` | `wrangler.toml` → `name = "[WORKER_NAME]"` |
| **배포 URL** | `https://[WORKER_NAME].[SUBDOMAIN].workers.dev` | Workers 기본 제공 서브도메인 또는 커스텀 도메인 |
| **환경변수(로컬)** | `.env.local` (또는 프론트엔드 폴더 내 `.env.local`) | gitignore 대상, 직접 편집 |
| **Supabase 등 DB 대시보드** | 프로젝트 대시보드 | API URL 및 ANON KEY 확인 |

> ⚠️ 로컬 환경변수의 값을 수정하면 **재빌드 + 재배포**가 필요한다.
> wrangler는 빌드 시 `.env.local` 또는 `.env`에 정의된 클라이언트 환경변수(`NEXT_PUBLIC_*` 등)를 자동으로 번들에 포함한다.

---

## 🚀 배포 명령 (표준 절차)

```bash
# 1. 프로젝트 루트로 이동 (또는 빌드 대상 디렉토리로 이동)
cd [PROJECT_ROOT]/[FRONTEND_DIR]

# 2. OpenNext 빌드 (Next.js → Workers 번들 생성)
pnpm run pages:build   # 또는 빌드 명령어로 지정된 스크립트 실행

# 3. Cloudflare에 배포
pnpm run pages:deploy  # wrangler deploy 실행 스크립트
```

빌드와 배포 스크립트는 일반적으로 `package.json`에 다음과 유사하게 정의되어 있어야 합니다:

```json
"scripts": {
  "pages:build":   "opennextjs-cloudflare build",
  "pages:preview": "opennextjs-cloudflare preview",
  "pages:deploy":  "opennextjs-cloudflare deploy"
}
```

---

## 🛠️ 구성 파일 위치

| 파일 | 역할 |
|---|---|
| `wrangler.toml` | Worker 이름, main 진입점, assets 경로, 호환성 플래그 |
| `open-next.config.ts` | OpenNext 어댑터 설정 (KV, R2 등 바인딩 추가 시 여기) |
| `.open-next/` | 빌드 산출물 (gitignore 대상, 커밋 금지) |

### wrangler.toml 표준 템플릿

```toml
name = "[WORKER_NAME]"
main = ".open-next/worker.js"
compatibility_date = "2025-06-01"
compatibility_flags = ["nodejs_compat"]

[assets]
directory = ".open-next/assets"
binding = "ASSETS"
```

---

## 🌍 환경변수 관리

### 로컬 개발
개발 시 실제 접속 정보를 환경변수 파일에 입력한다 (gitignore, 커밋 금지):

```bash
ENVIRONMENT_ENV=development
NEXT_PUBLIC_API_URL=http://localhost:3000
NEXT_PUBLIC_SUPABASE_URL=https://[PROJECT].supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=[ANON_KEY]
```

### Cloudflare 배포 시
`NEXT_PUBLIC_*` 변수는 빌드 타임에 번들에 포함되므로 **환경변수 파일의 값이 그대로 배포됩니다**.
서버 전용 시크릿(서버 측 env)은 `npx wrangler secret put KEY_NAME`으로 별도 등록해야 합니다:

```bash
# 예: 서버 전용 시크릿 등록
echo "VALUE" | npx wrangler secret put SECRET_KEY_NAME --name [WORKER_NAME]

# 등록된 시크릿 목록 확인
npx wrangler secret list --name [WORKER_NAME]
```

---

## 🔍 배포 상태 확인

```bash
# 인증 상태 및 계정 확인
npx wrangler whoami

# 배포 이력 확인
npx wrangler deployments list --name [WORKER_NAME]

# 사이트 응답 확인
curl -s -o /dev/null -w "%{http_code}" https://[WORKER_NAME].[SUBDOMAIN].workers.dev
```

---

## ⚠️ 주의사항

1. **`export const runtime = "edge"` 설정 시 주의** — OpenNext는 Node.js 호환 Workers 환경을 지원하므로 API Route에 Edge Runtime 선언을 강제로 추가하면 빌드가 실패할 수 있다.
2. **재빌드 필수 조건** — 환경변수 변경, 소스코드 변경 시 항상 `pages:build` → `pages:deploy` 순서로 실행해야 변경사항이 배포에 반영됩니다.
3. **로그인 만료** — CLI 토큰의 만료 시간이 지나 인증 에러가 나면 `npx wrangler login`으로 재인증을 수행한다.
4. **`.wrangler/` 폴더** — 로컬 캐시 폴더는 커밋되지 않도록 gitignore에 등록되어 있는지 반드시 확인한다.
5. **`pg` (node-postgres) 사용 시 `pg-cloudflare` 번들링 누락 에러**:
   - **증상**: OpenNext 빌드 시 `Could not resolve "pg-cloudflare"` 에러 발생
   - **원인**: `pg` 내부에서 Workers 환경 감지 시 `pg-cloudflare`를 동적 require하지만 번들러(esbuild)가 정적으로 추적하지 못함
   - **해결 절차**:
     1) `pnpm add -D pg-cloudflare` 설치
     2) `next.config.ts`에 번들 파일 추적 명시:
        ```typescript
        const nextConfig: NextConfig = {
          outputFileTracingIncludes: {
            "**/*": [
              "./node_modules/pg-cloudflare/dist/**",
              "./node_modules/pg-cloudflare/esm/**",
            ],
          },
        };
        ```
6. **`useSearchParams()` 사용 컴포넌트의 SSR 프리렌더 에러**:
   - **증상**: `Error occurred prerendering page "/admin/..."` 발생하며 빌드 워커 중단
   - **해결**: `useSearchParams()`를 포함한 GNB/내비게이션이 들어간 페이지 컴포넌트는 반드시 상위 또는 해당 페이지 레벨에서 `<Suspense fallback={...}>`로 감싸야 정적 빌드가 성공함.
