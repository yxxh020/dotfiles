---
name: add-dbeaver-connection
description: DBeaver의 가져오기 메뉴나 GUI 입력이 동작하지 않을 때 data-sources.json에 직접 DB 접속 정보를 병합하여 추가한다.
---

# DBeaver 접속 정보 직접 추가 가이드 (add-dbeaver-connection)

이 문서는 DBeaver의 가져오기(Import) 메뉴나 GUI 입력이 동작하지 않거나 버전 불일치가 있을 때, 로컬 DBeaver 설정 디렉토리 내의 `data-sources.json`을 직접 편집하여 데이터베이스 접속 정보를 주입/병합하는 방법을 규정한다.

## 1. DBeaver 설정 디렉토리 탐색

Linux 환경에서 DBeaver의 기본 workspace 경로는 다음과 같습니다:
`~/.local/share/DBeaverData/workspace6/General/.dbeaver/data-sources.json`

만약 다른 workspace명을 사용 중이라면 아래 명령어로 `data-sources.json`의 위치를 먼저 찾습니다:

```bash
find ~ -maxdepth 6 -name "data-sources.json" 2>/dev/null
```

## 2. data-sources.json 병합 패턴

검색된 `data-sources.json` 파일을 열어 기존의 `"connections"` 객체 내부에 추가할 데이터베이스 커넥션 메타데이터를 추가한다.

### 템플릿 예시

```json
"your-mysql-connection-id": {
  "provider": "mysql",
  "driver": "mysql8",
  "name": "My MySQL Connection",
  "save-password": true,
  "configuration": {
    "host": "your_db_host",
    "port": "your_db_port",
    "database": "your_database_name",
    "url": "jdbc:mysql://your_db_host:your_db_port/your_database_name",
    "user": "your_username",
    "password": "your_password",
    "configurationType": "MANUAL",
    "type": "dev",
    "auth-model": "native"
  }
},
"your-postgres-connection-id": {
  "provider": "postgresql",
  "driver": "postgres-jdbc",
  "name": "My PostgreSQL Connection",
  "save-password": true,
  "configuration": {
    "host": "your_db_host",
    "port": "your_db_port",
    "database": "your_database_name",
    "url": "jdbc:postgresql://your_db_host:your_db_port/your_database_name",
    "user": "your_username",
    "password": "your_password",
    "configurationType": "MANUAL",
    "type": "dev",
    "auth-model": "native"
  }
}
```
