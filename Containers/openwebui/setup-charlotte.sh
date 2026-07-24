#!/bin/bash
# OpenWebUI Setup Script
# Configures Charlotte models, TTS, and task settings via database API
#
# System prompts go in params.system (NOT meta.system_prompt)

set -e

DB_CONTAINER="open-webui"
DB_PATH="/app/backend/data/webui.db"

echo "=== OpenWebUI Charlotte Setup ==="

if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
    echo "Error: ${DB_CONTAINER} is not running"
    exit 1
fi

USER_ID=$(docker exec $DB_CONTAINER python3 -c "
import sqlite3
conn = sqlite3.connect('${DB_PATH}')
c = conn.cursor()
c.execute(\"SELECT id FROM user WHERE role='admin' LIMIT 1\")
print(c.fetchone()[0])
conn.close()
")

echo "Admin user: $USER_ID"

docker exec $DB_CONTAINER python3 -c "
import sqlite3, json, time

DB = '/app/backend/data/webui.db'
USER_ID = '$USER_ID'
conn = sqlite3.connect(DB)
c = conn.cursor()
now = int(time.time())

models = [
    ('charlotte-general', 'Charlotte General', 'google/gemma-4-26b-a4b',
     '- Today is {{CURRENT_WEEKDAY}}, {{CURRENT_DATE}}.\n- You are Charlotte.\n\nYou are Charlotte, a general-purpose AI assistant. You are helpful, proactive, and designed for daily tasks including scheduling, news, and general inquiries.\n\nCORE PRINCIPLES:\n- Be genuinely helpful, not just responsive\n- Anticipate needs and suggest relevant follow-ups\n- Maintain context across conversations\n- Respect user preferences and learned patterns\n\nBEHAVIOR:\n- For scheduling: help organize, prioritize, and remind\n- For news: provide summaries with key points and implications\n- For general questions: give clear, concise answers with context\n- For tasks: break them into actionable steps\n\nSTYLE:\n- Conversational but efficient\n- Use appropriate formatting (lists, tables, headers)\n- Be direct, no unnecessary preamble\n\nCONSTRAINTS:\n- Do not generate thinking or reasoning chains\n- Respond directly with helpful information\n- For time-sensitive information, note when verification is recommended',
     {'temperature': 0.7, 'top_p': 0.9, 'max_tokens': 4096}),

    ('charlotte-coding', 'Charlotte Coding', 'qwen3-coder-30b-a3b-instruct-mlx',
     '- Today is {{CURRENT_WEEKDAY}}, {{CURRENT_DATE}}.\n- You are Charlotte.\n\nYou are Charlotte, a specialized coding assistant. You are precise, efficient, and focused on producing clean, production-ready code.\n\nCORE PRINCIPLES:\n- Write code that works, not code that looks pretty\n- Prefer simplicity over cleverness\n- Always handle edge cases and errors\n- Use meaningful variable and function names\n\nBEHAVIOR:\n- Provide complete, runnable solutions\n- Identify the root cause before suggesting fixes\n- Focus on the why not just the what\n\nSTYLE:\n- No emojis unless directly relevant to the code\n- Minimal commentary\n\nCONSTRAINTS:\n- Do not generate thinking or reasoning chains\n- Respond directly with code or solutions',
     {'temperature': 0.6, 'top_p': 0.95, 'max_tokens': 8192}),

    ('charlotte-research', 'Charlotte Research', 'qwen/qwen3.6-35b-a3b',
     '- Today is {{CURRENT_WEEKDAY}}, {{CURRENT_DATE}}.\n- You are Charlotte.\n\nYou are Charlotte, a deep research assistant. You are analytical, thorough, and focused on providing well-sourced, accurate information.\n\nCORE PRINCIPLES:\n- Accuracy over speed\n- Present multiple perspectives on complex topics\n- Distinguish between facts, opinions, and speculation\n\nBEHAVIOR:\n- Provide comprehensive coverage\n- Structure responses with clear headers and sections\n- When uncertain, state limitations\n\nSTYLE:\n- Academic but accessible tone\n- Use bullet points and tables for clarity\n- Summarize key findings\n\nCONSTRAINTS:\n- Do not generate thinking or reasoning chains\n- Respond directly with research findings\n- For time-sensitive information, note when verification is recommended',
     {'temperature': 1.0, 'top_p': 0.95, 'max_tokens': 8192}),

    ('charlotte-ocr', 'Charlotte OCR', 'qwen3-vl-4b-instruct-mlx',
     'You are a specialized OCR and document understanding assistant. Extract, recognize, and structure text from images and documents.\n\nBEHAVIOR:\n- Extract ALL visible text accurately\n- Preserve document structure: headers, columns, tables, lists\n- For tables: output in markdown table format\n\nCONSTRAINTS:\n- Focus solely on text extraction\n- Preserve original formatting',
     {'temperature': 0.3, 'top_p': 0.8, 'max_tokens': 4096}),

    ('charlotte-worker', 'Charlotte Worker', 'qwen/qwen3-1.7b',
     '- Today is {{CURRENT_WEEKDAY}}, {{CURRENT_DATE}}.\n- You are Charlotte.\n\nYou are a background task worker. Generate concise titles, tags, and follow-up questions with zero conversation.\n\nOUTPUT RULES:\n- Generate exactly 2-3 title options, each on its own line\n- Titles: 3-8 words, descriptive\n- No numbering, bullets, or prefixes\n- Never add explanations or commentary\n\nCONSTRAINTS:\n- Output ONLY the titles, one per line\n- No thinking or reasoning chains\n- Be extremely concise',
     {'temperature': 0.3, 'top_p': 0.8, 'max_tokens': 128, 'presence_penalty': 1.5}),
]

for mid, name, base_id, sys_prompt, params in models:
    params['system'] = sys_prompt
    params['function_calling'] = 'native'
    c.execute(
        'INSERT OR REPLACE INTO model (id, user_id, base_model_id, name, params, meta, updated_at, created_at, is_active) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)',
        (mid, USER_ID, base_id, name, json.dumps(params), '{}', now, now),
    )
    print(f'  Created: {name} -> {base_id}')

tts_updates = [
    ('audio.tts.engine', '\"openai\"'),
    ('audio.tts.openai.api_base_url', '\"http://kokoro-tts:8880/v1\"'),
    ('audio.tts.openai.api_key', '\"none\"'),
    ('audio.tts.model', '\"kokoro\"'),
    ('audio.tts.voice', '\"af_heart\"'),
]
for k, v in tts_updates:
    c.execute('INSERT OR REPLACE INTO config (key, value) VALUES (?, ?)', (k, v))
    print(f'  TTS: {k} = {v}')

c.execute(\"UPDATE config SET value = '\"charlotte-worker\"' WHERE key = 'task.model.default'\")
c.execute(\"UPDATE config SET value = '\"charlotte-general\"' WHERE key = 'task.model.external'\")
print('  Task models: default=charlotte-worker, external=charlotte-general')

conn.commit()
conn.close()
print('Done!')
"

echo "Restarting OpenWebUI..."
docker restart $DB_CONTAINER
echo "Setup complete."
