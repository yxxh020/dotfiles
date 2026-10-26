---
name: gnome-workspace-layout
description: GNOME Wayland 환경에서 단일/듀얼 모니터의 Primary 보정 및 Auto Move Windows 확장을 이용해 가상 데스크톱(워크스페이스)별 앱 자동 배치와 단축키를 구성·트러블슈팅한다.
---

# GNOME 워크스페이스 레이아웃 전문가 스킬

Ubuntu/GNOME Wayland 환경에서 단일 모니터 및 듀얼 모니터 환경의 가상 데스크톱(워크스페이스) 애플리케이션 자동 배치, 주 모니터 인식 트러블슈팅, 창 이동 단축키를 관리한다.

## 트리거 조건

- "워크스페이스 배치해줘", "가상 데스크톱 정해진 대로 띄워줘"
- "노트북 화면이 워크스페이스를 넘겨도 다 똑같이 나와", "보조 모니터가 주 모니터로 잡혀"
- "Auto Move Windows 설정해줘", "로그인 시 창 위치 자동화"
- 단일/듀얼 모니터 환경에서 워크스페이스 레이아웃을 구성하거나 수정할 때

---

## 핵심 아키텍처 및 메커니즘

### 1. GNOME의 워크스페이스 & 모니터 동작 원리
- **`org.gnome.mutter workspaces-only-on-primary = true` (기본 표준)**:
  - **주 모니터 (Primary)**: 워크스페이스 1, 2, 3 전환이 정상 적용됨.
  - **보조 모니터 (Secondary)**: 워크스페이스 전환에 영향받지 않고 모든 가상 데스크톱에서 항상 동일하게 고정되는 **공용 모니터**로 동작함.
- **주 모니터 오인식(Primary Inversion) 버그 및 원인**:
  - GNOME Mutter 컴포지터는 내부적으로 논리 모니터 배열의 **0번 인덱스(첫 번째 요소)**를 우선 Primary로 취급함.
  - 외부 모니터(HDMI)가 0번에 위치하면 외부 모니터만 워크스페이스가 넘어가고, 내장 디스플레이(노트북 eDP-1)는 "화면이 안 바뀌는 보조 모니터"로 전락하여 1, 2, 3번 모두 같은 창이 보이는 현상이 발생함.

---

## 실행 절차 및 표준 가이드

### Phase 1. 디스플레이 주 모니터 상태 진단 및 보정

노트북 내장 디스플레이(`eDP-1`)가 0번 인덱스이자 Primary(`primary=1`)인지 검증하고, 그렇지 않다면 Mutter D-Bus API로 즉시 보정한다.

```python
import dbus

bus = dbus.SessionBus()
obj = bus.get_object('org.gnome.Mutter.DisplayConfig', '/org/gnome/Mutter/DisplayConfig')
iface = dbus.Interface(obj, 'org.gnome.Mutter.DisplayConfig')
state = iface.GetCurrentState()
serial, monitors, logical_monitors, properties = state

current_modes = {}
for m in monitors:
    spec, modes, props = m
    conn = str(spec[0])
    for mode in modes:
        mode_id, w, h, rate, flags, scale_list, mode_props = mode
        if mode_props.get('is-current', False):
            current_modes[conn] = str(mode_id)
            break

# eDP-1을 0번 인덱스(Primary=True), 나머지를 보조(Primary=False)로 정렬
lm_edp = next((lm for lm in logical_monitors if lm[5][0][0] == 'eDP-1'), None)
lm_ext = next((lm for lm in logical_monitors if lm[5][0][0] != 'eDP-1'), None)

if lm_edp:
    entry_edp = dbus.Struct(('eDP-1', current_modes['eDP-1'], dbus.Dictionary({}, signature='sv')), signature='ssa{sv}')
    struct_edp = dbus.Struct((lm_edp[0], lm_edp[1], lm_edp[2], lm_edp[3], dbus.Boolean(True), dbus.Array([entry_edp], signature='(ssa{sv})')), signature='iiduba(ssa{sv})')
    
    new_list = [struct_edp]
    if lm_ext:
        conn_ext = str(lm_ext[5][0][0])
        entry_ext = dbus.Struct((conn_ext, current_modes[conn_ext], dbus.Dictionary({}, signature='sv')), signature='ssa{sv}')
        struct_ext = dbus.Struct((lm_ext[0], lm_ext[1], lm_ext[2], lm_ext[3], dbus.Boolean(False), dbus.Array([entry_ext], signature='(ssa{sv})')), signature='iiduba(ssa{sv})')
        new_list.append(struct_ext)

    # method 3 = PERSISTENT (~/.config/monitors.xml 자동 저장)
    iface.ApplyMonitorsConfig(dbus.UInt32(serial), dbus.UInt32(3), new_list, dbus.Dictionary({}, signature='sv'))
```

