<#
.SYNOPSIS
    Agente 2: Code Guardian
    Monitora arquivos de codigo e gera relatorio de qualidade automaticamente.

.DESCRIPTION
    - Monitora pastas configuradas em busca de arquivos .ts, .tsx, .js, .py modificados
    - Para cada arquivo modificado, gera checklist de qualidade
    - Detecta: funcoes grandes, console.log esquecidos, TODO/FIXME, imports nao usados
    - Salva relatorio no Obsidian
    - Alerta no terminal sobre problemas criticos

.SCHEDULE
    A cada 2 horas via Task Scheduler, ou manual: .\agents\tasks\code-guardian.ps1
    Pode tambem monitorar em tempo real: .\agents\tasks\code-guardian.ps1 -Watch
#>

param(
    [string[]]$WatchPaths = @(),
    [switch]$Watch,
    [int]$IntervalSeconds = 10
)

$HubPath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$AgentRoot = Split-Path $PSScriptRoot -Parent
$DateStr   = Get-Date -Format "yyyy-MM-dd"
$TimeStr   = Get-Date -Format "HH:mm:ss"
$LogDir    = Join-Path $AgentRoot "logs"
$StateDir  = Join-Path $AgentRoot "state"
$LogFile   = Join-Path $LogDir "code-guardian.log"
$StateFile = Join-Path $StateDir "code-guardian.json"

New-Item -ItemType Directory -Path $LogDir   -Force | Out-Null
New-Item -ItemType Directory -Path $StateDir -Force | Out-Null

function Log {
    param([string]$msg)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$ts] $msg" | Add-Content $LogFile
}

