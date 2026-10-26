---
name: disk-cleaner
description: 시스템의 불필요한 패키지 캐시, 저널 로그, Flatpak 미사용 런타임을 안전하게 청소하여 디스크 공간을 확보하는 스킬.
---

# 디스크 정리 스킬 (Disk Cleaner)

이 스킬은 시스템 디스크 공간 부족을 해결하기 위해 불필요한 패키지 캐시, 오래된 시스템 로그, 미사용 런타임 등을 안전하게 청소하여 공간을 확보한다.

## 🚫 금지 사항 (Forbidden Actions)
1. **Google Chrome 웹 캐시 정리 금지**: Google Chrome 웹 캐시(`~/.cache/google-chrome/`)는 지워봤자 웹 서핑 시 즉시 재생성되며, 디스크 트래픽만 유발하므로 **정리 대상에서 제외**한다. (단, Opera, Firefox 등 기타 브라우저의 임시 캐시는 정리 가능)
2. **웹 브라우저 프로필 및 개인 데이터 보호**: 로그인 세션, 쿠키, 저장된 비밀번호, 북마크, 방문 기록(`~/.config/google-chrome/`, `~/.config/opera/` 등)은 절대 임의로 삭제하지 않다.
3. **컨테이너/이미지 일괄 삭제 금지**: Podman/Docker의 `prune -a`와 같은 전체 삭제는 이미지 재다운로드 및 재빌드 비용이 발생하므로 **절대 기본 삭제 옵션으로 사용하지 않다.**

## 트리거 및 사용 조건
- 사용자가 "디스크 정리해 줘", "용량 확보해 줘", "캐시 청소해 줘" 등 디스크 정리를 명시적으로 요청할 때 발동한다.
- 디스크 분석 스킬(`disk-analyzer`)의 수행 결과 디스크 공간 부족(예: 사용량 90% 이상)이 탐지되고 사용자가 정리를 요청/승인했을 때 발동한다.

## 실행 및 정리 지침 (Action & Guidelines)

### 1. 개발 패키지 매니저 캐시 정리
오래 쌓여 있는 개발 패키지 빌드/다운로드 캐시를 청소한다.
```bash
# pnpm 글로벌 스토어 미사용 패키지 정리
pnpm store prune

# pip 패키지 다운로드 캐시 정리
pip cache purge

# yarn / npm 패키지 캐시 정리 (필요시)
yarn cache clean
```

### 2. Systemd Journal 시스템 로그 정리
누적된 시스템 저널 로그의 보관 기간 및 용량을 제한하여 정리한다.
```bash
# 최근 7일간의 로그만 남기고 이전 아카이브 저널 삭제
sudo journalctl --vacuum-time=7d
```

### 3. Flatpak 미사용 런타임 정리
애플리케이션 삭제 후 시스템에 남아 있는 미사용 Flatpak 공통 런타임을 지웁니다.
```bash
flatpak uninstall --unused -y
```

### 4. 기타 브라우저 및 임시 캐시 정리 (Chrome 제외)
Google Chrome을 제외한 기타 브라우저(Opera, Firefox 등) 및 임시 툴 캐시를 정리한다.
```bash
# Opera / Firefox 웹 임시 캐시 정리 (Chrome은 제외)
rm -rf ~/.cache/opera/Cache/* ~/.cache/mozilla/firefox/*.default*/cache2/* 2>/dev/null || true

# 임시 툴 캐시 정리
rm -rf ~/.cache/datalab/* ~/.cache/qmd/* ~/.cache/thumbnails/* 2>/dev/null || true
```

### 5. 컨테이너/이미지 현황 참고 보고 (Podman / Docker)
컨테이너 리소스는 함부로 지우지 않고, 대형 이미지/컨테이너 현황을 참고 정보로만 보고한다. 사용자의 명시적 지정 요청이 있을 때만 특정 이미지를 삭제한다.
```bash
# Podman 거대 이미지/컨테이너 세부 조회 (참고용)
podman images --sort size
podman ps -a --sort size
```

## 리포팅 및 안전 규칙 (Reporting & Safety Rules)

1. **Google Chrome 캐시 제외 규칙 준수**: Google Chrome 웹 캐시(`~/.cache/google-chrome/`)는 제외하고, Opera/Firefox 등 기타 브라우저는 임시 캐시만 정리.
2. **프로필 데이터 보호**: 모든 브라우저의 로그인 상태, 쿠키, 북마크는 절대 삭제하지 않음.
3. **컨테이너 삭제 주의**: `prune -a` 금지, 사용자 지시 시에만 단일 이미지 삭제.
4. **명시적 승인**: `sudo journalctl` 등 권한 명령은 사전에 안내 후 수행.
5. **결과 검증 (Essential)**: 정리 작업 완료 후 반드시 `df -h /` 명령을 실행하여 **정리 전후의 사용량 및 실제 확보된 공간(GB)**을 정량적으로 요약 보고한다.
