<#
.SYNOPSIS
    Hook PostCommand — executado após comandos shell

.DESCRIPTION
    Registra resultados, captura erros, notifica falhas de build/test.
#>

param(
    [string]$Command    = "",
    [int]$ExitCode      = 0,
    [string]$Output     = "",
    [string]$WorkingDir = ""
)

$HubPath  = $PSScriptRoot | Split-Path -Parent
$DateStr  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$LogDir   = Join-Path $HubPath "hooks\logs"
$LogFile  = Join-Path $LogDir "commands.log"

New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

$Status = if ($ExitCode -eq 0) { "✅ OK" } else { "❌ FAIL (exit $ExitCode)" }
"[$DateStr] $Status — $Command" | Add-Content $LogFile

# ─── Alertar sobre falhas em build/test ──────────
if ($ExitCode -ne 0) {
    $AlertCommands = @("npm test", "npm run build", "npm run lint", "npx tsc")
    foreach ($alertCmd in $AlertCommands) {
        if ($Command -like "*$alertCmd*") {
            Write-Host ""
            Write-Host "🚨 $alertCmd FALHOU (exit code: $ExitCode)" -ForegroundColor Red
            Write-Host "   Verifique o output acima para detalhes." -ForegroundColor Yellow
            Write-Host ""
            break
        }
    }
}
