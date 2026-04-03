<#
.SYNOPSIS
    NotebookLM — Integração completa via Gemini 2.0 Flash
    Replica todas as funções do NotebookLM do Google localmente.

.USO RAPIDO
    .\notebooklm.ps1                          # Menu interativo
    .\notebooklm.ps1 -Resumo                  # Resumo das notas do Obsidian
    .\notebooklm.ps1 -Resumo -Fontes "doc.md" # Resumo de arquivo especifico
    .\notebooklm.ps1 -Perguntar "O que é X?"  # Pergunta direta
    .\notebooklm.ps1 -Chat                    # Chat interativo Q&A
    .\notebooklm.ps1 -Estudar                 # Guia de estudos + flashcards
    .\notebooklm.ps1 -MapaMental              # Mapa mental Markdown
    .\notebooklm.ps1 -Insights                # Pontos-chave e dados
    .\notebooklm.ps1 -Podcast                 # Roteiro de audio (2 vozes)
    .\notebooklm.ps1 -Testar                  # Testar conexao com Gemini
#>

param(
    [switch]$Resumo,
    [switch]$Chat,
    [switch]$Estudar,
    [switch]$MapaMental,
    [switch]$Insights,
    [switch]$Podcast,
    [switch]$Testar,
    [string]$Perguntar  = "",
    [string[]]$Fontes   = @(),
    [switch]$Menu
)

$HubPath = Split-Path $PSScriptRoot -Parent

. (Join-Path $PSScriptRoot "gemini-core.ps1")

$cfg     = Get-GeminiConfig
$OutDir  = $cfg.notebooklmOutputDir
$Ts      = Get-Date -Format "yyyyMMdd-HHmmss"

# ── Helpers ───────────────────────────────────────────

