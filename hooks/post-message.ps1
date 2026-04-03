<#
.SYNOPSIS
    Hook PostMessage — executado após cada resposta Claude

.DESCRIPTION
    Automatiza ações após respostas: salvar no Obsidian, exportar para NotebookLM,
    atualizar memória, notificações, etc.
    
    Configurar no settings.json:
    "hooks": { "postMessage": ["powershell -File hooks/post-message.ps1"] }
#>

param(
    [string]$MessageContent = "",
    [string]$ConversationId = "",
    [string]$SessionPath    = ""
)

$HubPath   = $PSScriptRoot | Split-Path -Parent
$DateStr   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# ─── Log da execução ───────────────────────────────
$LogDir  = Join-Path $HubPath "hooks\logs"
$LogFile = Join-Path $LogDir "post-message.log"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

"[$DateStr] PostMessage hook disparado. ConversationId: $ConversationId" | 
    Add-Content $LogFile

# ─── 1. Auto-save Obsidian (se palavra-chave detectada) ───
$ObsidianHook = Join-Path $HubPath "scripts\obsidian\auto-save-hook.ps1"
if (Test-Path $ObsidianHook) {
    & $ObsidianHook -MessageContent $MessageContent -ConversationTitle "Claude-$ConversationId"
}

# ─── 2. Atualizar timestamp no MEMORY.md ───
$MemoryFile = Join-Path $HubPath ".claude\memory\MEMORY.md"
if (Test-Path $MemoryFile) {
    $content = Get-Content $MemoryFile -Raw
    if ($content -notmatch "Última Atividade") {
        Add-Content $MemoryFile "`n### Última Atividade`n- $DateStr — Sessão: $ConversationId"
    }
}

"[$DateStr] PostMessage hook concluído." | Add-Content $LogFile
