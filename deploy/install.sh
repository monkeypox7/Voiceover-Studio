#!/usr/bin/env bash
# Sets up Voiceover Studio on a fresh Linux server.
#
# Run it on the server, from the folder this file is in:
#     sudo bash install.sh
#
# Safe to run again later. It will reuse the settings it wrote last time.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

say()  { printf '\n\033[36m%s\033[0m\n' "$*"; }
warn() { printf '\n\033[33m%s\033[0m\n' "$*"; }
die()  { printf '\n\033[31m%s\033[0m\n\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "Run this with sudo:   sudo bash install.sh"

# ------------------------------------------------------------------ docker
if ! command -v docker >/dev/null 2>&1; then
  say "Installing Docker. This takes a couple of minutes..."
  curl -fsSL https://get.docker.com | sh
fi
docker compose version >/dev/null 2>&1 || die "Docker Compose is missing. Install Docker from https://get.docker.com and try again."
systemctl enable --now docker >/dev/null 2>&1 || true
say "Docker is ready."

# ------------------------------------------------------------------ config
if [ -f .env ]; then
  say "Using the settings already in .env"
  # shellcheck disable=SC1091
  . ./.env
else
  say "First run. Two questions."
  echo
  echo "  1. The web address this will live at."
  echo "     It must already point at this server's IP."
  echo "     A free one from duckdns.org is fine, for example  calilio-voice.duckdns.org"
  echo
  read -r -p "  Address: " SITE_ADDRESS
  [ -n "$SITE_ADDRESS" ] || die "No address given, nothing was installed."

  echo
  echo "  2. The password your editors will type. Leave blank to have one made for you."
  read -r -p "  Password: " AUTH_PLAIN
  if [ -z "$AUTH_PLAIN" ]; then
    # Read a fixed block and filter it afterwards. Piping /dev/urandom into
    # head kills the pipeline with SIGPIPE, which under `set -o pipefail`
    # takes the whole installer down.
    raw=""
    while [ "${#raw}" -lt 16 ]; do
      raw="$raw$(head -c 512 /dev/urandom | LC_ALL=C tr -dc 'a-hjkmnp-z2-9' || true)"
    done
    AUTH_PLAIN="${raw:0:4}-${raw:4:4}-${raw:8:4}-${raw:12:4}"
  fi

  AUTH_USER="editors"
  say "Hashing the password..."
  AUTH_HASH="$(docker run --rm caddy:2.10-alpine caddy hash-password --plaintext "$AUTH_PLAIN")"

  # A bcrypt hash is full of dollar signs and Docker Compose treats those as
  # variables. If the salt happens to start with a letter the hash silently
  # turns into an empty string and the password stops working. Double them.
  AUTH_HASH_ESCAPED="${AUTH_HASH//\$/\$\$}"

  cat > .env <<EOF
SITE_ADDRESS=$SITE_ADDRESS
AUTH_USER=$AUTH_USER
AUTH_HASH=$AUTH_HASH_ESCAPED
EOF
  chmod 600 .env

  cat > LOGIN.txt <<EOF
VOICEOVER STUDIO - LOGIN FOR EDITORS

Address:   https://$SITE_ADDRESS
Username:  $AUTH_USER
Password:  $AUTH_PLAIN

Keep this file. The password is only stored here in plain form; the server
holds a one way hash of it that cannot be read back.

To change it later:
  docker run --rm caddy:2.10-alpine caddy hash-password --plaintext "new password"
then put the new line into .env as AUTH_HASH, update this file, and run:
  docker compose up -d --force-recreate gate
EOF
  chmod 600 LOGIN.txt
fi

[ -f web/studio.html ] || die "web/studio.html is missing. Copy the whole deploy folder up, not just install.sh."

# ---------------------------------------------------------------- firewall
# Oracle Cloud's Ubuntu image ships with an iptables rule that rejects
# everything except SSH, which silently blocks the web ports even after you
# open them in the Oracle console. This opens them on the machine itself.
open_port() {
  port="$1"
  if command -v iptables >/dev/null 2>&1; then
    if ! iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null; then
      iptables -I INPUT -p tcp --dport "$port" -m conntrack --ctstate NEW -j ACCEPT 2>/dev/null \
        || iptables -I INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null || true
    fi
  fi
  if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
    ufw allow "$port/tcp" >/dev/null 2>&1 || true
  fi
}

say "Opening ports 80 and 443 on the machine..."
open_port 80
open_port 443
if command -v netfilter-persistent >/dev/null 2>&1; then
  netfilter-persistent save >/dev/null 2>&1 || true
elif [ -d /etc/iptables ]; then
  iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
else
  DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent >/dev/null 2>&1 || true
  netfilter-persistent save >/dev/null 2>&1 || true
fi
say "Ports opened."
warn "Oracle Cloud also blocks them one level up. In the Oracle console open"
warn "your instance, click the subnet, click the security list, and add two"
warn "ingress rules for 0.0.0.0/0 TCP port 80 and TCP port 443."

# ------------------------------------------------------------------- start
say "Starting. The first run downloads about 5 GB, so give it a few minutes."
docker compose pull
docker compose up -d

say "Waiting for the voice engine to come up..."
ready=0
for _ in $(seq 1 60); do
  if docker compose exec -T kokoro python -c "import urllib.request;urllib.request.urlopen('http://localhost:8880/health')" >/dev/null 2>&1; then
    ready=1; break
  fi
  sleep 5
done
[ "$ready" -eq 1 ] || { docker compose logs --tail 40 kokoro; die "The voice engine did not start. The log above says why."; }
say "Voice engine is up."

# Refuse to leave it open. The engine has no login of its own, so if the gate
# is not asking for a password we would be publishing it to the whole internet.
say "Checking the password gate..."

# A bcrypt hash is exactly 60 characters and starts with $2. Checking only the
# prefix is not enough: a hash chewed up by variable expansion often survives as
# "$2a$14", which still starts with $2 but is not a password any more.
live_hash="$(docker compose exec -T gate printenv AUTH_HASH 2>/dev/null | tr -d '\r\n' || true)"
hash_ok=1
[ "${#live_hash}" -ge 55 ] || hash_ok=0
[ "${live_hash#\$2}" != "$live_hash" ] || hash_ok=0
if [ "$hash_ok" -ne 1 ]; then
  docker compose down >/dev/null 2>&1 || true
  die "SAFETY STOP. The password did not reach the gate intact (it arrived as '$live_hash', ${#live_hash} characters, expected 60). Everything was shut down again so nothing is exposed. Check the AUTH_HASH line in .env has every dollar sign doubled."
fi

# Capture first, then look. Piping into `grep -q` makes grep exit early, which
# SIGPIPEs caddy and, under `set -o pipefail`, looks like a failure even when
# the match was found.
adapted="$(docker compose exec -T gate caddy adapt --config /etc/caddy/Caddyfile --adapter caddyfile 2>/dev/null || true)"
case "$adapted" in
  *http_basic*) : ;;
  *)
    docker compose down >/dev/null 2>&1 || true
    die "SAFETY STOP. The password gate is not switched on in Caddyfile, so everything was shut down again. The basic_auth block must not be removed."
    ;;
esac
say "Password gate is on and the password reached it intact."

echo
echo "============================================================"
echo "  DONE"
echo "============================================================"
echo
echo "  Send your editors:"
echo
echo "     https://$SITE_ADDRESS"
echo
echo "  The username and password are in:  $HERE/LOGIN.txt"
echo
echo "  The first visit may take a minute while the HTTPS certificate"
echo "  is issued. After that it is instant."
echo
echo "  This runs on its own from now on. It restarts itself if it"
echo "  crashes and it comes back after the server reboots."
echo
