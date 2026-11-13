# telethon-docker

Container image of a small [Telethon](https://codeberg.org/Lonami/Telethon) service that lets a backend
read a Telegram user's contact list (Telegram has no "read my contacts" permission for apps; only a logged-in user account can).
Published as `ghcr.io/wentthefox/telethon-docker:sha-<7 hex>` (amd64 + arm64) on every push to `main`; the commit is the version.

- **Stateless**: every request carries the owner's session string and the reply carries it back; nothing is written to disk.
- Python 3.13, aiohttp + Telethon (both pinned in `requirements.txt`), runs as uid 10001. `GET /healthz` needs no auth; every other
  route (`POST /v1/login/start|code|password`, `/v1/contacts`, `/v1/photos`, `/v1/logout`) needs `Authorization: Bearer <token>`.
- Env: `TELEGRAM_API_ID`, `TELEGRAM_API_HASH` (an app registered at https://my.telegram.org), `TELEGRAM_SIDECAR_TOKEN`; optional `PORT` (8080).
  It refuses to start without the first three.
- It handles phone numbers, login codes and full-account sessions: keep it reachable only from its backend, never behind an Ingress, never log bodies.

Local check:

    docker build -t telethon-docker .
    tests/smoke.sh telethon-docker

## License

MIT, see `LICENSE`. Telethon is MIT licensed by its authors.
