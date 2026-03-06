#!/usr/bin/env bash
# ============================================================================
#  Vibe Kanban - 1-Click Installer (macOS / Linux)
#  Copyright (c) Daniel Le, Viact Team
# ============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
VERSION="1.0.0"
INSTALL_DIR="$HOME/.vibe-kanban"
CONTAINER_NAME="viact-vibe-kanban-desktop"
IMAGE_NAME="thanhlcm90/vibe-kanban:0.1.24"
COMPOSE_CMD=""

# ---------------------------------------------------------------------------
# Colors & Symbols
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

SYM_OK="${GREEN}✔${NC}"
SYM_ERR="${RED}✖${NC}"
SYM_WARN="${YELLOW}!${NC}"
SYM_INFO="${BLUE}ℹ${NC}"
SYM_ARROW="${CYAN}▶${NC}"

# ---------------------------------------------------------------------------
# UI Helpers
# ---------------------------------------------------------------------------
print_banner() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                                                          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${WHITE}${BOLD}██╗   ██╗██╗██████╗ ███████╗                        ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${WHITE}${BOLD}██║   ██║██║██╔══██╗██╔════╝                        ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${WHITE}${BOLD}██║   ██║██║██████╔╝█████╗                          ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${WHITE}${BOLD}╚██╗ ██╔╝██║██╔══██╗██╔══╝                          ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${WHITE}${BOLD} ╚████╔╝ ██║██████╔╝███████╗                        ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${WHITE}${BOLD}  ╚═══╝  ╚═╝╚═════╝ ╚══════╝                        ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${MAGENTA}${BOLD}██╗  ██╗ █████╗ ███╗   ██╗██████╗  █████╗ ███╗   ██╗${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${MAGENTA}${BOLD}██║ ██╔╝██╔══██╗████╗  ██║██╔══██╗██╔══██╗████╗  ██║${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${MAGENTA}${BOLD}█████╔╝ ███████║██╔██╗ ██║██████╔╝███████║██╔██╗ ██║${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${MAGENTA}${BOLD}██╔═██╗ ██╔══██║██║╚██╗██║██╔══██╗██╔══██║██║╚██╗██║${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${MAGENTA}${BOLD}██║  ██╗██║  ██║██║ ╚████║██████╔╝██║  ██║██║ ╚████║${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${MAGENTA}${BOLD}╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}        ${DIM}1-Click Installer  v${VERSION}${NC}                         ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}        ${DIM}Copyright (c) Daniel Le, Viact Team${NC}               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                          ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    local step_num=$1
    local total=$2
    local message=$3
    echo ""
    echo -e "  ${MAGENTA}${BOLD}[Step ${step_num}/${total}]${NC} ${WHITE}${BOLD}${message}${NC}"
    echo -e "  ${DIM}$(printf '%.0s─' $(seq 1 50))${NC}"
}

print_success() { echo -e "  ${SYM_OK}  $1"; }
print_error()   { echo -e "  ${SYM_ERR}  ${RED}$1${NC}"; }
print_warning() { echo -e "  ${SYM_WARN}  ${YELLOW}$1${NC}"; }
print_info()    { echo -e "  ${SYM_INFO}  $1"; }

print_box() {
    local max_len=0
    for line in "$@"; do
        local len=${#line}
        (( len > max_len )) && max_len=$len
    done
    max_len=$((max_len + 4))

    local border
    border=$(printf '═%.0s' $(seq 1 "$max_len"))

    echo ""
    echo -e "  ${GREEN}╔${border}╗${NC}"
    for line in "$@"; do
        local padding=$((max_len - ${#line} - 2))
        echo -e "  ${GREEN}║${NC}  ${WHITE}${BOLD}${line}${NC}$(printf ' %.0s' $(seq 1 "$padding"))${GREEN}║${NC}"
    done
    echo -e "  ${GREEN}╚${border}╝${NC}"
    echo ""
}

spinner() {
    local pid=$1
    local message=$2
    local spin_chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        local char="${spin_chars:$i:1}"
        printf "\r  ${CYAN}%s${NC}  %s" "$char" "$message"
        i=$(( (i + 1) % ${#spin_chars} ))
        sleep 0.1
    done
    printf "\r"
}

# ---------------------------------------------------------------------------
# Detect compose command (docker compose v2 vs docker-compose v1)
# ---------------------------------------------------------------------------
detect_compose_cmd() {
    if docker compose version &>/dev/null; then
        COMPOSE_CMD="docker compose"
    elif command -v docker-compose &>/dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Embedded docker-compose.yml
# ---------------------------------------------------------------------------
write_docker_compose() {
    mkdir -p "$INSTALL_DIR"
    cat > "$INSTALL_DIR/docker-compose.yml" << 'COMPOSE_EOF'
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
COMPOSE_EOF
}

write_env_file() {
    local token=$1
    cat > "$INSTALL_DIR/.env" << EOF
GITHUB_TOKEN=${token}
EOF
}

# ---------------------------------------------------------------------------
# Docker checks
# ---------------------------------------------------------------------------
check_docker() {
    if ! command -v docker &>/dev/null; then
        return 1
    fi
    if ! docker info &>/dev/null 2>&1; then
        return 2
    fi
    if ! detect_compose_cmd; then
        return 3
    fi
    return 0
}

guide_docker_install() {
    local os_type
    os_type="$(uname -s)"

    echo ""
    case "$os_type" in
        Darwin)
            print_info "Install Docker Desktop for macOS:"
            echo ""
            echo -e "     ${CYAN}https://docs.docker.com/desktop/install/mac-install/${NC}"
            echo ""
            print_info "Or install via Homebrew:"
            echo -e "     ${WHITE}brew install --cask docker${NC}"
            ;;
        Linux)
            print_info "Install Docker Engine for Linux:"
            echo ""
            echo -e "     ${CYAN}https://docs.docker.com/engine/install/${NC}"
            echo ""
            print_info "Quick install (Ubuntu/Debian):"
            echo -e "     ${WHITE}curl -fsSL https://get.docker.com | sudo sh${NC}"
            echo -e "     ${WHITE}sudo usermod -aG docker \$USER${NC}"
            echo ""
            print_warning "Log out and back in after installing for group changes to take effect."
            ;;
    esac
    echo ""
    print_info "After installing Docker, run this script again."
    echo ""
}

# ---------------------------------------------------------------------------
# GITHUB_TOKEN prompt
# ---------------------------------------------------------------------------
prompt_github_token() {
    # Check environment variable
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        print_success "Found GITHUB_TOKEN in environment."
        github_token="$GITHUB_TOKEN"
        return
    fi

    # Check existing .env
    if [[ -f "$INSTALL_DIR/.env" ]]; then
        local existing_token
        existing_token=$(grep -oP 'GITHUB_TOKEN=\K.+' "$INSTALL_DIR/.env" 2>/dev/null || true)
        if [[ -n "$existing_token" && "$existing_token" != "your_github_token_here" ]]; then
            print_info "Found existing GITHUB_TOKEN in configuration."
            local use_existing
            read -rp "$(echo -e "     ${YELLOW}Use existing token? [Y/n]: ${NC}")" use_existing < /dev/tty
            if [[ "${use_existing,,}" != "n" ]]; then
                github_token="$existing_token"
                return
            fi
        fi
    fi

    echo ""
    print_info "You need a GitHub Personal Access Token with ${WHITE}${BOLD}repo${NC} scope."
    print_info "Create one here: ${CYAN}https://github.com/settings/tokens/new${NC}"
    echo ""

    while true; do
        read -rsp "$(echo -e "     ${CYAN}Paste your GITHUB_TOKEN (input is hidden): ${NC}")" github_token < /dev/tty
        echo ""
        if [[ -z "$github_token" ]]; then
            print_error "Token cannot be empty. Please try again."
        elif [[ ${#github_token} -lt 10 ]]; then
            print_error "Token looks too short. Please try again."
        else
            break
        fi
    done

    print_success "Token saved."
}

# ---------------------------------------------------------------------------
# Wait for container to be running
# ---------------------------------------------------------------------------
wait_for_container() {
    local retries=60
    while [[ $retries -gt 0 ]]; do
        if docker ps --filter "name=${CONTAINER_NAME}" --filter "status=running" -q 2>/dev/null | grep -q .; then
            return 0
        fi
        sleep 2
        retries=$((retries - 1))
    done
    return 1
}

# ---------------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------------
do_install() {
    local total_steps=4
    print_banner

    # ── Step 1: Check Docker ──
    print_step 1 $total_steps "Checking Docker installation"

    local docker_status=0
    check_docker || docker_status=$?

    case $docker_status in
        1)
            print_error "Docker is not installed."
            guide_docker_install
            exit 1
            ;;
        2)
            print_error "Docker is installed but the daemon is not running."
            echo ""
            print_info "Please start Docker Desktop and run this script again."
            echo ""
            exit 1
            ;;
        3)
            print_error "Docker Compose is not available."
            echo ""
            print_info "Please update Docker to the latest version."
            echo ""
            exit 1
            ;;
        0)
            print_success "Docker is installed and running."
            local docker_ver
            docker_ver=$(docker --version 2>/dev/null | head -1)
            print_info "${DIM}${docker_ver}${NC}"
            ;;
    esac

    # ── Step 2: GitHub Token ──
    print_step 2 $total_steps "GitHub Personal Access Token"

    local github_token=""
    prompt_github_token

    # ── Step 3: Setup & Start ──
    print_step 3 $total_steps "Setting up Vibe Kanban"

    write_docker_compose
    write_env_file "$github_token"
    print_success "Configuration written to ${DIM}${INSTALL_DIR}${NC}"

    cd "$INSTALL_DIR"

    print_info "Pulling the latest Vibe Kanban image..."
    $COMPOSE_CMD pull 2>&1 | while IFS= read -r line; do
        echo -e "     ${DIM}${line}${NC}"
    done

    print_info "Starting Vibe Kanban..."
    $COMPOSE_CMD up -d 2>&1 | while IFS= read -r line; do
        echo -e "     ${DIM}${line}${NC}"
    done

    print_info "Waiting for container to start..."
    if wait_for_container; then
        print_success "Vibe Kanban is running!"
    else
        print_error "Container did not start in time. Check logs with:"
        echo -e "     ${WHITE}cd ${INSTALL_DIR} && ${COMPOSE_CMD} logs${NC}"
        exit 1
    fi

    # ── Step 4: Claude Login ──
    print_step 4 $total_steps "Claude Code Login"

    print_info "You need to log in to Claude Code inside the container."
    echo ""
    local do_claude
    read -rp "$(echo -e "     ${YELLOW}Log in to Claude now? [Y/n]: ${NC}")" do_claude < /dev/tty
    if [[ "${do_claude,,}" != "n" ]]; then
        echo ""
        print_info "Opening Claude login... Follow the on-screen instructions."
        echo ""
        docker exec -it "$CONTAINER_NAME" gosu node claude < /dev/tty
        echo ""
        print_success "Claude login complete!"
    else
        echo ""
        print_info "You can log in to Claude later with:"
        echo -e "     ${WHITE}docker exec -it ${CONTAINER_NAME} gosu node claude${NC}"
    fi

    # ── Done ──
    print_box \
        "Vibe Kanban is ready!" \
        "" \
        "Open your browser:" \
        "http://localhost:3000"

    echo -e "  ${DIM}Manage Vibe Kanban:${NC}"
    echo -e "     ${SYM_ARROW}  Stop       ${WHITE}curl -fsSL <URL> | bash -s -- --stop${NC}"
    echo -e "     ${SYM_ARROW}  Restart    ${WHITE}curl -fsSL <URL> | bash -s -- --restart${NC}"
    echo -e "     ${SYM_ARROW}  Uninstall  ${WHITE}curl -fsSL <URL> | bash -s -- --uninstall${NC}"
    echo ""
    echo -e "  ${DIM}Copyright (c) Daniel Le, Viact Team${NC}"
    echo ""
}

do_stop() {
    print_banner

    if [[ ! -f "$INSTALL_DIR/docker-compose.yml" ]]; then
        print_error "Vibe Kanban is not installed."
        exit 1
    fi

    print_step 1 1 "Stopping Vibe Kanban"
    cd "$INSTALL_DIR"
    $COMPOSE_CMD down 2>&1 | while IFS= read -r line; do
        echo -e "     ${DIM}${line}${NC}"
    done
    print_success "Vibe Kanban stopped."
    echo ""
    print_info "To start again, run the install command or use ${WHITE}--restart${NC}."
    echo ""
    echo -e "  ${DIM}Copyright (c) Daniel Le, Viact Team${NC}"
    echo ""
}

do_restart() {
    print_banner

    if [[ ! -f "$INSTALL_DIR/docker-compose.yml" ]]; then
        print_error "Vibe Kanban is not installed."
        exit 1
    fi

    detect_compose_cmd || { print_error "Docker Compose not found."; exit 1; }

    print_step 1 1 "Restarting Vibe Kanban"
    cd "$INSTALL_DIR"
    $COMPOSE_CMD restart 2>&1 | while IFS= read -r line; do
        echo -e "     ${DIM}${line}${NC}"
    done

    print_success "Vibe Kanban restarted!"

    print_box \
        "Vibe Kanban is ready!" \
        "" \
        "Open your browser:" \
        "http://localhost:3000"

    echo -e "  ${DIM}Copyright (c) Daniel Le, Viact Team${NC}"
    echo ""
}

do_uninstall() {
    print_banner

    print_step 1 1 "Uninstalling Vibe Kanban"

    print_warning "This will stop the container and remove all Vibe Kanban data."
    echo ""
    local confirm
    read -rp "$(echo -e "     ${RED}${BOLD}Are you sure? [y/N]: ${NC}")" confirm < /dev/tty
    if [[ "${confirm,,}" != "y" ]]; then
        print_info "Uninstall cancelled."
        exit 0
    fi

    echo ""

    detect_compose_cmd || true

    # Stop and remove containers + volumes
    if [[ -f "$INSTALL_DIR/docker-compose.yml" ]]; then
        cd "$INSTALL_DIR"
        print_info "Stopping container and removing volumes..."
        $COMPOSE_CMD down -v 2>/dev/null || true
    fi

    # Remove the image
    print_info "Removing Docker image..."
    docker rmi "$IMAGE_NAME" 2>/dev/null || true

    # Remove install directory
    print_info "Removing configuration files..."
    rm -rf "$INSTALL_DIR"

    echo ""
    print_success "Vibe Kanban has been completely uninstalled."
    echo ""
    echo -e "  ${DIM}Copyright (c) Daniel Le, Viact Team${NC}"
    echo ""
}

show_help() {
    print_banner
    echo -e "  ${WHITE}${BOLD}Usage:${NC}"
    echo ""
    echo -e "     ${WHITE}install.sh${NC}              Install and start Vibe Kanban (default)"
    echo -e "     ${WHITE}install.sh --stop${NC}       Stop Vibe Kanban"
    echo -e "     ${WHITE}install.sh --restart${NC}    Restart Vibe Kanban"
    echo -e "     ${WHITE}install.sh --uninstall${NC}  Uninstall and remove all data"
    echo -e "     ${WHITE}install.sh --help${NC}       Show this help message"
    echo ""
    echo -e "  ${DIM}One-liner usage:${NC}"
    echo -e "     ${CYAN}curl -fsSL <URL>/install.sh | bash${NC}"
    echo -e "     ${CYAN}curl -fsSL <URL>/install.sh | bash -s -- --stop${NC}"
    echo ""
    echo -e "  ${DIM}Copyright (c) Daniel Le, Viact Team${NC}"
    echo ""
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    local action="install"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --uninstall|-u)  action="uninstall" ;;
            --stop|-s)       action="stop" ;;
            --restart|-r)    action="restart" ;;
            --help|-h)       action="help" ;;
            *)               print_error "Unknown option: $1"; show_help; exit 1 ;;
        esac
        shift
    done

    case "$action" in
        install)    do_install ;;
        uninstall)  do_uninstall ;;
        stop)       do_stop ;;
        restart)    do_restart ;;
        help)       show_help ;;
    esac
}

main "$@"
