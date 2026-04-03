<#
.SYNOPSIS
    Agente 1: Daily Briefing
    Executa toda manha e gera um briefing completo do dia.
#>

# Paths corretos: script esta em agents\tasks\, hub e dois niveis acima
$HubPath   = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$AgentRoot = Split-Path $PSScriptRoot -Parent
$DateStr   = Get-Date -Format "yyyy-MM-dd"
$DateHuman = Get-Date -Format "dddd, dd/MM/yyyy"
$TimeStr   = Get-Date -Format "HH:mm"
$LogDir    = Join-Path $AgentRoot "logs"
$StateDir  = Join-Path $AgentRoot "state"
$LogFile   = Join-Path $LogDir "daily-briefing.log"
$StateFile = Join-Path $StateDir "daily-briefing.json"

# Garantir que pastas existam
New-Item -ItemType Directory -Path $LogDir   -Force | Out-Null
New-Item -ItemType Directory -Path $StateDir -Force | Out-Null

function Log {
    param([string]$msg)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$ts] $msg" | Add-Content $LogFile
}

function Read-Safe {
    param([string]$path)
    if (Test-Path $path) {
        return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    }
    return ""
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  DAILY BRIEFING AGENT" -ForegroundColor Cyan
Write-Host "  $DateHuman $TimeStr" -ForegroundColor White
Write-Host "============================================" -ForegroundColor Magenta
Write-Host ""

Log "Daily Briefing iniciado"

# ── 1. Arquivos modificados nas ultimas 24h ───────────
$recentFiles = Get-ChildItem $HubPath -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.LastWriteTime -gt (Get-Date).AddHours(-24) -and
        $_.FullName -notlike "*\agents\logs*" -and
        $_.FullName -notlike "*\.git\*" -and
        $_.FullName -notlike "*\node_modules\*" -and
        $_.FullName -notlike "*\local-vault\*"
    } |
    Sort-Object LastWriteTime -Descending

# ── 2. Notas recentes no Obsidian ─────────────────────
$obsConfigPath = Join-Path $HubPath "scripts\obsidian\config.json"
$recentNotes = @()
if (Test-Path $obsConfigPath) {
    $obsConfig  = Get-Content $obsConfigPath -Raw | ConvertFrom-Json
    $vaultInbox = Join-Path $obsConfig.vaultPath $obsConfig.inboxFolder
    if (Test-Path $vaultInbox) {
        $recentNotes = Get-ChildItem $vaultInbox -Filter "*.md" -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-3) } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 5
    }
}

# ── 3. Estado anterior ────────────────────────────────
$prevLastRun = "nunca"
if (Test-Path $StateFile) {
    $prevState = Get-Content $StateFile -Raw | ConvertFrom-Json
    if ($prevState.lastRun) { $prevLastRun = $prevState.lastRun }
}

# ── 4. Montar conteudo do briefing ────────────────────
$sep   = [System.Environment]::NewLine
$lines = @()
$lines += "## Status do Hub"
$lines += "- Skills ativas: 12 | Agentes: 4 | Integracoes: Obsidian + NotebookLM"
$lines += "- Ultima execucao anterior: $prevLastRun"
$lines += ""
$lines += "## Arquivos Modificados (24h)"
if ($recentFiles.Count -eq 0) {
    $lines += "- Nenhum arquivo modificado"
} else {
    foreach ($f in $recentFiles | Select-Object -First 10) {
        $rel = $f.FullName.Replace($HubPath + "\", "")
        $lines += "- $rel ($(Get-Date $f.LastWriteTime -Format 'HH:mm'))"
    }
}
$lines += ""
$lines += "## Inbox Obsidian"
if ($recentNotes.Count -eq 0) {
    $lines += "- Inbox vazio"
} else {
    foreach ($n in $recentNotes) {
        $noteName = [System.IO.Path]::GetFileNameWithoutExtension($n.Name)
        $lines += "- [[$noteName]]"
    }
}
$lines += ""
$lines += "## Prioridades do Dia"
$lines += "1. Processar notas do Inbox do Obsidian"
$lines += "2. Revisar codigo modificado com Code Guardian"
$lines += "3. Adicionar topicos de pesquisa ao Researcher"
$lines += "4. Atualizar MEMORY.md ao final do dia"
$lines += ""
$lines += "## Comandos Rapidos"
$lines += "  .\agents\orchestrator.ps1"
$lines += "  .\agents\dashboard.ps1"
$lines += "  .\agents\tasks\researcher.ps1 -Add 'Topico'"

$briefingContent = $lines -join $sep

# ── 5. Salvar no Obsidian ─────────────────────────────
$syncScript = Join-Path $HubPath "scripts\obsidian\sync-to-vault.ps1"
if (Test-Path $syncScript) {
    & powershell -ExecutionPolicy Bypass -File $syncScript `
        -NoteTitle "Daily $DateStr" `
        -NoteType "meeting" `
        -NoteContent $briefingContent `
        -Tags @("daily","agent/briefing") | Out-Null
}

# ── 6. Salvar estado ──────────────────────────────────
$newState = @{
    lastRun       = "$DateStr $TimeStr"
    filesModified = $recentFiles.Count
    notesInInbox  = $recentNotes.Count
}
$json = $newState | ConvertTo-Json
[System.IO.File]::WriteAllText($StateFile, $json, [System.Text.Encoding]::UTF8)

# ── 7. Exibir no terminal ─────────────────────────────
Write-Host "  STATUS DO PROJETO" -ForegroundColor Cyan
Write-Host "  Arquivos modificados (24h): $($recentFiles.Count)" -ForegroundColor White
Write-Host "  Notas no Inbox Obsidian:    $($recentNotes.Count)" -ForegroundColor White
Write-Host ""

if ($recentFiles.Count -gt 0) {
    Write-Host "  ARQUIVOS RECENTES:" -ForegroundColor Yellow
    foreach ($f in $recentFiles | Select-Object -First 5) {
        $rel = $f.FullName.Replace($HubPath + "\", "")
        Write-Host "    $rel" -ForegroundColor DarkGray
    }
    Write-Host ""
}

Write-Host "  PRIORIDADES DE HOJE:" -ForegroundColor Green
Write-Host "    1. Processar Inbox do Obsidian" -ForegroundColor White
Write-Host "    2. Revisar codigo modificado" -ForegroundColor White
Write-Host "    3. Atualizar MEMORY.md ao final do dia" -ForegroundColor White
Write-Host ""
Write-Host "  Nota diaria salva no vault Kaia: Daily $DateStr" -ForegroundColor Cyan
Write-Host ""

Log "Daily Briefing concluido. Arquivos: $($recentFiles.Count), Inbox: $($recentNotes.Count)"
