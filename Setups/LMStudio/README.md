# Charlotte AI Stack — LMStudio Setup

MLX-first local AI on Mac M1 Max 64GB. No Ollama.

## Models

| Role | Model Key | Size |
|------|-----------|------|
| General | `google/gemma-4-26b-a4b` | 15.6 GB |
| Coding | `qwen3-coder-30b-a3b-instruct-mlx` | 17.2 GB |
| Reasoning | `qwen/qwen3.6-35b-a3b` | 20.4 GB |
| OCR/Vision | `qwen3-vl-4b-instruct-mlx` | 3.1 GB |
| Worker | `qwen/qwen3-1.7b` | 1.8 GB |

**Total: ~58 GB**

## Quick Start

```bash
# 1. Download all models
bash scripts/download-models.sh

# 2. Start LM Studio server
lms server start

# 3. Load a model
lms load google/gemma-4-26b-a4b

# 4. Open WebUI at http://localhost:8080
```

## Charlotte Personas

Each model has a Charlotte persona preset installed at `~/.lmstudio/config-presets/`:

- `general.json` — Daily tasks, scheduling, vision
- `coding.json` — Deep coding, production-ready code
- `research.json` — Analysis, reasoning, synthesis
- `ocr.json` — Document understanding, text extraction
- `worker.json` — Background tasks, titles, tags

**Usage:**
1. Load a model in LMStudio
2. Apply the matching preset via the UI (Presets dropdown)
3. System prompt is automatically applied

## API Usage

For programmatic access, include the system prompt in your API call:

```bash
curl http://localhost:1234/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "google/gemma-4-26b-a4b",
    "messages": [
      {"role": "system", "content": "You are Charlotte..."},
      {"role": "user", "content": "Hello!"}
    ]
  }'
```

System prompts are in `prompts/*.txt`.

## Architecture

```
Browser → Open WebUI (localhost:8080)
               ↓
         LM Studio (localhost:1234)
               ↓
         MLX Engine (Apple Silicon)
```
