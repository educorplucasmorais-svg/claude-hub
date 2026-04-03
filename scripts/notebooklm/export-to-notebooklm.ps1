<#
.SYNOPSIS
    Exporta conteudo Claude Hub para formatos compativeis com NotebookLM
.DESCRIPTION
    NotebookLM aceita: txt, md, PDF, URLs.
    Este script exporta conversas e notas em formato otimizado.
.EXAMPLE
    .\export-to-notebooklm.ps1 -InputPath ".\docs\artigo.md"
    .\export-to-notebooklm.ps1 -Bundle
    .\export-to-notebooklm.ps1 -Bundle -OpenOutputFolder
#>

param(
    [string]$InputPath  = "",
    [ValidateSet("txt","md")]
    [string]$OutputFormat = "txt",
    [string]$Title      = "",
    [switch]$Bundle,
    [switch]$OpenOutputFolder
)

$OutputDir  = Join-Path $PSScriptRoot "exports"
$DateStr    = Get-Date -Format "yyyy-MM-dd"
$ConfigPath = Join-Path $PSScriptRoot "config.json"

$Config = if (Test-Path $ConfigPath) {
    Get-Content $ConfigPath -Raw | ConvertFrom-Json
} else {
    [PSCustomObject]@{ claudeHubPath = "C:\Users\Pichau\Desktop\Claude Full" }
}

function Write-Status {
    param([string]$msg, [string]$color = "Cyan")
    Write-Host "  $msg" -ForegroundColor $color
}

function Strip-FrontMatter {
    param([string]$content)
    if ($content -match "(?s)^---\r?\n.*?\r?\n---\r?\n") {
        return ($content -replace "(?s)^---\r?\n.*?\r?\n---\r?\n", "").TrimStart()
    }
    return $content
}

function Format-ForNotebookLM {
    param([string]$content, [string]$sourceTitle)
    $stripped = Strip-FrontMatter $content
    $sep = [System.Environment]::NewLine
    return ("# Fonte: $sourceTitle" + $sep +
            "# Exportado em: $(Get-Date -Format 'dd/MM/yyyy HH:mm')" + $sep +
            "# Origem: Claude Hub" + $sep +
            "# --------------------------------------------------" + $sep +
            $sep + $stripped)
}

function Export-SingleFile {
    param([string]$filePath, [string]$outputName = "")
    if (-not (Test-Path $filePath)) {
        Write-Status "Arquivo nao encontrado: $filePath" "Red"
        return $null
    }
    $content  = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
    $baseName = if ($outputName) { $outputName } else { [System.IO.Path]::GetFileNameWithoutExtension($filePath) }
    $docTitle = if ($Title) { $Title } else { $baseName }
    $formatted   = Format-ForNotebookLM $content $docTitle
    $outputFile  = Join-Path $OutputDir ($DateStr + " - " + $baseName + "." + $OutputFormat)
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    [System.IO.File]::WriteAllText($outputFile, $formatted, [System.Text.Encoding]::UTF8)
    return $outputFile
}

function Export-Bundle {
    param([string]$folderPath)
    $mdFiles = Get-ChildItem -Path $folderPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
    if (-not $mdFiles -or $mdFiles.Count -eq 0) {
        Write-Status "Nenhum .md encontrado em: $folderPath" "Yellow"
        return $null
    }
    $bundleTitle   = if ($Title) { $Title } else { "Claude Hub Bundle " + (Get-Date -Format "yyyy-MM-dd") }
    $sep           = [System.Environment]::NewLine
    $bundleContent = ("# " + $bundleTitle + $sep +
                     "Exportado em: " + (Get-Date -Format "dd/MM/yyyy HH:mm") + $sep +
                     "Total de arquivos: " + $mdFiles.Count + $sep +
                     $sep + "==================================================" + $sep + $sep)
    foreach ($file in $mdFiles) {
        $fileContent = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
        $stripped    = Strip-FrontMatter $fileContent
        $sectionName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $bundleContent += "## " + $sectionName + $sep + $sep + $stripped + $sep + $sep
        $bundleContent += "==================================================" + $sep + $sep
    }
    $outputFile = Join-Path $OutputDir ($DateStr + " - " + $bundleTitle + "." + $OutputFormat)
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    [System.IO.File]::WriteAllText($outputFile, $bundleContent, [System.Text.Encoding]::UTF8)
    Write-Status "Bundle criado: $outputFile" "Green"
    Write-Status "$($mdFiles.Count) arquivos bundled" "DarkGray"
    return $outputFile
}

# ---- Main ----

Write-Host "`n[NotebookLM Export] Claude Hub" -ForegroundColor Blue
Write-Host "---------------------------------" -ForegroundColor DarkGray

if ($InputPath -eq "") {
    $InputPath = Join-Path $Config.claudeHubPath "docs"
    Write-Status "Usando pasta padrao: $InputPath" "Yellow"
    $Bundle = $true
}

if ($Bundle) {
    $result = Export-Bundle $InputPath
} elseif (Test-Path $InputPath -PathType Container) {
    $files = Get-ChildItem -Path $InputPath -Filter "*.md"
    foreach ($f in $files) {
        $out = Export-SingleFile $f.FullName
        if ($out) { Write-Status "Exportado: $out" "Green" }
    }
} else {
    $result = Export-SingleFile $InputPath
    if ($result) { Write-Status "Exportado: $result" "Green" }
}

Write-Host ""
Write-Status "Como usar no NotebookLM:" "Magenta"
Write-Status "  1. Acesse: https://notebooklm.google.com" "White"
Write-Status "  2. Crie ou abra um Notebook" "White"
Write-Status "  3. Clique em Add source > Upload file" "White"
Write-Status "  4. Carregue o arquivo de: $OutputDir" "White"
Write-Host ""

if ($OpenOutputFolder -and (Test-Path $OutputDir)) {
    Start-Process "explorer.exe" $OutputDir
}
