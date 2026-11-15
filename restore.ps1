<#
.SYNOPSIS
    从备份还原官方文件（撤销汉化）

.EXAMPLE
    .\restore.ps1 -BackupDir ".\backups\20261115-100603"

.EXAMPLE
    .\restore.ps1            # 自动使用最近一次备份
#>
[CmdletBinding()]
param(
    [string]$BackupDir
)

$ErrorActionPreference = 'Stop'

if (-not $BackupDir) {
    $root = Join-Path $PSScriptRoot 'backups'
    if (-not (Test-Path -LiteralPath $root)) { throw "找不到 backups 目录：$root" }
    $latest = Get-ChildItem -LiteralPath $root -Directory | Sort-Object Name -Descending | Select-Object -First 1
    if (-not $latest) { throw "backups 目录为空，没有可还原的备份" }
    $BackupDir = $latest.FullName
}

if (-not (Test-Path -LiteralPath $BackupDir)) { throw "备份目录不存在：$BackupDir" }

$manifestPath = Join-Path $BackupDir 'manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath)) { throw "备份缺少 manifest.json：$manifestPath" }

$entries = Get-Content -Raw -LiteralPath $manifestPath -Encoding UTF8 | ConvertFrom-Json

Write-Host ""
Write-Host "=== 从备份还原 ===" -ForegroundColor Cyan
Write-Host ("  备份 : {0}" -f $BackupDir)
Write-Host ""

$ok = 0; $skip = 0
foreach ($e in $entries) {
    if (-not (Test-Path -LiteralPath $e.backup)) { $skip++; Write-Host ("SKIP  {0}  (备份文件缺失)" -f $e.target) -ForegroundColor DarkYellow; continue }
    $dir = Split-Path -Parent $e.target
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Copy-Item -LiteralPath $e.backup -Destination $e.target -Force
    $ok++
    Write-Host ("RESTORE  {0}" -f $e.target)
}

Write-Host ""
Write-Host ("还原 {0} 个文件，跳过 {1} 个" -f $ok, $skip) -ForegroundColor Green
Write-Host ""
