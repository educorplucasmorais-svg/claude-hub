# gerar-site.ps1
# Uso: .\scripts\site-builder\gerar-site.ps1 "landing page para uma startup de IA dark mode"
# Ou via hub.ps1: "gerar site landing page para startup de IA"
#
# Funciona com GitHub Copilot (gh auth token) - SEM API KEY extra.
# Usa GitHub Models API (GPT-4o).

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Descricao,

    [string]$Tipo = "landing",
    [string]$Cores = "dark",
    [string]$Modelo = "gpt-4o",
    [switch]$Abrir,
    [switch]$Deploy
)

$ErrorActionPreference = "Stop"
$HubPath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$OutputDir = Join-Path $HubPath "outputs\sites"

# ─── Garantir pasta de output ──────────────────────────────
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Write-Host ""
Write-Host "  Site Builder CLI" -ForegroundColor Cyan
Write-Host "  Powered by GitHub Copilot (GPT-4o)" -ForegroundColor DarkCyan
Write-Host "  --------------------------------" -ForegroundColor DarkGray
Write-Host "  Descricao : $Descricao" -ForegroundColor White
Write-Host "  Tipo      : $Tipo" -ForegroundColor White
Write-Host "  Cores     : $Cores" -ForegroundColor White
Write-Host "  Modelo    : $Modelo" -ForegroundColor White
Write-Host ""

# ─── Obter token do GitHub Copilot ────────────────────────
Write-Host "  [1/4] Obtendo token GitHub Copilot..." -ForegroundColor Yellow
try {
    $GhToken = (gh auth token 2>&1).Trim()
    if (-not $GhToken -or $GhToken.StartsWith("error")) {
        throw "Token invalido. Execute: gh auth login"
    }
    Write-Host "  Token OK" -ForegroundColor Green
} catch {
    Write-Host "  ERRO: $_" -ForegroundColor Red
    Write-Host "  Execute: gh auth login" -ForegroundColor Yellow
    exit 1
}

# ─── System prompt ────────────────────────────────────────
$SystemPrompt = @"
Voce e um expert em HTML/CSS/JS. Gere APENAS um documento HTML5 COMPLETO e funcional (sem explicacoes, sem markdown, sem texto extra - so o HTML).

Regras obrigatorias:
- Use Tailwind CSS via CDN: <script src="https://cdn.tailwindcss.com"></script>
- Use Alpine.js via CDN: <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
- Configure Tailwind: tailwind.config = { darkMode: 'class' }
- NAO use imagens externas - use gradientes CSS ou placeholders
- Use icones SVG inline ou emojis
- Mobile-first, responsivo
- Inclua micro-interacoes com Alpine.js
- Paleta de cores coesa e moderna
- Google Fonts (Inter via @import no <style>)
- Resultado deve parecer um site REAL e profissional
- Retorne APENAS o HTML, nada mais
"@

$UserPrompt = "Tipo de site: $Tipo`nEsquema de cores: $Cores`n$Descricao"

# ─── Chamar GitHub Models API ─────────────────────────────
Write-Host "  [2/4] Gerando site com $Modelo..." -ForegroundColor Yellow

$RequestBody = @{
    model = $Modelo
    messages = @(
        @{ role = "system"; content = $SystemPrompt }
        @{ role = "user";   content = $UserPrompt }
    )
    max_tokens = 8192
    temperature = 0.7
} | ConvertTo-Json -Depth 10 -Compress

$Headers = @{
    "Content-Type"  = "application/json"
    "Authorization" = "Bearer $GhToken"
}

try {
    $Response = Invoke-RestMethod `
        -Uri "https://models.inference.ai.azure.com/chat/completions" `
        -Method POST `
        -Headers $Headers `
        -Body $RequestBody `
        -TimeoutSec 90

    $HtmlContent = $Response.choices[0].message.content

    # Strip markdown code block if present
    if ($HtmlContent -match '(?s)```html\s*(.*?)```') {
        $HtmlContent = $Matches[1].Trim()
    }

    Write-Host "  Gerado! ($($HtmlContent.Length) chars via $($Response.model))" -ForegroundColor Green

} catch {
    $StatusCode = $_.Exception.Response.StatusCode.value__
    if ($StatusCode -eq 429 -and $Modelo -ne "gpt-4o-mini") {
        Write-Host "  Rate limit em $Modelo, tentando gpt-4o-mini..." -ForegroundColor Yellow
        # Retry with smaller model
        $RequestBody = $RequestBody -replace '"model":"gpt-4o"', '"model":"gpt-4o-mini"'
        $Response = Invoke-RestMethod `
            -Uri "https://models.inference.ai.azure.com/chat/completions" `
            -Method POST `
            -Headers $Headers `
            -Body $RequestBody `
            -TimeoutSec 90
        $HtmlContent = $Response.choices[0].message.content
        if ($HtmlContent -match '(?s)```html\s*(.*?)```') { $HtmlContent = $Matches[1].Trim() }
        Write-Host "  Gerado com fallback gpt-4o-mini!" -ForegroundColor Green
    } else {
        Write-Host "  ERRO na geracao: $_" -ForegroundColor Red
        exit 1
    }
}

# ─── Salvar arquivo ───────────────────────────────────────
Write-Host "  [3/4] Salvando arquivo..." -ForegroundColor Yellow

$Slug = ($Descricao -replace '[^a-zA-Z0-9\s]', '' -replace '\s+', '-').ToLower()
if ($Slug.Length -gt 40) { $Slug = $Slug.Substring(0, 40) }
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
$FileName = "$Timestamp-$Slug.html"
$FilePath = Join-Path $OutputDir $FileName

$HtmlContent | Out-File -FilePath $FilePath -Encoding UTF8
Write-Host "  Salvo em: $FilePath" -ForegroundColor Green

# Salvar no backend history se servidor estiver rodando
try {
    $HistBody = @{
        prompt   = $Descricao
        siteType = $Tipo
        html     = $HtmlContent
    } | ConvertTo-Json -Depth 3 -Compress

    Invoke-RestMethod `
        -Uri "http://localhost:3001/api/history" `
        -Method POST `
        -ContentType "application/json" `
        -Body $HistBody `
        -TimeoutSec 3 | Out-Null
    Write-Host "  Salvo no historico do servidor" -ForegroundColor DarkGreen
} catch {
    # Servidor nao esta rodando - tudo bem
}

# ─── Abrir no browser ─────────────────────────────────────
Write-Host "  [4/4] Concluido!" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Arquivo: $FilePath" -ForegroundColor White

if ($Abrir -or (-not $Deploy)) {
    Write-Host "  Abrindo no browser..." -ForegroundColor Cyan
    Start-Process $FilePath
}

# ─── Deploy no Vercel (opcional) ──────────────────────────
if ($Deploy) {
    Write-Host "  Fazendo deploy no Vercel..." -ForegroundColor Cyan
    $TempDir = Join-Path $env:TEMP "site-deploy-$(Get-Random)"
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    Copy-Item $FilePath (Join-Path $TempDir "index.html")

    Push-Location $TempDir
    try {
        npx vercel deploy --prod --yes 2>&1 | Select-Object -Last 3
    } finally {
        Pop-Location
        Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "  Site gerado com sucesso!" -ForegroundColor Green
Write-Host "  Uso no hub: gerar site [descricao]" -ForegroundColor DarkGray
Write-Host ""
