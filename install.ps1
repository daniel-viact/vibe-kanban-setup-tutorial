#Requires -Version 5.1
<#
.SYNOPSIS
    Vibe Kanban - 1-Click Installer (Windows)
.DESCRIPTION
    Installs and manages Vibe Kanban using Docker.
    Copyright (c) Daniel Le, Viact Team
.PARAMETER Action
    The action to perform: install (default), uninstall, stop, restart, help
.EXAMPLE
    .\install.ps1
    .\install.ps1 -Action stop
    .\install.ps1 -Action uninstall
#>

param(
    [ValidateSet("install", "uninstall", "stop", "restart", "help")]
    [string]$Action = "install"
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Override action from environment (for irm | iex usage)
# ---------------------------------------------------------------------------
if ($env:VK_ACTION) {
    $Action = $env:VK_ACTION
    Remove-Item Env:\VK_ACTION -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
$script:Version = "1.0.0"
$script:InstallDir = Join-Path $env:USERPROFILE ".vibe-kanban"
$script:ContainerName = "viact-vibe-kanban-desktop"
$script:ImageName = "thanhlcm90/vibe-kanban:0.1.24"

# ---------------------------------------------------------------------------
# UI Helpers
# ---------------------------------------------------------------------------
function Write-Banner {
    $lines = @(
        ""
        "  ========================================================"
        "  |                                                      |"
        "  |   __     _____ ____  _____                           |"
        "  |   \ \   / /_ _| __ )| ____|                          |"
        "  |    \ \ / / | ||  _ \|  _|                            |"
        "  |     \ V /  | || |_) | |___                           |"
        "  |      \_/  |___|____/|_____|                          |"
        "  |                                                      |"
        "  |   _  __    _    _   _ ____    _    _   _             |"
        "  |  | |/ /   / \  | \ | | __ )  / \  | \ | |            |"
        "  |  | ' /   / _ \ |  \| |  _ \ / _ \ |  \| |            |"
        "  |  | . \  / ___ \| |\  | |_) / ___ \| |\  |            |"
        "  |  |_|\_\/_/   \_\_| \_|____/_/   \_\_| \_|            |"
        "  |                                                      |"
        "  |      1-Click Installer  v$($script:Version)                    |"
        "  |      Copyright (c) Daniel Le, Viact Team             |"
        "  |                                                      |"
        "  ========================================================"
        ""
    )
    foreach ($line in $lines) {
        Write-Host $line -ForegroundColor Cyan
    }
}

function Write-Step {
    param([int]$StepNum, [int]$TotalSteps, [string]$Message)
    Write-Host ""
    Write-Host "  [$StepNum/$TotalSteps] " -ForegroundColor Magenta -NoNewline
    Write-Host $Message -ForegroundColor White
    Write-Host "  $('─' * 50)" -ForegroundColor DarkGray
}

function Write-Ok {
    param([string]$Message)
    Write-Host "  [OK] " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Err {
    param([string]$Message)
    Write-Host "  [X] " -ForegroundColor Red -NoNewline
    Write-Host $Message -ForegroundColor Red
}

function Write-Warn {
    param([string]$Message)
    Write-Host "  [!] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "  [i] " -ForegroundColor Blue -NoNewline
    Write-Host $Message
}

function Write-BoxMessage {
    param([string[]]$Lines)
    $maxLen = 0
    foreach ($line in $Lines) {
        if ($line.Length -gt $maxLen) { $maxLen = $line.Length }
    }
    $maxLen += 4
    $border = "=" * $maxLen
    Write-Host ""
    Write-Host "  $border" -ForegroundColor Green
    foreach ($line in $Lines) {
        $padded = $line.PadRight($maxLen - 4)
        Write-Host "  | " -ForegroundColor Green -NoNewline
        Write-Host "$padded" -ForegroundColor White -NoNewline
        Write-Host " |" -ForegroundColor Green
    }
    Write-Host "  $border" -ForegroundColor Green
    Write-Host ""
}

function Write-Copyright {
    Write-Host "  Copyright (c) Daniel Le, Viact Team" -ForegroundColor DarkGray
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Docker checks
# ---------------------------------------------------------------------------
function Test-DockerInstalled {
    $cmd = Get-Command docker -ErrorAction SilentlyContinue
    return $null -ne $cmd
}

function Test-DockerRunning {
    try {
        $null = docker info 2>$null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Test-DockerCompose {
    try {
        $null = docker compose version 2>$null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Show-DockerInstallGuide {
    Write-Host ""
    Write-Info "Install Docker Desktop for Windows:"
    Write-Host ""
    Write-Host "     https://docs.docker.com/desktop/install/windows-install/" -ForegroundColor Cyan
    Write-Host ""
    Write-Info "Or install via winget:"
    Write-Host "     winget install Docker.DockerDesktop" -ForegroundColor White
    Write-Host ""
    Write-Warn "After installing, restart your computer and run this script again."
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Embedded docker-compose.yml
# ---------------------------------------------------------------------------
function Write-DockerCompose {
    if (-not (Test-Path $script:InstallDir)) {
        New-Item -ItemType Directory -Path $script:InstallDir -Force | Out-Null
    }

    $composeContent = @'
services:
  desktop-client:
    container_name: viact-vibe-kanban-desktop
    image: thanhlcm90/vibe-kanban:0.1.24
    restart: unless-stopped
    ports:
      - "3000:3000"
      - "5173:5173"
      - "5174:5174"
    environment:
      - HOST=0.0.0.0
      - PORT=3000
      - BROWSER=none
      - VK_SHARED_API_BASE=https://api-vg01-kanban-01.viact.ai/
      - ELECTRIC_SERVICE=https://api-vg01-kanban-01.viact.ai/electric
      - RUST_LOG=info
      - GITHUB_TOKEN=${GITHUB_TOKEN}
    working_dir: /home/node/workspaces
    volumes:
      - vibe_node_home:/home/node:rw
      - vibe_tmp_data:/var/tmp/vibe-kanban:rw

volumes:
  claude_session:
  vibe_config:
  vibe_node_home:
  vibe_tmp_data:
'@

    $composePath = Join-Path $script:InstallDir "docker-compose.yml"
    [System.IO.File]::WriteAllText($composePath, $composeContent, [System.Text.UTF8Encoding]::new($false))
}

function Write-EnvFile {
    param([string]$Token)
    $envPath = Join-Path $script:InstallDir ".env"
    [System.IO.File]::WriteAllText($envPath, "GITHUB_TOKEN=$Token`n", [System.Text.UTF8Encoding]::new($false))
}

# ---------------------------------------------------------------------------
# GitHub Token prompt
# ---------------------------------------------------------------------------
function Get-GitHubToken {
    # Check environment variable
    if ($env:GITHUB_TOKEN) {
        Write-Ok "Found GITHUB_TOKEN in environment."
        return $env:GITHUB_TOKEN
    }

    # Check existing .env
    $envFile = Join-Path $script:InstallDir ".env"
    if (Test-Path $envFile) {
        $content = Get-Content $envFile -Raw
        if ($content -match "GITHUB_TOKEN=(.+)") {
            $existing = $Matches[1].Trim()
            if ($existing -and $existing -ne "your_github_token_here") {
                Write-Info "Found existing GITHUB_TOKEN in configuration."
                $useExisting = Read-Host "     Use existing token? [Y/n]"
                if ($useExisting -ne "n") {
                    return $existing
                }
            }
        }
    }

    Write-Host ""
    Write-Info "You need a GitHub Personal Access Token with 'repo' scope."
    Write-Info "Create one here: https://github.com/settings/tokens/new"
    Write-Host ""

    while ($true) {
        $secureToken = Read-Host "     Paste your GITHUB_TOKEN (input is hidden)" -AsSecureString
        $token = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
        )

        if ([string]::IsNullOrWhiteSpace($token)) {
            Write-Err "Token cannot be empty. Please try again."
            continue
        }
        if ($token.Length -lt 10) {
            Write-Err "Token looks too short. Please try again."
            continue
        }
        break
    }

    Write-Ok "Token saved."
    return $token
}

# ---------------------------------------------------------------------------
# Wait for container
# ---------------------------------------------------------------------------
function Wait-ForContainer {
    $retries = 60
    while ($retries -gt 0) {
        $running = docker ps --filter "name=$($script:ContainerName)" --filter "status=running" -q 2>$null
        if ($running) { return $true }
        Start-Sleep -Seconds 2
        $retries--
    }
    return $false
}

# ---------------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------------
function Invoke-Install {
    $totalSteps = 4
    Write-Banner

    # Step 1: Check Docker
    Write-Step 1 $totalSteps "Checking Docker installation"

    if (-not (Test-DockerInstalled)) {
        Write-Err "Docker is not installed."
        Show-DockerInstallGuide
        exit 1
    }

    if (-not (Test-DockerRunning)) {
        Write-Err "Docker is installed but not running."
        Write-Host ""
        Write-Info "Please start Docker Desktop and run this script again."
        Write-Host ""
        exit 1
    }

    if (-not (Test-DockerCompose)) {
        Write-Err "Docker Compose is not available."
        Write-Host ""
        Write-Info "Please update Docker Desktop to the latest version."
        Write-Host ""
        exit 1
    }

    Write-Ok "Docker is installed and running."
    $dockerVer = docker --version 2>$null
    Write-Info $dockerVer

    # Step 2: GitHub Token
    Write-Step 2 $totalSteps "GitHub Personal Access Token"

    $token = Get-GitHubToken

    # Step 3: Setup & Start
    Write-Step 3 $totalSteps "Setting up Vibe Kanban"

    Write-DockerCompose
    Write-EnvFile -Token $token
    Write-Ok "Configuration written to $($script:InstallDir)"

    Push-Location $script:InstallDir
    try {
        Write-Info "Pulling the latest Vibe Kanban image..."
        docker compose pull 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor DarkGray }

        Write-Info "Starting Vibe Kanban..."
        docker compose up -d 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor DarkGray }

        Write-Info "Waiting for container to start..."
        if (Wait-ForContainer) {
            Write-Ok "Vibe Kanban is running!"
        }
        else {
            Write-Err "Container did not start in time. Check logs with:"
            Write-Host "     cd $($script:InstallDir); docker compose logs" -ForegroundColor White
            exit 1
        }
    }
    finally {
        Pop-Location
    }

    # Step 4: Claude Login
    Write-Step 4 $totalSteps "Claude Code Login"

    Write-Info "You need to log in to Claude Code inside the container."
    Write-Host ""
    $doClaude = Read-Host "     Log in to Claude now? [Y/n]"
    if ($doClaude -ne "n") {
        Write-Host ""
        Write-Info "Opening Claude login... Follow the on-screen instructions."
        Write-Host ""
        docker exec -it $script:ContainerName gosu node claude
        Write-Host ""
        Write-Ok "Claude login complete!"
    }
    else {
        Write-Host ""
        Write-Info "You can log in to Claude later with:"
        Write-Host "     docker exec -it $($script:ContainerName) gosu node claude" -ForegroundColor White
    }

    # Done
    Write-BoxMessage @(
        "Vibe Kanban is ready!",
        "",
        "Open your browser:",
        "http://localhost:3000"
    )

    Write-Host "  Manage Vibe Kanban:" -ForegroundColor DarkGray
    Write-Host '     > Stop       $env:VK_ACTION="stop"; irm <URL>/install.ps1 | iex' -ForegroundColor White
    Write-Host '     > Restart    $env:VK_ACTION="restart"; irm <URL>/install.ps1 | iex' -ForegroundColor White
    Write-Host '     > Uninstall  $env:VK_ACTION="uninstall"; irm <URL>/install.ps1 | iex' -ForegroundColor White
    Write-Host ""
    Write-Copyright
}

function Invoke-Stop {
    Write-Banner

    $composePath = Join-Path $script:InstallDir "docker-compose.yml"
    if (-not (Test-Path $composePath)) {
        Write-Err "Vibe Kanban is not installed."
        exit 1
    }

    Write-Step 1 1 "Stopping Vibe Kanban"

    Push-Location $script:InstallDir
    try {
        docker compose down 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor DarkGray }
    }
    finally {
        Pop-Location
    }

    Write-Ok "Vibe Kanban stopped."
    Write-Host ""
    Write-Info "To start again, run the install command."
    Write-Host ""
    Write-Copyright
}

function Invoke-Restart {
    Write-Banner

    $composePath = Join-Path $script:InstallDir "docker-compose.yml"
    if (-not (Test-Path $composePath)) {
        Write-Err "Vibe Kanban is not installed."
        exit 1
    }

    Write-Step 1 1 "Restarting Vibe Kanban"

    Push-Location $script:InstallDir
    try {
        docker compose restart 2>&1 | ForEach-Object { Write-Host "     $_" -ForegroundColor DarkGray }
    }
    finally {
        Pop-Location
    }

    Write-Ok "Vibe Kanban restarted!"

    Write-BoxMessage @(
        "Vibe Kanban is ready!",
        "",
        "Open your browser:",
        "http://localhost:3000"
    )

    Write-Copyright
}

function Invoke-Uninstall {
    Write-Banner

    Write-Step 1 1 "Uninstalling Vibe Kanban"

    Write-Warn "This will stop the container and remove all Vibe Kanban data."
    Write-Host ""
    $confirm = Read-Host "     Are you sure? [y/N]"
    if ($confirm -ne "y") {
        Write-Info "Uninstall cancelled."
        exit 0
    }

    Write-Host ""

    # Stop and remove containers + volumes
    $composePath = Join-Path $script:InstallDir "docker-compose.yml"
    if (Test-Path $composePath) {
        Push-Location $script:InstallDir
        try {
            Write-Info "Stopping container and removing volumes..."
            docker compose down -v 2>$null
        }
        catch { }
        finally {
            Pop-Location
        }
    }

    # Remove the image
    Write-Info "Removing Docker image..."
    try { docker rmi $script:ImageName 2>$null } catch { }

    # Remove install directory
    Write-Info "Removing configuration files..."
    if (Test-Path $script:InstallDir) {
        Remove-Item -Recurse -Force $script:InstallDir
    }

    Write-Host ""
    Write-Ok "Vibe Kanban has been completely uninstalled."
    Write-Host ""
    Write-Copyright
}

function Show-Help {
    Write-Banner
    Write-Host "  Usage:" -ForegroundColor White
    Write-Host ""
    Write-Host "     .\install.ps1                     Install and start (default)" -ForegroundColor White
    Write-Host "     .\install.ps1 -Action stop        Stop Vibe Kanban" -ForegroundColor White
    Write-Host "     .\install.ps1 -Action restart     Restart Vibe Kanban" -ForegroundColor White
    Write-Host "     .\install.ps1 -Action uninstall   Uninstall and remove all data" -ForegroundColor White
    Write-Host "     .\install.ps1 -Action help        Show this help" -ForegroundColor White
    Write-Host ""
    Write-Host "  One-liner usage (PowerShell):" -ForegroundColor DarkGray
    Write-Host '     irm <URL>/install.ps1 | iex' -ForegroundColor Cyan
    Write-Host '     $env:VK_ACTION="stop"; irm <URL>/install.ps1 | iex' -ForegroundColor Cyan
    Write-Host ""
    Write-Copyright
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
switch ($Action) {
    "install"   { Invoke-Install }
    "stop"      { Invoke-Stop }
    "restart"   { Invoke-Restart }
    "uninstall" { Invoke-Uninstall }
    "help"      { Show-Help }
}
