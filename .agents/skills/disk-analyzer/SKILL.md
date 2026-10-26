---
name: disk-analyzer
description: "디스크 일별 사용량 CSV 추이 분석 및 필요 시 디렉터리 용량 분석을 수행하는 스킬."
---
# 디스크 분석 스킬 (Disk Analyzer)

디스크 공간 상태를 점검하거나 용량 추이 및 불필요하게 급증한 항목을 파악할 때 사용한다.

## 1. 트리거 조건
- "디스크 상황 분석해 줘", "디스크 용량 추이 확인해 줘", "용량이 왜 늘었지?"
- "어떤 폴더가 용량을 차지하고 있어?", "디스크 점검해 줘"

## 2. 2단계 분석 절차 (우선순위 원칙)

### 1단계: 일별 CSV 시계열 데이터 우선 분석 (1순위 - 빠른 응답)
`~/dotfiles/data/disk_usage_daily_*.csv` 파일이 존재하는 경우, 무거운 실시간 `du` 전체 스캔 대신 **CSV 데이터를 파이썬으로 신속하게 집계하여 보고**한다.

- **분석 파이썬 원라이너/스크립트**:
  ```bash
  python3 -c '
  import csv, socket, os
  from collections import defaultdict

  hostname = socket.gethostname()
  csv_path = os.path.expanduser(f"~/dotfiles/data/disk_usage_daily_{hostname}.csv")
  if not os.path.exists(csv_path):
      csv_path = os.path.expanduser("~/dotfiles/data/disk_usage_daily.csv")

  data = defaultdict(lambda: defaultdict(dict))
  dates = set()
  with open(csv_path) as f:
      for r in csv.DictReader(f):
          d, cat, p, s = r["Date"], r["Category"], r["Path"], float(r["Size_GB"])
          dates.add(d)
          data[cat][p][d] = s

  sorted_dates = sorted(list(dates))
  date_hdr = " | ".join(d[5:] for d in sorted_dates)
  print(f"=== [1. 루트/홈/프로젝트 총량 추이 (단위: GB)] ===")
  print("%-18s | %s" % ("항목", date_hdr))
  for cat, p, label in [("TOTAL_ROOT", "/", "Root (/)"), ("HOME_TOTAL", os.path.expanduser("~"), "Home (~/)"), ("PRJ_TOTAL", os.path.expanduser("~/prj"), "Prj (~/prj)")]:
      vals = [f"{data[cat][p].get(d, 0.0):6.2f}" for d in sorted_dates]
      print("%-18s | %s" % (label, " | ".join(vals)))
  '
  ```

### 2단계: 특정 디렉터리 실시간 정밀 스캔 (2순위 - CSV 부재 또는 특정 폴더 정밀 분석 요청 시)
CSV 데이터가 없거나, 사용자가 "특정 폴더(`/var/log`, `~/.cache` 등) 실시간 용량 조사해 줘"라고 명시한 경우에만 `du` 명령어를 실행한다.

```bash
# 특정 대상 디렉터리만 타겟팅하여 depth 1~2 스캔
du -h --max-depth=1 /path/to/target 2>/dev/null | sort -rh | head -n 20
```

## 3. 리포팅 표준 (Reporting Standard)
1. **총량 추이 테이블**: 루트(`/`), 홈(`~/`), 프로젝트(`~/prj`)의 날짜별 변화 및 일평균 증감 보고.
2. **주요 증가/감소 요인 표**: 최근 기간 대비 용량 변동이 큰 폴더와 원인 추정(패키지 캐시, 컨테이너 볼륨, 빌드 아티팩트 등).
3. **공간 회수 제안**: 캐시 정리(`pnpm store prune`, `~/.cache` 정리 등) 안전한 최적화 방안 안내.
4. **안전 제일**: 임의로 파일을 삭제하지 않으며, 삭제 명령어 실행 전 반드시 사용자의 명시적 승인을 받음.
