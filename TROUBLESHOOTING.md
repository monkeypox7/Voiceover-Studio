# Voiceover Server - Owner's Guide

This is your copy. The editors get `EDITORS-README.md` instead.

---

## What is actually running

| Thing | Value |
|---|---|
| Software | Kokoro-FastAPI (Kokoro-82M text-to-speech) |
| Exact version | `ghcr.io/remsky/kokoro-fastapi-cpu:v0.2.2` |
| Container name | `kokoro` |
| Port | 8880 |
| Your address | http://localhost:8880/web/studio.html |
| Editors' address | http://10.10.20.64:8880/web/studio.html |
| Backup / old page | http://localhost:8880/web/ |
| All files for this app | `Desktop\Internal Apps\kokoro-voiceover-server\` |

Everything belonging to this tool lives in that one folder:

| File | What it is |
|---|---|
| `EDITORS-README.md` | The guide to send to your video editors |
| `TROUBLESHOOTING.md` | This file, for you |
| `RUN ONCE - Allow Editors On Wifi.cmd` | Double-click once to let editors connect |
| `start-kokoro.ps1` | The script behind the Desktop shortcut |
| `allow-firewall.ps1` | The script behind the RUN ONCE file |
| `web\studio.html` | The Voiceover Studio page the editors use |
| `SERVER-SETUP.md` | How to move the whole thing onto a free always-on Oracle server |
| `DEPLOY - Put Voiceover On A Server.cmd` | Double-click to install it on that server |
| `deploy-to-server.ps1` | The script behind the DEPLOY file |
| `deploy\` | What gets copied to the server: compose file, Caddyfile, installer, the page |
| `SHARE - Voiceover Link For Editors.cmd` | Double-click to put it on the internet for a while |
| `start-tunnel.ps1` | The script behind the SHARE file |
| `VOICEOVER-PASSWORD.txt` | The login editors need for the internet link |
| `gate\Caddyfile` | Settings for the password gate. Do not delete. |
| `tunnel\cloudflared.exe` | The internet link program (Cloudflare, version 2026.7.3) |

The only thing kept outside that folder is the **Start Voiceover Server**
shortcut on your Desktop, so it stays one click away.

It runs inside **Docker Desktop**, which is a program that runs
self-contained mini-computers called *containers*. Ours is named `kokoro`.
You never need to understand more than that.

It is set to restart automatically if it crashes, and Docker is set to
start when you log in, so it survives reboots on its own.

---

## The one-click way to do everything

Double-click **Start Voiceover Server** on your Desktop.

It starts Docker if needed, starts the server if needed, waits until it is
actually ready, then opens the page. It is safe to double-click at any
time, even if everything is already running.

Try this first for any problem. It fixes most things.

---

## About the Voiceover Studio page

The page the editors use is `web\studio.html` in this folder. It is a
single file. The server can only serve pages that are inside the container,
so the shortcut copies that file in every time it runs.

What the page does beyond the original player:

- **45 voices**: 28 current English, 13 older English, 4 Hindi. Dropdown
  filters for language, gender and voice tone.
- **Pitch control**, minus 6 to plus 6 semitones. The model has no pitch
  parameter, so the page asks the server for audio slowed by the pitch
  ratio and then speeds it back up in the browser. Speeding up raises the
  pitch and the two length changes mostly cancel. Verified: plus 4
  semitones moved 185 Hz to 229 Hz. The length still drifts by about a
  tenth, which is why the page says so on screen. Pitched output is always
  WAV because the browser can only write WAV.
- **Custom controls**: speed, pitch, pause length and word stress can each
  be driven by hand. Presets fill them in; touching one switches the style
  to Custom.
- **Per sentence pauses.** The script box is a plain text box as before. Below
  it the script is split into sentences and each gets an exact pause in
  milliseconds. When every pause is left at the default the whole script goes
  to the server in one request and any file type works. As soon as one pause
  differs, or pitch is used, each sentence is fetched separately and joined in
  the browser, so the output is WAV. That is deliberate; the browser can only
  write WAV. Pauses are keyed by the sentence text, so editing one sentence
  does not shift anyone else's pause.
- **A duration estimate** per sentence and for the whole script, from each
  voice's measured characters per second minus the silence the joiner trims.
  Checked against three real generations it came out +2.5, +6.4 and -0.4
  percent, so treat it as within about five percent, not exact.
- **A pronunciation list**, applied to every line before anything else.
  Calilio reads as "KAL-ih-lee-oh" out of the box, so that is the first entry
  anyone should add.
- **Per line preview**, so an editor can fix one sentence without remaking the
  whole script.
- **Sample preview** on every voice, cached after the first play.
- **Delivery styles** (Natural, Conversational, Professional, Formal,
  Narration, Energetic) that set the speed and the amount of pausing.
- **Emphasis marking**: words the user wraps in `*stars*` get a pause
  placed in front of them, which is what makes the voice stress the word.
- **Automatic full stop repair.** This server truncates any line that does
  not end in `.` `!` or `?`. Measured: three lines with no full stops gave
  1.59 seconds of audio, the same three lines with full stops gave 4.59
  seconds. The page adds the missing stops and tells the user it did.
- A clearly labelled Download button, and a light responsive layout.

The voice tone labels are not guesses. All 45 voices were measured on this
server reading one identical sentence (an English one, or a Hindi one for
the Hindi voices), recording median pitch, pitch range in semitones,
reading time, and how breathy it is. Those numbers are baked into the page
in the `VOICE_DATA` list. If the image is ever updated to a version with
different voices, those numbers should be re-measured.

**There is no Nepali voice and there cannot be one.** Kokoro supports nine
languages and Nepali is not among them. The Nepali option in the page shows
the Hindi voices, which will read Devanagari script but with Hindi
pronunciation and a Hindi accent. The page says so on screen. If an editor
needs real Nepali, that needs a different model, not a setting.

That means:

- **Editing the page**: change `web\studio.html`, then double-click
  **Start Voiceover Server**. The new version is copied in and the page
  reloads with your change.
- **After a rebuild**: if you ever delete and recreate the container, the
  Studio page disappears with it. Double-click the Desktop shortcut once
  and it comes straight back.
- **If it ever goes missing** and you want to put it back by hand:

      docker cp "C:\Users\Acer\Desktop\Internal Apps\kokoro-voiceover-server\web\studio.html" kokoro:/app/web/studio.html

- The original player at `http://localhost:8880/web/` is built into the
  image and is always there as a backup.

