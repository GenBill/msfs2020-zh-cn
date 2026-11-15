<#
.SYNOPSIS
    微软模拟飞行 2020 民间汉化 —— 合并式安装器

.DESCRIPTION
    以【当前官方文件】为底，逐键替换为中文，而不是整文件覆盖。
    这样游戏更新后新增的文案保持英文，不会出现空白/原始键名。

    重复运行是安全的（幂等）：已经汉化的键会再次被替换成相同内容。

.PARAMETER PackagesRoot
    数据包目录（Packages）。默认从 UserCfg.opt 的 InstalledPackagesPath 读取。

.PARAMETER GamePackagesDir
    游戏安装目录下的 Packages（存放 fs-base-ui / fs-base-onboarding）。默认自动探测 Steam 库。

.PARAMETER Edition
    Steam / OneStore / Auto（默认按 PackagesRoot 下的 Official 子目录自动判断）。

.PARAMETER DryRun
    只显示将要做什么，不写任何文件。

.PARAMETER IncludeGameDir
    同时写入游戏安装目录下的 Packages（fs-base-onboarding / fs-base-ui）。
    注意：这些文件由 Steam 管理，Steam 校验或更新时会被重置，默认不写。

.EXAMPLE
    .\install.ps1
    .\install.ps1 -DryRun
    .\install.ps1 -PackagesRoot "F:\Microsoft Flight Simulator\Packages"
#>
[CmdletBinding()]
param(
    [string]$PackagesRoot,
    [string]$GamePackagesDir,
    [ValidateSet('Auto', 'Steam', 'OneStore')][string]$Edition = 'Auto',
    [switch]$DryRun,
    [switch]$IncludeGameDir,
    [switch]$IncludeFont
)

$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$payloadRoot = Join-Path $PSScriptRoot 'payload'
if (-not (Test-Path -LiteralPath $payloadRoot)) { throw "找不到 payload 目录：$payloadRoot" }

$BasePackages = @('fs-base-onboarding', 'fs-base-ui')

# ---------- 自动探测 ----------

function Get-InstalledPackagesPath {
    $cfg = Join-Path $env:APPDATA 'Microsoft Flight Simulator\UserCfg.opt'
    if (Test-Path -LiteralPath $cfg) {
        $m = Select-String -LiteralPath $cfg -Pattern 'InstalledPackagesPath\s+"([^"]+)"' | Select-Object -First 1
        if ($m) { return $m.Matches[0].Groups[1].Value }
    }
    return $null
}

function Get-SteamLibraries {
    $libs = New-Object System.Collections.Generic.List[string]
    $steamPath = $null
    if (Test-Path 'HKCU:\Software\Valve\Steam') {
        $steamPath = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -Name SteamPath -ErrorAction SilentlyContinue).SteamPath
    }
    if (-not $steamPath) {
        $steamPath = (Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam' -Name InstallPath -ErrorAction SilentlyContinue).InstallPath
    }
    if ($steamPath) {
        $steamPath = $steamPath -replace '/', '\'
        if (-not $libs.Contains($steamPath)) { $libs.Add($steamPath) }
        $vdf = Join-Path $steamPath 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            foreach ($line in Get-Content -LiteralPath $vdf) {
                if ($line -match '"path"\s+"([^"]+)"') {
                    $p = $Matches[1] -replace '\\\\', '\'
                    if (-not $libs.Contains($p)) { $libs.Add($p) }
                }
            }
        }
    }
    return $libs
}

function Find-GamePackagesDir {
    foreach ($lib in (Get-SteamLibraries)) {
        $cand = Join-Path $lib 'steamapps\common\MicrosoftFlightSimulator\Packages'
        if (Test-Path -LiteralPath $cand) { return $cand }
    }
    # 微软商店版
    $storeCand = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.FlightSimulator_8wekyb3d8bbwe\LocalCache\Packages'
    if (Test-Path -LiteralPath $storeCand) { return $storeCand }
    return $null
}

if (-not $PackagesRoot) { $PackagesRoot = Get-InstalledPackagesPath }
if (-not $PackagesRoot) { throw "无法确定数据包目录，请用 -PackagesRoot 指定（例如 F:\Microsoft Flight Simulator\Packages）" }
if (-not (Test-Path -LiteralPath $PackagesRoot)) { throw "数据包目录不存在：$PackagesRoot" }

if (-not $GamePackagesDir) { $GamePackagesDir = Find-GamePackagesDir }

$officialDir = Join-Path $PackagesRoot 'Official'
if (-not (Test-Path -LiteralPath $officialDir)) { throw "找不到 Official 目录：$officialDir" }

