---
name: form-persistence-expert
description: 페이지 새로고침이나 네트워크 오류 시 사용자 입력 데이터 손실을 방지하기 위해 sessionStorage를 활용하여 폼 입력을 보존하고 복원하는 UI/UX 전문가 스킬.
---

# 폼 입력 보존 전문가 스킬

웹 폼에서 사용자가 입력한 데이터가 실수로 새로고침되거나 네트워크 오류가 발생했을 때 손실되지 않도록 보존 로직을 구현한다.

## 핵심 책임

1. **데이터 손실 방지**: 사용자가 입력하는 동안 폼 데이터를 `sessionStorage`에 자동 저장한다.
2. **상태 복원**: 폼 컴포넌트가 마운트될 때 `sessionStorage`에 저장된 임시 데이터를 확인하고 복원한다.
3. **정리**: 폼이 성공적으로 제출되면 임시 `sessionStorage` 데이터를 즉시 삭제하여 다음 방문 시 오래된 데이터가 남지 않도록 한다.

## 구현 가이드라인

### 1. 감시 및 sessionStorage 저장

`useEffect`를 사용하여 모든 폼 값을 감시하고 JSON으로 직렬화하여 `sessionStorage`에 저장한다.

```tsx
const allValues = form.watch();
useEffect(() => {
  sessionStorage.setItem("myUniqueFormKey", JSON.stringify(allValues));
}, [allValues]);
```

### 2. 초기 마운트 시 복원

별도의 `useEffect`에서 마운트 시 `sessionStorage`를 읽어 폼 값을 설정한다. 빈 값이나 undefined 값으로 덮어쓰지 않도록 주의한다.

```tsx
useEffect(() => {
  const savedData = sessionStorage.getItem("myUniqueFormKey");
  if (savedData) {
    try {
      const parsedData = JSON.parse(savedData);
      Object.keys(parsedData).forEach((key) => {
        if (parsedData[key] !== undefined && parsedData[key] !== null && parsedData[key] !== "") {
          form.setValue(key, parsedData[key]);
        }
      });
    } catch (e) {
      console.error("sessionStorage 폼 데이터 파싱 실패", e);
    }
  }
}, [form]);
```

### 3. 성공 시 정리

`onSubmit` 핸들러에서 API 응답이 **성공**한 경우 반드시 `sessionStorage`에서 해당 항목을 제거한 뒤 다음 동작(페이지 이동, 성공 다이얼로그 등)을 수행한다.

```tsx
apiClient.post('/api/submit', data)
  .then(() => {
    sessionStorage.removeItem("myUniqueFormKey"); // 성공 시 반드시 삭제
    showSuccessDialog();
  })
  .catch((err) => {
    // 오류 시에는 삭제하지 않음 — 재시도 시 데이터 유지
    showErrorMessage();
  });
```

## 주요 고려사항

- **`sessionStorage` 사용**: 민감한 폼 데이터(회원가입, 결제 등)는 `localStorage` 대신 `sessionStorage`를 사용하여 탭 종료 시 자동 삭제되도록 한다.
- **고유한 저장 키**: 저장 키(`myUniqueFormKey`)는 해당 폼에 고유하게 설정하여 다른 폼과의 충돌을 방지한다.
- **JSON.parse 안전 처리**: 반드시 `try...catch` 블록 안에서 파싱한다.
- **폼 라이브러리 호환**: `react-hook-form`, `formik`, `zustand` 등 어떤 상태 관리를 사용하든 동일한 패턴을 적용할 수 있다.