---

## Letting editors work from outside the office

Double-click **SHARE - Voiceover Link For Editors** in this folder.

A window opens, does its checks, and then prints a link ending in
`.trycloudflare.com`, plus the username and password. The link is already
on your clipboard, so you can paste it straight into a chat.

Send editors the link **and** the login from `VOICEOVER-PASSWORD.txt`.

Three things to tell them:

- The link works from anywhere, including mobile data.
- **You must leave that window open.** Closing it switches the link off.
- The link is different every time you run it. The password never changes.

Nothing here needs an administrator prompt, and it does not need the
firewall rule.

### What it is actually doing

Three pieces, in order:

1. **The password gate** (`voiceover-gate`), a small Caddy container that
   asks for a username and password and then passes the request through to
   the voiceover server. It listens on `127.0.0.1:8890`, which means only
   this computer can talk to it. Nobody on the office wifi or the internet
   reaches it directly.
2. **The tunnel** (`cloudflared.exe`), which makes an outgoing connection
   to Cloudflare and gets a public HTTPS address in return. Nothing is
   opened on your router and no port is forwarded.
3. Cloudflare then forwards visitors from that address, through the tunnel,
   into the password gate.

The script refuses to publish anything if the password gate is not answering
with "401 Unauthorized" to a request with no password. That check exists
because the voiceover server itself has no login of any kind, so the gate is
the only thing protecting it.

### Turning it off

Close the window, or press Ctrl and C in it. The link dies immediately.

The password gate container keeps running in the background. That is fine
and is not exposed to anything, because it only listens on this computer.
To stop it too:

    docker stop voiceover-gate

### If the link does not appear

- Check this computer has working internet.
- Look in `tunnel\tunnel-error.log` for the reason.
- Run it again. Cloudflare sometimes refuses a link and gives one on retry.

### Changing the password

See the instructions at the bottom of `VOICEOVER-PASSWORD.txt`.

