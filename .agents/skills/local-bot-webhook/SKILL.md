---
name: local-bot-webhook
description: 사용자의 텍스트를 카카오톡 오픈빌더 JSON 응답 형식(SimpleText, BasicCard 등)으로 자동 포맷팅하고 로컬 웹훅 서버로 테스트 요청을 전송한다.
---

# 로컬 챗봇 연동 및 웹훅 테스트 스킬 (Local Bot Webhook Skill)

이 스킬은 사용자가 "이 내용을 카카오톡 봇 응답 형태로 만들어서 테스트해 봐"라고 지시할 때 발동됩니다.

## 동작 원리 및 지침
당신(AI 에이전트)은 다음 절차에 따라 작업을 수행합니다:

1. **응답 포맷팅 (Kakao i Open Builder Spec)**:
   사용자의 요청 내용을 분석하여 카카오톡 챗봇 응답 규격에 맞는 JSON 문자열을 생성한다.
   기본 구조 예시 (`SimpleText` 기준):
   ```json
   {
     "version": "2.0",
     "template": {
       "outputs": [
         {
           "simpleText": {
             "text": "사용자가 원하는 응답 내용"
           }
         }
       ]
     }
   }
   ```
   만약 사용자 요청이 이미지나 버튼을 포함해야 한다면 `BasicCard` 구조를 생성해라.

2. **로컬 웹훅 전송**:
   생성된 JSON 데이터를 `curl` 명령어를 사용하여 로컬 테스트 서버(기본값: `http://localhost:5000/webhook` 또는 사용자가 지정한 주소)로 전송한다.
   ```bash
   curl -X POST -H "Content-Type: application/json" \
        -d '{"version": "2.0", "template": {"outputs": [{"simpleText": {"text": "테스트 응답"}}]}}' \
        http://localhost:5000/webhook
   ```
   *참고: JSON 내부에 싱글 쿼테이션(`'`)이 들어가지 않도록 주의하여 Bash 명령어가 깨지지 않게 조립해라.*

3. **결과 보고**:
   - 전송에 성공하면 HTTP 200/OK 응답 결과를 보고하고, 생성했던 JSON 구조를 사용자에게 보여줍니다.
   - 서버가 켜져 있지 않아 `Connection refused` 에러가 나더라도 "웹훅 서버가 열려있지 않으나 JSON 페이로드는 정상적으로 생성되었습니다"라고 안내하며 JSON 코드를 출력한다.

## 주의 사항
- 항상 `version: "2.0"`을 포함해야 카카오 규격에 맞다.
- 실제 상용망(외부 API)으로 쏘지 말고, 반드시 로컬 주소(`localhost` 또는 `127.0.0.1`)를 타겟으로 해라.
