# Kanzo on Railway

Kanzo — a self-hosted, sharable kanban board for humans and AI agents, with a built-in MCP server. Deploy on Railway with one click.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template?template=PENDING)

This repository packages the official [Kanzo](https://github.com/emanuele-em/kanzo) v0.4.1 release binary (AGPL-3.0) for Railway. It is an independent community packaging, not affiliated with or endorsed by the Kanzo project. Source for the packaged binary: upstream tag v0.4.1; packaging source: this repository.

## What you get

- One small container: the Kanzo binary (board + MCP over HTTP at `/mcp`) on `127.0.0.1:4242`, Caddy on the public port, and a tiny login gate.
- **Login.** Kanzo deliberately has no logins ("anyone who can reach the port can read and change the board"), so the board is behind a login page: user `admin`, password = the generated `KANZO_PASSWORD` variable.
- **MCP for remote agents** at `https://<domain>/mcp` with the header `Authorization: Bearer <KANZO_PASSWORD>`.
- **Persistent board** on a Railway volume at `/data` (`KANZO_HOME`): `kanzo.db` + `config.toml`.

## Connect an agent

Claude Code:

```bash
claude mcp add --transport http kanzo https://<domain>/mcp --header "Authorization: Bearer <KANZO_PASSWORD>"
```

Cursor / other clients (`mcp.json`):

```json
{ "mcpServers": { "kanzo": { "url": "https://<domain>/mcp", "headers": { "Authorization": "Bearer <KANZO_PASSWORD>" } } } }
```

## Variables

| Variable | Default | Purpose |
|---|---|---|
| `KANZO_PASSWORD` | generated | Login password for the board, and the Bearer token for `/mcp` |
| `KANZO_USERNAME` | `admin` (image default) | Login user name |
| `KANZO_HOME` | `/data` (image default) | Data folder on the volume |

## Notes

- Kanzo's **Share this board** / **Join** features are for machines on one LAN/VPN. On Railway, share mode would only open the raw port to the project's private network, and the board is reset to `listen = "127.0.0.1"` on every boot. Use the public URL + login (and `/mcp` with the Bearer token) to share instead.
- Back up `/data/kanzo.db`. `kanzo export` output is available from a Railway shell (`kanzo --home /data export`).
- To upgrade, bump `KANZO_VERSION` / `KANZO_SHA256` in the `Dockerfile`; GitHub Actions rebuilds `ghcr.io/onepush-dev/kanzo`.