---

## How to open a command window

Several fixes below need one. To open it:

1. Press the **Windows key**.
2. Type `powershell`
3. Press **Enter**.

A blue or black window opens. Type the command, press Enter. That is all
"running a command" means.

---

## Check if it is running

    docker ps

You should see a line containing `kokoro` and `Up`, like:

    kokoro   ghcr.io/remsky/kokoro-fastapi-cpu:v0.2.2   Up 2 hours   0.0.0.0:8880->8880/tcp

- If you see `kokoro` and `Up` - it is running and healthy.
- If you see nothing - it is not running. See *Restart* below.
- If you get an error about the docker daemon or a pipe - Docker Desktop
  itself is not running. Start Docker Desktop from the Start menu, wait
  about a minute, then try again.

A second, stronger check - this asks the server itself if it is well:

    curl http://localhost:8880/health

A healthy answer is:

    {"status":"healthy"}

---

## Restart the container

Normal restart:

    docker restart kokoro

Wait about 30 seconds, then check `http://localhost:8880/health`.

If that does not help, stop it and start it fresh:

    docker stop kokoro
    docker start kokoro

---

## View the logs when something breaks

The logs are the server's own diary. They tell you what went wrong.

Last 100 lines:

    docker logs --tail 100 kokoro

Watch it live as you use the page (press **Ctrl + C** to stop watching):

    docker logs -f kokoro

You do not need to understand every line. Look for lines with `Error`,
`Exception`, or `Traceback`. If you need help, copy those lines and send
them on.

---

## Common problems

**The page is very slow to make audio.**
Normal. This runs on the computer's processor, not a graphics card. A few
seconds per sentence is expected. Long scripts take longer. It is not broken.

**Editors cannot reach it but it works on this computer.**
Three things to check, in order:
1. Is this computer awake? Sleep kills it. See *Stop it sleeping* below.
2. Did the firewall rule get added? Double-click
   **RUN ONCE - Allow Editors On Wifi** in this folder and approve the
   Windows prompt. It is safe to run twice; it will just say the rule
   already exists.
3. Has the address changed? See *If the address changes* below.

**An editor says the audio stops early and loses words.**
This is a real bug in this version of the server, not a mistake by them.
Any line of script that does not end in `.` `!` or `?` gets cut short.
The Studio page repairs this automatically and shows an orange note when
it does. If they were using the old player at `/web/`, move them to the
Studio page.

**An editor says they cannot change the voice, or it is stuck on Alloy.**
Their browser is holding an old copy of the page. Tell them to press Ctrl
and F5. The bottom of the page shows a "Page version" which should be
`2026-08-06d` or later. Alloy was the default in the very first version;
the current one defaults to Heart and clicking anywhere on a voice row
selects it. Old saved settings are wiped automatically on first load of a
new version.

**An editor says the voice list is nearly empty.**
A filter is still saved from last time. The **Show all 28 voices** button
under the search box clears all three dropdowns and the search.

**An editor says the voice sounds flat or robotic.**
Three things, in order of impact:
1. The voice. Flat voices sound fake. Tell them to pick one tagged
   **Expressive** in the Voices list. Aoede, Kore, Jadzia, Fenrir and Eric
   are the strongest.
2. The stress. Wrapping a word in `*stars*` puts a pause in front of it so
   the voice lands on it. Without any marked stress, every word gets equal
   weight and it sounds mechanical.
3. The style. **Formal** and **Narration** slow it down and add pauses,
   which reads as more considered.
This model will not match ElevenLabs or other paid cloud services. That is
a limit of a small model running on a CPU, not a setting we can change.

**Something is already using port 8880.**
Find out what:

    Get-NetTCPConnection -LocalPort 8880 -State Listen

Then either close that program, or ask for help. Do not change the port
yourself, or the editors' bookmarks stop working.

**Nothing works and you want a clean slate.**
This deletes the container and builds a new one from the same pinned
version. Your setup is not lost; nothing personal is stored inside it.

    docker rm -f kokoro
    docker run -d --name kokoro --restart always -p 8880:8880 ghcr.io/remsky/kokoro-fastapi-cpu:v0.2.2

