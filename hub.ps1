<#
.SYNOPSIS
    Claude Hub - Terminal Interativo
    Dialogo natural no terminal com seus agentes e skills.
.USAGE
    .\hub.ps1
#>

$HubPath = $PSScriptRoot
$Version = "1.0.0"

function W { param([string]$m, [string]$c = "White"); Write-Host $m -ForegroundColor $c }
function WC { param([string]$m); Write-Host "  claude -> " -ForegroundColor Magenta -NoNewline; Write-Host $m -ForegroundColor White }
function WA { param([string]$m); Write-Host "  [acao]    " -ForegroundColor Yellow -NoNewline; Write-Host $m -ForegroundColor DarkGray }
function WOK { param([string]$m); Write-Host "  [ok]      " -ForegroundColor Green -NoNewline; Write-Host $m -ForegroundColor White }
function WDiv { Write-Host "  ------------------------------------------" -ForegroundColor DarkGray }
function WBlank { Write-Host "" }

function Show-Prompt {
    WBlank
    Write-Host "  voce    -> " -ForegroundColor DarkGray -NoNewline
}

function Run-Script {
    param([string]$rel, [string[]]$args = @())
    $full = Join-Path $HubPath $rel
    if (Test-Path $full) {
        & powershell -ExecutionPolicy Bypass -File $full @args
    } else {
        WC "Script nao encontrado: $rel"
    }
}

function Show-Help {
    WBlank
    W "  AGENTES AUTONOMOS" "Cyan"
    WDiv
    W "  bom dia / briefing          Briefing diario do projeto" "White"
    W "  analisar codigo             Code Guardian: revisar arquivos" "White"
    W "  processar inbox             Organizar notas do Obsidian" "White"
    W "  todos os agentes            Rodar todos de uma vez" "White"
    W "  dashboard                   Status dos agentes" "White"
    WBlank
    W "  PESQUISA" "Cyan"
    WDiv
    W "  pesquisar [topico]          Adicionar topico a fila" "White"
    W "  processar pesquisas         Gerar notas + exportar NotebookLM" "White"
    W "  fila de pesquisa            Ver o que esta na fila" "White"
    WBlank
    W "  OBSIDIAN" "Cyan"
    WDiv
    W "  criar nota                  Nova nota no vault Kaia" "White"
    W "  listar notas                Ver notas recentes" "White"
    W "  abrir obsidian              Abrir o app Obsidian" "White"
    WBlank
    W "  NOTEBOOKLM + GEMINI AI" "Cyan"
    WDiv
    W "  resumir                     Resumo executivo das notas/docs" "White"
    W "  guia de estudos             Flashcards e questoes de revisao" "White"
    W "  insights                    Extrair pontos-chave e dados" "White"
    W "  mapa mental                 Mapa mental hierarquico" "White"
    W "  audio overview              Roteiro de podcast (2 vozes)" "White"
    W "  perguntar                   Chat Q&A sobre documentos" "White"
    WBlank
    W "  DESIGN GENERATOR (Stitch)" "Cyan"
    WDiv
    W "  design [descricao]          Gerar componente React + Tailwind" "White"
    W "  html [descricao]            Gerar pagina HTML completa" "White"
    W "  abrir site                  Abrir Claude Hub no navegador" "White"
    W "  configurar chave            Configurar Gemini API key" "White"
    WBlank
    W "  OUTROS" "Cyan"
    WDiv
    W "  skills                      Listar todas as skills" "White"
    W "  agendar                     Configurar Task Scheduler Windows" "White"
    W "  sair                        Fechar o terminal" "White"
    WBlank
}

