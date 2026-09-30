# ==============================================================================
# Windows PowerShell 7 Profile (Microsoft.PowerShell_profile.ps1)
# ==============================================================================

# 1. UTF-8 & Console Encoding Settings
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
chcp 65001 > $null

# 2. Oh My Posh Theme Init
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh | Invoke-Expression
}

# 3. Aliases
Set-Alias -Name c -Value Clear-Host

# ------------------------------------------------------------------------------
# 4. GitHub CLI (gh) 디렉토리별 계정 자동 전환 래퍼
# ------------------------------------------------------------------------------
function gh {
    $ghExe = (Get-Command gh -CommandType Application).Source

    # gh auth 명령은 래핑하지 않음
    if ($args.Count -gt 0 -and $args[0] -eq 'auth') {
        & $ghExe @args
        return
    }

    # 현재 디렉토리 기준 계정 매핑
    $targetUser = $null
    if ($PWD.Path -like 'C:\Users\user\orca\*' -or $PWD.Path -like 'C:\orca\*') {
        $targetUser = 'YiranHwang'
    } elseif ($PWD.Path -like 'C:\Users\user\personal\*' -or $PWD.Path -like 'C:\personal\*') {
        $targetUser = 'yxxh020'
    }

    if ($targetUser) {
        $token = & $ghExe auth token --user $targetUser 2>$null
        if ($token) {
            $oldToken = $env:GH_TOKEN
            $env:GH_TOKEN = $token
            try {
                & $ghExe @args
            } finally {
                if ($oldToken) { $env:GH_TOKEN = $oldToken }
                else { Remove-Item Env:\GH_TOKEN -ErrorAction SilentlyContinue }
            }
            return
        }
    }

    & $ghExe @args
}

# ------------------------------------------------------------------------------
# 5. Git Aliases (Oh My Zsh 호환)
# ------------------------------------------------------------------------------
function g    { git @args }
function gst  { git status @args }
function gss  { git status -s @args }
function gd   { git diff @args }
function gds  { git diff --staged @args }
function gdc  { git diff --cached @args }

function ga   { git add @args }
function gaa  { git add --all @args }
function gapa { git add --patch @args }

function gc   { git commit -v @args }
function gca  { git commit -v -a @args }
function gcam { git commit -a -m @args }
function gcm  { git commit -m @args }

function gb   { git branch @args }
function gba  { git branch -a @args }
function gbd  { git branch -D @args }
function gco  { git checkout @args }
function gcb  { git checkout -b @args }
function gsw  { git switch @args }
function gswc { git switch -c @args }

function gp   { git push @args }
function gpl  { git pull @args }
function glg  { git log --stat @args }
function glo  { git log --oneline --decorate @args }