Then double-click **Start Voiceover Server** once, to put the Studio page
back inside the fresh container.

---

## Stop it sleeping

If this computer sleeps, the editors lose the tool. To prevent that:

1. Press the Windows key, type `Power & sleep settings`, press Enter.
2. Under **Screen and sleep**, set
   *When plugged in, put my device to sleep after* to **Never**.

Turning the screen off is fine. Sleeping is not.

---

## If the address changes

The address `10.10.20.64` is handed out by the office router and **can
change** after a long power cut or a router restart. If editors suddenly
cannot connect, check the current address:

    ipconfig

Look under your **Wi-Fi** adapter for `IPv4 Address`. Whatever number is
there is the new one. Tell the editors to bookmark:

    http://THAT-NUMBER:8880/web/studio.html

To stop it changing for good, ask whoever manages the office router for a
**DHCP reservation** for this computer. That pins the address permanently.
It is a five-minute job for them.

---

## Updating later - READ THIS BEFORE UPDATING

**Never use `:latest`.** That tag points at whatever the developer pushed
most recently, including half-finished versions. It is the single most
likely way to break this setup. We are pinned to `v0.2.2` deliberately.

To update properly:

**Step 1 - find the new version number.**
Go to https://github.com/remsky/Kokoro-FastAPI/releases and look at the
newest release. You want a version tag like `v0.3.0`. Read what changed.

**Step 2 - download the new version, but do not switch to it yet.**
Replace `v0.3.0` with the real number in all commands below.

    docker pull ghcr.io/remsky/kokoro-fastapi-cpu:v0.3.0

**Step 3 - test it on a spare port first.** This runs the new version
alongside the old one, on port 8881, so nothing breaks for the editors.

    docker run -d --name kokoro-test -p 8881:8880 ghcr.io/remsky/kokoro-fastapi-cpu:v0.3.0

Wait a minute, then open `http://localhost:8881/web` and generate a test
voiceover. If it works, continue. If it does not, skip to *Abandon the
update* below.

**Step 4 - remove the test copy.**

    docker rm -f kokoro-test

**Step 5 - switch the real one over.**

    docker rm -f kokoro
    docker run -d --name kokoro --restart always -p 8880:8880 ghcr.io/remsky/kokoro-fastapi-cpu:v0.3.0

**Step 6 - put the Studio page back.** The new container does not have it
yet. Double-click **Start Voiceover Server** on the Desktop, then confirm
`http://localhost:8880/web/studio.html` loads and generates audio.

**Step 7 - update the version number** in `start-kokoro.ps1` in this folder
(the line beginning `$Image`) so the Desktop shortcut stays correct.
Also update the version number written at the top of this file.

**Abandon the update / go back.** If the new version misbehaves at any
point, this puts you back exactly where you are today:

    docker rm -f kokoro kokoro-test
    docker run -d --name kokoro --restart always -p 8880:8880 ghcr.io/remsky/kokoro-fastapi-cpu:v0.2.2

Then double-click **Start Voiceover Server** once to reinstall the Studio
page.

The old version stays on the disk, so going back is instant and always
works.

---

## A note on security

The voiceover server itself has **no password**. Anyone who can reach port
8880 can use it. That shapes everything below.

**On the office wifi.** The firewall rule is deliberately limited to the
local network, so only devices on the office wifi can reach port 8880, not
the wider internet. That is the right trade-off for a small team tool, but
it does mean anyone on the office wifi, including guests on the same
network, can use it.

**On the internet.** The SHARE script does not expose port 8880. It exposes
a password gate that sits in front of it, and only while you have that
window open. That is why:

- **Do not remove the `basic_auth` block** from `gate\Caddyfile`. It is the
  only thing between the internet and a server with no login.
- **Do not post the link publicly.** Addresses like this get found by
  scanners. The password is what stops them, so treat it like a real one.
- **Close the window when the editors are done.** A link that is off cannot
  be attacked at all.
- If you think the password has leaked, change it (instructions in
  `VOICEOVER-PASSWORD.txt`) and send editors the new one.

**Still do not port-forward 8880 on the router.** The tunnel exists so that
you never have to. Port forwarding would put the unprotected server itself
on the internet, which is a different and much worse thing.
