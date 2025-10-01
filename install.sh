#!/bin/bash

# LibreChat + n8n + MCP + LM Studio - Automated Installation Script
# Copyright (c) 2025 Zacharie Elbaz (zach0028)
# MIT License

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="$HOME/librechat-stack"
MONGODB_PORT=27017
N8N_PORT=5678
MCP_PORT=3000
LIBRECHAT_PORT=3080
LMSTUDIO_PORT=1234

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    else
        log_error "Unsupported OS: $OSTYPE"
        exit 1
    fi
    log_info "Detected OS: $OS"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed. Please install Node.js v20+ first."
        log_info "Visit: https://nodejs.org/"
        exit 1
    fi

    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 20 ]; then
        log_error "Node.js version must be 20 or higher. Current: $(node -v)"
        exit 1
    fi
    log_success "Node.js $(node -v) detected"

    # Check npm
    if ! command -v npm &> /dev/null; then
        log_error "npm is not installed"
        exit 1
    fi
    log_success "npm $(npm -v) detected"

    # Check git
    if ! command -v git &> /dev/null; then
        log_error "git is not installed"
        exit 1
    fi
    log_success "git detected"
}

# Install MongoDB
install_mongodb() {
    log_info "Installing MongoDB..."

    if command -v mongod &> /dev/null; then
        log_warning "MongoDB already installed"
        return
    fi

    if [ "$OS" == "macos" ]; then
        if ! command -v brew &> /dev/null; then
            log_error "Homebrew is required on macOS. Install from https://brew.sh/"
            exit 1
        fi
        brew tap mongodb/brew
        brew install mongodb-community
        brew services start mongodb-community
    elif [ "$OS" == "linux" ]; then
        wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | sudo apt-key add -
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
        sudo apt-get update
        sudo apt-get install -y mongodb-org
        sudo systemctl start mongod
        sudo systemctl enable mongod
    fi

    log_success "MongoDB installed and started"
}

# Install n8n
install_n8n() {
    log_info "Installing n8n globally..."

    if command -v n8n &> /dev/null; then
        log_warning "n8n already installed"
    else
        npm install -g n8n
        log_success "n8n installed"
    fi
}

# Setup installation directory
setup_directory() {
    log_info "Creating installation directory: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
}

# Clone and setup LibreChat
install_librechat() {
    log_info "Installing LibreChat..."

    if [ -d "$INSTALL_DIR/LibreChat" ]; then
        log_warning "LibreChat directory already exists, skipping clone"
        cd "$INSTALL_DIR/LibreChat"
    else
        cd "$INSTALL_DIR"
        git clone https://github.com/danny-avila/LibreChat.git
        cd LibreChat
        log_success "LibreChat cloned"
    fi

    log_info "Installing LibreChat dependencies (this may take several minutes)..."
    npm ci

    log_info "Configuring LibreChat environment..."
    if [ ! -f .env ]; then
        cp .env.example .env

        # Configure .env
        sed -i.bak "s|MONGO_URI=.*|MONGO_URI=mongodb://localhost:${MONGODB_PORT}/LibreChat|g" .env

        echo ""
        echo -e "${YELLOW}======================================${NC}"
        echo -e "${YELLOW}IMPORTANT: API Keys Configuration${NC}"
        echo -e "${YELLOW}======================================${NC}"
        echo ""
        read -p "Enter your OpenAI API key (or press Enter to skip): " OPENAI_KEY
        if [ -n "$OPENAI_KEY" ]; then
            sed -i.bak "s|OPENAI_API_KEY=.*|OPENAI_API_KEY=$OPENAI_KEY|g" .env
        fi

        rm -f .env.bak
    fi

    log_info "Building LibreChat frontend..."
    npm run frontend

    log_success "LibreChat installed and configured"
}

# Clone and setup n8n-mcp
install_n8n_mcp() {
    log_info "Installing n8n-mcp server..."

    if [ -d "$INSTALL_DIR/n8n-mcp" ]; then
        log_warning "n8n-mcp directory already exists, skipping clone"
        cd "$INSTALL_DIR/n8n-mcp"
    else
        cd "$INSTALL_DIR"
        git clone https://github.com/czlonkowski/n8n-mcp.git
        cd n8n-mcp
        log_success "n8n-mcp cloned"
    fi

    log_info "Installing n8n-mcp dependencies..."
    npm install
    npm run build

    log_success "n8n-mcp installed"
}

# Generate secure token
generate_token() {
    if command -v openssl &> /dev/null; then
        openssl rand -hex 32
    else
        echo "librechat-n8n-token-$(date +%s)"
    fi
}

