<#
.SYNOPSIS
    NotebookLM Agent — Powered by Gemini 2.0 Flash
    Replica as funcoes principais do NotebookLM usando a API Gemini.

.COMMANDS
    -Summary   [files]   Gerar resumo executivo dos documentos
    -QA        [files]   Modo perguntas e respostas interativo
    -StudyGuide[files]   Gerar guia de estudos com conceitos e flashcards
    -Mindmap   [files]   Gerar mapa mental em Markdown
    -KeyPoints [files]   Extrair pontos-chave e insights
    -AudioScript[files]  Gerar roteiro de podcast/audio overview
    -Ask       [question][files]  Fazer uma pergunta especifica

.EXAMPLES
    .\notebooklm-agent.ps1 -Summary -Sources "doc1.pdf","doc2.txt"
    .\notebooklm-agent.ps1 -QA -Sources "relatorio.pdf"
    .\notebooklm-agent.ps1 -StudyGuide -Sources "aula1.md","aula2.md"
    .\notebooklm-agent.ps1 -Ask "Quais sao as principais conclusoes?" -Sources "paper.pdf"
    .\notebooklm-agent.ps1 -AudioScript -Sources "docs/"
#>

param(
    [switch]$Summary,
    [switch]$QA,
    [switch]$StudyGuide,
    [switch]$Mindmap,
    [switch]$KeyPoints,
    [switch]$AudioScript,
    [string]$Ask         = "",
    [string[]]$Sources   = @(),
    [string]$OutputPath  = ""
)

$HubPath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

. (Join-Path $PSScriptRoot "gemini-core.ps1")

$cfg       = Get-GeminiConfig
$OutDir    = $cfg.notebooklmOutputDir
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

function Write-NLM { param([string]$m, [string]$c = "White"); Write-Host "  $m" -ForegroundColor $c }
function Write-NLMHeader { param([string]$t); Write-Host ""; Write-Host "  NOTEBOOKLM  >>  $t" -ForegroundColor Magenta; Write-Host "  ────────────────────────────────" -ForegroundColor DarkGray }

function Resolve-Sources {
    param([string[]]$s)
    $files = @()
    foreach ($src in $s) {
        if (Test-Path $src -PathType Container) {
            $files += Get-ChildItem $src -Include "*.md","*.txt","*.pdf","*.html" -Recurse | Select-Object -ExpandProperty FullName
        } elseif (Test-Path $src) {
            $files += $src
        } else {
            Write-NLM "Fonte nao encontrada: $src" "Yellow"
        }
    }
    
    # Se nenhuma fonte, usar vault Obsidian
    if ($files.Count -eq 0) {
        $obsConf  = Get-Content (Join-Path $HubPath "scripts\obsidian\config.json") -Raw | ConvertFrom-Json
        $files    = @(Get-ChildItem $obsConf.vaultPath -Include "*.md" -Recurse | Select-Object -ExpandProperty FullName | Select-Object -First 10)
        Write-NLM "Usando vault Kaia: $($files.Count) notas" "DarkGray"
    }
    return $files
}

function Save-Output {
    param([string]$content, [string]$label)
    $out = if ($OutputPath) { $OutputPath } else { Join-Path $OutDir "${label}-${Timestamp}.md" }
    [System.IO.File]::WriteAllText($out, $content, [System.Text.Encoding]::UTF8)
    Write-NLM "[salvo] $out" "DarkGray"
    return $out
}

# ── RESUMO ───────────────────────────────────────────

if ($Summary) {
    Write-NLMHeader "RESUMO EXECUTIVO"
    $files = Resolve-Sources $Sources
    Write-NLM "Processando $($files.Count) fonte(s)..." "Yellow"

    $prompt = @"
Analise os documentos fornecidos e gere um RESUMO EXECUTIVO completo.

Estruture assim:
## Resumo em Uma Frase
(1 frase que capture a essencia)

## Visao Geral
(2-3 paragrafos descrevendo o conteudo principal)

## Topicos Principais
(lista dos temas abordados com breve descricao de cada)

## Insights Importantes
(descobertas, dados, conclusoes relevantes)

## Proximos Passos Sugeridos
(acoes praticas baseadas no conteudo)

Seja conciso e use linguagem clara. Responda em portugues.
"@

    $result = Invoke-GeminiWithFiles -Prompt $prompt -FilePaths $files
    Write-Host ""
    Write-Host $result -ForegroundColor White
    Save-Output "# Resumo Executivo`n_Gerado em $(Get-Date -Format 'yyyy-MM-dd HH:mm')_`n_Fontes: $($files.Count) documentos_`n`n$result" "summary"
}

