"""Charlotte Discord Bot — agentic personal assistant.

Responds only to YOUR Discord user ID in DMs.
Uses LMStudio for LLM, with tools for calendar, search, fetch, and brain dump.
"""

import os
import json
import asyncio
from datetime import datetime, timedelta

import discord
import httpx
from dotenv import load_dotenv
from openai import AsyncOpenAI
from apscheduler.schedulers.asyncio import AsyncIOScheduler

load_dotenv()

# --- Config ---
DISCORD_TOKEN = os.environ["DISCORD_TOKEN"]
YOUR_DISCORD_ID = int(os.environ["YOUR_DISCORD_ID"])
LMSTUDIO_URL = os.environ.get("LMSTUDIO_URL", "http://mac.lan:1234/v1")
LMSTUDIO_MODEL = os.environ.get("LMSTUDIO_MODEL", "qwen/qwen3.6-35b-a3b")
SEARXNG_URL = os.environ.get("SEARXNG_URL", "http://localhost:8081")
OPENWEBUI_URL = os.environ.get("OPENWEBUI_URL", "http://localhost:8080")
OPENWEBUI_API_KEY = os.environ.get("OPENWEBUI_API_KEY", "")
OPENWEBUI_KB_NAME = os.environ.get("OPENWEBUI_KB_NAME", "brain-dump")

SYSTEM_PROMPT = """You are Charlotte, a personal AI assistant in a Discord DM.

You have these tools:
- search: web search via SearXNG
- fetch: fetch and read a URL
- brain_dump: store text in the user's personal knowledge base
- brain_search: search the user's personal knowledge base
- check_calendar: check Google Calendar events (today, tomorrow, this week)

BEHAVIOR:
- Be concise. This is a Discord DM, not an essay.
- Use tools when needed. Don't ask permission — just do it.
- For brain dumps, confirm what was stored briefly.
- For calendar, summarize events clearly.
- For web stuff, give the key points, not the full page.
- If unsure, ask. Don't hallucinate.
- Use the current date/time for context: {current_datetime}
"""

# --- LLM Client ---
llm = AsyncOpenAI(base_url=LMSTUDIO_URL, api_key="lmstudio")

