<#
.SYNOPSIS
    Sincroniza notas Claude Hub com Obsidian Vault
.DESCRIPTION
    Cria notas formatadas com frontmatter YAML no vault Obsidian.
.EXAMPLE
    .\sync-to-vault.ps1 -NoteTitle "React Hooks" -NoteType "concept"
    .\sync-to-vault.ps1 -SyncAll
    .\sync-to-vault.ps1 -ListNotes
#>

param(
    [string]$NoteTitle   = "",
    [string]$NoteContent = "",
    [ValidateSet("concept","project","meeting","snippet","learning")]
    [string]$NoteType    = "concept",
    [string[]]$Tags      = @(),
    [switch]$SyncAll,
    [switch]$ListNotes,
    [switch]$OpenVault
)

$ConfigPath = Join-Path $PSScriptRoot "config.json"

if (-not (Test-Path $ConfigPath)) {
    Write-Error "config.json nao encontrado em $ConfigPath"
    exit 1
}

$Config    = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$VaultPath = $Config.vaultPath
$InboxPath = Join-Path $VaultPath $Config.inboxFolder
$DateStr   = Get-Date -Format "yyyy-MM-dd"

function Write-Status {
    param([string]$msg, [string]$color = "Cyan")
    Write-Host "  $msg" -ForegroundColor $color
}

function Ensure-Dir {
    param([string]$path)
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

function Sanitize-FileName {
    param([string]$name)
    $invalid = [System.IO.Path]::GetInvalidFileNameChars()
    $s = $name
    foreach ($c in $invalid) { $s = $s.Replace($c, '-') }
    return $s.Trim('-').Trim()
}

function Build-Frontmatter {
    param([string]$title, [string]$type, [string[]]$tags)
    $allTags = @("type/$type") + $tags + @("source/claude-hub")
    $tagLines = ($allTags | ForEach-Object { "  - $_" }) -join [System.Environment]::NewLine
    $sep = [System.Environment]::NewLine
    return ("---" + $sep +
            "title: " + '"' + $title + '"' + $sep +
            "created: $DateStr" + $sep +
            "modified: $DateStr" + $sep +
            "type: $type" + $sep +
            "tags:" + $sep +
            $tagLines + $sep +
            "status: raw" + $sep +
            "source: claude-hub" + $sep +
            "---" + $sep + $sep)
}

function Create-Note {
    param(
        [string]$Title,
        [string]$Content,
        [string]$Type,
        [string[]]$ExtraTags
    )

    $TargetInbox = $null
    if (-not (Test-Path $VaultPath)) {
        Write-Status "Vault nao encontrado em: $VaultPath" "Yellow"
        Write-Status "Configure o caminho em: scripts/obsidian/config.json" "Yellow"
        $FallbackPath = Join-Path $PSScriptRoot "local-vault\Inbox"
        Ensure-Dir $FallbackPath
        Write-Status "Salvando localmente em: $FallbackPath" "Yellow"
        $TargetInbox = $FallbackPath
    } else {
        Ensure-Dir $InboxPath
        $TargetInbox = $InboxPath
    }

    $SafeTitle   = Sanitize-FileName $Title
    $FileName    = "$DateStr - $SafeTitle.md"
    $FilePath    = Join-Path $TargetInbox $FileName
    $Frontmatter = Build-Frontmatter $Title $Type $ExtraTags
    $FullContent = $Frontmatter + "# $Title" + [System.Environment]::NewLine + [System.Environment]::NewLine + $Content

    if (Test-Path $FilePath) {
        $BackupPath = $FilePath + ".bak"
        Copy-Item $FilePath $BackupPath
        Write-Status "Backup: $BackupPath" "DarkGray"
    }

    [System.IO.File]::WriteAllText($FilePath, $FullContent, [System.Text.Encoding]::UTF8)
    Write-Status "Nota criada: $FileName" "Green"
    Write-Status "Local: $FilePath" "DarkGray"
    return $FilePath
}

function Sync-AllDocs {
    $DocsPath = Join-Path $Config.claudeHubPath "docs"
    if (-not (Test-Path $DocsPath)) {
        Write-Status "Pasta docs/ nao encontrada." "Yellow"
        return
    }
    $mdFiles = Get-ChildItem -Path $DocsPath -Filter "*.md" -Recurse
    if ($mdFiles.Count -eq 0) {
        Write-Status "Nenhum .md encontrado em docs/" "Yellow"
        return
    }
    Write-Status "Sincronizando $($mdFiles.Count) arquivo(s)..." "Cyan"
    foreach ($file in $mdFiles) {
        $title   = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
        Create-Note -Title $title -Content $content -Type "concept" -ExtraTags @("sync/docs")
    }
    Write-Status "Sincronizacao completa!" "Green"
}

function List-VaultNotes {
    $SearchPath = if (Test-Path $VaultPath) { $VaultPath } else { Join-Path $PSScriptRoot "local-vault" }
    if (-not (Test-Path $SearchPath)) {
        Write-Status "Vault vazio ou nao configurado." "Yellow"
        return
    }
    $notes = Get-ChildItem -Path $SearchPath -Filter "*.md" -Recurse | Sort-Object LastWriteTime -Descending
    Write-Host "`nNotas no Vault ($($notes.Count) total):`n" -ForegroundColor Cyan
    foreach ($note in $notes | Select-Object -First 20) {
        $relPath = $note.FullName.Replace($SearchPath, "").TrimStart('\')
        Write-Host "  [NOTE] $relPath" -ForegroundColor White
        Write-Host "         $(Get-Date $note.LastWriteTime -Format 'dd/MM/yyyy HH:mm')" -ForegroundColor DarkGray
    }
    if ($notes.Count -gt 20) {
        Write-Host "`n  ... e mais $($notes.Count - 20) notas" -ForegroundColor DarkGray
    }
}

# ---- Main ----

Write-Host "`n[Obsidian Sync] Claude Hub" -ForegroundColor Magenta
Write-Host "----------------------------" -ForegroundColor DarkGray

if ($OpenVault) {
    if (Test-Path $VaultPath) {
        $vaultName = Split-Path $VaultPath -Leaf
        Start-Process "obsidian" -ArgumentList "obsidian://open?vault=$vaultName"
        Write-Status "Abrindo vault no Obsidian..." "Green"
    } else {
        Write-Status "Vault nao encontrado: $VaultPath" "Red"
    }
    exit 0
}

if ($ListNotes) { List-VaultNotes; exit 0 }
if ($SyncAll)   { Sync-AllDocs;   exit 0 }

if ($NoteTitle -ne "") {
    Create-Note -Title $NoteTitle -Content $NoteContent -Type $NoteType -ExtraTags $Tags
    exit 0
}

Write-Host "`nUso:" -ForegroundColor Yellow
Write-Host "  -NoteTitle 'Titulo'  -NoteType concept|project|meeting|snippet|learning" -ForegroundColor White
Write-Host "  -SyncAll             (sync docs/ para vault)" -ForegroundColor White
Write-Host "  -ListNotes           (listar notas)" -ForegroundColor White
Write-Host "  -OpenVault           (abrir no Obsidian)" -ForegroundColor White
Write-Host ""
Write-Host "Exemplo:" -ForegroundColor DarkGray
Write-Host "  .\sync-to-vault.ps1 -NoteTitle 'Como usar Prisma' -NoteType snippet" -ForegroundColor DarkGray