# ── Q&A INTERATIVO ───────────────────────────────────

if ($QA) {
    Write-NLMHeader "MODO PERGUNTAS E RESPOSTAS"
    $files = Resolve-Sources $Sources
    Write-NLM "Carregando $($files.Count) fonte(s)..." "Yellow"
    
    # Pre-load context
    $contextParts = @()
    foreach ($f in $files) {
        $content = Get-Content $f -Raw -ErrorAction SilentlyContinue
        if ($content) { $contextParts += "=== $([System.IO.Path]::GetFileName($f)) ===`n$content" }
    }
    $context = $contextParts -join "`n`n"
    
    Write-NLM "Pronto! Digite suas perguntas (ou 'sair' para fechar)" "Green"
    Write-Host ""

    $sysPrompt = "Voce e um assistente especializado nos documentos fornecidos. Responda APENAS com base no conteudo dos documentos. Se a resposta nao estiver nos documentos, diga isso claramente. Seja preciso e cite trechos relevantes quando possivel. Responda em portugues."

    while ($true) {
        Write-Host "  pergunta -> " -ForegroundColor Cyan -NoNewline
        $question = Read-Host " "
        if ($question -match "^(sair|exit|quit)$") { break }
        if ([string]::IsNullOrWhiteSpace($question)) { continue }
        
        Write-Host ""
        Write-Host "  [processando...]" -ForegroundColor DarkGray
        
        $fullPrompt = "DOCUMENTOS:`n$context`n`nPERGUNTA: $question"
        $answer     = Invoke-Gemini -Prompt $fullPrompt -SystemPrompt $sysPrompt
        Write-Host ""
        Write-Host "  claude -> " -ForegroundColor Magenta -NoNewline
        Write-Host $answer -ForegroundColor White
        Write-Host ""
    }
}

# ── GUIA DE ESTUDOS ──────────────────────────────────

if ($StudyGuide) {
    Write-NLMHeader "GUIA DE ESTUDOS"
    $files = Resolve-Sources $Sources
    Write-NLM "Gerando guia de $($files.Count) fonte(s)..." "Yellow"

    $prompt = @"
Crie um GUIA DE ESTUDOS completo e estruturado com base nos documentos.

Inclua:
## Conceitos Fundamentais
(lista de conceitos com definicoes claras)

## Pontos-Chave para Memorizar
(os itens mais importantes)

## Flashcards (10 perguntas e respostas)
Formato: **P:** pergunta | **R:** resposta

## Questoes de Revisao
(5 questoes dissertativas para testar compreensao)

## Mapa de Dependencias
(quais conceitos dependem de outros)

## Recursos Complementares Sugeridos
(topicos para aprofundamento)

Responda em portugues. Seja didatico e organizado.
"@

    $result = Invoke-GeminiWithFiles -Prompt $prompt -FilePaths $files
    Write-Host ""
    Write-Host $result -ForegroundColor White
    $path = Save-Output "# Guia de Estudos`n_Gerado em $(Get-Date -Format 'yyyy-MM-dd HH:mm')_`n`n$result" "study-guide"
    Write-NLM "Guia salvo: $path" "Green"
}

# ── MAPA MENTAL ──────────────────────────────────────

