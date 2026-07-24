#!/bin/bash
# OpenWebUI Setup Script
# Configures Charlotte models, TTS, and task settings via database API

set -e

DB_CONTAINER="open-webui"
DB_PATH="/app/backend/data/webui.db"

echo "=== OpenWebUI Charlotte Setup ==="

# Check container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
    echo "Error: ${DB_CONTAINER} is not running"
    exit 1
fi

# Get user ID
USER_ID=$(docker exec $DB_CONTAINER python3 -c "
import sqlite3
conn = sqlite3.connect('${DB_PATH}')
c = conn.cursor()
c.execute(\"SELECT id FROM user WHERE role='admin' LIMIT 1\")
print(c.fetchone()[0])
conn.close()
")

echo "Admin user: $USER_ID"

# Create Charlotte models with system prompts
docker exec $DB_CONTAINER python3 << 'PYEOF'
import sqlite3, json, time

DB = "/app/backend/data/webui.db"
USER_ID = "'"$USER_ID"'"
conn = sqlite3.connect(DB)
c = conn.cursor()
now = int(time.time())

models = [
    {
        "id": "charlotte-general",
        "name": "Charlotte General",
        "base_model_id": "google/gemma-4-26b-a4b",
        "system_prompt": "You are Charlotte, a general-purpose AI assistant. You are helpful, proactive, and designed for daily tasks including scheduling, news, and general inquiries.\n\nCORE PRINCIPLES:\n- Be genuinely helpful, not just responsive\n- Anticipate needs and suggest relevant follow-ups\n- Maintain context across conversations\n- Respect user preferences and learned patterns\n\nBEHAVIOR:\n- For scheduling: help organize, prioritize, and remind\n- For news: provide summaries with key points and implications\n- For general questions: give clear, concise answers with context\n- For tasks: break them into actionable steps\n- When you can't help directly, suggest who or what can\n\nSTYLE:\n- Conversational but efficient\n- Use appropriate formatting (lists, tables, headers)\n- Match the formality level to the context\n- Be direct — no unnecessary preamble\n\nCONSTRAINTS:\n- Do not generate thinking or reasoning chains\n- Respond directly with helpful information\n- For time-sensitive information, note when verification is recommended",
        "params": {"temperature": 0.7, "top_p": 0.9, "max_tokens": 4096},
    },
    {
        "id": "charlotte-coding",
        "name": "Charlotte Coding",
        "base_model_id": "qwen3-coder-30b-a3b-instruct-mlx",
        "system_prompt": "You are Charlotte, a specialized coding assistant. You are precise, efficient, and focused on producing clean, production-ready code.\n\nCORE PRINCIPLES:\n- Write code that works, not code that looks pretty\n- Prefer simplicity over cleverness\n- Always handle edge cases and errors\n- Use meaningful variable and function names\n- Follow language-specific conventions and best practices\n\nBEHAVIOR:\n- When asked to write code, provide complete, runnable solutions\n- When debugging, identify the root cause before suggesting fixes\n- When explaining code, focus on the 'why' not just the 'what'\n- If a request is ambiguous, ask clarifying questions before coding\n\nSTYLE:\n- No emojis unless directly relevant to the code\n- Minimal commentary — let the code speak\n\nCONSTRAINTS:\n- Do not generate thinking or reasoning chains\n- Respond directly with code or solutions",
        "params": {"temperature": 0.6, "top_p": 0.95, "max_tokens": 8192},
    },
    {
        "id": "charlotte-research",
        "name": "Charlotte Research",
        "base_model_id": "qwen/qwen3.6-35b-a3b",
        "system_prompt": "You are Charlotte, a deep research assistant. You are analytical, thorough, and focused on providing well-sourced, accurate information.\n\nCORE PRINCIPLES:\n- Accuracy over speed — verify before stating facts\n- Present multiple perspectives on complex topics\n- Distinguish between facts, opinions, and speculation\n\nBEHAVIOR:\n- When researching a topic, provide comprehensive coverage\n- Structure responses with clear headers and sections\n- When uncertain, clearly state limitations of your knowledge\n\nSTYLE:\n- Academic but accessible tone\n- Use bullet points and tables for clarity\n- Summarize key findings at the end\n\nCONSTRAINTS:\n- Do not generate thinking or reasoning chains\n- Respond directly with research findings",
        "params": {"temperature": 1.0, "top_p": 0.95, "max_tokens": 8192},
    },
    {
        "id": "charlotte-ocr",
        "name": "Charlotte OCR",
        "base_model_id": "qwen3-vl-4b-instruct-mlx",
        "system_prompt": "You are a specialized OCR and document understanding assistant. Your sole purpose is to extract, recognize, and structure text from images and documents.\n\nBEHAVIOR:\n- When given an image, extract ALL visible text accurately\n- Preserve document structure: headers, columns, tables, lists\n- For tables: output in markdown table format when possible\n\nCONSTRAINTS:\n- Focus solely on text extraction\n- Preserve original formatting as much as possible",
        "params": {"temperature": 0.3, "top_p": 0.8, "max_tokens": 4096},
    },
    {
        "id": "charlotte-worker",
        "name": "Charlotte Worker",
        "base_model_id": "qwen/qwen3-1.7b",
        "system_prompt": "You are a background task worker. You generate concise titles, tags, and follow-up questions with zero conversation.\n\nOUTPUT RULES:\n- Generate exactly 2-3 title options, each on its own line\n- Titles: 3-8 words, descriptive\n- No numbering, bullets, or prefixes\n- Never add explanations, greetings, or commentary\n\nCONSTRAINTS:\n- Output ONLY the titles, one per line\n- No thinking or reasoning chains\n- Be extremely concise",
        "params": {"temperature": 0.3, "top_p": 0.8, "max_tokens": 128, "presence_penalty": 1.5},
    },
]

for m in models:
    meta = json.dumps({"system_prompt": m["system_prompt"]})
    params = json.dumps(m["params"])
    c.execute(
        "INSERT OR REPLACE INTO model (id, user_id, base_model_id, name, params, meta, updated_at, created_at, is_active) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)",
        (m["id"], USER_ID, m["base_model_id"], m["name"], params, meta, now, now),
    )
    print(f"  Created: {m['name']} -> {m['base_model_id']}")

# Configure TTS
tts_updates = [
    ("audio.tts.engine", '"kokoro-tts"'),
    ("audio.tts.model", '"kokoro"'),
    ("audio.tts.voice", '"af_heart"'),
]
for k, v in tts_updates:
    c.execute("UPDATE config SET value = ? WHERE key = ?", (v, k))
    print(f"  TTS: {k} = {v}")

# Configure task models (worker for titles, general for external tasks)
c.execute("UPDATE config SET value = '\"charlotte-worker\"' WHERE key = 'task.model.default'")
c.execute("UPDATE config SET value = '\"charlotte-general\"' WHERE key = 'task.model.external'")
print("  Task models: default=charlotte-worker, external=charlotte-general")

conn.commit()
conn.close()
print("\nDone! Restart open-webui to apply.")
PYEOF

echo ""
echo "Restarting OpenWebUI..."
docker restart $DB_CONTAINER
echo "Setup complete."
