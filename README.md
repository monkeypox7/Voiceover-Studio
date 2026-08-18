# Voiceover Studio

A browser-based text-to-speech studio for the Calilio video editors. Paste a
script, pick a voice, get an audio file back. It runs the
[Kokoro-FastAPI](https://github.com/remsky/Kokoro-FastAPI) engine behind a
password gate, so the whole thing is two containers and one HTML page.

Nothing here calls a paid API. The voices are generated locally by the
Kokoro-82M model.

## What is in this repo

| Path | What it is |
| --- | --- |
| `web/studio.html` | The whole editor UI. One self-contained page, no build step. |
| `gate/Caddyfile.example` | Password gate for running it on a PC. Copy to `gate/Caddyfile`. |
| `deploy/` | Server version: docker-compose, HTTPS Caddyfile, and `install.sh`. |
| `start-kokoro.ps1` | Starts the containers on a Windows PC. |
| `start-tunnel.ps1` | Publishes a temporary public link over a Cloudflare quick tunnel. |
| `allow-firewall.ps1` | Opens port 8880 so the office wifi can reach it. Needs admin. |
| `deploy-to-server.ps1` | Copies `deploy/` to a server over SSH and runs the installer. |
| `EDITORS-README.md` | Plain-language guide written for the editors, not for developers. |
| `TROUBLESHOOTING.md` | Symptom-by-symptom fixes. |
| `SERVER-SETUP.md` | How to create the always-on server. |

## Architecture

```
browser --> gate (Caddy)  --> kokoro (Kokoro-FastAPI)
            password + HTTPS   voice engine, port 8880
```

The gate is the only part exposed. **Kokoro itself has no authentication of
any kind**, so it must never be published directly. On a server it is not
even port-mapped - it is only reachable over the private container network.

Pinned images, deliberately. Do not move either to `:latest`:

- `ghcr.io/remsky/kokoro-fastapi-cpu:v0.2.2`
- `caddy:2.10-alpine`

## Run it on a Windows PC

1. Install Docker Desktop and start it.
2. Copy `gate/Caddyfile.example` to `gate/Caddyfile`.
3. Generate a password hash and paste it into that copy:
   ```
   docker run --rm caddy:2.10-alpine caddy hash-password --plaintext "your password"
   ```
4. Run `start-kokoro.ps1`.
5. Open http://localhost:8880/web/studio.html

To hand a temporary internet link to someone outside the office, run
`start-tunnel.ps1`. It downloads nothing and needs no account, but the address
changes every single time it starts.

## Run it on a server (recommended for always-on)

See `SERVER-SETUP.md`. In short:

1. Point a domain or subdomain at the server's IP.
2. Copy the `deploy/` folder to the server.
3. Run `install.sh`. It writes a `.env`, generates the password hash, and
   brings up docker-compose. Caddy then gets a free Let's Encrypt certificate
   for the domain automatically.

Sizing: the engine wants roughly 2 GB of RAM and is CPU-bound. Two shared
vCPUs generate faster than real time for normal scripts.

## Security notes

- The password gate is the only protection. Do not remove the `basic_auth`
  block, and do not port-forward 8880 to the internet.
- `gate/Caddyfile`, `VOICEOVER-PASSWORD.txt` and `.env` are gitignored because
  they contain live credentials. Keep it that way. This repository is public.
- The bcrypt hash is not a safe thing to publish either. Publishing it lets
  anyone attempt an offline crack at their own pace.
- Rotate the password by regenerating the hash and restarting the gate:
  ```
  docker restart voiceover-gate
  ```

## Licence

The Kokoro model and Kokoro-FastAPI are Apache-2.0. The Studio page and the
scripts in this repository are internal Calilio tooling.