# Create configuration files
create_configs() {
    log_info "Creating configuration files..."

    AUTH_TOKEN=$(generate_token)

    # Create librechat.yaml
    cat > "$INSTALL_DIR/LibreChat/librechat.yaml" <<EOF
version: 1.1.7
cache: true

mcpServers:
  n8n:
    type: streamable-http
    url: http://localhost:${MCP_PORT}/mcp
    timeout: 60000
    headers:
      Authorization: "Bearer ${AUTH_TOKEN}"

endpoints:
  custom:
    - name: 'LM Studio'
      apiKey: 'lm-studio'
      baseURL: 'http://localhost:${LMSTUDIO_PORT}/v1'
      models:
        default: ['local-model']
        fetch: true
      titleConvo: true
      titleModel: 'local-model'
      modelDisplayLabel: 'LM Studio'
      iconURL: 'https://lmstudio.ai/favicon.ico'
EOF

    # Create startup script for n8n-mcp
    cat > "$INSTALL_DIR/n8n-mcp/start-mcp.sh" <<EOF
#!/bin/bash
export MCP_MODE=http
export USE_FIXED_HTTP=true
export PORT=${MCP_PORT}
export HOST=0.0.0.0
export AUTH_TOKEN="${AUTH_TOKEN}"
export N8N_API_URL="http://localhost:${N8N_PORT}/api/v1"

# Check if N8N_API_KEY is set
if [ -z "\$N8N_API_KEY" ]; then
    echo "Warning: N8N_API_KEY not set. Only documentation tools will be available (24 tools)."
    echo "To enable workflow management tools (42 tools total), generate an API key in n8n Settings > API"
    echo "Then run: export N8N_API_KEY='your-api-key' before starting this script"
fi

npm run start:http:fixed
EOF
    chmod +x "$INSTALL_DIR/n8n-mcp/start-mcp.sh"

    # Create master startup script
    cat > "$INSTALL_DIR/start-all.sh" <<EOF
#!/bin/bash

echo "Starting LibreChat Stack..."
echo ""

# Start n8n in background
echo "[1/3] Starting n8n on port ${N8N_PORT}..."
n8n start &
N8N_PID=\$!
sleep 5

# Start n8n-mcp in background
echo "[2/3] Starting n8n-mcp on port ${MCP_PORT}..."
cd "$INSTALL_DIR/n8n-mcp"
./start-mcp.sh &
MCP_PID=\$!
sleep 3

# Start LibreChat backend
echo "[3/3] Starting LibreChat on port ${LIBRECHAT_PORT}..."
cd "$INSTALL_DIR/LibreChat"
npm run backend

# Cleanup on exit
trap "kill \$N8N_PID \$MCP_PID 2>/dev/null" EXIT
EOF
    chmod +x "$INSTALL_DIR/start-all.sh"

    log_success "Configuration files created"

    # Save config info
    cat > "$INSTALL_DIR/INSTALLATION_INFO.txt" <<EOF
LibreChat + n8n + MCP Stack - Installation Info
================================================

Installation Directory: $INSTALL_DIR
Installation Date: $(date)

Services Configuration:
- MongoDB: mongodb://localhost:${MONGODB_PORT}
- n8n: http://localhost:${N8N_PORT}
- n8n-mcp: http://localhost:${MCP_PORT}
- LibreChat: http://localhost:${LIBRECHAT_PORT}
- LM Studio: http://localhost:${LMSTUDIO_PORT} (optional)

MCP Authentication Token: ${AUTH_TOKEN}

Next Steps:
===========

1. Start n8n and create an API key:
   $ n8n start
   - Open http://localhost:${N8N_PORT}
   - Go to Settings > API
   - Create API Key
   - Save the key

2. Configure n8n API key:
   $ export N8N_API_KEY='your-n8n-api-key'

3. Start all services:
   $ cd $INSTALL_DIR
   $ ./start-all.sh

4. Access LibreChat:
   Open http://localhost:${LIBRECHAT_PORT} in your browser

5. (Optional) Install LM Studio:
   - Download from https://lmstudio.ai/
   - Load a model and start server on port ${LMSTUDIO_PORT}

Troubleshooting:
===============
- Check MongoDB: mongosh --eval "db.version()"
- View logs in each service directory
- GitHub Issues: https://github.com/zach0028/librechat-n8n-mcp-stack/issues

EOF
}

# Main installation
main() {
    echo ""
    echo "======================================="
    echo "  LibreChat + n8n + MCP Stack Installer"
    echo "======================================="
    echo ""

    detect_os
    check_prerequisites
    setup_directory
    install_mongodb
    install_n8n
    install_librechat
    install_n8n_mcp
    create_configs

    echo ""
    echo -e "${GREEN}=======================================${NC}"
    echo -e "${GREEN}   Installation Complete!${NC}"
    echo -e "${GREEN}=======================================${NC}"
    echo ""
    log_info "Installation directory: $INSTALL_DIR"
    log_info "Configuration details: $INSTALL_DIR/INSTALLATION_INFO.txt"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo ""
    echo "1. Start n8n and create an API key:"
    echo "   $ n8n start"
    echo "   Then open http://localhost:${N8N_PORT} and go to Settings > API"
    echo ""
    echo "2. Set your n8n API key:"
    echo "   $ export N8N_API_KEY='your-api-key-here'"
    echo ""
    echo "3. Start all services:"
    echo "   $ cd $INSTALL_DIR"
    echo "   $ ./start-all.sh"
    echo ""
    echo "4. Open LibreChat: http://localhost:${LIBRECHAT_PORT}"
    echo ""
    echo -e "${BLUE}Full documentation: $INSTALL_DIR/INSTALLATION_INFO.txt${NC}"
    echo ""
}

# Run main installation
main