---

### Phase 2. Auto Move Windows 확장 설치 및 매핑 등록

1. **공식 패키지 설치**:
   ```bash
   sudo apt-get install -y gnome-shell-extension-auto-move-windows
   ```

2. **앱별 워크스페이스 매핑 등록 (`gsettings`)**:
   - 1번 워크스페이스: Chrome (`google-chrome.desktop:1`, `com.google.Chrome.desktop:1`)
   - 2번 워크스페이스: IDE / 개발 도구 (`orca.desktop:2`, `orca-ide.desktop:2`)
   - 3번 워크스페이스: 유틸리티 (`org.keepassxc.KeePassXC.desktop:3`, `org.gnome.Nautilus.desktop:3`, `Alacritty.desktop:3`, `alacritty.desktop:3`)
   
   > [!IMPORTANT]
   > `auto-move-windows` 확장은 오직 XDG 표준 애플리케이션 디렉터리(`/usr/share/applications/`, `~/.local/share/applications/`)에 존재하는 `.desktop` ID만 매핑한다.
   > 네이티브 설치와 Flatpak 설치 간 ID 차이(예: `google-chrome.desktop` vs `com.google.Chrome.desktop`) 및 Electron AppImage ID(`orca-ide.desktop`)를 안전하게 병기하고, 필요 시 `~/.local/share/applications/`에 심링크를 구성해야 한다.
   
   ```bash
   gsettings set org.gnome.shell.extensions.auto-move-windows application-list "[ \
     'google-chrome.desktop:1', \
     'com.google.Chrome.desktop:1', \
     'orca.desktop:2', \
     'orca-ide.desktop:2', \
     'org.keepassxc.KeePassXC.desktop:3', \
     'org.gnome.Nautilus.desktop:3', \
     'Alacritty.desktop:3', \
     'alacritty.desktop:3' \
   ]"
   ```

3. **GNOME Shell 확장 활성화 및 시작 지연(Delay) 구성**:
   - **확장 활성화**:
     ```bash
     gsettings set org.gnome.shell enabled-extensions "['ding@rastersoft.com', 'ubuntu-dock@ubuntu.com', 'tiling-assistant@ubuntu.com', 'auto-move-windows@gnome-shell-extensions.gcampax.github.com']"
     ```
   - **Autostart 2초 지연 (Race Condition 방지)**:
     로그인 직후 확장이 완전히 로드되기 전에 앱 창이 먼저 뜨면 기본 1번 화면에 남는 현상이 발생한다.
     따라서 시작 프로그램의 `Exec`에 `sh -c "sleep 2 && exec ..."` 형태로 2초 안전 지연을 부여해야 확장이 모든 새 창을 100% 감지하여 지정 워크스페이스로 이동시킵니다.

---

### Phase 3. 창 이동 단축키 표준 등록

작업 중 언제든 키보드로 현재 활성 창을 워크스페이스 1, 2, 3으로 즉시 보낼 수 있도록 표준 단축키를 구성합니다:

```bash
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Super><Shift>1']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Super><Shift>2']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Super><Shift>3']"
```

---

### Phase 4. 현재 열려 있는 창 즉시 분배 (런타임 조치)

`Auto Move Windows` 확장은 확장이 켜진 이후 새로 생성되는 창에만 적용되므로, **이미 열려 있는 창**은 `gtk-launch` 포커싱 + `ydotool` 단축키 주입을 통해 즉시 지정 워크스페이스로 이동시킵니다:

```bash
# 예: Orca 창을 2번 워크스페이스로 이동
gtk-launch orca >/dev/null 2>&1
sleep 0.5
ydotool key 125:1 42:1 3:1 3:0 42:0 125:0  # Super+Shift+2

# 예: KeePassXC 창을 3번 워크스페이스로 이동
gtk-launch org.keepassxc.KeePassXC >/dev/null 2>&1
sleep 0.5
ydotool key 125:1 42:1 4:1 4:0 42:0 125:0  # Super+Shift+3
```

---

## 점검 및 검증 체크리스트

1. `python3` 스크립트로 `LM 0: connector=eDP-1, primary=1` 상태인지 확인.
2. 노트북 화면에서 `Super + PageUp/Down` 전환 시 가상 데스크톱 1, 2, 3이 분리되어 표시되는지 확인.
3. 외부 모니터는 워크스페이스 전환에 영향을 받지 않고 화면이 유지되는지 확인.
4. `Super + Shift + 1/2/3` 단축키를 눌렀을 때 활성 창이 즉시 해당 워크스페이스로 이동하는지 확인.
