<#
.SYNOPSIS
    Claude Hub - Interface de Dialogo Interativo
    Terminal tipo "chat" para comandar todos os agentes e skills via linguagem natural.

.USAGE
    .\claude-hub.ps1
    .\claude-hub.ps1 -Command "pesquisar React Hooks"
#>

param([string]$Command = "")

$HubPath   = $PSScriptRoot
$AgentDir  = Join-Path $HubPath "agents\tasks"
$ScriptDir = Join-Path $HubPath "scripts"
$History   = @()
$Version   = "1.0.0"

# ── Cores e UI ────────────────────────────────────────
function Write-Header {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "  ║          CLAUDE HUB  v$Version                   ║" -ForegroundColor Cyan
    Write-Host "  ║       Assistente Autonomo Inteligente         ║" -ForegroundColor White
    Write-Host "  ╚═══════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host "  Digite 'ajuda' para ver os comandos disponíveis." -ForegroundColor DarkGray
    Write-Host ""
}

function Write-Bot {
    param([string]$msg, [string]$color = "Cyan")
    Write-Host "  🤖 $msg" -ForegroundColor $color
}

function Write-Success {
    param([string]$msg)
    Write-Host "  ✅ $msg" -ForegroundColor Green
}

function Write-Warn {
    param([string]$msg)
    Write-Host "  ⚠️  $msg" -ForegroundColor Yellow
}

function Write-Divider {
    Write-Host "  ─────────────────────────────────────────────────" -ForegroundColor DarkGray
}

function Prompt-User {
    Write-Host ""
    Write-Host "  você" -ForegroundColor Yellow -NoNewline
    Write-Host " > " -ForegroundColor DarkGray -NoNewline
    return (Read-Host).Trim()
}

# ── Roteador de Intenções (NLU simples) ──────────────
function Detect-Intent {
    param([string]$userInput)
    $lower = $userInput.ToLower()

    # Pesquisa / Research
    if ($lower -match "pesquis|research|estudar|aprender sobre|buscar sobre|procurar sobre") {
        return "research"
    }
    # Criar nota Obsidian
    if ($lower -match "criar nota|nova nota|salvar no obsidian|nota obsidian|adicionar ao vault") {
        return "obsidian-create"
    }
    # Ver notas / inbox
    if ($lower -match "ver notas|listar notas|inbox|notas do obsidian|o que tem no vault") {
        return "obsidian-list"
    }
    # Processar inbox
    if ($lower -match "processar inbox|organizar notas|mover notas|limpar inbox") {
        return "obsidian-process"
    }
    # Exportar NotebookLM
    if ($lower -match "exportar|notebooklm|notebook lm|export") {
        return "notebooklm-export"
    }
    # Daily briefing
    if ($lower -match "daily|briefing|resumo do dia|status do projeto|como está o projeto") {
        return "daily"
    }
    # Code Guardian / revisar código
    if ($lower -match "revisar codigo|code review|analisar codigo|checar codigo|guardian") {
        return "code-guardian"
    }
    # Rodar todos os agentes
    if ($lower -match "rodar tudo|executar tudo|run all|todos os agentes") {
        return "run-all"
    }
    # Dashboard / status
    if ($lower -match "dashboard|status dos agentes|status agentes|ver agentes") {
        return "dashboard"
    }
    # Agendar / scheduler
    if ($lower -match "agendar|schedule|task scheduler|automatizar") {
        return "scheduler"
    }
    # Abrir Obsidian
    if ($lower -match "abrir obsidian|open obsidian|abrir vault") {
        return "obsidian-open"
    }
    # Ajuda
    if ($lower -match "^ajuda$|^help$|^\?$|o que (você|voce) (faz|pode)|comandos") {
        return "help"
    }
    # Sair
    if ($lower -match "^sair$|^exit$|^quit$|^bye$|^tchau$") {
        return "exit"
    }
    # Limpar tela
    if ($lower -match "^limpar$|^clear$|^cls$") {
        return "clear"
    }
    # Abrir explorador de arquivos (hub)
    if ($lower -match "abrir pasta|abrir hub|explorar|abrir projeto") {
        return "open-folder"
    }
    # Histórico
    if ($lower -match "historico|history|o que eu pedi|ultimos comandos") {
        return "history"
    }

    return "unknown"
}

