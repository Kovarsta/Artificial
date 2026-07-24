"""SearXNG MCP Server — wraps local SearXNG/Vane instance as MCP tools."""

import json
import os
import sys
import urllib.request
import urllib.parse
from mcp.server.fastmcp import FastMCP

SEARXNG_URL = os.environ.get("SEARXNG_URL", "http://localhost:8080")

mcp = FastMCP("searxng")


@mcp.tool()
def search(query: str, categories: str = "general", max_results: int = 5) -> str:
    """Search the web via SearXNG.

    Args:
        query: Search query string.
        categories: Comma-separated categories (general, images, news, videos, music, files, it, science, social media).
        max_results: Maximum number of results to return.
    """
    params = urllib.parse.urlencode({
        "q": query,
        "categories": categories,
        "format": "json",
    })
    url = f"{SEARXNG_URL}/search?{params}"
    try:
        req = urllib.request.Request(url, headers={"Accept": "application/json"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read())
        results = data.get("results", [])[:max_results]
        if not results:
            return f"No results found for: {query}"
        out = []
        for i, r in enumerate(results, 1):
            title = r.get("title", "No title")
            link = r.get("url", "")
            snippet = r.get("content", "")[:200]
            out.append(f"{i}. {title}\n   {link}\n   {snippet}")
        return "\n\n".join(out)
    except Exception as e:
        return f"Search error: {e}"


def main():
    mcp.run(transport="stdio")


if __name__ == "__main__":
    main()
