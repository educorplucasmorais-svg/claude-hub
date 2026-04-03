<#
.SYNOPSIS
    Hook PreCommand — executado antes de comandos shell

.DESCRIPTION
    Valida comandos perigosos antes de executar (rm, DROP, etc.)
    Loga todos os comandos executados para auditoria.
#>

param(
    [string]$Command = "",
    [string]$WorkingDir = ""
)

$HubPath  = $PSScriptRoot | Split-Path -Parent
$DateStr  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$LogDir   = Join-Path $HubPath "hooks\logs"
$LogFile  = Join-Path $LogDir "commands.log"

New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

# ─── Comandos perigosos — bloquear e alertar ───────
$DangerousPatterns = @(
    "DROP TABLE",
    "DROP DATABASE", 
    "DELETE FROM.*WHERE.*1=1",
    "TRUNCATE",
    "rm -rf",
    "Remove-Item.*-Recurse.*-Force",
    "format c:",
    "del /f /s /q"
)

foreach ($pattern in $DangerousPatterns) {
    if ($Command -match $pattern) {
        Write-Warning "⚠️  COMANDO PERIGOSO DETECTADO: $pattern"
        Write-Warning "   Comando: $Command"
        Write-Warning "   Requer confirmação explícita antes de executar."
        "[$DateStr] BLOCKED - Dangerous: $Command" | Add-Content $LogFile
        exit 1
    }
}

# ─── Log normal ───────────────────────────────────
"[$DateStr] CMD: $Command (dir: $WorkingDir)" | Add-Content $LogFile