# ── Extratores de Conteúdo ────────────────────────────
function Extract-TopicFromInput {
    param([string]$userInput)
    $lower = $userInput.ToLower()
    $stopWords = @("pesquisar","pesquisa","estudar","aprender sobre","buscar sobre","procurar sobre","sobre","um","uma","o","a")
    $topic = $userInput
    foreach ($sw in $stopWords) {
        $topic = $topic -replace "(?i)^$sw\s*", ""
        $topic = $topic -replace "(?i)\s*$sw\s*", " "
    }
    return $topic.Trim()
}

function Extract-NoteTitleFromInput {
    param([string]$userInput)
    $clean = $userInput -replace "(?i)(criar nota|nova nota|salvar no obsidian|nota sobre|nota obsidian)", ""
    return $clean.Trim().Trim('"').Trim("'")
}

# ── Handlers de Intenção ──────────────────────────────
function Handle-Research {
    param([string]$userInput)
    $topic = Extract-TopicFromInput $userInput
    if ($topic -eq "" -or $topic.Length -lt 3) {
        Write-Bot "Sobre qual topico voce quer pesquisar?" "Yellow"
        $topic = Prompt-User
    }
    Write-Bot "Adicionando '$topic' a fila de pesquisa..." "Cyan"
    & powershell -ExecutionPolicy Bypass -File (Join-Path $AgentDir "researcher.ps1") -Add $topic 2>&1 | Where-Object { $_ -match "Adicionado|Para processar" } | ForEach-Object { Write-Host "  $_" }
    Write-Bot "Topico adicionado! Quer processar a fila agora e criar as notas no Obsidian?" "Cyan"
    $resp = Prompt-User
    if ($resp -match "(?i)sim|s|yes|y|ok|claro|vai") {
        Write-Bot "Processando fila de pesquisa..." "Cyan"
        & powershell -ExecutionPolicy Bypass -File (Join-Path $AgentDir "researcher.ps1") -Process 2>&1 | Where-Object { $_ -notmatch "^$" } | Select-Object -First 15 | ForEach-Object { Write-Host "  $_" }
    }
}

function Handle-ObsidianCreate {
    param([string]$userInput)
    $title = Extract-NoteTitleFromInput $userInput
    if ($title -eq "" -or $title.Length -lt 3) {
        Write-Bot "Qual é o título da nota?" "Yellow"
        $title = Prompt-User
    }
    Write-Bot "Que tipo de nota? (concept / project / meeting / snippet / learning)" "Yellow"
    Write-Host "  [Enter para 'concept']" -ForegroundColor DarkGray
    $type = Prompt-User
    if ($type -eq "") { $type = "concept" }

    Write-Bot "Qual o conteudo da nota? (deixe vazio para criar nota em branco)" "Yellow"
    $content = Prompt-User

    Write-Bot "Criando nota '$title' no vault Kaia..." "Cyan"
    $syncScript = Join-Path $ScriptDir "obsidian\sync-to-vault.ps1"
    & powershell -ExecutionPolicy Bypass -File $syncScript -NoteTitle $title -NoteType $type -NoteContent $content 2>&1 |
        Where-Object { $_ -match "Nota criada|Local:|Vault" } | ForEach-Object { Write-Host "  $_" -ForegroundColor Green }
    Write-Success "Nota criada no vault Kaia!"
}

function Handle-ObsidianList {
    $syncScript = Join-Path $ScriptDir "obsidian\sync-to-vault.ps1"
    Write-Bot "Buscando notas recentes no vault Kaia..." "Cyan"
    & powershell -ExecutionPolicy Bypass -File $syncScript -ListNotes 2>&1 | ForEach-Object { Write-Host "  $_" }
}

function Handle-ObsidianProcess {
    Write-Bot "Processar inbox vai mover as notas para as pastas corretas. Continuar?" "Yellow"
    Write-Host "  [sim / nao]" -ForegroundColor DarkGray
    $resp = Prompt-User
    if ($resp -match "(?i)sim|s|yes|y|ok") {
        & powershell -ExecutionPolicy Bypass -File (Join-Path $AgentDir "inbox-processor.ps1") 2>&1 | ForEach-Object { Write-Host "  $_" }
    } else {
        Write-Bot "Cancelado. Voce pode rodar -DryRun para simular antes: .\agents\tasks\inbox-processor.ps1 -DryRun" "DarkGray"
    }
}