if ($Mindmap) {
    Write-NLMHeader "MAPA MENTAL"
    $files = Resolve-Sources $Sources
    Write-NLM "Mapeando $($files.Count) fonte(s)..." "Yellow"

    $prompt = @"
Crie um MAPA MENTAL em formato Markdown (compativel com Obsidian) dos documentos.

Use esta estrutura hierarquica:
# [TOPICO CENTRAL]

## Ramo 1: [Nome]
### Sub-item 1.1
- Detalhe
- Detalhe

### Sub-item 1.2
...

## Ramo 2: [Nome]
...

Seja completo mas conciso. Capture todas as relacoes importantes. Responda em portugues.
"@

    $result = Invoke-GeminiWithFiles -Prompt $prompt -FilePaths $files
    Write-Host ""
    Write-Host $result -ForegroundColor White
    $path = Save-Output $result "mindmap"
    
    # Also save to Obsidian
    $obsConf    = Get-Content (Join-Path $HubPath "scripts\obsidian\config.json") -Raw | ConvertFrom-Json
    $obsOutPath = Join-Path $obsConf.vaultPath "Maps\mindmap-${Timestamp}.md"
    New-Item -ItemType Directory -Force (Split-Path $obsOutPath -Parent) | Out-Null
    [System.IO.File]::WriteAllText($obsOutPath, $result, [System.Text.Encoding]::UTF8)
    Write-NLM "Mapa salvo no Obsidian: $obsOutPath" "Green"
}

# ── PONTOS-CHAVE ─────────────────────────────────────

if ($KeyPoints) {
    Write-NLMHeader "PONTOS-CHAVE E INSIGHTS"
    $files = Resolve-Sources $Sources
    Write-NLM "Extraindo insights de $($files.Count) fonte(s)..." "Yellow"

    $prompt = @"
Extraia os PONTOS-CHAVE e INSIGHTS mais importantes dos documentos.

Formato:
## Top 10 Insights
(os 10 insights mais valiosos, ordenados por importancia)

## Dados e Numeros Relevantes
(estatisticas, metricas, datas importantes)

## Citacoes Memoraveis
(frases importantes dos documentos)

## Padroes e Tendencias
(padroes observados entre os documentos)

## O Que Fazer Com Isso
(acoes praticas baseadas nos insights)

Responda em portugues. Seja direto e objetivo.
"@

    $result = Invoke-GeminiWithFiles -Prompt $prompt -FilePaths $files
    Write-Host ""
    Write-Host $result -ForegroundColor White
    Save-Output "# Pontos-Chave`n_Gerado em $(Get-Date -Format 'yyyy-MM-dd HH:mm')_`n`n$result" "keypoints"
}

# ── AUDIO SCRIPT ─────────────────────────────────────

if ($AudioScript) {
    Write-NLMHeader "ROTEIRO DE AUDIO (Audio Overview)"
    $files = Resolve-Sources $Sources
    Write-NLM "Criando roteiro de $($files.Count) fonte(s)..." "Yellow"

    $prompt = @"
Crie um ROTEIRO DE PODCAST de 5-10 minutos sobre o conteudo dos documentos.
Estilo: dois apresentadores conversando de forma natural (Host A e Host B).

Estrutura:
## Introducao (30s)
[MUSICA DE ABERTURA]
Host A: ...
Host B: ...

## Desenvolvimento (4-8 min)
(dialogo natural cobrindo os principais pontos)

## Conclusao (30s)
(resumo e chamada para acao)

Faca o dialogo soar natural, use perguntas retorias, anedotas.
Responda em portugues.
"@

    $result = Invoke-GeminiWithFiles -Prompt $prompt -FilePaths $files
    Write-Host ""
    Write-Host $result -ForegroundColor White
    Save-Output "# Roteiro de Audio`n_Gerado em $(Get-Date -Format 'yyyy-MM-dd HH:mm')_`n`n$result" "audio-script"
}

# ── PERGUNTA DIRETA ──────────────────────────────────

if ($Ask) {
    Write-NLMHeader "PERGUNTA DIRETA"
    $files = Resolve-Sources $Sources
    Write-NLM "Pergunta: $Ask" "Cyan"
    Write-NLM "Processando $($files.Count) fonte(s)..." "Yellow"

    $prompt  = "Responda em portugues, de forma clara e detalhada: $Ask"
    $result  = Invoke-GeminiWithFiles -Prompt $prompt -FilePaths $files
    Write-Host ""
    Write-Host $result -ForegroundColor White
    Write-Host ""
}
