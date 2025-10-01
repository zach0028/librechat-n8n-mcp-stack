# 🚀 LibreChat + n8n + MCP Integration Stack

> A complete guide to building an AI automation powerhouse by integrating LibreChat, n8n workflows, and Model Context Protocol (MCP) with local LLMs via LM Studio.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/VOTRE-USERNAME/librechat-n8n-mcp-stack)](https://github.com/VOTRE-USERNAME/librechat-n8n-mcp-stack/stargazers)

## 📖 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Configuration](#configuration)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)
- [Credits](#credits)
- [License](#license)

## 🎯 Overview

This project provides a comprehensive setup guide for integrating:

- **[LibreChat](https://github.com/danny-avila/LibreChat)**: An enhanced ChatGPT clone with multi-AI support
- **[n8n](https://n8n.io/)**: Workflow automation platform
- **[n8n-mcp](https://github.com/czlonkowski/n8n-mcp)**: Model Context Protocol server for n8n
- **[LM Studio](https://lmstudio.ai/)**: Local LLM inference server

The result? A powerful AI platform where you can:
- Chat with multiple AI models (OpenAI, local models via LM Studio)
- Create and manage n8n workflows directly from chat conversations
- Automate complex tasks using AI-powered workflow generation

## 🏗️ Architecture

```
┌─────────────────┐
│   LM Studio     │ (Local LLMs)
│  192.168.x.x    │
└────────┬────────┘
         │
         │ OpenAI-compatible API
         │
┌────────▼────────────────────────────────────┐
│                                             │
│            LibreChat (Port 3080)            │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │  Chat Interface                       │  │
│  │  • OpenAI GPT Models                  │  │
│  │  • LM Studio Local Models             │  │
│  │  • MCP Tools (42 n8n tools)           │  │
│  └──────────────────────────────────────┘  │
│                                             │
└───────────┬─────────────────────────────────┘
            │
            │ HTTP/Streamable
            │
┌───────────▼─────────────────────────────────┐
│                                             │
│        n8n-mcp Server (Port 3000)           │
│                                             │
│  • 24 Documentation Tools                   │
│  • 18 Workflow Management Tools             │
│    - create_workflow                        │
│    - update_workflow                        │
│    - execute_workflow                       │
│    - list_workflows                         │
│                                             │
└───────────┬─────────────────────────────────┘
            │
            │ n8n REST API
            │
┌───────────▼─────────────────────────────────┐
│                                             │
│             n8n (Port 5678)                 │
│                                             │
│  • Workflow Automation                      │
│  • 400+ Integrations                        │
│  • Custom Nodes                             │
│                                             │
└─────────────────────────────────────────────┘

        ┌──────────────────────┐
        │  MongoDB (Port 27017) │
        │  (LibreChat Database) │
        └──────────────────────┘
```

## ✨ Features

### Chat Experience
- 🤖 **Multiple AI Models**: Switch between OpenAI, local LLMs, and more
- 💬 **Enhanced UI**: Better than vanilla ChatGPT
- 🔐 **Multi-user Auth**: Secure authentication system
- 📝 **Conversation Management**: Save, search, and organize chats

### n8n Integration via MCP
- ⚡ **42 MCP Tools** for n8n operations
- 🔧 **Create Workflows** directly from chat
- 📊 **Execute Workflows** on demand
- 🔍 **Search & Discovery** of n8n nodes and templates
- ✅ **Validation & Autofix** for workflows

### Local AI Power
- 🏠 **Privacy-First**: Run LLMs locally with LM Studio
- ⚡ **Fast Inference**: No API rate limits
- 💰 **Cost-Effective**: No per-token charges
- 🔒 **Offline Capable**: Works without internet

## 📋 Prerequisites

### Software Requirements
- **Node.js** v20+ and npm
- **MongoDB** (local or Atlas)
- **n8n** installed
- **LM Studio** (for local models)
- **Git**

### System Requirements
- **OS**: macOS, Linux, or Windows
- **RAM**: 8GB minimum (16GB+ recommended for local LLMs)
- **Storage**: 10GB+ free space
- **Network**: For initial setup and AI model downloads

## 🚀 Quick Start

### 1. Clone this repository
```bash
git clone https://github.com/VOTRE-USERNAME/librechat-n8n-mcp-stack.git
cd librechat-n8n-mcp-stack
```

### 2. Run the automated setup script
```bash
chmod +x scripts/setup-all.sh
./scripts/setup-all.sh
```

### 3. Access the services
- **LibreChat**: http://localhost:3080
- **n8n**: http://localhost:5678
- **n8n-mcp**: http://localhost:3000

## 📚 Detailed Setup

For step-by-step instructions, see our detailed guides in the [`docs/`](docs/) directory:

1. [Prerequisites Setup](docs/01-prerequisites.md)
2. [LibreChat Installation](docs/02-librechat-setup.md)
3. [n8n Setup](docs/03-n8n-setup.md)
4. [MCP Integration](docs/04-mcp-integration.md)
5. [LM Studio Connection](docs/05-lm-studio-connection.md)

## ⚙️ Configuration

### LibreChat Configuration (`librechat.yaml`)

```yaml
mcpServers:
  n8n:
    type: streamable-http
    url: http://localhost:3000/mcp
    timeout: 60000
    headers:
      Authorization: "Bearer YOUR-SECURE-TOKEN"

endpoints:
  custom:
    - name: 'LM Studio'
      apiKey: 'lm-studio'
      baseURL: 'http://YOUR-LM-STUDIO-IP:1234/v1'
      models:
        default: ['local-model']
        fetch: true
      modelDisplayLabel: 'LM Studio'
```

See [`configs/librechat.yaml.example`](configs/librechat.yaml.example) for the complete configuration.

### Environment Variables

```bash
# LibreChat
MONGO_URI=mongodb://localhost:27017/LibreChat
OPENAI_API_KEY=your-openai-key

# n8n
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your-password

# n8n-mcp
N8N_API_URL=http://localhost:5678/api/v1
N8N_API_KEY=your-n8n-api-key
MCP_MODE=http
PORT=3000
AUTH_TOKEN=your-secure-token
```

See [`.env.example`](configs/.env.example) for all variables.

## 💡 Usage Examples

### Create an n8n Workflow from Chat

**You**: "Can you create an n8n workflow that sends me an email every day at 9 AM with a weather forecast?"

**AI** will:
1. Use `search_nodes` to find "Schedule Trigger" and "Email" nodes
2. Use `get_node_info` to understand their configuration
3. Use `n8n_create_workflow` to build the workflow
4. Use `n8n_validate_workflow` to ensure it works
5. Provide you with the workflow ID and activation status

### List Your Workflows

**You**: "Show me all my n8n workflows"

**AI** uses `n8n_list_workflows` and displays:
- Workflow names
- Status (active/inactive)
- Last execution time
- Success/failure rates

### Execute a Workflow

**You**: "Run my 'Daily Report' workflow now"

**AI** uses `n8n_trigger_webhook_workflow` and shows execution results.

## 🐛 Troubleshooting

### LibreChat won't start
- Check MongoDB is running: `mongo --eval "db.version()"`
- Verify `.env` file exists and has correct values
- Check ports 3080, 3000, 5678 are available

### MCP tools not appearing
- Ensure n8n-mcp server is running on port 3000
- Check `librechat.yaml` has correct MCP configuration
- Verify AUTH_TOKEN matches in both configs
- Restart LibreChat after config changes

### LM Studio models not showing
- Verify LM Studio server is running
- Check the IP address in `librechat.yaml`
- Ensure at least one model is loaded in LM Studio
- Test: `curl http://YOUR-LM-STUDIO-IP:1234/v1/models`

### n8n API errors
- Generate a new API key in n8n Settings > API
- Update `N8N_API_KEY` in n8n-mcp environment
- Restart n8n-mcp server

## 🙏 Credits

This project builds upon these amazing open-source projects:

- **[LibreChat](https://github.com/danny-avila/LibreChat)** by Danny Avila - MIT License
- **[n8n-mcp](https://github.com/czlonkowski/n8n-mcp)** by Romuald Czlonkowski - MIT License
- **[n8n](https://n8n.io/)** - Sustainable Use License
- **[LM Studio](https://lmstudio.ai/)** - Commercial software (free for personal/work use)

See [CREDITS.md](CREDITS.md) for detailed attribution.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Note**: While this guide is MIT licensed, the individual projects (LibreChat, n8n, n8n-mcp, LM Studio) have their own licenses. Please review and comply with each project's license terms.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## ⭐ Show Your Support

If this project helped you, please consider giving it a ⭐ on GitHub!

## 📞 Contact

Project Issues: [GitHub Issues](https://github.com/zach0028/librechat-n8n-mcp-stack/issues)