function Handle-NotebookLMExport {
    Write-Bot "Exportar o que? (1) Skills  (2) Workflows  (3) Docs  (4) Inbox Obsidian  (5) Tudo" "Yellow"
    $choice = Prompt-User
    $exportScript = Join-Path $ScriptDir "notebooklm\export-to-notebooklm.ps1"
    switch ($choice) {
        "1" { $path = Join-Path $HubPath "skills" }
        "2" { $path = Join-Path $HubPath "workflows" }
        "3" { $path = Join-Path $HubPath "docs" }
        "4" {
            $obsConf = Get-Content (Join-Path $ScriptDir "obsidian\config.json") -Raw | ConvertFrom-Json
            $path = Join-Path $obsConf.vaultPath $obsConf.inboxFolder
        }
        default { $path = $HubPath }
    }
    Write-Bot "Exportando para NotebookLM..." "Cyan"
    & powershell -ExecutionPolicy Bypass -File $exportScript -InputPath $path -Bundle 2>&1 |
        Where-Object { $_ -notmatch "^$" } | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" }
    Write-Bot "Abrir a pasta de exports?" "Yellow"
    Write-Host "  [sim / nao]" -ForegroundColor DarkGray
    if ((Prompt-User) -match "(?i)sim|s|yes") {
        $exportsDir = Join-Path $ScriptDir "notebooklm\exports"
        if (Test-Path $exportsDir) { Start-Process "explorer.exe" $exportsDir }
    }
}

function Handle-Daily {
    Write-Bot "Gerando Daily Briefing..." "Cyan"
    & powershell -ExecutionPolicy Bypass -File (Join-Path $AgentDir "daily-briefing.ps1") 2>&1 |
        Where-Object { $_ -notmatch "^$" } | ForEach-Object { Write-Host "  $_" }
}

function Handle-CodeGuardian {
    Write-Bot "Iniciando Code Guardian (analise de codigo modificado)..." "Cyan"
    & powershell -ExecutionPolicy Bypass -File (Join-Path $AgentDir "code-guardian.ps1") 2>&1 |
        Where-Object { $_ -notmatch "^$" } | ForEach-Object { Write-Host "  $_" }
}

function Handle-Dashboard {
    & powershell -ExecutionPolicy Bypass -File (Join-Path $HubPath "agents\dashboard.ps1") 2>&1 |
        Where-Object { $_ -notmatch "^$" } | ForEach-Object { Write-Host "  $_" }
}

function Handle-RunAll {
    Write-Bot "Executando todos os agentes..." "Cyan"
    & powershell -ExecutionPolicy Bypass -File (Join-Path $HubPath "agents\orchestrator.ps1") -RunAll 2>&1 |
        Where-Object { $_ -notmatch "^$" } | ForEach-Object { Write-Host "  $_" }
}

function Handle-Help {
    Write-Host ""
    Write-Host "  O QUE EU POSSO FAZER POR VOCE:" -ForegroundColor Cyan
    Write-Divider
    Write-Host "  PESQUISA E CONHECIMENTO" -ForegroundColor Yellow
    Write-Host "  pesquisar [topico]          Pesquisar e criar nota de estudo no Obsidian" -ForegroundColor White
    Write-Host "  criar nota [titulo]         Criar nota no vault Obsidian (Kaia)" -ForegroundColor White
    Write-Host "  ver notas                   Listar notas recentes do vault" -ForegroundColor White
    Write-Host "  processar inbox             Organizar notas do Inbox por tipo" -ForegroundColor White
    Write-Host "  exportar                    Exportar conteudo para NotebookLM" -ForegroundColor White
    Write-Host ""
    Write-Host "  AGENTES E AUTOMACAO" -ForegroundColor Yellow
    Write-Host "  daily                       Gerar briefing do dia" -ForegroundColor White
    Write-Host "  revisar codigo              Analisar codigo modificado (Code Guardian)" -ForegroundColor White
    Write-Host "  rodar tudo                  Executar todos os agentes" -ForegroundColor White
    Write-Host "  dashboard                   Ver status de todos os agentes" -ForegroundColor White
    Write-Host "  agendar                     Instalar agentes no Task Scheduler" -ForegroundColor White
    Write-Host ""
    Write-Host "  NAVEGACAO" -ForegroundColor Yellow
    Write-Host "  abrir obsidian              Abrir vault Kaia no Obsidian" -ForegroundColor White
    Write-Host "  abrir pasta                 Abrir pasta do Claude Hub" -ForegroundColor White
    Write-Host "  historico                   Ver seus ultimos comandos" -ForegroundColor White
    Write-Host "  limpar                      Limpar a tela" -ForegroundColor White
    Write-Host "  sair                        Encerrar" -ForegroundColor White
    Write-Divider
    Write-Host ""
    Write-Host "  EXEMPLOS DE USO:" -ForegroundColor DarkGray
    Write-Host "  pesquisar TypeScript generics" -ForegroundColor DarkGray
    Write-Host "  criar nota sobre React performance" -ForegroundColor DarkGray
    Write-Host "  exportar skills para NotebookLM" -ForegroundColor DarkGray
    Write-Host ""
}

