<#
.SYNOPSIS
    Design Generator — Stitch by Google (via Gemini API)
    Gera componentes React/HTML/CSS completos a partir de descricoes em portugues.

.PARAMETER Prompt     Descricao do design desejado
.PARAMETER Type       Tipo de saida: react | html | tailwind (default: react)
.PARAMETER Output     Caminho de saida (opcional)
.PARAMETER Open       Abrir o arquivo gerado apos criacao

.EXAMPLES
    .\design-generator.ps1 -Prompt "Dashboard de analytics com graficos de vendas"
    .\design-generator.ps1 -Prompt "Landing page para app de delivery" -Type html -Open
    .\design-generator.ps1 -Prompt "Formulario de login com dark mode" -Type tailwind
#>

param(
    [Parameter(Mandatory)][string]$Prompt,
    [ValidateSet("react", "html", "tailwind")][string]$Type = "react",
    [string]$Output = "",
    [switch]$Open,
    [switch]$Preview
)

$HubPath   = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$OutputDir = Join-Path $HubPath "outputs\designs"

. (Join-Path $PSScriptRoot "gemini-core.ps1")

Write-Host ""
Write-Host "  DESIGN GENERATOR (Stitch-powered)" -ForegroundColor Magenta
Write-Host "  ────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  Tipo   : $Type" -ForegroundColor Cyan
Write-Host "  Prompt : $Prompt" -ForegroundColor White
Write-Host ""
Write-Host "  [gerando] Chamando Gemini 2.0 Flash..." -ForegroundColor Yellow

$systemPromptReact = @"
Voce e um designer UI/UX senior especialista em React + TailwindCSS (estilo 2026).
Sua tarefa: gerar codigo React completo, funcional e bonito com base no prompt do usuario.

REGRAS OBRIGATORIAS:
1. Retorne APENAS o codigo — sem explicacoes, sem markdown, sem ```
2. Use React 18 com TypeScript e TailwindCSS
3. Dark mode como padrao (bg-[#0a0a0f] ou similar)
4. Use Lucide React para icones (import { Icon } from 'lucide-react')
5. Componentes funcionais com hooks
6. Mobile-first, responsivo
7. Dados mock realistas (nao deixe campos vazios)
8. O componente deve ser exportado como default
9. Inclua todos os imports necessarios

ESTILO: Moderno, clean, profissional — similar ao Vercel, Linear, ou Notion.
"@

$systemPromptHTML = @"
Voce e um designer UI/UX senior especialista em HTML/CSS moderno.
Gere uma pagina HTML completa, moderna e responsiva com base no prompt.

REGRAS:
1. Retorne APENAS o HTML — sem explicacoes, sem markdown
2. Use TailwindCSS via CDN: <script src="https://cdn.tailwindcss.com"></script>
3. Dark mode por padrao
4. Icones: Lucide via CDN ou SVG inline
5. Dados mock realistas
6. Responsivo (mobile-first)
7. Inclua meta viewport
8. Animacoes CSS quando apropriado
"@

$systemPromptTailwind = @"
Voce e um designer UI/UX senior.
Gere um componente HTML usando APENAS classes TailwindCSS (sem CSS custom).

REGRAS:
1. Retorne apenas o HTML do componente (sem <html><body>)
2. Use apenas classes Tailwind v3+
3. Dark mode (dark: prefixes)
4. Dados mock realistas
5. Mobile-first
"@

$sysPrompt = switch ($Type) {
    "react"    { $systemPromptReact }
    "html"     { $systemPromptHTML }
    "tailwind" { $systemPromptTailwind }
}

$fullPrompt = "Crie: $Prompt"

try {
    $code = Invoke-Gemini -Prompt $fullPrompt -SystemPrompt $sysPrompt -MaxTokens 8192
    
    # Remove markdown code fences if present
    $code = $code -replace '^```(tsx|jsx|typescript|html|react)?\n', ''
    $code = $code -replace '\n```$', ''
    $code = $code.Trim()

    # Determine output path
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $slug      = ($Prompt -replace '[^a-zA-Z0-9\s]', '' -replace '\s+', '-').ToLower()
    if ($slug.Length -gt 40) { $slug = $slug.Substring(0, 40) }
    
    $ext = switch ($Type) { "react" { ".tsx" }; "html" { ".html" }; "tailwind" { ".html" } }
    $filename = "design-${slug}-${timestamp}${ext}"
    
    if ($Output) {
        $outPath = $Output
    } else {
        $outPath = Join-Path $OutputDir $filename
    }

    [System.IO.File]::WriteAllText($outPath, $code, [System.Text.Encoding]::UTF8)

    Write-Host "  [ok]  Design gerado!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Arquivo : $outPath" -ForegroundColor Cyan
    Write-Host "  Tipo    : $Type" -ForegroundColor White
    Write-Host "  Linhas  : $($code.Split("`n").Count)" -ForegroundColor White
    Write-Host ""

    if ($Type -in @("html", "tailwind") -and $Open) {
        Start-Process $outPath
        Write-Host "  [ok] Abrindo no navegador..." -ForegroundColor Green
    }

    if ($Type -eq "react" -and $Open) {
        Write-Host "  Copie o arquivo para seu projeto React e importe o componente." -ForegroundColor DarkGray
        explorer.exe (Split-Path $outPath -Parent)
    }

    # Save to Obsidian design log
    $obsConfig = Get-Content (Join-Path $HubPath "scripts\obsidian\config.json") -Raw | ConvertFrom-Json
    $designNote = Join-Path $obsConfig.vaultPath "Designs\design-log-${timestamp}.md"
    $noteDir    = Split-Path $designNote -Parent
    if (-not (Test-Path $noteDir)) { New-Item -ItemType Directory -Force $noteDir | Out-Null }
    
    $noteContent = "---`ntags: [design, generated, $Type]`ndate: $(Get-Date -Format 'yyyy-MM-dd')`n---`n`n# Design: $Prompt`n`nTipo: $Type`nArquivo: $outPath`nGerado: $(Get-Date -Format 'yyyy-MM-dd HH:mm')`n`n## Preview (primeiras 20 linhas)`n`n``````$($ext.TrimStart('.'))`n$($code.Split("`n") | Select-Object -First 20 | Join-String -Separator "`n")`n```````n"
    [System.IO.File]::WriteAllText($designNote, $noteContent, [System.Text.Encoding]::UTF8)
    Write-Host "  [ok] Nota salva no Obsidian: $designNote" -ForegroundColor DarkGray

    return $outPath

} catch {
    Write-Host "  [erro] $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Message -match "invalida|403") {
        Write-Host ""
        Write-Host "  Para obter uma chave Gemini gratuita:" -ForegroundColor Yellow
        Write-Host "  1. Acesse: https://aistudio.google.com/apikey" -ForegroundColor Cyan
        Write-Host "  2. Copie a chave (comeca com AIza...)" -ForegroundColor Cyan
        Write-Host "  3. Edite: scripts\gemini\config.json" -ForegroundColor Cyan
        Write-Host "  4. Cole no campo 'geminiApiKey'" -ForegroundColor Cyan
    }
}
