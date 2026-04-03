<#
.SYNOPSIS
    Agente 3: Researcher
    Processa uma lista de topicos, gera documentos de pesquisa e exporta para Obsidian + NotebookLM.

.DESCRIPTION
    - Le a fila de pesquisa em agents/state/research-queue.json
    - Para cada topico, gera um documento estruturado de pesquisa
    - Salva no Obsidian com tags de learning
    - Exporta para NotebookLM automaticamente
    - Remove topico da fila apos processar

.USAGE
    # Adicionar topico a fila de pesquisa:
    .\agents\tasks\researcher.ps1 -Add "Como funciona o Prisma ORM"
    .\agents\tasks\researcher.ps1 -Add "SOLID principles em TypeScript"

    # Processar toda a fila:
    .\agents\tasks\researcher.ps1 -Process

    # Ver fila atual:
    .\agents\tasks\researcher.ps1 -List
#>

param(
    [string]$Add     = "",
    [switch]$Process,
    [switch]$List,
    [string]$Topic   = ""
)

$HubPath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$AgentRoot = Split-Path $PSScriptRoot -Parent
$DateStr   = Get-Date -Format "yyyy-MM-dd"
$TimeStr   = Get-Date -Format "HH:mm"
$LogDir    = Join-Path $AgentRoot "logs"
$StateDir  = Join-Path $AgentRoot "state"
$QueueFile = Join-Path $StateDir "research-queue.json"
$LogFile   = Join-Path $LogDir "researcher.log"
$StateFile = Join-Path $StateDir "researcher.json"

New-Item -ItemType Directory -Path $LogDir   -Force | Out-Null
New-Item -ItemType Directory -Path $StateDir -Force | Out-Null

function Log {
    param([string]$msg)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$ts] $msg" | Add-Content $LogFile
}

function Load-Queue {
    if (Test-Path $QueueFile) {
        $raw = [System.IO.File]::ReadAllText($QueueFile, [System.Text.Encoding]::UTF8)
        return ($raw | ConvertFrom-Json)
    }
    return @()
}

function Save-Queue {
    param($queue)
    $json = $queue | ConvertTo-Json -Depth 3
    [System.IO.File]::WriteAllText($QueueFile, $json, [System.Text.Encoding]::UTF8)
}

