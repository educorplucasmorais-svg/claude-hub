<#
.SYNOPSIS
    Agente 4: Obsidian Inbox Processor
    Processa automaticamente notas da pasta Inbox do vault Kaia.
.USAGE
    .\agents\tasks\inbox-processor.ps1           # Processar
    .\agents\tasks\inbox-processor.ps1 -DryRun   # Simular
#>

param([switch]$DryRun)

$HubPath   = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$AgentRoot = Split-Path $PSScriptRoot -Parent
$DateStr   = Get-Date -Format "yyyy-MM-dd"
$TimeStr   = Get-Date -Format "HH:mm"
$LogDir    = Join-Path $AgentRoot "logs"
$StateDir  = Join-Path $AgentRoot "state"
$LogFile   = Join-Path $LogDir "inbox-processor.log"
$StateFile = Join-Path $StateDir "inbox-processor.json"

New-Item -ItemType Directory -Path $LogDir   -Force | Out-Null
New-Item -ItemType Directory -Path $StateDir -Force | Out-Null

$obsConfig  = Get-Content (Join-Path $HubPath "scripts\obsidian\config.json") -Raw | ConvertFrom-Json
$VaultPath  = $obsConfig.vaultPath
$InboxPath  = Join-Path $VaultPath $obsConfig.inboxFolder

function Log {
    param([string]$msg)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$ts] $msg" | Add-Content $LogFile
}

function Parse-FrontMatter {
    param([string]$content)
    $result = @{ type = "concept"; status = "raw"; title = "" }
    if ($content -match "type:\s*(\w+)")                      { $result.type   = $Matches[1] }
    if ($content -match "status:\s*(\S+)")                    { $result.status = $Matches[1] }
    if ($content -match 'title:\s*"?([^"' + "'" + '\n]+)"?') { $result.title  = $Matches[1].Trim() }
    return $result
}

function Get-TargetFolder {
    param([string]$type)
    switch ($type) {
        "concept"  { return "Notes\Concepts" }
        "project"  { return "Notes\Projects" }
        "meeting"  { return "Notes\Meetings" }
        "snippet"  { return "Notes\Snippets" }
        "learning" { return "Notes\Learning" }
        default    { return "Notes\General"  }
    }
}

function Update-NoteStatus {
    param([string]$filePath, [string]$newStatus)
    $content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
    $content = $content -replace "status:\s*\S+",         "status: $newStatus"
    $content = $content -replace "modified:\s*[\d-]+",    "modified: $DateStr"
    [System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::UTF8)
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  OBSIDIAN INBOX PROCESSOR" -ForegroundColor Cyan
Write-Host "  Vault: Kaia | $DateStr $TimeStr" -ForegroundColor White
if ($DryRun) { Write-Host "  [MODO DRY-RUN - sem alteracoes reais]" -ForegroundColor Yellow }
Write-Host "============================================" -ForegroundColor Magenta
Write-Host ""

if (-not (Test-Path $InboxPath)) {
    Write-Host "  Inbox nao encontrado: $InboxPath" -ForegroundColor Red
    exit 1
}

$notes = @(Get-ChildItem -Path $InboxPath -Filter "*.md" -ErrorAction SilentlyContinue)

if ($notes.Count -eq 0) {
    Write-Host "  Inbox esta vazio - nada a processar." -ForegroundColor DarkGray
    Write-Host ""
    exit 0
}

Write-Host "  Encontradas $($notes.Count) nota(s) no Inbox." -ForegroundColor Cyan
Write-Host ""

$processed = 0
$report    = @()

foreach ($note in $notes) {
    $content      = [System.IO.File]::ReadAllText($note.FullName, [System.Text.Encoding]::UTF8)
    $meta         = Parse-FrontMatter $content
    $targetFolder = Get-TargetFolder $meta.type
    $targetPath   = Join-Path $VaultPath $targetFolder
    $targetFile   = Join-Path $targetPath $note.Name

    Write-Host "  Nota: $($note.Name)" -ForegroundColor White
    Write-Host "    Tipo:   $($meta.type)  ->  $targetFolder" -ForegroundColor DarkGray

    if ($DryRun) {
        Write-Host "    [DRY-RUN] Seria movida para: $targetFolder" -ForegroundColor Yellow
    } else {
        if (-not (Test-Path $targetPath)) {
            New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
            Write-Host "    Pasta criada: $targetFolder" -ForegroundColor Green
        }
        Update-NoteStatus $note.FullName "processed"
        if ($note.FullName -ne $targetFile) {
            Move-Item $note.FullName $targetFile -Force
            Write-Host "    Movida para: $targetFolder" -ForegroundColor Green
        }
        $processed++
        Log "Movida: $($note.Name) -> $targetFolder"
    }

    $report += @{ note = $note.Name; type = $meta.type; movedTo = $targetFolder }
}

Write-Host ""
Write-Host "  Processadas: $processed nota(s)" -ForegroundColor Green
if ($DryRun) { Write-Host "  (Dry-run: nenhum arquivo movido)" -ForegroundColor Yellow }
Write-Host ""

$state = @{ lastRun = "$DateStr $TimeStr"; processed = $processed }
[System.IO.File]::WriteAllText($StateFile, ($state | ConvertTo-Json), [System.Text.Encoding]::UTF8)
Log "Processamento concluido: $processed notas"
