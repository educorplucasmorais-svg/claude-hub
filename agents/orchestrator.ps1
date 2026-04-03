<#
.SYNOPSIS
    Orquestrador Central de Agentes - Claude Hub
    Gerencia, executa e monitora todos os agentes autonomos.

.USAGE
    .\agents\orchestrator.ps1               # Menu interativo
    .\agents\orchestrator.ps1 -RunAll       # Rodar todos os agentes
    .\agents\orchestrator.ps1 -Run daily    # Rodar agente especifico
    .\agents\orchestrator.ps1 -Status       # Ver status de todos
#>

param(
    [switch]$RunAll,
    [string]$Run    = "",
    [switch]$Status
)

$HubPath  = Split-Path $PSScriptRoot -Parent
$AgentDir = Join-Path $PSScriptRoot "tasks"
$DateStr  = Get-Date -Format "yyyy-MM-dd"
$TimeStr  = Get-Date -Format "HH:mm"

$Agents = @(
    @{ id = "daily";    name = "Daily Briefing";         script = "daily-briefing.ps1";   schedule = "08:00 diario" }
    @{ id = "guardian"; name = "Code Guardian";          script = "code-guardian.ps1";    schedule = "A cada 2h" }
    @{ id = "inbox";    name = "Obsidian Inbox";         script = "inbox-processor.ps1";  schedule = "12:00 e 20:00" }
    @{ id = "research"; name = "Researcher (processar)"; script = "researcher.ps1 -Process"; schedule = "Manual" }
)

function Get-AgentState {
    param([string]$agentId)
    $stateMap = @{
        "daily"    = "daily-briefing.json"
        "guardian" = "code-guardian.json"
        "inbox"    = "inbox-processor.json"
        "research" = "researcher.json"
    }
    $stateFile = Join-Path $PSScriptRoot "state\$($stateMap[$agentId])"
    if (Test-Path $stateFile) {
        return Get-Content $stateFile -Raw | ConvertFrom-Json
    }
    return $null
}

function Show-Status {
    Write-Host "`n  STATUS DOS AGENTES" -ForegroundColor Cyan
    Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray

    foreach ($agent in $Agents) {
        $state = Get-AgentState $agent.id
        if ($state -and $state.lastRun) {
            $lastRun = $state.lastRun
            Write-Host "  [OK] $($agent.name)" -ForegroundColor Green
            Write-Host "       Ultima execucao: $lastRun" -ForegroundColor DarkGray
            Write-Host "       Agendamento: $($agent.schedule)" -ForegroundColor DarkGray
        } else {
            Write-Host "  [--] $($agent.name)" -ForegroundColor Yellow
            Write-Host "       Nunca executado" -ForegroundColor DarkGray
            Write-Host "       Agendamento: $($agent.schedule)" -ForegroundColor DarkGray
        }
        Write-Host ""
    }
}

function Run-Agent {
    param([string]$agentId)
    $agent = $Agents | Where-Object { $_.id -eq $agentId }
    if (-not $agent) {
        Write-Host "  Agente nao encontrado: $agentId" -ForegroundColor Red
        Write-Host "  IDs validos: daily, guardian, inbox, research" -ForegroundColor DarkGray
        return
    }

    $parts     = $agent.script -split " "
    $scriptFile = Join-Path $AgentDir $parts[0]
    $extraArgs  = if ($parts.Count -gt 1) { $parts[1..($parts.Count-1)] } else { @() }

    Write-Host "`n  Iniciando: $($agent.name)..." -ForegroundColor Cyan
    if (Test-Path $scriptFile) {
        & powershell -ExecutionPolicy Bypass -File $scriptFile @extraArgs
    } else {
        Write-Host "  Script nao encontrado: $scriptFile" -ForegroundColor Red
    }
}

function Run-AllAgents {
    Write-Host "`n  EXECUTANDO TODOS OS AGENTES" -ForegroundColor Magenta
    Write-Host "  ─────────────────────────────────────────`n" -ForegroundColor DarkGray
    foreach ($agent in $Agents) {
        if ($agent.id -ne "research") {  # Research e manual
            Run-Agent $agent.id
        }
    }
    Write-Host "`n  Todos os agentes concluidos!" -ForegroundColor Green
}

function Show-Menu {
    Write-Host "`n  O QUE DESEJA EXECUTAR?" -ForegroundColor Yellow
    Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  [1] Daily Briefing (status + prioridades)" -ForegroundColor White
    Write-Host "  [2] Code Guardian (analisar codigo modificado)" -ForegroundColor White
    Write-Host "  [3] Inbox Processor (organizar notas Obsidian)" -ForegroundColor White
    Write-Host "  [4] Researcher (processar fila de pesquisa)" -ForegroundColor White
    Write-Host "  [5] Rodar TODOS os agentes" -ForegroundColor Cyan
    Write-Host "  [6] Ver status dos agentes" -ForegroundColor White
    Write-Host "  [7] Adicionar topico de pesquisa" -ForegroundColor White
    Write-Host "  [0] Sair" -ForegroundColor DarkGray
    Write-Host ""

    $choice = Read-Host "  Escolha"

    switch ($choice) {
        "1" { Run-Agent "daily" }
        "2" { Run-Agent "guardian" }
        "3" { Run-Agent "inbox" }
        "4" { Run-Agent "research" }
        "5" { Run-AllAgents }
        "6" { Show-Status }
        "7" {
            $topic = Read-Host "  Digite o topico de pesquisa"
            & powershell -ExecutionPolicy Bypass -File (Join-Path $AgentDir "researcher.ps1") -Add $topic
        }
        "0" { Write-Host "  Ate logo!" -ForegroundColor DarkGray; exit 0 }
        default { Write-Host "  Opcao invalida." -ForegroundColor Red }
    }
}

# ── Main ──────────────────────────────────────────────

Write-Host "`n============================================" -ForegroundColor Magenta
Write-Host "  ORQUESTRADOR DE AGENTES - CLAUDE HUB" -ForegroundColor Cyan
Write-Host "  $DateStr $TimeStr" -ForegroundColor White
Write-Host "============================================" -ForegroundColor Magenta

if ($RunAll)    { Run-AllAgents; exit 0 }
if ($Status)    { Show-Status;   exit 0 }
if ($Run -ne "") { Run-Agent $Run; exit 0 }

Show-Menu
