<#
.SYNOPSIS
    Instala os agentes como tarefas agendadas no Windows Task Scheduler.
    Execute UMA VEZ como Administrador para registrar os agentes.

.USAGE
    # Instalar todos os agentes agendados:
    .\agents\setup-scheduler.ps1

    # Remover todos os agentes agendados:
    .\agents\setup-scheduler.ps1 -Uninstall

    # Ver status das tarefas:
    .\agents\setup-scheduler.ps1 -Status
#>

param(
    [switch]$Uninstall,
    [switch]$Status
)

$HubPath  = "c:\Users\Pichau\Desktop\Claude Full"
$AgentDir = Join-Path $HubPath "agents\tasks"
$PS       = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"

$Tasks = @(
    @{
        Name        = "ClaudeHub-DailyBriefing"
        Description = "Claude Hub: Gera briefing diario e salva no Obsidian"
        Script      = Join-Path $AgentDir "daily-briefing.ps1"
        Trigger     = "Daily"
        At          = "08:00"
        Args        = ""
    }
    @{
        Name        = "ClaudeHub-CodeGuardian"
        Description = "Claude Hub: Analisa codigo modificado a cada 2 horas"
        Script      = Join-Path $AgentDir "code-guardian.ps1"
        Trigger     = "Repetitive"
        RepeatEvery = (New-TimeSpan -Hours 2)
        Args        = ""
    }
    @{
        Name        = "ClaudeHub-InboxProcessor-Noon"
        Description = "Claude Hub: Processa inbox Obsidian ao meio-dia"
        Script      = Join-Path $AgentDir "inbox-processor.ps1"
        Trigger     = "Daily"
        At          = "12:00"
        Args        = ""
    }
    @{
        Name        = "ClaudeHub-InboxProcessor-Evening"
        Description = "Claude Hub: Processa inbox Obsidian a noite"
        Script      = Join-Path $AgentDir "inbox-processor.ps1"
        Trigger     = "Daily"
        At          = "20:00"
        Args        = ""
    }
)

function Show-TaskStatus {
    Write-Host "`n  Status das Tarefas Agendadas Claude Hub:" -ForegroundColor Cyan
    Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
    foreach ($task in $Tasks) {
        $t = Get-ScheduledTask -TaskName $task.Name -ErrorAction SilentlyContinue
        if ($t) {
            $info = Get-ScheduledTaskInfo -TaskName $task.Name -ErrorAction SilentlyContinue
            $lastRun = if ($info.LastRunTime -and $info.LastRunTime -gt [DateTime]::MinValue) {
                Get-Date $info.LastRunTime -Format "dd/MM HH:mm"
            } else { "nunca" }
            $nextRun = if ($info.NextRunTime -and $info.NextRunTime -gt [DateTime]::MinValue) {
                Get-Date $info.NextRunTime -Format "dd/MM HH:mm"
            } else { "-" }
            $state = if ($t.State -eq "Ready") { "OK" } else { $t.State }
            Write-Host "  [$state] $($task.Name)" -ForegroundColor Green
            Write-Host "         Ultima: $lastRun | Proxima: $nextRun" -ForegroundColor DarkGray
        } else {
            Write-Host "  [--] $($task.Name) (nao instalado)" -ForegroundColor Yellow
        }
    }
    Write-Host ""
}

function Install-Tasks {
    Write-Host "`n  Instalando agentes no Task Scheduler..." -ForegroundColor Cyan

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host ""
        Write-Host "  ATENCAO: Execute este script como Administrador!" -ForegroundColor Red
        Write-Host "  Clique direito no PowerShell > Executar como administrador" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Alternativa sem admin - instalar manualmente:" -ForegroundColor Cyan
        foreach ($task in $Tasks) {
            $trigger = if ($task.Trigger -eq "Daily") { "Diario as $($task.At)" } else { "A cada 2 horas" }
            Write-Host "  - $($task.Name) | $trigger" -ForegroundColor White
            Write-Host "    Script: $($task.Script)" -ForegroundColor DarkGray
        }
        exit 1
    }

    foreach ($task in $Tasks) {
        # Remover se ja existir
        Unregister-ScheduledTask -TaskName $task.Name -Confirm:$false -ErrorAction SilentlyContinue

        $action = New-ScheduledTaskAction `
            -Execute $PS `
            -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$($task.Script)`" $($task.Args)"

        if ($task.Trigger -eq "Daily") {
            $trigger = New-ScheduledTaskTrigger -Daily -At $task.At
        } else {
            $trigger = New-ScheduledTaskTrigger -RepetitionInterval $task.RepeatEvery -Once -At (Get-Date)
        }

        $settings = New-ScheduledTaskSettingsSet `
            -ExecutionTimeLimit (New-TimeSpan -Minutes 10) `
            -StartWhenAvailable `
            -DontStopIfGoingOnBatteries `
            -Hidden

        Register-ScheduledTask `
            -TaskName $task.Name `
            -Description $task.Description `
            -Action $action `
            -Trigger $trigger `
            -Settings $settings `
            -RunLevel Limited `
            -Force | Out-Null

        Write-Host "  [OK] $($task.Name)" -ForegroundColor Green
    }

    Write-Host "`n  Todos os agentes instalados!" -ForegroundColor Green
    Write-Host "  Execute: .\agents\setup-scheduler.ps1 -Status" -ForegroundColor DarkGray
    Write-Host ""
}

function Uninstall-Tasks {
    Write-Host "`n  Removendo agentes do Task Scheduler..." -ForegroundColor Yellow
    foreach ($task in $Tasks) {
        Unregister-ScheduledTask -TaskName $task.Name -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "  Removido: $($task.Name)" -ForegroundColor DarkGray
    }
    Write-Host "  Agentes removidos." -ForegroundColor Yellow
}

# ── Main ──────────────────────────────────────────────

Write-Host "`n============================================" -ForegroundColor Magenta
Write-Host "  SETUP DO AGENDADOR - CLAUDE HUB" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Magenta

if ($Uninstall) { Uninstall-Tasks; exit 0 }
if ($Status)    { Show-TaskStatus; exit 0 }

Install-Tasks
Show-TaskStatus
