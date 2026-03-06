# Vibe Kanban

**AI-powered Kanban board by Viact Team**

Run Vibe Kanban on your personal computer with a single command. No programming experience needed.

---

## Quick Start (1-Click Install)

### macOS / Linux

Open **Terminal** and paste this command:

```bash
curl -fsSL https://raw.githubusercontent.com/daniel-viact/vibe-kanban-setup-tutorial/main/install.sh | bash
```

### Windows

Open **PowerShell** and paste this command:

```powershell
irm https://raw.githubusercontent.com/daniel-viact/vibe-kanban-setup-tutorial/main/install.ps1 | iex
```

> **That's it!** The installer will guide you through everything step by step.

---

## What the Installer Does

The installer takes care of everything automatically:

1. **Checks Docker** — Verifies Docker is installed and running. If not, it shows you how to install it.
2. **Asks for your GitHub Token** — Guides you to create one and securely saves it.
3. **Downloads and starts Vibe Kanban** — Sets up all necessary files and starts the application.
4. **Helps you log in to Claude Code** — Opens the Claude login directly inside the container.
5. **Shows you the link** — Once ready, just open **http://localhost:3000** in your browser.

---

## Before You Begin

You will need two things. The installer will check for these and help you set them up:

### 1. Docker Desktop

Docker is the tool that runs Vibe Kanban on your computer.

| Platform | Download Link |
|----------|---------------|
| Windows  | [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/) |
| macOS    | [Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/) |
| Linux    | [Docker Engine for Linux](https://docs.docker.com/engine/install/) |

> **Windows users:** Docker may ask you to enable WSL 2 during installation. Follow the prompts — this is required.

### 2. GitHub Personal Access Token

Vibe Kanban needs a GitHub token to work with your repositories.

1. Go to **[github.com/settings/tokens/new](https://github.com/settings/tokens/new)**
2. Give your token a name (e.g., "Vibe Kanban")
3. Select the **`repo`** scope (Full control of private repositories)
4. Click **Generate token**
5. **Copy the token immediately** — you won't be able to see it again

> The installer will ask you to paste this token during setup.

---

## Managing Vibe Kanban

After installation, you can manage Vibe Kanban with these commands:

### Stop

<table>
<tr><td><strong>macOS / Linux</strong></td></tr>
<tr><td>

```bash
curl -fsSL https://raw.githubusercontent.com/daniel-viact/vibe-kanban-setup-tutorial/main/install.sh | bash -s -- --stop
```

</td></tr>
<tr><td><strong>Windows (PowerShell)</strong></td></tr>
<tr><td>

```powershell
$env:VK_ACTION="stop"; irm https://raw.githubusercontent.com/daniel-viact/vibe-kanban-setup-tutorial/main/install.ps1 | iex
```

</td></tr>
</table>

### Restart

<table>
<tr><td><strong>macOS / Linux</strong></td></tr>
<tr><td>

```bash
curl -fsSL https://raw.githubusercontent.com/daniel-viact/vibe-kanban-setup-tutorial/main/install.sh | bash -s -- --restart
```

</td></tr>
<tr><td><strong>Windows (PowerShell)</strong></td></tr>
<tr><td>

```powershell
$env:VK_ACTION="restart"; irm https://raw.githubusercontent.com/daniel-viact/vibe-kanban-setup-tutorial/main/install.ps1 | iex
```

</td></tr>
</table>

### Uninstall

This will stop Vibe Kanban and remove all related Docker data.

<table>
<tr><td><strong>macOS / Linux</strong></td></tr>
<tr><td>

```bash
curl -fsSL https://raw.githubusercontent.com/daniel-viact/vibe-kanban-setup-tutorial/main/install.sh | bash -s -- --uninstall
```

</td></tr>
<tr><td><strong>Windows (PowerShell)</strong></td></tr>
<tr><td>

```powershell
$env:VK_ACTION="uninstall"; irm https://raw.githubusercontent.com/daniel-viact/vibe-kanban-setup-tutorial/main/install.ps1 | iex
```

</td></tr>
</table>

---

## Troubleshooting

### "Docker is not running"
Make sure Docker Desktop is open and running before you run the installer.

### "Port 3000 is already in use"
Another application is using port 3000. Stop that application and try again.

### "Permission denied" errors
- **macOS / Linux:** Try running the command with `sudo` in front.
- **Windows:** Right-click PowerShell and select "Run as Administrator".

### The page is blank or won't load
Wait about a minute after starting — the application may still be loading. Refresh the page.

### "Invalid token" or GitHub errors
Run the installer again. It will let you re-enter your GitHub token.

---

## Quick Reference

| Action | macOS / Linux | Windows (PowerShell) |
|--------|---------------|----------------------|
| Install | `curl -fsSL .../install.sh \| bash` | `irm .../install.ps1 \| iex` |
| Stop | `... \| bash -s -- --stop` | `$env:VK_ACTION="stop"; ...` |
| Restart | `... \| bash -s -- --restart` | `$env:VK_ACTION="restart"; ...` |
| Uninstall | `... \| bash -s -- --uninstall` | `$env:VK_ACTION="uninstall"; ...` |
| Claude Login | `docker exec -it viact-vibe-kanban-desktop gosu node claude` | Same |
| View Logs | `docker compose logs -f` (in `~/.vibe-kanban`) | Same |

---

<p align="center">
  <strong>Copyright (c) Daniel Le, Viact Team</strong>
</p>
