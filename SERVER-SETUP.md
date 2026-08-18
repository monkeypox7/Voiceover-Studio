# Moving Voiceover Studio onto a free Oracle server

Right now the tool lives on your computer. That means it only works while your
computer is switched on, and you have to keep a window open to share it.

This guide moves it onto a free computer in Oracle's data centre that never
sleeps. After that:

- It is on all the time, whether or not your computer is.
- Your two editors get **one fixed web address** and a password. Nothing to
  install, no wifi requirement, works from home and from phones.
- The address never changes.
- You never have to run anything again.
- It costs nothing.

Everything needed is already in the `deploy` folder next to this file.

Set aside about an hour for the first time. Most of it is waiting.

---

## What you are getting

Oracle's "Always Free" tier includes an ARM machine with **4 processor cores
and 24 GB of memory**, free permanently. That is more powerful than your
office PC for this job. The voice engine has an ARM version, so it runs
natively, and it needs about 4 GB, so there is plenty of room.

Two honest warnings before you start:

1. **Signup asks for a credit card.** It is an identity check. You are not
   charged as long as you stay on Always Free. Do not upgrade when it offers.
2. **The free machines are often full.** You may get "Out of host capacity"
   when you try to create it. That is normal. Try a different availability
   domain in the dropdown, or try again a few hours later. It usually works
   within a day or two.

If you get tired of retrying, tell me and I will switch you to a paid server
that costs about EUR 3.79 a month and works immediately. The install is
identical.

---

## Step 1 - make the Oracle account

1. Go to https://www.oracle.com/cloud/free/ and press Start for free.
2. Fill in the details. **Choose your home region carefully - it cannot be
   changed later.** Pick one near Nepal, for example Mumbai, Singapore or
   Hyderabad.
3. Enter the card when asked. Confirm the email.

Signup can take 15 minutes to be approved.

---

## Step 2 - create the machine

1. In the Oracle console, open the menu and go to **Compute**, then
   **Instances**, then **Create instance**.
2. **Image and shape**, press Edit:
   - Image: **Canonical Ubuntu 24.04**
   - Shape: press Change shape, choose **Ampere**, then
     **VM.Standard.A1.Flex**
   - Set it to **4 OCPUs** and **24 GB memory**. That is the whole free
     allowance.
   - Anything labelled "Always Free eligible" is what you want.
3. **Networking**: leave the defaults. Make sure **Assign a public IPv4
   address** is on.
4. **Add SSH keys**: choose **Generate a key pair for me**, then press
   **Save private key**. It downloads a file ending in `.key`.
   **Keep that file.** You cannot download it again and you cannot get in
   without it.
5. Press **Create**.

If it says **Out of host capacity**, change the Availability Domain in the
dropdown and press Create again. If all of them are full, wait a few hours.

When it finishes, the page shows a **Public IP address**. Write it down.

---

## Step 3 - open the two web ports in Oracle

Oracle blocks everything by default. The installer opens the ports on the
machine itself, but you have to open them in Oracle's own firewall too.

1. On your instance page, under Primary VNIC, click the **subnet** link.
2. Click the **security list** (usually "Default Security List for ...").
3. Press **Add Ingress Rules** and add these two:

   | Source CIDR | IP Protocol | Destination Port Range |
   | --- | --- | --- |
   | 0.0.0.0/0 | TCP | 80 |
   | 0.0.0.0/0 | TCP | 443 |

4. Save.

If you skip this, the address will simply never load and nothing will explain
why. It is the single most common mistake with Oracle.

---

## Step 4 - get a web address

The tool needs a name, not just a number, so the browser shows a padlock.

**If you already own a domain**, point an A record at the server's IP and skip
ahead.

**If you do not**, get a free one:

1. Go to https://www.duckdns.org
2. Sign in with a Google or GitHub account.
3. Type a name, for example `calilio-voice`, and press add domain.
4. Paste the server's public IP into the box next to it and press update.