function Show-Skills {
    WBlank
    W "  SKILLS DISPONIVEIS" "Cyan"
    WDiv
    $skills = @(
        "code-review     Revisa codigo com checklist OWASP + SOLID"
        "debug           Debug sistematico com Root Cause Analysis"
        "refactor        Refatoracao Clean Code, DRY, SRP"
        "docs-generator  JSDoc, README, ADR automaticos"
        "test-generator  Jest, Vitest, Testing Library"
        "architect       Design de sistemas, C4 Model, DDD"
        "security-audit  OWASP Top 10, hardening"
        "performance     Frontend, backend e DB optimization"
        "git-workflow    Conventional Commits, branching"
        "api-design      REST, DTOs, versionamento"
        "obsidian-sync   Templates e sync com vault"
        "notebooklm-export  Exportar para NotebookLM"
    )
    foreach ($s in $skills) {
        $parts = $s -split "\s{2,}", 2
        Write-Host ("  " + $parts[0].PadRight(20)) -ForegroundColor Yellow -NoNewline
        Write-Host $parts[1] -ForegroundColor DarkGray
    }
    WBlank
    WC "Para usar uma skill, basta descrever o que quer. Ex: 'fazer code review do arquivo X'"
}

function Show-Banner {
    Clear-Host
    WBlank
    W "  ================================================" "Magenta"
    W "    CLAUDE HUB  -  Terminal Interativo  v$Version" "Cyan"
    W "    Vault: Kaia  |  4 Agentes  |  12 Skills" "DarkGray"
    W "  ================================================" "Magenta"
    WBlank
    W "  Digite 'ajuda' para ver os comandos disponíveis." "DarkGray"
    W "  Digite 'sair' para fechar." "DarkGray"
    WBlank
}

function Show-QuickStatus {
    $StateDir = Join-Path $HubPath "agents\state"
    $obsConfigPath = Join-Path $HubPath "scripts\obsidian\config.json"
    
    if (Test-Path $obsConfigPath) {
        $obsConfig = Get-Content $obsConfigPath -Raw | ConvertFrom-Json
        $inbox     = Join-Path $obsConfig.vaultPath $obsConfig.inboxFolder
        if (Test-Path $inbox) {
            $cnt = @(Get-ChildItem $inbox -Filter "*.md" -ErrorAction SilentlyContinue).Count
            if ($cnt -gt 0) {
                W "  [!] $cnt nota(s) no Inbox aguardando processamento" "Yellow"
            }
        }
    }

    $queueFile = Join-Path $StateDir "research-queue.json"
    if (Test-Path $queueFile) {
        $q = @(Get-Content $queueFile -Raw | ConvertFrom-Json)
        $p = @($q | Where-Object { $_.status -eq "pending" })
        if ($p.Count -gt 0) {
            W "  [!] $($p.Count) topico(s) de pesquisa pendente(s)" "Yellow"
        }
    }
    WBlank
}

