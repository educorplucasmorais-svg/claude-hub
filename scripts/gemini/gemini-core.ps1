<#
.SYNOPSIS
    Gemini API Core — com retry automatico e rate limit handling
#>

$GeminiConfigPath = Join-Path $PSScriptRoot "config.json"

function Get-GeminiConfig {
    if (-not (Test-Path $GeminiConfigPath)) { throw "Config nao encontrado: $GeminiConfigPath" }
    return Get-Content $GeminiConfigPath -Raw | ConvertFrom-Json
}

function Get-GeminiKey {
    $cfg = Get-GeminiConfig
    if ($env:GEMINI_API_KEY) { return $env:GEMINI_API_KEY }
    if ($cfg.geminiApiKey -and $cfg.geminiApiKey -notmatch "COLE_SUA|^$") { return $cfg.geminiApiKey }
    if ($cfg.stitchApiKey -and $cfg.stitchApiKey -notmatch "^$") { return $cfg.stitchApiKey }
    throw "Chave Gemini nao encontrada. Configure em scripts\gemini\config.json"
}

function Invoke-Gemini {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [string]$Model        = "",
        [string]$SystemPrompt = "",
        [switch]$Json,
        [int]$MaxTokens       = 8192,
        [int]$MaxRetries      = 3
    )

    $cfg   = Get-GeminiConfig
    $key   = Get-GeminiKey
    $model = if ($Model) { $Model } else { $cfg.geminiModel }

    # Fallback models in order
    $models = @($model, "gemini-2.0-flash", "gemini-2.0-flash-lite", "gemini-1.5-flash")
    $models = $models | Select-Object -Unique

    $parts   = @(@{ text = $Prompt })
    $contents= @(@{ role = "user"; parts = $parts })
    $body    = @{
        contents         = $contents
        generationConfig = @{ maxOutputTokens = $MaxTokens; temperature = 0.7 }
    }
    if ($SystemPrompt) { $body.systemInstruction = @{ parts = @(@{ text = $SystemPrompt }) } }
    if ($Json)         { $body.generationConfig.responseMimeType = "application/json" }

    $bodyJson = $body | ConvertTo-Json -Depth 10 -Compress

    foreach ($m in $models) {
        $url = "https://generativelanguage.googleapis.com/v1beta/models/${m}:generateContent?key=$key"
        for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
            try {
                $response = Invoke-RestMethod -Uri $url -Method POST -ContentType "application/json" -Body $bodyJson
                return $response.candidates[0].content.parts[0].text
            } catch {
                $status = $_.Exception.Response.StatusCode.value__
                if ($status -eq 429) {
                    $wait = $attempt * 10
                    Write-Host "  [rate limit] Aguardando ${wait}s (tentativa $attempt/$MaxRetries)..." -ForegroundColor Yellow
                    Start-Sleep -Seconds $wait
                } elseif ($status -eq 404) {
                    break  # Model not found, try next
                } elseif ($status -eq 403) {
                    throw "Chave API invalida (403). Obtenha uma chave em: https://aistudio.google.com/apikey"
                } else {
                    if ($attempt -eq $MaxRetries) { throw "Erro $status apos $MaxRetries tentativas: $($_.Exception.Message)" }
                    Start-Sleep -Seconds 3
                }
            }
        }
    }
    throw "Todos os modelos falharam. Verifique sua chave ou aguarde o reset do rate limit (1 min)."
}

function Invoke-GeminiWithFiles {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [string[]]$FilePaths = @(),
        [string]$SystemPrompt = "",
        [string]$Model = ""
    )

    $parts = @()
    foreach ($file in $FilePaths) {
        if (-not (Test-Path $file)) { continue }
        $ext = [System.IO.Path]::GetExtension($file).ToLower()
        if ($ext -in @(".md",".txt",".html",".pdf",".js",".ts",".tsx",".jsx",".py",".json")) {
            $content = Get-Content $file -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if ($content) {
                $name = Split-Path $file -Leaf
                $parts += @{ text = "=== $name ===`n$content" }
            }
        }
    }
    $parts += @{ text = $Prompt }

    $bodyParts = @{ parts = $parts }
    $contents  = @(@{ role = "user"; parts = $parts })

    $cfg   = Get-GeminiConfig
    $key   = Get-GeminiKey
    $model = if ($Model) { $Model } else { $cfg.geminiModel }
    $models = @($model, "gemini-2.0-flash", "gemini-1.5-flash") | Select-Object -Unique

    $body = @{
        contents         = $contents
        generationConfig = @{ maxOutputTokens = 8192; temperature = 0.5 }
    }
    if ($SystemPrompt) { $body.systemInstruction = @{ parts = @(@{ text = $SystemPrompt }) } }

    $bodyJson = $body | ConvertTo-Json -Depth 10 -Compress

    foreach ($m in $models) {
        $url = "https://generativelanguage.googleapis.com/v1beta/models/${m}:generateContent?key=$key"
        for ($attempt = 1; $attempt -le 3; $attempt++) {
            try {
                $response = Invoke-RestMethod -Uri $url -Method POST -ContentType "application/json" -Body $bodyJson
                return $response.candidates[0].content.parts[0].text
            } catch {
                $status = $_.Exception.Response.StatusCode.value__
                if ($status -eq 429) { $w = $attempt * 15; Write-Host "  [rate limit] Aguardando ${w}s..." -ForegroundColor Yellow; Start-Sleep -Seconds $w }
                elseif ($status -eq 404) { break }
                else { if ($attempt -eq 3) { throw "Erro $status" }; Start-Sleep -Seconds 5 }
            }
        }
    }
    throw "Falha em todos os modelos."
}

function Test-GeminiKey {
    try {
        $r = Invoke-Gemini -Prompt "Responda apenas: OK" -MaxTokens 5
        return @{ Valid = $true; Response = $r.Trim() }
    } catch {
        return @{ Valid = $false; Error = $_.Exception.Message }
    }
}