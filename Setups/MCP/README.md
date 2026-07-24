# MCP Servers

Model Context Protocol servers for OpenCode and LMStudio.

## Servers

| Server | What it does | Package |
|--------|-------------|---------|
| **fetch** | HTTP requests, web scraping | `@modelcontextprotocol/server-fetch` |
| **time** | Current time, timezone conversion | `mcp-server-time` |
| **memory** | Persistent knowledge graph | `@modelcontextprotocol/server-memory` |
| **searxng** | Web search via local SearXNG/Vane | Custom wrapper |

## Setup

### OpenCode
Config at `~/.config/opencode/opencode.jsonc` — already configured.

### LMStudio
Config at `~/.lmstudio/mcp.json` — already configured.

### SearXNG
The custom SearXNG MCP server lives in `searxng-mcp/`. It queries the Vane container's SearXNG backend on port 8081.

To run standalone:
```bash
SEARXNG_URL=http://localhost:8081 uvx --from ./searxng-mcp searxng-mcp
```

## Dependencies
- `npx` (Node.js) — for official MCP servers
- `uvx` (uv) — for Python MCP servers
- SearXNG accessible at `localhost:8081` (Vane container)