function Handle-Input {
    param([string]$inp)
    $L = $inp.ToLower().Trim()

    # Sair
    if ($L -match "^(sair|exit|quit|tchau|bye)$") {
        WBlank
        WC "Ate logo! Os agentes continuam trabalhando em background."
        WBlank
        exit 0
    }

    # Ajuda
    if ($L -match "^(ajuda|help|\?|comandos|o que posso)") {
        Show-Help; return
    }

    # Skills
    if ($L -match "skills|quais skills|o que voce sabe") {
        Show-Skills; return
    }

    # Daily Briefing
    if ($L -match "briefing|bom dia|status do dia|resumo do dia|como esta o projeto") {
        WC "Gerando briefing diario..."
        WA "Daily Briefing Agent"
        Run-Script "agents\tasks\daily-briefing.ps1"
        return
    }

    # Inbox Processor
    if ($L -match "processar inbox|organizar obsidian|mover notas|limpar inbox|inbox") {
        WC "Processando Inbox do vault Kaia..."
        WA "Inbox Processor Agent"
        Run-Script "agents\tasks\inbox-processor.ps1"
        return
    }

    # Code Guardian
    if ($L -match "analisar codigo|code.?review|revisar codigo|guardian|checar") {
        WC "Analisando codigo modificado recentemente..."
        WA "Code Guardian Agent"
        Run-Script "agents\tasks\code-guardian.ps1"
        return
    }

    # Todos os agentes
    if ($L -match "todos os agentes|rodar tudo|run all|executar tudo") {
        WC "Disparando todos os agentes..."
        Run-Script "agents\orchestrator.ps1" @("-RunAll")
        return
    }

    # Dashboard
    if ($L -match "dashboard|status.?agentes|ver agentes") {
        Run-Script "agents\dashboard.ps1"
        return
    }

    # Pesquisar (captura o topico)
    if ($L -match "^(pesquisar?|estudar?|quero aprender|adicionar pesquisa)\s+(.+)") {
        $topic = $inp -replace "(?i)^(pesquisar?|estudar?|quero aprender|adicionar pesquisa)\s+", ""
        WC "Adicionando a fila: '$topic'"
        Run-Script "agents\tasks\researcher.ps1" @("-Add", $topic)
        WC "Use 'processar pesquisas' para gerar as notas no Obsidian."
        return
    }

    # Processar pesquisas
    if ($L -match "processar pesquisas|processar fila|gerar notas pesquisa") {
        WC "Processando fila e exportando para NotebookLM..."
        Run-Script "agents\tasks\researcher.ps1" @("-Process")
        return
    }

    # Ver fila
    if ($L -match "fila.?(pesquisa)?|ver pesquisas|listar pesquisas") {
        Run-Script "agents\tasks\researcher.ps1" @("-List")
        return
    }

    # Criar nota Obsidian
    if ($L -match "criar nota|nova nota|salvar nota|nota obsidian") {
        WBlank
        WC "Qual o titulo da nota?"
        Show-Prompt
        $title = Read-Host " "
        WC "Tipo: concept / project / meeting / snippet / learning"
        Show-Prompt
        $type = Read-Host " "
        if ($type -notmatch "^(concept|project|meeting|snippet|learning)$") { $type = "concept" }
        WC "Conteudo (opcional - Enter para pular):"
        Show-Prompt
        $content = Read-Host " "
        WA "Salvando no vault Kaia..."
        Run-Script "scripts\obsidian\sync-to-vault.ps1" @("-NoteTitle", $title, "-NoteType", $type, "-NoteContent", $content)
        return
    }

    # Listar notas
    if ($L -match "listar notas|ver notas|notas obsidian") {
        Run-Script "scripts\obsidian\sync-to-vault.ps1" @("-ListNotes")
        return
    }

    # Abrir Obsidian
    if ($L -match "abrir obsidian|open obsidian|^obsidian$") {
        WA "Abrindo Obsidian..."
        Run-Script "scripts\obsidian\sync-to-vault.ps1" @("-OpenVault")
        return
    }

    # NotebookLM (Gemini-powered)
    if ($L -match "notebooklm|exportar notebooklm|export notebook") {
        WC "Exportando bundle para NotebookLM..."
        Run-Script "scripts\notebooklm\export-to-notebooklm.ps1" @("-Bundle", "-OpenOutputFolder")
        return
    }

    # NotebookLM AI - Resumo
    if ($L -match "^resumir?|resumo dos docs|resumo das notas|summarize") {
        WC "Gerando resumo com Gemini 2.0 Flash..."
        Run-Script "scripts\gemini\notebooklm-agent.ps1" @("-Summary")
        return
    }

    # NotebookLM AI - Guia de Estudos
    if ($L -match "guia de estudos|study guide|flashcards") {
        WC "Gerando guia de estudos com flashcards..."
        Run-Script "scripts\gemini\notebooklm-agent.ps1" @("-StudyGuide")
        return
    }

    # NotebookLM AI - Insights
    if ($L -match "insights|pontos.?chave|key points|extrair pontos") {
        WC "Extraindo insights e pontos-chave..."
        Run-Script "scripts\gemini\notebooklm-agent.ps1" @("-KeyPoints")
        return
    }

    # NotebookLM AI - Mapa Mental
    if ($L -match "mapa mental|mindmap|mind map") {
        WC "Gerando mapa mental..."
        Run-Script "scripts\gemini\notebooklm-agent.ps1" @("-Mindmap")
        return
    }

    # NotebookLM AI - Audio Script
    if ($L -match "audio overview|roteiro.?(audio|podcast)|audio script") {
        WC "Gerando roteiro de audio (podcast)..."
        Run-Script "scripts\gemini\notebooklm-agent.ps1" @("-AudioScript")
        return
    }

    # NotebookLM AI - Q&A
    if ($L -match "^(perguntar|qa|chat com docs|conversar com docs)") {
        WC "Iniciando modo Q&A sobre seus documentos..."
        Run-Script "scripts\gemini\notebooklm-agent.ps1" @("-QA")
        return
    }

    # Design Generator (Stitch-powered)
    if ($L -match "^(design|criar design|gerar design|criar ui|gerar ui|criar componente)\s+(.+)") {
        $desc = $inp -replace "(?i)^(design|criar design|gerar design|criar ui|gerar ui|criar componente)\s+", ""
        WC "Gerando design: '$desc'"
        WA "Design Generator (Gemini 2.0 Flash / Stitch)"
        Run-Script "scripts\gemini\design-generator.ps1" @("-Prompt", $desc, "-Type", "react", "-Open")
        return
    }

    if ($L -match "^(design html|html)\s+(.+)") {
        $desc = $inp -replace "(?i)^(design html|html)\s+", ""
        WC "Gerando pagina HTML: '$desc'"
        Run-Script "scripts\gemini\design-generator.ps1" @("-Prompt", $desc, "-Type", "html", "-Open")
        return
    }

    # Abrir site no browser
    if ($L -match "abrir site|open site|ver site|hub site|dashboard web") {
        WC "Abrindo Claude Hub no navegador..."
        Start-Process "https://site-seven-snowy-17.vercel.app"
        return
    }

    # Configurar chave Gemini
    if ($L -match "configurar chave|gemini key|api key|chave gemini") {
        WBlank
        WC "Para ativar o Gemini AI (Design + NotebookLM):"
        WBlank
        W "  1. Acesse: https://aistudio.google.com/apikey" "Cyan"
        W "  2. Crie uma chave gratuita (AIza...)" "White"
        W "  3. Edite: scripts\gemini\config.json" "Yellow"
        W "  4. Coloque no campo 'geminiApiKey'" "White"
        WBlank
        W "  Modelo: gemini-2.0-flash (gratuito)" "DarkGray"
        W "  Uso: 1.5M tokens/dia no plano gratuito" "DarkGray"
        WBlank
        return
    }

    # Agendar
    if ($L -match "agendar|task.?scheduler|automatizar agentes") {
        WBlank
        WC "Para instalar os agentes no Windows Task Scheduler:"
        WBlank
        W "  Execute como Administrador:" "DarkGray"
        W "  .\agents\setup-scheduler.ps1" "Yellow"
        WBlank
        W "  Agendamentos:" "DarkGray"
        W "  Daily Briefing   -> 08:00 todos os dias" "White"
        W "  Code Guardian    -> A cada 2 horas" "White"
        W "  Inbox Processor  -> 12:00 e 20:00" "White"
        WBlank
        return
    }

    # Fallback
    WBlank
    WC "Nao entendi '$inp'. Aqui esta o que posso fazer:"
    Show-Help
}

# ── Main Loop ─────────────────────────────────────────

Show-Banner
Show-QuickStatus

while ($true) {
    Show-Prompt
    $userInput = Read-Host " "
    if ([string]::IsNullOrWhiteSpace($userInput)) { continue }
    WBlank
    Handle-Input $userInput
}
