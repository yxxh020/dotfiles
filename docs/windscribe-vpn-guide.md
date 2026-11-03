# Windscribe VPN CLI 설치 및 사용 가이드

> **관련 이슈**: #282  
> **적용 환경**: Ubuntu / Debian / Fedora / RHEL 및 Linux 환경  
> **목적**: 해외 서비스(OpenRouter 등) 가입이나 지역 제한 우회가 필요할 때 Windscribe VPN CLI를 설치하고 사용하는 절차를 정리합니다.

---

## 개요

* Windscribe는 Linux에서 백그라운드 서비스 기반의 가벼운 CLI 도구(`windscribe-cli`)를 제공합니다.
* GUI를 설치해도 되며, 필요 시 다른 VPN(미국 설정이 가능한 도구)으로 대체 가능합니다.
* 무료 플랜으로 월 10GB(이메일 인증 시 15GB) 트래픽이 제공되며, 매월 1일에 초기화됩니다.

---

## 1. 설치

### 1-1. Ubuntu / Debian (`.deb` 패키지)

공식 웹사이트([windscribe.com/install/desktop/linux](https://windscribe.com/install/desktop/linux))에서 최신 버전을 확인 후 설치합니다.

```bash
# 1) deb 패키지 다운로드
wget https://assets.windscribe.com/desktop/linux/windscribe-cli_2.24.12_amd64.deb

# 2) dpkg로 패키지 설치
sudo dpkg -i windscribe-cli_2.24.12_amd64.deb

# 3) 의존성 문제 발생 시 자동 해결
sudo apt-get install -f
```

### 1-2. Fedora / RHEL (`.rpm` 패키지)

```bash
# 공식 사이트에서 rpm 패키지 다운로드 후 설치
sudo dnf install ./windscribe-cli_*.rpm
```

### 1-3. 설치 확인

```bash
which windscribe-cli
windscribe-cli --version
```

> [!IMPORTANT]
> 실행 명령어 이름은 `windscribe`가 아니라 **`windscribe-cli`**입니다. `windscribe` 명령은 존재하지 않으므로 주의하세요.

---

## 2. 헬퍼 서비스 확인

Windscribe는 백그라운드 헬퍼 서비스(`windscribe-helper.service`)가 필요합니다.

```bash
# 1) 서비스 상태 확인
systemctl status windscribe-helper.service

# 2) 서비스가 꺼져 있으면 수동 시작
sudo systemctl start windscribe-helper.service

# 3) 부팅 시 자동 시작 등록 (설치 시 기본 활성화됨)
sudo systemctl enable windscribe-helper.service
```

---

## 3. 계정 로그인

```bash
# 대화형 로그인 (사용자명 및 비밀번호 프롬프트)
windscribe-cli login

# 또는 사용자명을 인자로 전달
windscribe-cli login <username>
```

> [!CAUTION]
> 비밀번호는 KeePassXC에서 안전하게 관리합니다. 터미널 히스토리에 패스워드가 노출되지 않도록 대화형 프롬프트 입력 방식을 사용하세요.  
> *계정 정보: KeePassXC → `Windscribe` 항목 참조*

* **계정 생성**: 계정이 없는 경우 [windscribe.com](https://windscribe.com)에서 무료 가입 가능 (기본 10GB + 이메일 인증 5GB = 총 15GB).

---

## 4. 연결 및 제어

### 4-1. VPN 서버 연결

```bash
# 자동 최적 서버 연결
windscribe-cli connect

# 특정 국가 서버 지정 연결
windscribe-cli connect US       # 미국 (OpenRouter 가입 권장)
windscribe-cli connect JP       # 일본
windscribe-cli connect KR       # 한국
windscribe-cli connect GB       # 영국
```

### 4-2. 연결 해제

```bash
windscribe-cli disconnect
```

### 4-3. 연결 상태 및 데이터 잔량 확인

```bash
windscribe-cli status
```

**출력 예시:**
```text
인터넷 연결: 사용 가능
로그인 상태: 로그인 됨
방화벽 상태: 끄기
연결 상태: 연결 됨
공개 IP: xxx.xxx.xxx.xxx
데이터 사용량: 91.10 MB / 10.00 GB
```

### 4-4. 사용 가능 서버 위치 조회

```bash
windscribe-cli locations
```

---

## 5. 실제 사용 사례: OpenRouter 가입 및 API 키 발급

해외 지역 제한이 있는 API 제공사(OpenRouter 등) 초기 가입 및 결제 시 활용 절차:

```bash
# 1) VPN 미국 서버 연결
windscribe-cli login <username>
windscribe-cli connect US

# 2) 브라우저에서 https://openrouter.ai 접속 및 가입, API 키 발급

# 3) 발급받은 API 키를 시스템 Keyring(secret-tool)에 안전 등록
secret-tool store --label="OpenRouter" Title "OpenRouter"

# 4) 가입 완료 후 VPN 해제
windscribe-cli disconnect
```

> [!NOTE]
> OpenRouter API는 지역 제한이 없으므로, 가입 및 키 발급 이후 실제 API 호출 단계에서는 VPN 연결 없이 로컬 네트워크에서 바로 사용 가능합니다.

---

## 6. Jev CLI 연동 (`bin/jev`)

OpenRouter 또는 TypeSafe API를 경유하여 고속 "System One" 자동 판정/라우팅을 수행하는 CLI 도구가 제공됩니다:

* **실행 파일**: [`bin/jev`](file:///Users/hwang/dotfiles/bin/jev) (`~/.local/bin/jev`)
* **API 키 로드 순서**:
  1. 환경변수 `TYPESAFE_API_KEY` (공식 엔드포인트)
  2. 환경변수 `OPENROUTER_API_KEY` (OpenRouter 엔드포인트)
  3. 시스템 Keyring / secret-tool (`Title: openrouter`, `Title: typesafe` 등)

### Jev CLI 빠른 사용법

```bash
# 1) 카테고리 분류 (다지선다)
jev "사용자가 로그인 비밀번호 재설정 링크를 받지 못했습니다" -c "auth,billing,bug,general"

# 2) Yes/No 판정
jev "서버 디스크 사용량이 98%에 도달했습니다" -y "즉각적인 긴급 조치가 필요한 장애 상황인가?"

# 3) 스크립트용 정적 결과값만 출력 (--quiet)
CATEGORY=$(jev "이슈 내용" -c "feature,bug,docs" -q)

# 4) 신뢰도 점수 (0.0 ~ 1.0)
jev "이 제안서의 완성도를 평가해주세요" --score "완성도 점수 (0.0 ~ 1.0)"
```

---

## 7. 트러블슈팅

### `windscribe: command not found`
* 실행 명령어는 `windscribe`가 아니라 **`windscribe-cli`**입니다.
  ```bash
  windscribe-cli status   # ✅ 올바른 명령
  windscribe    status    # ❌ 존재하지 않는 명령
  ```

### `Failed to start windscribe.service: Unit not found`
* 시스템 서비스 이름은 `windscribe.service`가 아니라 **`windscribe-helper.service`**입니다.
  ```bash
  sudo systemctl start windscribe-helper.service   # ✅ 올바른 서비스명
  ```

### 로그인 실패 / 인증 오류 발생 시
```bash
# 로그아웃 후 다시 대화형 로그인 진행
windscribe-cli logout
windscribe-cli login
```

### 무료 데이터 잔량 확인
```bash
windscribe-cli status | grep "데이터 사용량"
```

---

## 8. 관련 문서

* **회사 VPN (`openfortivpn`)**: `tasks/023-vpn-lin/`
* **ProtonVPN 설정 가이드**: [`docs/protonvpn-manual.md`](file:///Users/hwang/dotfiles/docs/protonvpn-manual.md)
* **Jev CLI 스크립트**: [`bin/jev`](file:///Users/hwang/dotfiles/bin/jev)
