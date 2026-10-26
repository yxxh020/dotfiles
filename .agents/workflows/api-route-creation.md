---
description: Next.js App Router, Prisma, Zod를 사용하여 견고한 API 라우트를 생성하는 표준 절차.
---

# 워크플로우: Next.js API 라우트 생성

새로운 백엔드 API 엔드포인트를 만들 때 이 워크플로우를 사용한다.

## 1. 요청 스키마 정의 (Zod)

요청 페이로드 또는 쿼리 파라미터에 대한 엄격한 Zod 스키마를 먼저 정의한다. API가 유효한 데이터만 처리하도록 보장한다. 공유 `lib/validations` 폴더에 두거나, 매우 특정한 경우 라우트 파일 내에 직접 둔다.

## 2. 라우트 핸들러 스캐폴딩 (Next.js App Router)

`src/app/api/[라우트경로]/route.ts`에 라우트 파일을 생성한다. 해당 HTTP 메서드 핸들러를 export한다 (`export async function POST(req: Request) { ... }`).

## 3. 실행 로직 구현 (Prisma)

핸들러 내부에서:
1. Zod 스키마로 요청을 파싱하고 검증한다 (`schema.parse` 또는 `schema.safeParse`).
2. 검증 실패 시 Zod 에러 상세와 함께 `400 Bad Request`를 즉시 반환한다.
3. 검증 통과 시 Prisma 데이터베이스 쿼리를 작성한다. `try/catch`로 잠재적 DB 예외를 처리한다.

## 4. 응답 표준화

API가 일관된 JSON 구조를 반환하도록 한다.
- **성공 (`200 OK` 또는 `201 Created`)**: `{ "success": true, "data": { ... } }`
- **클라이언트 에러 (`400`, `401`, `403`, `404`)**: `{ "success": false, "error": "명확한 에러 메시지" }`
- **서버 에러 (`500`)**: 예기치 않은 에러를 캐치하여 앱 크래시를 방지하고 `{ "success": false, "error": "Internal Server Error" }`를 반환한다. 실제 에러는 내부적으로 로깅한다.

## 5. 보안 및 인증 확인 (권장)

엔드포인트가 특정 사용자 역할을 요구하면(예: Admin), 요청 검증 직후 Prisma 쿼리 실행 전에 사용자의 토큰/세션을 확인한다. 확인 실패 시 `401 Unauthorized` 또는 `403 Forbidden`을 반환한다.
