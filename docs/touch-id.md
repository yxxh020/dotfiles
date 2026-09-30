# macOS 터미널에서 Touch ID로 sudo 인증 설정하기

macOS 터미널에서 `sudo` 명령어를 실행할 때, 매번 비밀번호를 입력하는 대신 MacBook의 Touch ID를 사용하여 간편하게 인증할 수 있습니다.

## 1. 운영체제별 설정 방식
macOS 버전에 따라 권장 설정 방식이 다릅니다. 이 가이드는 최신 버전(Sonoma 14.0 이상)에서 시스템 업데이트 후에도 설정이 영구적으로 유지되는 방식을 따릅니다.

- **macOS Sonoma (14.0) 이상**: `/etc/pam.d/sudo_local` 파일을 사용하는 방식 (권장)
- **이전 버전**: `/etc/pam.d/sudo` 파일을 직접 수정하는 방식

## 2. 설정 단계 (Sonoma 이상 권장)

최신 macOS에서는 `/etc/pam.d/sudo_local` 파일을 생성하여 안전하게 설정할 수 있습니다.

### 2.1. 설정 파일 생성 및 활성화
터미널에서 아래 명령어를 순서대로 입력하세요.

1. **템플릿 파일 복사하여 설정 파일 생성**
   ```bash
   sudo cp /etc/pam.d/sudo_local.template /etc/pam.d/sudo_local
   ```

2. **Touch ID 인증 모듈 활성화**
   설정 파일 내의 `#auth` 주석을 해제합니다.
   ```bash
   sudo sed -i '' 's/#auth/auth/' /etc/pam.d/sudo_local
   ```

### 2.2. (수동 확인 시) 파일 내용 확인
파일이 아래와 같은 내용을 포함하고 있는지 확인합니다 (`cat /etc/pam.d/sudo_local`).
```bash
# sudo_local: local config file which survives system update and is included for sudo
# uncomment following line to enable Touch ID for sudo
auth       sufficient     pam_tid.so
```

## 3. 적용 확인
새로운 터미널 창을 열고 아래 명령어를 입력하여 Touch ID 팝업이 뜨는지 확인합니다.
```bash
sudo ls
```

## 4. 트러블슈팅

### Ghostty / iTerm2에서 작동하지 않는 경우
iTerm2 사용 시 Touch ID 팝업 대신 비밀번호 입력을 먼저 요구한다면 아래 설정을 확인하세요:
1. `iTerm2 Settings` (`Cmd + ,`) 창을 엽니다.
2. `Advanced` 탭을 선택합니다.
3. 검색창에 `auth`를 입력합니다.
4. **"Allow sessions to survive logging out and back in"** 항목을 **No**로 변경합니다.

### SSH 접속 시
Touch ID는 로컬 기기 지문 인식 센서를 통한 인증이므로, 원격 SSH 세션에서는 비밀번호를 입력해야 합니다.