if ($Edition -eq 'Auto') {
    if (Test-Path -LiteralPath (Join-Path $officialDir 'Steam')) { $Edition = 'Steam' }
    elseif (Test-Path -LiteralPath (Join-Path $officialDir 'OneStore')) { $Edition = 'OneStore' }
    else { throw "Official 下既没有 Steam 也没有 OneStore 子目录" }
}

$payloadEdition = Join-Path $payloadRoot $Edition
if (-not (Test-Path -LiteralPath $payloadEdition)) { throw "payload 缺少 $Edition 分支：$payloadEdition" }
$editionDir = Join-Path $officialDir $Edition

Write-Host ""
Write-Host "=== MSFS 2020 汉化 合并安装 ===" -ForegroundColor Cyan
Write-Host ("  版本分支   : {0}" -f $Edition)
Write-Host ("  数据包目录 : {0}" -f $PackagesRoot)
Write-Host ("  游戏目录包 : {0}" -f $(if ($GamePackagesDir) { $GamePackagesDir } else { '(未找到，fs-base-ui/onboarding 将跳过)' }))
if ($DryRun) { Write-Host "  模式       : 预览（不写入）" -ForegroundColor Yellow }
Write-Host ""

# ---------- 合并逻辑 ----------

function Save-JsonFile($obj, $path) {
    $json = $obj | ConvertTo-Json -Depth 100
    [System.IO.File]::WriteAllText($path, $json, $utf8NoBom)
}

function Merge-LocPak {
    param([string]$PackFile, [string]$OfficialFile, [string]$OutFile)
    $packObj = (Get-Content -Raw -LiteralPath $PackFile -Encoding UTF8) | ConvertFrom-Json
    $offObj = (Get-Content -Raw -LiteralPath $OfficialFile -Encoding UTF8) | ConvertFrom-Json
    $ps = $packObj.LocalisationPackage.Strings
    $os = $offObj.LocalisationPackage.Strings
    if ($null -eq $ps -or $null -eq $os) { return -1 }
    $hits = 0
    foreach ($prop in $ps.PSObject.Properties) {
        $op = $os.PSObject.Properties[$prop.Name]
        if ($null -ne $op) { $op.Value = $prop.Value; $hits++ }
    }
    if (-not $DryRun) { Save-JsonFile $offObj $OutFile }
    return $hits
}

function Merge-Loc {
    param([string]$PackFile, [string]$OfficialFile, [string]$OutFile)
    $packObj = (Get-Content -Raw -LiteralPath $PackFile -Encoding UTF8) | ConvertFrom-Json
    $offObj = (Get-Content -Raw -LiteralPath $OfficialFile -Encoding UTF8) | ConvertFrom-Json
    $ps = $packObj.LocalisationFile.Strings
    $os = $offObj.LocalisationFile.Strings
    if ($null -eq $ps -or $null -eq $os) { return -1 }
    $hits = 0
    foreach ($prop in $ps.PSObject.Properties) {
        $op = $os.PSObject.Properties[$prop.Name]
        if ($null -eq $op) { continue }
        $pl = $prop.Value.Languages.PSObject.Properties['en-US']
        $ol = $op.Value.Languages.PSObject.Properties['en-US']
        if ($null -ne $pl -and $null -ne $ol -and $null -ne $pl.Value.Text) {
            $ol.Value.Text = $pl.Value.Text
            $hits++
        }
    }
    if (-not $DryRun) { Save-JsonFile $offObj $OutFile }
    return $hits
}

# ---------- 主流程 ----------

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = Join-Path $PSScriptRoot ("backups\$stamp")
$manifest = New-Object System.Collections.ArrayList

$statMerged = 0; $statCopied = 0; $statSkipped = 0; $statNoPkg = 0; $statFailed = 0
$hitsTotal = 0

