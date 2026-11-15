<#
.SYNOPSIS
    提取尚未汉化的官方文本，生成 missing.csv 供翻译

.DESCRIPTION
    读取当前已安装的 en-US.locPak，与 payload 中的中文词条对比，
    导出「仍是英文且含字母」的条目（自动排除 .tts 语音合成串）。

    输出的 CSV 列为：Key, Value
    翻译后按 payload/<Edition>/<包名>/en-US.locPak 的 JSON 结构补充键值即可。

.EXAMPLE
    .\Extract-Missing.ps1
    .\Extract-Missing.ps1 -Output "C:\temp\missing.csv"
#>
[CmdletBinding()]
param(
    [string]$PackagesRoot,
    [string]$Output = "missing.csv",
    [switch]$IncludeTts
)

$ErrorActionPreference = 'Stop'

function Get-InstalledPackagesPath {
    $cfg = Join-Path $env:APPDATA 'Microsoft Flight Simulator\UserCfg.opt'
    if (Test-Path -LiteralPath $cfg) {
        $m = Select-String -LiteralPath $cfg -Pattern 'InstalledPackagesPath\s+"([^"]+)"' | Select-Object -First 1
        if ($m) { return $m.Matches[0].Groups[1].Value }
    }
    return $null
}

if (-not $PackagesRoot) { $PackagesRoot = Get-InstalledPackagesPath }
if (-not $PackagesRoot) { throw "无法确定数据包目录，请用 -PackagesRoot 指定" }

$officialDir = Join-Path $PackagesRoot 'Official'
if (Test-Path -LiteralPath (Join-Path $officialDir 'Steam')) { $edition = 'Steam' }
elseif (Test-Path -LiteralPath (Join-Path $officialDir 'OneStore')) { $edition = 'OneStore' }
else { throw "Official 下既没有 Steam 也没有 OneStore" }

$srcRoot = Join-Path $PSScriptRoot '..\payload' | Resolve-Path
$srcDir = Join-Path $srcRoot $edition
if (-not (Test-Path -LiteralPath $srcDir)) { throw "payload 缺少 $edition 分支" }

$rows = New-Object System.Collections.ArrayList

foreach ($packFile in (Get-ChildItem -LiteralPath $srcDir -Recurse -File -Filter 'en-US.locPak')) {
    $rel = $packFile.FullName.Substring((Resolve-Path $srcDir).Path.Length + 1)
    $live = Join-Path (Join-Path $officialDir $edition) $rel
    if (-not (Test-Path -LiteralPath $live)) { continue }

    $s = ((Get-Content -Raw -LiteralPath $live -Encoding UTF8) | ConvertFrom-Json).LocalisationPackage.Strings
    foreach ($prop in $s.PSObject.Properties) {
        $v = [string]$prop.Value
        if ([string]::IsNullOrWhiteSpace($v)) { continue }
        if ($v -match '[\u4e00-\u9fff]') { continue }
        if ($v -notmatch '[A-Za-z]') { continue }
        if (-not $IncludeTts -and $prop.Name -like '*.tts') { continue }
        [void]$rows.Add([pscustomobject]@{ Key = $prop.Name; Value = $v })
    }
}

$rows | Export-Csv -LiteralPath $Output -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host ("未汉化条目: {0}" -f $rows.Count) -ForegroundColor Cyan
Write-Host ("已写入: {0}" -f (Resolve-Path $Output)) -ForegroundColor Green
Write-Host ""