function Add-ToQueue {
    param([string]$topicText)
    $queue = @(Load-Queue)
    $exists = $queue | Where-Object { $_.topic -eq $topicText }
    if ($exists) {
        Write-Host "  Topico ja esta na fila: $topicText" -ForegroundColor Yellow
        return
    }
    $item = @{
        id       = [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
        topic    = $topicText
        added    = "$DateStr $TimeStr"
        status   = "pending"
        priority = "normal"
    }
    $queue += $item
    Save-Queue $queue
    Write-Host "  Adicionado a fila: $topicText" -ForegroundColor Green
    Log "Adicionado: $topicText"
}

function Generate-ResearchDoc {
    param([string]$topicText)

    $sep = [System.Environment]::NewLine

    # Template de documento de pesquisa estruturado
    $doc = ""
    $doc += "## Visao Geral" + $sep
    $doc += "Documento de pesquisa gerado automaticamente pelo Researcher Agent em $DateStr." + $sep
    $doc += "Topico: **$topicText**" + $sep + $sep

    $doc += "## O Que Pesquisar" + $sep
    $doc += "Use os prompts abaixo no Claude ou NotebookLM:" + $sep + $sep
    $doc += "### Prompt 1 - Conceito" + $sep
    $doc += '```' + $sep
    $doc += "Explique $topicText de forma completa e didatica:" + $sep
    $doc += "1. O que e e para que serve" + $sep
    $doc += "2. Conceitos fundamentais (5-10 conceitos-chave)" + $sep
    $doc += "3. Como funciona internamente" + $sep
    $doc += "4. Casos de uso reais" + $sep
    $doc += "5. Exemplos praticos com codigo" + $sep
    $doc += "6. Vantagens e limitacoes" + $sep
    $doc += "7. Alternativas existentes" + $sep
    $doc += "8. Recursos para aprofundar" + $sep
    $doc += '```' + $sep + $sep

    $doc += "### Prompt 2 - Pratico" + $sep
    $doc += '```' + $sep
    $doc += "Mostre $topicText na pratica com exemplos de codigo TypeScript/React." + $sep
    $doc += "Inclua: setup basico, casos comuns, armadilhas a evitar, boas praticas." + $sep
    $doc += '```' + $sep + $sep

    $doc += "### Prompt 3 - Avancado" + $sep
    $doc += '```' + $sep
    $doc += "Quais sao os conceitos avancados de $topicText que um desenvolvedor senior deve dominar?" + $sep
    $doc += "Inclua: performance, seguranca, patterns especificos, integracao com outras ferramentas." + $sep
    $doc += '```' + $sep + $sep

    $doc += "## Conexoes com Outras Notas" + $sep
    $doc += "- [[Claude Hub Skills]]" + $sep
    $doc += "- (adicionar links apos pesquisar)" + $sep + $sep

    $doc += "## Minhas Notas" + $sep
    $doc += "(espaco para anotar insights durante a pesquisa)" + $sep + $sep

    $doc += "## Status" + $sep
    $doc += "- [ ] Prompt 1 respondido" + $sep
    $doc += "- [ ] Prompt 2 respondido" + $sep
    $doc += "- [ ] Prompt 3 respondido" + $sep
    $doc += "- [ ] Exportado para NotebookLM" + $sep
    $doc += "- [ ] Conectado a notas existentes" + $sep

    return $doc
}

function Process-Queue {
    $queue = @(Load-Queue)
    $pending = $queue | Where-Object { $_.status -eq "pending" }

    if ($pending.Count -eq 0) {
        Write-Host "  Nenhum topico pendente na fila." -ForegroundColor DarkGray
        Write-Host "  Adicione topicos com: -Add 'Meu Topico'" -ForegroundColor DarkGray
        return
    }

    Write-Host "  Processando $($pending.Count) topico(s)..." -ForegroundColor Cyan

    $syncScript   = Join-Path $HubPath "scripts\obsidian\sync-to-vault.ps1"
    $exportScript = Join-Path $HubPath "scripts\notebooklm\export-to-notebooklm.ps1"

    foreach ($item in $pending) {
        Write-Host "`n  Topico: $($item.topic)" -ForegroundColor White

        # Gerar documento de pesquisa
        $doc = Generate-ResearchDoc $item.topic

        # Salvar no Obsidian
        $noteTitle = "Research - " + $item.topic
        & $syncScript `
            -NoteTitle $noteTitle `
            -NoteType "learning" `
            -NoteContent $doc `
            -Tags @("research","agent/researcher","status/pending") | Out-Null

        Write-Host "  Nota criada no Obsidian: $noteTitle" -ForegroundColor Green

        # Marcar como processado (recriar objeto com nova propriedade)
        for ($i = 0; $i -lt $queue.Count; $i++) {
            if ($queue[$i].id -eq $item.id) {
                $queue[$i] = [PSCustomObject]@{
                    id          = $queue[$i].id
                    topic       = $queue[$i].topic
                    added       = $queue[$i].added
                    status      = "processed"
                    priority    = $queue[$i].priority
                    processedAt = "$DateStr $TimeStr"
                }
            }
        }

        Log "Processado: $($item.topic)"
    }

    Save-Queue $queue

    # Exportar tudo para NotebookLM (bundle das notas de research)
    $vaultInbox = Join-Path (Get-Content (Join-Path $HubPath "scripts\obsidian\config.json") -Raw | ConvertFrom-Json).vaultPath "Inbox"
    if (Test-Path $vaultInbox) {
        & $exportScript -InputPath $vaultInbox -Bundle -Title "Research Queue $DateStr" | Out-Null
        Write-Host "`n  Bundle exportado para NotebookLM" -ForegroundColor Cyan
    }

    $state = @{ lastRun = "$DateStr $TimeStr"; processed = $pending.Count }
    [System.IO.File]::WriteAllText($StateFile, ($state | ConvertTo-Json), [System.Text.Encoding]::UTF8)
}

function Show-Queue {
    $queue = @(Load-Queue)
    if ($queue.Count -eq 0) {
        Write-Host "`n  Fila vazia. Use -Add 'Topico' para adicionar." -ForegroundColor DarkGray
        return
    }
    Write-Host "`n  Fila de Pesquisa ($($queue.Count) itens):" -ForegroundColor Cyan
    foreach ($item in $queue) {
        $statusColor = if ($item.status -eq "pending") { "Yellow" } else { "Green" }
        $statusLabel = if ($item.status -eq "pending") { "[PENDENTE]" } else { "[PROCESSADO]" }
        Write-Host "  $statusLabel $($item.topic)" -ForegroundColor $statusColor
        Write-Host "         Adicionado: $($item.added)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

# ── Main ──────────────────────────────────────────────

Write-Host "`n============================================" -ForegroundColor Magenta
Write-Host "  RESEARCHER AGENT" -ForegroundColor Cyan
Write-Host "  $DateStr $TimeStr" -ForegroundColor White
Write-Host "============================================`n" -ForegroundColor Magenta

if ($Add -ne "") {
    Add-ToQueue $Add
    Write-Host ""
    Write-Host "  Para processar a fila: .\agents\tasks\researcher.ps1 -Process" -ForegroundColor DarkGray
    exit 0
}

if ($List) {
    Show-Queue
    exit 0
}

if ($Process) {
    Process-Queue
    exit 0
}

# Sem parametros: mostrar status
Show-Queue
Write-Host "  Uso:" -ForegroundColor Yellow
Write-Host "  -Add 'Topico'   Adicionar a fila" -ForegroundColor White
Write-Host "  -Process        Processar toda a fila" -ForegroundColor White
Write-Host "  -List           Ver fila atual" -ForegroundColor White