function Analyze-CodeFile {
    param([string]$filePath)

    $issues   = @()
    $warnings = @()
    $info     = @()
    $content  = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
    $lines    = $content -split "`n"
    $ext      = [System.IO.Path]::GetExtension($filePath).ToLower()
    $fileName = [System.IO.Path]::GetFileName($filePath)
    $lineCount = $lines.Count

    # ── Analises ───────────────────────────────────────

    # 1. Console.log/print esquecido
    $consoleLogs = $lines | Select-String "console\.(log|error|warn|debug)" -AllMatches
    if ($consoleLogs.Count -gt 0) {
        $lnums = ($consoleLogs | ForEach-Object { $_.LineNumber }) -join ", "
        $warnings += "[console.log] Encontrados $($consoleLogs.Count) console.log nas linhas: $lnums"
    }

    # 2. TODOs e FIXMEs
    $todos = $lines | Select-String "(TODO|FIXME|HACK|XXX|BUG)" -AllMatches
    if ($todos.Count -gt 0) {
        foreach ($t in $todos) {
            $info += "[TODO] Linha $($t.LineNumber): $($t.Line.Trim())"
        }
    }

    # 3. Arquivo muito grande
    if ($lineCount -gt 300) {
        $issues += "[TAMANHO] Arquivo com $lineCount linhas - considere dividir (SRP)"
    } elseif ($lineCount -gt 150) {
        $warnings += "[TAMANHO] Arquivo com $lineCount linhas - ficando grande"
    }

    # 4. Funcoes longas (heuristica simples)
    $functionStarts = $lines | Select-String "(function |=> \{|async \()" -AllMatches
    if ($functionStarts.Count -gt 15) {
        $warnings += "[COMPLEXIDADE] $($functionStarts.Count) funcoes/setas - arquivo muito responsavel"
    }

    # 5. any do TypeScript
    if ($ext -in @(".ts", ".tsx")) {
        $anyUsage = $lines | Select-String ": any" -AllMatches
        if ($anyUsage.Count -gt 0) {
            $lnums = ($anyUsage | ForEach-Object { $_.LineNumber }) -join ", "
            $warnings += "[TYPESCRIPT] $($anyUsage.Count) uso(s) de 'any' nas linhas: $lnums"
        }

        # @ts-ignore
        $tsIgnore = $lines | Select-String "@ts-ignore|@ts-nocheck" -AllMatches
        if ($tsIgnore.Count -gt 0) {
            $issues += "[TYPESCRIPT] $($tsIgnore.Count) @ts-ignore encontrado(s) - resolva os tipos"
        }
    }

    # 6. Secrets hardcoded (heuristica)
    $secretPatterns = @("password\s*=\s*[`"'][^`"']+[`"']", "api_key\s*=\s*[`"'][^`"']+[`"']", "secret\s*=\s*[`"'][^`"']+[`"']")
    foreach ($pattern in $secretPatterns) {
        $found = $lines | Select-String $pattern -AllMatches
        if ($found.Count -gt 0) {
            $issues += "[SEGURANCA] Possivel secret hardcoded na linha $($found[0].LineNumber)"
        }
    }

    # 7. Imports nao utilizados (heuristica basica TS/JS)
    if ($ext -in @(".ts", ".tsx", ".js", ".jsx")) {
        $importLines = $lines | Where-Object { $_ -match "^import " }
        foreach ($imp in $importLines) {
            if ($imp -match "import \{ ([^}]+) \}") {
                $imported = $Matches[1] -split "," | ForEach-Object { $_.Trim() }
                foreach ($symbol in $imported) {
                    $symbol = $symbol -replace " as .*", ""
                    $symbol = $symbol.Trim()
                    if ($symbol -ne "" -and ($content -split $symbol).Count -le 2) {
                        $info += "[IMPORT] Possivel import nao usado: '$symbol'"
                    }
                }
            }
        }
    }

    return @{
        File     = $fileName
        Path     = $filePath
        Lines    = $lineCount
        Issues   = $issues
        Warnings = $warnings
        Info     = $info
        Score    = [math]::Max(0, 10 - ($issues.Count * 3) - ($warnings.Count))
    }
}

function Format-Report {
    param([hashtable]$result)
    $sep    = [System.Environment]::NewLine
    $report = ""
    $score  = $result.Score
    $emoji  = if ($score -ge 8) { "OTIMO" } elseif ($score -ge 5) { "OK" } else { "ATENCAO" }

    $report += "## $($result.File) - Score: $score/10 [$emoji]" + $sep
    $report += "- Caminho: $($result.Path)" + $sep
    $report += "- Linhas: $($result.Lines)" + $sep + $sep

    if ($result.Issues.Count -gt 0) {
        $report += "### Criticos" + $sep
        foreach ($i in $result.Issues) { $report += "- $i" + $sep }
        $report += $sep
    }
    if ($result.Warnings.Count -gt 0) {
        $report += "### Avisos" + $sep
        foreach ($w in $result.Warnings) { $report += "- $w" + $sep }
        $report += $sep
    }
    if ($result.Info.Count -gt 0) {
        $report += "### Informacoes" + $sep
        foreach ($inf in $result.Info) { $report += "- $inf" + $sep }
        $report += $sep
    }
    if ($result.Issues.Count -eq 0 -and $result.Warnings.Count -eq 0) {
        $report += "Nenhum problema encontrado." + $sep
    }
    return $report
}

function Run-Guardian {
    param([string[]]$paths, [switch]$isWatch)

    $codeExts = @("*.ts", "*.tsx", "*.js", "*.jsx", "*.py", "*.cs")
    $allFiles = @()

    # Pegar arquivos modificados nas ultimas 2h (modo batch) ou todos (modo watch)
    $since = if ($isWatch) { (Get-Date).AddMinutes(-1) } else { (Get-Date).AddHours(-2) }

    foreach ($p in $paths) {
        if (Test-Path $p) {
            foreach ($ext in $codeExts) {
                $found = Get-ChildItem -Path $p -Filter $ext -Recurse -ErrorAction SilentlyContinue |
                    Where-Object {
                        $_.LastWriteTime -gt $since -and
                        $_.FullName -notlike "*\node_modules\*" -and
                        $_.FullName -notlike "*\dist\*" -and
                        $_.FullName -notlike "*\.git\*"
                    }
                $allFiles += $found
            }
        }
    }

    if ($allFiles.Count -eq 0) {
        Write-Host "  Nenhum arquivo de codigo modificado recentemente." -ForegroundColor DarkGray
        return
    }

    Write-Host "  Analisando $($allFiles.Count) arquivo(s)..." -ForegroundColor Cyan

    $totalIssues   = 0
    $totalWarnings = 0
    $reportContent = "# Code Guardian Report - $DateStr $TimeStr" + [System.Environment]::NewLine + [System.Environment]::NewLine

    foreach ($file in $allFiles) {
        $result = Analyze-CodeFile $file.FullName
        $totalIssues   += $result.Issues.Count
        $totalWarnings += $result.Warnings.Count
        $reportContent += Format-Report $result

        # Mostrar no terminal
        $color = if ($result.Score -ge 8) { "Green" } elseif ($result.Score -ge 5) { "Yellow" } else { "Red" }
        Write-Host "  [$($result.Score)/10] $($result.File)" -ForegroundColor $color
        foreach ($issue in $result.Issues)   { Write-Host "    CRITICO: $issue" -ForegroundColor Red }
        foreach ($warn in $result.Warnings)  { Write-Host "    AVISO:   $warn" -ForegroundColor Yellow }
    }

    # Salvar no Obsidian se houver problemas
    if ($totalIssues -gt 0 -or $totalWarnings -gt 0) {
        $syncScript = Join-Path $HubPath "scripts\obsidian\sync-to-vault.ps1"
        & $syncScript `
            -NoteTitle "Code Guardian $DateStr" `
            -NoteType "meeting" `
            -NoteContent $reportContent `
            -Tags @("code-guardian","agent/code") | Out-Null
        Write-Host "`n  Relatorio salvo no Obsidian: Code Guardian $DateStr" -ForegroundColor Cyan
    }

    $summary = @{ lastRun = "$DateStr $TimeStr"; files = $allFiles.Count; issues = $totalIssues; warnings = $totalWarnings }
    [System.IO.File]::WriteAllText($StateFile, ($summary | ConvertTo-Json), [System.Text.Encoding]::UTF8)
    Log "Guardian: $($allFiles.Count) arquivos, $totalIssues criticos, $totalWarnings avisos"
}

# ── Main ──────────────────────────────────────────────

Write-Host "`n============================================" -ForegroundColor Magenta
Write-Host "  CODE GUARDIAN AGENT" -ForegroundColor Cyan
Write-Host "  $DateStr $TimeStr" -ForegroundColor White
Write-Host "============================================`n" -ForegroundColor Magenta

# Paths padrao: projetos na Desktop e Documentos
if ($WatchPaths.Count -eq 0) {
    $WatchPaths = @(
        "$env:USERPROFILE\Desktop",
        "$env:USERPROFILE\Documents\projetos",
        "$env:USERPROFILE\Documents\projects",
        "$env:USERPROFILE\source"
    ) | Where-Object { Test-Path $_ }
}

if ($Watch) {
    Write-Host "  Modo WATCH ativo (verificando a cada ${IntervalSeconds}s)" -ForegroundColor Yellow
    Write-Host "  Monitorando: $($WatchPaths -join ', ')" -ForegroundColor DarkGray
    Write-Host "  Pressione Ctrl+C para parar.`n" -ForegroundColor DarkGray
    while ($true) {
        Run-Guardian $WatchPaths -isWatch
        Start-Sleep $IntervalSeconds
    }
} else {
    Write-Host "  Monitorando: $($WatchPaths -join ', ')" -ForegroundColor DarkGray
    Run-Guardian $WatchPaths
    Write-Host ""
}