function Handle-History {
    if ($script:History.Count -eq 0) {
        Write-Bot "Nenhum comando no historico ainda." "DarkGray"
        return
    }
    Write-Host ""
    Write-Host "  Seus ultimos comandos:" -ForegroundColor Cyan
    $i = 1
    foreach ($h in $script:History | Select-Object -Last 10) {
        Write-Host "  [$i] $h" -ForegroundColor White
        $i++
    }
    Write-Host ""
}

# ── Loop Principal ────────────────────────────────────
function Start-Dialog {
    Write-Header
    Write-Bot "Ola! Sou o assistente do Claude Hub. Como posso ajudar?" "Cyan"
    Write-Bot "Digite 'ajuda' para ver tudo que posso fazer, ou simplesmente me diga o que precisa." "DarkGray"

    while ($true) {
        $userInput = Prompt-User

        if ($userInput -eq "") { continue }
        $script:History += $userInput

        $intent = Detect-Intent $userInput
        Write-Host ""
        Write-Divider

        switch ($intent) {
            "research"        { Handle-Research $userInput }
            "obsidian-create" { Handle-ObsidianCreate $userInput }
            "obsidian-list"   { Handle-ObsidianList }
            "obsidian-process"{ Handle-ObsidianProcess }
            "obsidian-open"   {
                Write-Bot "Abrindo Obsidian..." "Cyan"
                & powershell -ExecutionPolicy Bypass -File (Join-Path $ScriptDir "obsidian\sync-to-vault.ps1") -OpenVault
            }
            "notebooklm-export" { Handle-NotebookLMExport }
            "daily"           { Handle-Daily }
            "code-guardian"   { Handle-CodeGuardian }
            "run-all"         { Handle-RunAll }
            "dashboard"       { Handle-Dashboard }
            "scheduler"       {
                Write-Bot "Para instalar agentes como tarefas automaticas no Windows:" "Cyan"
                Write-Host "  Execute como Administrador: .\agents\setup-scheduler.ps1" -ForegroundColor White
                Write-Host "  Isso vai agendar: Daily 08h | Code Guardian a cada 2h | Inbox 12h e 20h" -ForegroundColor DarkGray
            }
            "open-folder"     {
                Write-Bot "Abrindo pasta do Claude Hub..." "Cyan"
                Start-Process "explorer.exe" $HubPath
            }
            "history"         { Handle-History }
            "help"            { Handle-Help }
            "clear"           { Write-Header; Write-Bot "Tela limpa! Como posso ajudar?" "Cyan" }
            "exit"            {
                Write-Host ""
                Write-Bot "Ate logo! Os agentes continuam trabalhando em background." "Magenta"
                Write-Host ""
                exit 0
            }
            "unknown"         {
                Write-Bot "Nao entendi exatamente. Aqui estao algumas coisas que posso fazer:" "Yellow"
                Write-Host "  pesquisar [topico] | criar nota | ver notas | daily | dashboard | ajuda" -ForegroundColor DarkGray
            }
        }

        Write-Divider
    }
}

# ── Entrada ───────────────────────────────────────────
if ($Command -ne "") {
    # Modo nao-interativo: executar comando direto
    $intent = Detect-Intent $Command
    switch ($intent) {
        "research"          { Handle-Research $Command }
        "daily"             { Handle-Daily }
        "dashboard"         { Handle-Dashboard }
        "run-all"           { Handle-RunAll }
        "obsidian-list"     { Handle-ObsidianList }
        "obsidian-process"  { Handle-ObsidianProcess }
        "notebooklm-export" { Handle-NotebookLMExport }
        "code-guardian"     { Handle-CodeGuardian }
        default             { Write-Bot "Comando: '$Command' -> intent: $intent" "DarkGray" }
    }
} else {
    Start-Dialog
}