foreach ($src in (Get-ChildItem -LiteralPath $payloadEdition -Recurse -File)) {
    $rel = $src.FullName.Substring($payloadEdition.Length + 1)
    $parts = $rel -split '\\'
    $pkg = $parts[0]

    if ($BasePackages -contains $pkg) {
        if (-not $IncludeGameDir) { $statSkipped++; Write-Host ("SKIP   {0}  (Steam 管理的游戏目录，默认跳过；加 -IncludeGameDir 可强制)" -f $rel) -ForegroundColor DarkGray; continue }
        if (-not $GamePackagesDir) { $statSkipped++; Write-Host ("SKIP   {0}  (未找到游戏目录)" -f $rel) -ForegroundColor DarkYellow; continue }
        $targetRoot = $GamePackagesDir
    }
    else {
        $targetRoot = $editionDir
    }

    if ($src.Extension -eq '.ttc' -and -not $IncludeFont) {
        $statSkipped++
        Write-Host ("SKIP   {0}  (字体，游戏已自带 NotoSansSC；加 -IncludeFont 可强制)" -f $rel) -ForegroundColor DarkGray
        continue
    }

    $pkgDir = Join-Path $targetRoot $pkg
    if (-not (Test-Path -LiteralPath $pkgDir)) {
        $statNoPkg++
        Write-Host ("SKIP   {0}  (未安装该包)" -f $rel) -ForegroundColor DarkGray
        continue
    }
    $hasLayout = Test-Path -LiteralPath (Join-Path $pkgDir 'layout.json')
    if (-not $hasLayout -and -not ($BasePackages -contains $pkg)) {
        $statNoPkg++
        Write-Host ("SKIP   {0}  (包目录无 layout.json)" -f $rel) -ForegroundColor DarkGray
        continue
    }

    $target = Join-Path $targetRoot $rel
    $targetDir = Split-Path -Parent $target
    if (-not $DryRun -and -not (Test-Path -LiteralPath $targetDir)) { New-Item -ItemType Directory -Force -Path $targetDir | Out-Null }

    # 备份已存在的官方文件
    if (Test-Path -LiteralPath $target) {
        $bFile = Join-Path $backupDir $rel
        if (-not $DryRun) {
            $bDir = Split-Path -Parent $bFile
            if (-not (Test-Path -LiteralPath $bDir)) { New-Item -ItemType Directory -Force -Path $bDir | Out-Null }
            Copy-Item -LiteralPath $target -Destination $bFile -Force
        }
        [void]$manifest.Add([pscustomobject]@{ target = $target; backup = $bFile })
    }

    try {
        if ($src.Extension -eq '.ttc' -or -not (Test-Path -LiteralPath $target)) {
            if (-not $DryRun) { Copy-Item -LiteralPath $src.FullName -Destination $target -Force }
            $statCopied++
            $ctag = if ($DryRun) { 'DRY  ' } else { 'COPY ' }
            Write-Host ("{0}  {1}" -f $ctag, $rel) -ForegroundColor Gray
        }
        elseif ($src.Extension -eq '.locPak' -or $src.Extension -eq '.loc') {
            if ($src.Extension -eq '.locPak') {
                $h = Merge-LocPak -PackFile $src.FullName -OfficialFile $target -OutFile $target
            }
            else {
                $h = Merge-Loc -PackFile $src.FullName -OfficialFile $target -OutFile $target
            }
            if ($h -lt 0) { throw "结构异常（本地化文件格式不符合预期）" }
            $hitsTotal += $h; $statMerged++
            $tag = if ($DryRun) { 'DRY  ' } else { 'MERGE' }
            Write-Host ("{0}  {1,6} 键  {2}" -f $tag, $h, $rel) -ForegroundColor Green
        }
        else {
            $statSkipped++
            Write-Host ("SKIP   {0}  (未知类型)" -f $rel) -ForegroundColor DarkGray
        }
    }
    catch {
        $statFailed++
        Write-Host ("FAIL   {0}  {1}" -f $rel, $_.Exception.Message) -ForegroundColor Red
    }
}

if (-not $DryRun -and $manifest.Count -gt 0) {
    $manifestPath = Join-Path $backupDir 'manifest.json'
    [void](New-Item -ItemType Directory -Force -Path $backupDir)
    Save-JsonFile $manifest $manifestPath
}

Write-Host ""
Write-Host "---- 汇总 ----" -ForegroundColor Cyan
Write-Host ("  合并 {0} 个文件（共替换 {1} 条文案）" -f $statMerged, $hitsTotal)
Write-Host ("  直接复制 {0} 个文件" -f $statCopied)
Write-Host ("  跳过（包未安装）{0} 个" -f $statNoPkg)
Write-Host ("  跳过（其他）{0} 个" -f $statSkipped)
if ($statFailed -gt 0) { Write-Host ("  失败 {0} 个" -f $statFailed) -ForegroundColor Red }
if ($DryRun) {
    Write-Host "  预览模式，未写入任何文件" -ForegroundColor Yellow
} else {
    Write-Host ("  备份目录 : {0}" -f $backupDir)
    Write-Host "  还原方法 : .\restore.ps1 -BackupDir `"$backupDir`""
}
Write-Host ""
Write-Host "提示：游戏内语言需保持 English（汉化写入的是 en-US 槽位）。" -ForegroundColor DarkYellow
Write-Host ""
