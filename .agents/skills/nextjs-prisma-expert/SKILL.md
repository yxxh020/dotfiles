---
name: nextjs-prisma-expert
description: Prisma와 Zod를 사용하는 Next.js App Router 프론트엔드 API 라우트 전문가 스킬. 별도 백엔드 서비스가 아닌 프론트엔드 측 API 라우트에만 적용.
---

> **[안내]** 이 파일은 각 프로젝트가 복사해갈 때 프로젝트 상황에 맞게 수정하여 사용하는 템플릿이다.
> 적용 시 이 안내 문구를 제거하고 프로젝트에 맞게 내용을 수정한다.

# Next.js 프론트엔드 API 전문가

> **참고**: 이 스킬은 **프론트엔드 측 API 라우트** (예: `src/app/api/`)를 다룬다.
> 별도의 백엔드 서비스(NestJS, Express 등)에는 해당 백엔드 스킬을 사용한다.

Next.js 프론트엔드 앱에 자체 API 라우트 핸들러가 필요한 경우(예: 요청 프록시, OAuth 콜백 처리, 경량 데이터 작업)를 처리하는 스킬이다.

## 1. 역할과 전문 영역

Next.js App Router 서버 사이드 로직과 프론트엔드 인접 작업을 위한 Prisma 데이터 접근에 전문화된 시니어 프론트엔드 엔지니어로서 행동한다.

## 2. 기술 표준

- **라우트 위치**: `src/app/api/<your-route>/route.ts`
- **메서드 내보내기**: `export async function GET(req: Request) { ... }`
- **Zod 검증**: DB 호출이나 외부 호출 전에 모든 요청 바디와 쿼리 파라미터를 검증한다
- **Prisma**: 작업이 프론트엔드 특화인 경우에만 사용. 그렇지 않으면 HTTP 클라이언트를 통해 백엔드 서비스에 위임한다

## 3. 표준화된 응답

```typescript
// 성공
return Response.json({ success: true, data: result }, { status: 200 });

// 클라이언트 오류
return Response.json({ success: false, error: '메시지' }, { status: 400 });

// 서버 오류
return Response.json({ success: false, error: 'Internal Server Error' }, { status: 500 });
```

## 4. 이 스킬 vs 백엔드 서비스 사용 기준

| 상황 | 사용 |
|------|------|
| 신규 비즈니스 도메인 API (핵심 엔티티) | 백엔드 서비스 스킬 |
| OAuth 콜백, 토큰 갱신 프록시 | `nextjs-prisma-expert` |
| SSR에 필요한 경량 읽기 전용 작업 | `nextjs-prisma-expert` |
| 역할 기반 접근 제어가 필요한 모든 작업 | 백엔드 서비스 스킬 |

## 5. 운영 지침

1. 먼저 백엔드 API 클라이언트를 확인한다 — 백엔드 서비스가 이미 필요한 것을 제공하고 있을 수 있다.
2. Prisma 쿼리 작성 전 반드시 `prisma/schema.prisma`를 확인한다.
3. 민감한 데이터를 노출하기 전에 프로젝트의 인증 유틸리티로 JWT 토큰을 검증한다.
4. 코드와 주석은 영어로만 작성한다.

---

## 하네스 연동

### Phase 0 — 레슨 로드
이 스킬을 사용하는 작업을 시작하기 전에 다음을 읽는다:
- `.agents/learnings/general.md`
- `.agents/learnings/nextjs-prisma-expert.md`

관련 레슨을 먼저 적용한 뒤 진행한다.

### Phase 5 — 레슨 기록
중요한 작업 완료 후, 다음 경우에 해당하면 `.agents/learnings/nextjs-prisma-expert.md`에 레슨을 추가한다:
- 예상보다 어려웠던 부분이 있었을 때
- 반복될 패턴이 발견되었을 때
- 다음에 방지해야 할 실수를 했을 때
- 사용자가 출력 결과를 의미 있게 수정했을 때

> 레슨이 **3회 이상** 반복되면 → `rules-project.md` 또는 프로젝트 규칙 반영 후보로 승격한다.

### ⛔ 혼자 결정하면 안 되는 사항
- 명시적 승인 없이 백엔드를 우회하는 새 API 라우트 추가
- 여러 라우트에서 공유하는 Zod 스키마 변경
