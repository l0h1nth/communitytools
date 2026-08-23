# Transilience Vulnerability MCP Server

A local MCP server that exposes the [Transilience](https://transilienceapi.com)
vulnerability enrichment API to Codex and other MCP clients.

## Tools

- **`enrich_cve(cve_id, force_refresh=False)`** — full CVE payload with CVSS,
  EPSS, KEV status, impact taxonomy, and vendor remediation data.
- **`bulk_enrich_cves(cve_ids, force_refresh=False)`** — summarized enrichment
  for prioritization; full payloads remain in the local cache.
- **`get_cached_cve(cve_id, summarized=False)`** — read a cached CVE without an
  API call.
- **`cache_stats()`** — cache size, location, and sample entries.

The server includes a sliding-window rate limiter, disk cache, retry handling,
and strict API-key isolation. The key is read only from
`TRANSILIENCE_API_KEY`; it is never logged or returned in tool output.

## Requirements

- Python 3.10+
- A Transilience API key from <https://transilienceapi.com>

## Install

```bash
cd mcp/transilience-vuln
python -m venv .venv
source .venv/bin/activate
pip install -e .
```

On Windows, activate `.venv\Scripts\Activate.ps1` instead.

## Configure Codex

The repository root already includes `.codex/config.toml` with a project-scoped
`transilience_vuln` server entry. Export the key in the shell that launches
Codex, then start Codex from the repository root:

```bash
export TRANSILIENCE_API_KEY="your-actual-key-here"
codex
```

For a standalone checkout, add this to `.codex/config.toml`, replacing the
paths with absolute paths:

```toml
[mcp_servers.transilience_vuln]
command = "/ABSOLUTE/PATH/TO/communitytools/mcp/transilience-vuln/.venv/bin/python"
args = ["/ABSOLUTE/PATH/TO/communitytools/mcp/transilience-vuln/server.py"]
env_vars = ["TRANSILIENCE_API_KEY", "TRANSILIENCE_RATE_LIMIT", "TRANSILIENCE_CACHE_DIR"]
startup_timeout_sec = 15
tool_timeout_sec = 60
```

Keep the API key in the process environment, never in a checked-in config file.
Use `/mcp` in Codex to inspect the configured server and its tools.

## Verify it loaded

In a new Codex thread, ask: *“What MCP tools do you have for vulnerability
enrichment?”* You should see `enrich_cve`, `bulk_enrich_cves`,
`get_cached_cve`, and `cache_stats`.

If they do not show up, inspect the server with `/mcp` and run it directly from
the activated virtual environment. The most common failure is an incorrect
path to Python or `server.py`.

## Smoke test

The server communicates over stdio and waits for JSON-RPC input:

```bash
TRANSILIENCE_API_KEY=your-key python server.py
```

You should see `Starting transilience-vuln MCP server on stdio` on stderr.
After `pip install -e .`, the console script also works:

```bash
TRANSILIENCE_API_KEY=your-key transilience-vuln-mcp
```

## Environment variables

| Variable | Required | Default | Notes |
| --- | --- | --- | --- |
| `TRANSILIENCE_API_KEY` | yes | — | `x-api-key` from transilienceapi.com |
| `TRANSILIENCE_CACHE_DIR` | no | `~/.transilience-mcp-cache` | Local CVE JSON cache |
| `TRANSILIENCE_RATE_LIMIT` | no | `18` | Requests/minute; free tier is 20 |

## Troubleshooting

**429 errors.** Set `TRANSILIENCE_RATE_LIMIT=15` and restart Codex.

**Cache too big.** The cache is JSON in `~/.transilience-mcp-cache`; remove it
when you want a clean cache.

**Stale data.** Pass `force_refresh=true` to `enrich_cve` or
`bulk_enrich_cves`.

## License

MIT. See the repo-level [LICENSE](../../LICENSE).
