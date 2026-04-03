<#
.SYNOPSIS
    Dashboard visual de todos os agentes Claude Hub
#>

$HubPath   = Split-Path $PSScriptRoot -Parent
$AgentRoot = $PSScriptRoot
$StateDir  = Join-Path $AgentRoot "state"
$DateStr   = Get-Date -Format "yyyy-MM-dd HH:mm"

$StateFiles = @{
    "Daily Briefing"  = "daily-briefing.json"
    "Code Guardian"   = "code-guardian.json"
    "Inbox Processor" = "inbox-processor.json"
    "Researcher"      = "researcher.json"
}

function Get-State {
    param([string]$file)
    $path = Join-Path $StateDir $file
    if (Test-Path $path) { return Get-Content $path -Raw | ConvertFrom-Json }
    return $null
}

Clear-Host
Write-Host ""
Write-Host "  ============================================" -ForegroundColor Magenta
Write-Host "     CLAUDE HUB - AGENTES AUTONOMOS" -ForegroundColor Cyan
Write-Host "     $DateStr" -ForegroundColor White
Write-Host "  ============================================" -ForegroundColor Magenta
Write-Host ""

foreach ($agentName in $StateFiles.Keys) {
    $state = Get-State $StateFiles[$agentName]
    if ($state -and $state.lastRun) {
        Write-Host "  [ATIVO] $agentName" -ForegroundColor Green
        Write-Host "          Ultima execucao: $($state.lastRun)" -ForegroundColor DarkGray
        if ($null -ne $state.filesModified) {
            Write-Host "          Arquivos modificados: $($state.filesModified)" -ForegroundColor DarkGray
        }
        if ($null -ne $state.processed) {
            Write-Host "          Processados: $($state.processed)" -ForegroundColor DarkGray
        }
        if ($null -ne $state.issues -and $state.issues -gt 0) {
            Write-Host "          Criticos detectados: $($state.issues)" -ForegroundColor Red
        }
    } else {
        Write-Host "  [INATIVO] $agentName" -ForegroundColor DarkGray
        Write-Host "          Nunca executado" -ForegroundColor DarkGray
    }
    Write-Host ""
}

# Fila de pesquisa
$queueFile = Join-Path $StateDir "research-queue.json"
if (Test-Path $queueFile) {
    $queueRaw  = Get-Content $queueFile -Raw | ConvertFrom-Json
    $queue     = @($queueRaw)
    $pending   = $queue | Where-Object { $_.status -eq "pending" }
    $pendCount = @($pending).Count
    Write-Host "  Fila de Pesquisa: $($queue.Count) total | $pendCount pendente(s)" -ForegroundColor Cyan
    if ($pendCount -gt 0) {
        foreach ($p in $pending) {
            Write-Host "    - $($p.topic)" -ForegroundColor Yellow
        }
    }
    Write-Host ""
}

# Inbox Obsidian
$obsConfigPath = Join-Path $HubPath "scripts\obsidian\config.json"
if (Test-Path $obsConfigPath) {
    $obsConfig  = Get-Content $obsConfigPath -Raw | ConvertFrom-Json
    $inboxPath  = Join-Path $obsConfig.vaultPath $obsConfig.inboxFolder
    if (Test-Path $inboxPath) {
        $inboxCount = @(Get-ChildItem $inboxPath -Filter "*.md" -ErrorAction SilentlyContinue).Count
        $inboxColor = if ($inboxCount -gt 5) { "Yellow" } else { "Green" }
        Write-Host "  Inbox Obsidian (Kaia): $inboxCount nota(s) no inbox" -ForegroundColor $inboxColor
        Write-Host ""
    }
}

Write-Host "  COMANDOS RAPIDOS:" -ForegroundColor Cyan
Write-Host "  .\agents\orchestrator.ps1             (menu interativo)" -ForegroundColor White
Write-Host "  .\agents\orchestrator.ps1 -RunAll     (todos os agentes)" -ForegroundColor White
Write-Host "  .\agents\tasks\researcher.ps1 -Add 'Topico'" -ForegroundColor White
Write-Host "  .\agents\setup-scheduler.ps1          (agendar no Windows)" -ForegroundColor White
Write-Host ""