function W  { param([string]$m, [string]$c="White"); Write-Host "  $m" -ForegroundColor $c }
function WC { param([string]$m); Write-Host ""; Write-Host "  claude -> " -ForegroundColor Magenta -NoNewline; Write-Host $m -ForegroundColor White }
function WH { param([string]$t); Write-Host ""; Write-Host "  NOTEBOOKLM >> $t" -ForegroundColor Cyan; Write-Host "  ─────────────────────────────────────" -ForegroundColor DarkGray }
function Salvar { param([string]$c,[string]$l); $p = Join-Path $OutDir "${l}-${Ts}.md"; New-Item -ItemType Directory -Force $OutDir | Out-Null; [System.IO.File]::WriteAllText($p,$c,[System.Text.Encoding]::UTF8); W "[salvo] $p" "DarkGray"; return $p }
function SalvarObsidian { param([string]$c,[string]$l); $d = Join-Path $cfg.notebooklmOutputDir "..\..\"; $obs = Get-Content (Join-Path $HubPath "obsidian\config.json") -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json; if ($obs) { $p = Join-Path $obs.vaultPath "NotebookLM\${l}-${Ts}.md"; New-Item -ItemType Directory -Force (Split-Path $p) | Out-Null; [System.IO.File]::WriteAllText($p,$c,[System.Text.Encoding]::UTF8); W "[obsidian] $p" "DarkGray" } }

function Get-Fontes {
    param([string[]]$s)
    $files = @()

    # Fontes passadas como parametro
    foreach ($src in $s) {
        if (Test-Path $src -PathType Container) {
            $files += (Get-ChildItem $src -Include "*.md","*.txt","*.pdf" -Recurse).FullName
        } elseif (Test-Path $src) {
            $files += $src
        }
    }

    # Fallback: vault Obsidian
    if ($files.Count -eq 0) {
        $obsCfg = Get-Content (Join-Path $HubPath "scripts\obsidian\config.json") -Raw | ConvertFrom-Json
        $vault  = $obsCfg.vaultPath
        $files  = (Get-ChildItem $vault -Filter "*.md" -Recurse -ErrorAction SilentlyContinue |
                   Sort-Object LastWriteTime -Descending |
                   Select-Object -First 15).FullName
        if ($files.Count -gt 0) {
            W "Usando vault Kaia ($($files.Count) notas recentes)" "DarkGray"
        }
    }

    # Fallback: pasta docs
    if ($files.Count -eq 0) {
        $docsPath = Join-Path $HubPath "docs"
        if (Test-Path $docsPath) {
            $files = (Get-ChildItem $docsPath -Include "*.md","*.txt" -Recurse).FullName
        }
    }

    return $files
}

function Rodar {
    param([string]$prompt, [string[]]$files, [string]$sys="")
    if ($files.Count -gt 0) {
        return Invoke-GeminiWithFiles -Prompt $prompt -FilePaths $files -SystemPrompt $sys
    } else {
        return Invoke-Gemini -Prompt $prompt -SystemPrompt $sys
    }
}

# ── TESTAR CONEXAO ────────────────────────────────────

if ($Testar) {
    WH "TESTE DE CONEXAO"
    W "Testando chave Gemini API..." "Yellow"
    $r = Test-GeminiKey
    if ($r.Valid) {
        W "Conexao OK! Modelo: $($cfg.geminiModel)" "Green"
        W "Resposta: $($r.Response)" "DarkGray"
    } else {
        W "Falha: $($r.Error)" "Red"
        W ""
        W "Verifique a chave em: scripts\gemini\config.json" "Yellow"
        W "Obtenha uma chave em: https://aistudio.google.com/apikey" "Cyan"
    }
    exit 0
}

# ── RESUMO ────────────────────────────────────────────

if ($Resumo) {
    WH "RESUMO EXECUTIVO"
    $files = Get-Fontes $Fontes
    W "Analisando $($files.Count) fonte(s)..." "Yellow"

    $sys = "Voce e o NotebookLM. Analise os documentos e gere um resumo executivo claro e util. Responda em portugues."
    $prompt = @"
Gere um RESUMO EXECUTIVO dos documentos com esta estrutura:

## Resumo em Uma Frase
(capture a essencia em 1 frase)

## Visao Geral
(2-3 paragrafos descrevendo o conteudo)

## Topicos Abordados
(lista dos principais temas)

## Insights Importantes
(descobertas e conclusoes relevantes)

## Proximos Passos
(acoes praticas recomendadas)
"@
    $result = Rodar $prompt $files $sys
    Write-Host ""
    Write-Host $result -ForegroundColor White
    $path = Salvar "# Resumo Executivo`n_$(Get-Date -Format 'yyyy-MM-dd HH:mm')_`n`n$result" "resumo"
    SalvarObsidian "# Resumo`n$result" "resumo"
    WC "Resumo salvo em: $path"
    exit 0
}

# ── CHAT Q&A ──────────────────────────────────────────

if ($Chat) {
    WH "CHAT Q&A — Converse com seus documentos"
    $files = Get-Fontes $Fontes
    W "Carregando $($files.Count) fonte(s)..." "Yellow"

    # Pre-carregar contexto
    $ctx = ($files | ForEach-Object {
        $n = Split-Path $_ -Leaf
        $c = Get-Content $_ -Raw -ErrorAction SilentlyContinue
        if ($c) { "=== $n ===`n$c" }
    }) -join "`n`n"

    $sys = "Voce e o NotebookLM. Responda APENAS com base nos documentos fornecidos. Se a informacao nao estiver nos docs, diga claramente. Cite trechos relevantes. Responda em portugues."

    W "Pronto! Faca suas perguntas. Digite 'sair' para fechar." "Green"
    Write-Host ""

    $historico = @()
    while ($true) {
        Write-Host "  voce -> " -ForegroundColor DarkGray -NoNewline
        $q = Read-Host " "
        if ($q -match "^(sair|exit|quit)$") { break }
        if ([string]::IsNullOrWhiteSpace($q)) { continue }

        Write-Host "  [processando...]" -ForegroundColor DarkGray

        $fullPrompt = "DOCUMENTOS:`n$ctx`n`nHISTORICO:`n$(($historico | ForEach-Object { "$($_.role): $($_.text}" }) -join "`n")`n`nPERGUNTA ATUAL: $q"
        $resp       = Invoke-Gemini -Prompt $fullPrompt -SystemPrompt $sys

        $historico += @{ role = "usuario"; text = $q }
        $historico += @{ role = "claude";  text = $resp }

        Write-Host ""
        Write-Host "  claude -> " -ForegroundColor Magenta -NoNewline
        Write-Host $resp -ForegroundColor White
        Write-Host ""
    }
    exit 0
}

# ── PERGUNTA DIRETA ──────────────────────────────────

if ($Perguntar) {
    WH "PERGUNTA"
    $files = Get-Fontes $Fontes
    W "Pergunta: $Perguntar" "Cyan"
    W "Fontes: $($files.Count)" "DarkGray"

    $sys  = "Responda com base nos documentos. Se nao estiver nos docs, use seu conhecimento geral mas avise. Responda em portugues."
    $full = if ($files.Count -gt 0) { $Perguntar } else { $Perguntar }
    $resp = Rodar $Perguntar $files $sys

    Write-Host ""
    Write-Host $resp -ForegroundColor White
    Write-Host ""
    exit 0
}

# ── GUIA DE ESTUDOS ──────────────────────────────────

if ($Estudar) {
    WH "GUIA DE ESTUDOS + FLASHCARDS"
    $files = Get-Fontes $Fontes
    W "Gerando guia de $($files.Count) fonte(s)..." "Yellow"

    $sys = "Voce e um professor especialista. Crie material de estudo didatico e bem organizado. Responda em portugues."
    $prompt = @"
Crie um GUIA DE ESTUDOS completo com:

## Conceitos Fundamentais
(lista com definicoes claras de cada conceito)

## Pontos-Chave para Memorizar
(os 10 itens mais importantes)

## Flashcards (10 cartoes)
**P:** [pergunta] | **R:** [resposta]

## Questoes de Revisao
(5 questoes dissertativas com gabarito)

## Ordem de Aprendizagem Sugerida
(sequencia ideal para estudar os topicos)
"@

    $result = Rodar $prompt $files $sys
    Write-Host ""
    Write-Host $result -ForegroundColor White
    $path = Salvar "# Guia de Estudos`n_$(Get-Date -Format 'yyyy-MM-dd HH:mm')_`n`n$result" "guia-estudos"
    SalvarObsidian $result "guia-estudos"
    WC "Guia salvo: $path"
    exit 0
}

# ── MAPA MENTAL ──────────────────────────────────────

if ($MapaMental) {
    WH "MAPA MENTAL"
    $files = Get-Fontes $Fontes
    W "Mapeando $($files.Count) fonte(s)..." "Yellow"

    $prompt = @"
Crie um MAPA MENTAL hierarquico em Markdown compativel com Obsidian.

Use a estrutura:
# [TOPICO CENTRAL]

## Ramo: [Nome]
### Sub-topico
- Detalhe importante
- Conexao com outro conceito

Cubra todos os aspectos relevantes. Responda em portugues.
"@

    $result = Rodar $prompt $files "Seja um especialista em mapas mentais. Organize o conhecimento de forma clara e visual."
    Write-Host ""
    Write-Host $result -ForegroundColor White
    $path = Salvar $result "mapa-mental"
    SalvarObsidian $result "mapa-mental"
    WC "Mapa salvo: $path"
    exit 0
}

# ── INSIGHTS ─────────────────────────────────────────

if ($Insights) {
    WH "PONTOS-CHAVE E INSIGHTS"
    $files = Get-Fontes $Fontes
    W "Extraindo insights de $($files.Count) fonte(s)..." "Yellow"

    $prompt = @"
Extraia os INSIGHTS mais valiosos dos documentos:

## Top 10 Insights
(ordenados por importancia e impacto)

## Dados e Numeros Relevantes
(estatisticas, metricas, datas)

## Citacoes Memoraveis
(frases impactantes dos documentos)

## Padroes e Tendencias
(repeticoes e conexoes entre documentos)

## Acoes Recomendadas
(o que fazer com este conhecimento)
"@

    $result = Rodar $prompt $files "Seja analitico e perspicaz. Identifique o que realmente importa. Responda em portugues."
    Write-Host ""
    Write-Host $result -ForegroundColor White
    $path = Salvar "# Insights`n_$(Get-Date -Format 'yyyy-MM-dd HH:mm')_`n`n$result" "insights"
    WC "Insights salvos: $path"
    exit 0
}

# ── PODCAST / AUDIO OVERVIEW ─────────────────────────

if ($Podcast) {
    WH "ROTEIRO DE AUDIO (Audio Overview)"
    $files = Get-Fontes $Fontes
    W "Criando podcast de $($files.Count) fonte(s)..." "Yellow"

    $prompt = @"
Crie um ROTEIRO DE PODCAST de 7-10 minutos sobre o conteudo.
Dois apresentadores brasileiros: Alex (analitico) e Maya (didatica e entusiasmada).

Formato:
[ABERTURA — 30s]
Alex: ...
Maya: ...

[DESENVOLVIMENTO — 6-8 min]
(dialogo natural cobrindo todos os pontos importantes)
(use perguntas retorias, exemplos, analogias)

[CONCLUSAO — 1 min]
Alex: (resumo dos pontos)
Maya: (call to action, o que o ouvinte deve fazer)

[ENCERRAMENTO]
Alex + Maya: ...

Faca soar natural e engajante. Responda em portugues.
"@

    $result = Rodar $prompt $files "Voce e um roteirista de podcast. Crie dialogos naturais e educativos."
    Write-Host ""
    Write-Host $result -ForegroundColor White
    $path = Salvar "# Roteiro de Audio`n_$(Get-Date -Format 'yyyy-MM-dd HH:mm')_`n`n$result" "podcast"
    WC "Roteiro salvo: $path"
    exit 0
}

# ── MENU INTERATIVO ───────────────────────────────────

WH "MENU PRINCIPAL"
W "Selecione uma funcao:" "White"
Write-Host ""
W "  1  Resumo executivo" "Yellow"
W "  2  Chat Q&A interativo" "Yellow"
W "  3  Guia de estudos + flashcards" "Yellow"
W "  4  Mapa mental" "Yellow"
W "  5  Insights e pontos-chave" "Yellow"
W "  6  Roteiro de podcast" "Yellow"
W "  7  Testar conexao Gemini" "Yellow"
W "  0  Sair" "DarkGray"
Write-Host ""

Write-Host "  opcao -> " -ForegroundColor DarkGray -NoNewline
$opcao = Read-Host " "

switch ($opcao.Trim()) {
    "1" { & $MyInvocation.MyCommand.Path -Resumo    -Fontes $Fontes }
    "2" { & $MyInvocation.MyCommand.Path -Chat      -Fontes $Fontes }
    "3" { & $MyInvocation.MyCommand.Path -Estudar   -Fontes $Fontes }
    "4" { & $MyInvocation.MyCommand.Path -MapaMental -Fontes $Fontes }
    "5" { & $MyInvocation.MyCommand.Path -Insights  -Fontes $Fontes }
    "6" { & $MyInvocation.MyCommand.Path -Podcast   -Fontes $Fontes }
    "7" { & $MyInvocation.MyCommand.Path -Testar }
    "0" { exit 0 }
    default { W "Opcao invalida. Use 1-7 ou 0 para sair." "Red" }
}