---
name: phone-input-expert
description: 한국 휴대폰 번호 입력 필드에 대한 표준 UX 패턴 스킬. IMaskInput 기반으로 010 자동 채움, 커서 위치 제어, 하이픈 자동 삽입, 중간 편집 정상 동작, 저장 시 하이픈 제거를 구현한다.
---

# 전화번호 입력 전문가 스킬

회원가입, 프로필 수정, 관리자 등록 등 전화번호 입력이 필요한 모든 UI에 적용하는 표준 UX 패턴.

## 핵심 구현 패턴

### ✅ 올바른 구현 (IMaskInput 사용)

```tsx
import { IMaskInput } from "react-imask";

<IMaskInput
  mask="000-0000-0000"
  value={field.value || ""}
  onAccept={(value: string) => field.onChange(value)}
  onFocus={(e: React.FocusEvent<HTMLInputElement>) => {
    const len = e.target.value.length;
    e.target.setSelectionRange(len, len);
  }}
  placeholder="010-XXXX-XXXX"
/>
```

### ❌ 잘못된 구현 (사용 금지)

```tsx
// ❌ 커서가 항상 끝으로 이동하는 버그 발생
<Input
  onChange={(e) => {
    const formatted = formatPhoneNumber(e.target.value);
    field.onChange(formatted);
  }}
/>
```

**이유**: React controlled input에서 `onChange`로 전체 값을 교체하면 브라우저가 커서를 항상 끝으로 리셋함 → Home, Delete, 중간 클릭 편집 불가.

## 기본값 설정

```ts
defaultValues: {
  phone: "010",   // ← "010"으로 초기화 (빈 문자열 X)
}
```

## 저장 시 하이픈 제거

API 전송 또는 DB 저장 전에 하이픈을 제거한다:

```ts
const phoneRaw = values.phone?.replace(/-/g, "") ?? ""; // "01012345678"
```

## Zod 유효성 검사 스키마

```ts
phone: z
  .string()
  .optional()
  .refine(
    (val) => !val || /^010-\d{4}-\d{4}$/.test(val),
    { message: "올바른 휴대폰 번호 형식이 아닙니다. (예: 010-1234-5678)" }
  ),
```

## IMaskInput이 커서 문제를 해결하는 이유

`react-imask`는 DOM 이벤트를 직접 처리하고 내부적으로 커서 위치를 추적·복원한다.
React의 `onChange` 사이클 밖에서 동작하므로 controlled input의 커서 리셋 문제가 없다.

| 기능 | `Input + onChange` | `IMaskInput` |
|------|-------------------|-------------|
| 하이픈 자동 삽입 | ✅ (수동 구현) | ✅ (mask로 자동) |
| 커서 중간 편집 | ❌ (항상 끝으로 이동) | ✅ |
| Home/Delete 키 | ❌ | ✅ |

## 의존 패키지

```bash
npm install react-imask
```
