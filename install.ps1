# ==============================================================================
# Windows Dotfiles Installation & Symlink Script
# ==============================================================================
$ErrorActionPreference = "Stop"

$dotfilesDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "🚀 [1/3] 작업 디렉토리 생성 (C:\personal, C:\orca)..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "$HOME\personal", "$HOME\orca" | Out-Null

Write-Host "🔗 [2/3] Git 설정 파일 복사/연결..." -ForegroundColor Cyan
Copy-Item -Path "$dotfilesDir\git\.gitconfig" -Destination "$HOME\.gitconfig" -Force
Copy-Item -Path "$dotfilesDir\git\.gitconfig-personal" -Destination "$HOME\.gitconfig-personal" -Force
Copy-Item -Path "$dotfilesDir\git\.gitconfig-orca" -Destination "$HOME\.gitconfig-orca" -Force

Write-Host "🐚 [3/3] PowerShell 프로필 설정..." -ForegroundColor Cyan
$profileDir = Split-Path -Parent $PROFILE
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
}
Copy-Item -Path "$dotfilesDir\shell\powershell\Microsoft.PowerShell_profile.ps1" -Destination $PROFILE -Force

Write-Host "`n✅ Windows Dotfiles 설정이 완료되었습니다!" -ForegroundColor Green
Write-Host "👉 새 PowerShell 창을 열어 적용을 확인하세요."
