param([string]$OutputDirectory = "WebPreview", [string]$SavePath)
$ErrorActionPreference = "Stop"
if (-not (Get-Command swift -ErrorAction SilentlyContinue)) {
    throw "Swift não encontrado (recomendado 6.3.3+ no Windows). Instale conforme https://www.swift.org/install/windows/ e reabra o PowerShell."
}
$ProjectRoot = Split-Path $PSScriptRoot -Parent
# Resolve user-supplied relative paths before switching to the repository root.
$OutputDirectory = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDirectory)
if ($SavePath) { $SavePath = (Resolve-Path $SavePath).Path }
Push-Location $ProjectRoot
try {
    swift package resolve
    if ($LASTEXITCODE -ne 0) { throw "Falha ao resolver SwiftUIWeb." }
    $PreviewArguments = @("run", "DeepGemsWebPreview", "--output", $OutputDirectory)
    if ($SavePath) { $PreviewArguments += @("--save", $SavePath) }
    & swift @PreviewArguments
    if ($LASTEXITCODE -ne 0) { throw "Falha ao gerar a prévia." }
    Start-Process (Join-Path $OutputDirectory "preview.html")
} finally { Pop-Location }
