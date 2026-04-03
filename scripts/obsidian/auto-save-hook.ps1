<#
.SYNOPSIS
    Hook post-message para salvar respostas Claude no Obsidian automaticamente

.DESCRIPTION
    Este script é chamado automaticamente pelo hooks/post-message.ps1.
    Detecta se uma resposta Claude deve ser salva como nota Obsidian.
    Palavras-chave: "salvar no Obsidian", "criar nota", "guardar isso"
#>

param(
    [string]$MessageContent = "",
    [string]$ConversationTitle = "Conversa Claude",
    [string]$NoteType = "learning"
)

$SyncScript = Join-Path $PSScriptRoot "sync-to-vault.ps1"

# Palavras-chave que disparam salvamento automático
$TriggerKeywords = @(
    "salvar no obsidian",
    "criar nota",
    "guardar isso", 
    "save to obsidian",
    "nota obsidian",
    "adicionar ao vault"
)

$ShouldSave = $false
foreach ($kw in $TriggerKeywords) {
    if ($MessageContent.ToLower().Contains($kw)) {
        $ShouldSave = $true
        break
    }
}

if ($ShouldSave -and $MessageContent -ne "") {
    Write-Host "🗒️  Salvando no Obsidian automaticamente..." -ForegroundColor Cyan
    & $SyncScript -NoteTitle $ConversationTitle -NoteContent $MessageContent -NoteType $NoteType
}