# --- Tools (OpenAI function calling format) ---
TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "search",
            "description": "Search the web via SearXNG",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Search query"},
                },
                "required": ["query"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "fetch",
            "description": "Fetch a URL and return its content",
            "parameters": {
                "type": "object",
                "properties": {
                    "url": {"type": "string", "description": "URL to fetch"},
                },
                "required": ["url"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "brain_dump",
            "description": "Store text in the user's personal knowledge base for later retrieval",
            "parameters": {
                "type": "object",
                "properties": {
                    "text": {"type": "string", "description": "Text to store"},
                    "title": {"type": "string", "description": "Optional title for the note"},
                },
                "required": ["text"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "brain_search",
            "description": "Search the user's personal knowledge base",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "What to search for"},
                },
                "required": ["query"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "check_calendar",
            "description": "Check Google Calendar events for a given time range",
            "parameters": {
                "type": "object",
                "properties": {
                    "range": {
                        "type": "string",
                        "enum": ["today", "tomorrow", "this_week", "next_week"],
                        "description": "Time range to check",
                    },
                },
                "required": ["range"],
            },
        },
    },
]

# --- Tool Implementations ---


async def tool_search(query: str) -> str:
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.get(
            f"{SEARXNG_URL}/search",
            params={"q": query, "format": "json"},
        )
        data = resp.json()
        results = data.get("results", [])[:5]
        if not results:
            return "No results found."
        lines = []
        for r in results:
            lines.append(f"- **{r.get('title', '')}**\n  {r.get('url', '')}\n  {r.get('content', '')[:200]}")
        return "\n".join(lines)


async def tool_fetch(url: str) -> str:
    async with httpx.AsyncClient(timeout=15, follow_redirects=True) as client:
        resp = await client.get(url, headers={"User-Agent": "CharlotteBot/1.0"})
        text = resp.text[:8000]
        return text


async def tool_brain_dump(text: str, title: str = "") -> str:
    if not OPENWEBUI_API_KEY:
        return "OpenWebUI API key not configured."
    doc_name = title or f"dump-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
    async with httpx.AsyncClient(timeout=30) as client:
        # Upload as file
        files = {"file": (f"{doc_name}.txt", text.encode(), "text/plain")}
        resp = await client.post(
            f"{OPENWEBUI_URL}/api/v1/files/upload",
            headers={"Authorization": f"Bearer {OPENWEBUI_API_KEY}"},
            files=files,
        )
        if resp.status_code != 200:
            return f"Upload failed: {resp.status_code}"
        file_data = resp.json()
        file_id = file_data.get("id", "")
        # Add to knowledge base
        resp2 = await client.post(
            f"{OPENWEBUI_URL}/api/v1/knowledge/{OPENWEBUI_KB_NAME}/file/add",
            headers={"Authorization": f"Bearer {OPENWEBUI_API_KEY}"},
            json={"file_id": file_id},
        )
        if resp2.status_code == 200:
            return f"Stored: {doc_name}"
        # Try creating KB if it doesn't exist
        await client.post(
            f"{OPENWEBUI_URL}/api/v1/knowledge/create",
            headers={"Authorization": f"Bearer {OPENWEBUI_API_KEY}"},
            json={"name": OPENWEBUI_KB_NAME, "description": "Personal brain dump"},
        )
        await client.post(
            f"{OPENWEBUI_URL}/api/v1/knowledge/{OPENWEBUI_KB_NAME}/file/add",
            headers={"Authorization": f"Bearer {OPENWEBUI_API_KEY}"},
            json={"file_id": file_id},
        )
        return f"Stored: {doc_name} (created new KB)"


async def tool_brain_search(query: str) -> str:
    if not OPENWEBUI_API_KEY:
        return "OpenWebUI API key not configured."
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.post(
            f"{OPENWEBUI_URL}/api/v1/knowledge/{OPENWEBUI_KB_NAME}/search",
            headers={"Authorization": f"Bearer {OPENWEBUI_API_KEY}"},
            json={"query": query, "k": 3},
        )
        if resp.status_code != 200:
            return f"Search failed: {resp.status_code}"
        results = resp.json()
        if not results:
            return "Nothing found in your knowledge base."
        lines = []
        for r in results:
            lines.append(f"- {r.get('content', '')[:300]}")
        return "\n".join(lines)


async def tool_check_calendar(range: str) -> str:
    # Placeholder — needs Google Calendar OAuth setup
    # When configured, this will call the Google Calendar API
    return f"Calendar integration not yet configured. Set up GOOGLE_CALENDAR_CREDENTIALS in .env to enable."


TOOL_MAP = {
    "search": lambda args: tool_search(args["query"]),
    "fetch": lambda args: tool_fetch(args["url"]),
    "brain_dump": lambda args: tool_brain_dump(args["text"], args.get("title", "")),
    "brain_search": lambda args: tool_brain_search(args["query"]),
    "check_calendar": lambda args: tool_check_calendar(args["range"]),
}

# --- Conversation history (per user, in-memory) ---
conversations: dict[int, list] = {}
MAX_HISTORY = 20


def get_history(user_id: int) -> list:
    if user_id not in conversations:
        conversations[user_id] = []
    return conversations[user_id]


def add_to_history(user_id: int, role: str, content: str):
    history = get_history(user_id)
    history.append({"role": role, "content": content})
    if len(history) > MAX_HISTORY:
        conversations[user_id] = history[-MAX_HISTORY:]


# --- Agentic Loop ---


async def agent_loop(user_id: int, message: str) -> str:
    history = get_history(user_id)
    add_to_history(user_id, "user", message)

    system = SYSTEM_PROMPT.format(
        current_datetime=datetime.now().strftime("%A, %B %d, %Y %H:%M")
    )
    messages = [{"role": "system", "content": system}] + history[-MAX_HISTORY:]

    max_iterations = 5
    for _ in range(max_iterations):
        response = await llm.chat.completions.create(
            model=LMSTUDIO_MODEL,
            messages=messages,
            tools=TOOLS,
            tool_choice="auto",
        )
        choice = response.choices[0]

        if choice.message.tool_calls:
            # LLM wants to call tools
            messages.append(choice.message)
            for tool_call in choice.message.tool_calls:
                fn_name = tool_call.function.name
                fn_args = json.loads(tool_call.function.arguments)
                try:
                    result = await TOOL_MAP[fn_name](fn_args)
                except Exception as e:
                    result = f"Error: {e}"
                messages.append({
                    "role": "tool",
                    "tool_call_id": tool_call.id,
                    "content": str(result),
                })
            # Continue loop — LLM will process tool results
        else:
            # LLM gave a final text response
            reply = choice.message.content or ""
            add_to_history(user_id, "assistant", reply)
            return reply

    return "Reached max tool iterations. Try a simpler request."


# --- Discord Bot ---

intents = discord.Intents.default()
intents.message_content = True
bot = discord.Client(intents=intents)


@bot.event
async def on_ready():
    print(f"Charlotte online as {bot.user}")
    # Schedule daily reminder check
    scheduler = AsyncIOScheduler()
    scheduler.add_job(daily_reminder, "cron", hour=8, minute=0)
    scheduler.start()


async def daily_reminder():
    """Check calendar and send morning briefing."""
    channel = bot.get_user(YOUR_DISCORD_ID)
    if channel:
        try:
            result = await tool_check_calendar("today")
            await channel.send(f"Good morning! Here's your day:\n{result}")
        except Exception:
            pass


@bot.event
async def on_message(message: int):
    # Guard: only respond to DMs from you
    if message.author.id != YOUR_DISCORD_ID:
        return
    if not isinstance(message.channel, discord.DMChannel):
        return

    async with message.channel.typing():
        reply = await agent_loop(message.author.id, message.content)

    # Split long messages (Discord limit: 2000 chars)
    for i in range(0, len(reply), 2000):
        await message.channel.send(reply[i : i + 2000])


if __name__ == "__main__":
    bot.run(DISCORD_TOKEN)