Your address is now `calilio-voice.duckdns.org`, free and permanent.

Wait five minutes before the next step so the name spreads.

---

## Step 5 - install it

On your own computer, double-click:

    DEPLOY - Put Voiceover On A Server.cmd

It asks four things:

- the server's **public IP address**
- the **user name** - press Enter, `ubuntu` is right for Oracle
- the **key file** you downloaded in step 2 - you can drag the file into the
  window
- then, on the server, the **web address** from step 4 and a **password** for
  your editors (leave the password blank to have a strong one made for you)

Then it copies everything up, downloads about 5 GB and starts. Five to ten
minutes.

When it finishes it prints the address, username and password. They are also
saved on the server in `/opt/voiceover/LOGIN.txt`.

The very first visit takes an extra minute while the HTTPS certificate is
issued. After that it is instant.

---

## Step 6 - hand it to your editors

Send both of them:

- the address, for example `https://calilio-voice.duckdns.org`
- username `editors`
- the password

That is everything. No install, no setup, no wifi requirement.

Send them `EDITORS-README.md` too, which explains how to use the page.

---

## After that

- The server restarts the tool by itself if it crashes.
- It comes back on its own after a reboot.
- The HTTPS padlock renews itself.
- **Your office computer is no longer involved and can be switched off.**

Keep the local copy on your PC as a backup. It does not interfere with the
server. The tunnel script also still works if you ever need it.

One Oracle housekeeping note: accounts that sit completely unused can have
their free resources reclaimed. Since the editors will be using it, this
should not come up, but do not be surprised if Oracle emails you about
inactivity after a long quiet period.

---

## Everyday jobs on the server

Log in from your PC:

    ssh -i %USERPROFILE%\.ssh\voiceover-server.key ubuntu@YOUR-IP

Then:

**Is it running**

    cd /opt/voiceover && sudo docker compose ps

**Read the log when something breaks**

    cd /opt/voiceover && sudo docker compose logs --tail 100

**Restart it**

    cd /opt/voiceover && sudo docker compose restart

**Update the Studio page after changing it on your PC**

Double-click `DEPLOY - Put Voiceover On A Server.cmd` again. It copies the new
page up and restarts. It remembers the address and password, so it will not
ask those again.

**Change the password**

    cd /opt/voiceover
    sudo docker run --rm caddy:2.10-alpine caddy hash-password --plaintext "your new password"

Copy the line it prints. Edit `.env` and replace the `AUTH_HASH=` line with
it, **doubling every dollar sign**: write `$$` everywhere the hash has a `$`.
That is not a typo. Without it the hash gets mangled and the password stops
working. Then:

    sudo docker compose up -d --force-recreate gate

Update `LOGIN.txt` and tell your editors.

---

## If the address does not load

Work down this list:

1. **Did you add the two ingress rules in step 3?** This is nearly always it.
2. Does the DuckDNS entry still point at the right IP? Check on duckdns.org.
3. Is the server running? Check the Oracle console shows it as Running.
4. Log in and run `cd /opt/voiceover && sudo docker compose ps`. Both
   `kokoro` and `voiceover-gate` should say Up.
5. Look at `sudo docker compose logs --tail 50 gate` for certificate errors.
   A common one is that the address was not pointing at the server yet when
   Caddy first tried. Fix DuckDNS, then
   `sudo docker compose restart gate` and wait a minute.

---

## Security

The voice engine still has **no login of its own**. The password gate in front
of it is the only thing protecting it.

- The engine is not published at all. It sits on a private network between the
  two containers and only the gate can reach it.
- Only ports 80 and 443 are open, and 80 only redirects to 443.
- Traffic is encrypted, so the password is never sent in the clear.
- The installer refuses to leave the site running if the password did not
  reach the gate intact, or if the `basic_auth` block has been removed from
  `Caddyfile`. Do not remove it.
- Do not post the address and password anywhere public. Two editors, one
  password, sent privately.

If you think the password leaked, change it with the steps above.
