# focus

A website blocker for Linux that works at the DNS level. During your focus blocks only the domains on an allowlist resolve, for every program on the machine, and everything else fails to load. In the breaks between blocks everything works as usual.

Because the blocking happens in DNS rather than in a browser extension, it covers every browser, every profile and every app, and there is no extension to quietly turn off.

## How it works

A systemd timer runs `focus tick` every minute. When the current time falls inside a block from `/etc/focus/schedule`, focus starts a dnsmasq instance that only forwards queries for allowlisted domains to your normal DNS servers and refuses everything else. An nftables rule redirects all outgoing DNS on port 53 to that dnsmasq, so programs can't go around it by using a different resolver. When the block ends, dnsmasq stops and the rule is removed.

Allowing a domain also allows its subdomains, so `github.com` covers `api.github.com` and `gist.github.com`.

## Requirements

dnsmasq, nftables and systemd. fzf is needed for `focus learn`. NetworkManager is used to find your DNS servers when available, otherwise focus reads `/etc/resolv.conf` and falls back to 1.1.1.1. Root commands go through doas or sudo, whichever is installed.

## Install

```sh
git clone https://github.com/sw1jari/focus
cd focus
sudo sh install.sh
```

The installer copies the script to `/usr/local/bin/focus`, sets up `/etc/focus` from the example files, installs the systemd units and starts the timer. It never overwrites files that already exist in `/etc/focus`, so running it again after an update is safe. If you keep your own `allow.txt`, `schedule`, `config` or `until` next to `install.sh`, those are used instead of the examples (they are ignored by git).

It also installs a Firefox policy that turns off Firefox's built in DNS over HTTPS, since Firefox would otherwise skip the system DNS and focus with it. Restart Firefox once after installing.

Reading what got blocked comes from the journal, so add yourself to the `systemd-journal` group (or `wheel` on some distros) if `focus blocked` shows nothing.

## Configuration

All config lives in `/etc/focus` and is owned by root, which is the point: changing it takes a deliberate step.

`schedule` has one block per line as `HH:MM-HH:MM` in local time. A block may cross midnight, like `22:00-02:00`.

`allow.txt` has one domain per line. Comments start with `#`, and pasted urls or `*.example.com` are cleaned up to a plain hostname.

`config` sets the pause sentence, the cooldown before a pause starts and how long a pause lasts. See `config.example`.

`until` is optional and holds a date like `2026-11-03 13:30`. At that moment focus turns itself off and disables the timer, which is handy for an exam week. Without it focus keeps following the schedule.

## Usage

`focus` or `focus status` shows whether blocking is on, any pause and the schedule.

`focus allow github.com example.org` adds domains to the allowlist and applies them right away.

`focus learn` is the easy way to make a site work. Run it, reload the broken page in your browser, then press enter. You get a list of every domain that was blocked while you waited, all selected. Tab or space unselects the ones you don't want, and enter allows the rest.

`focus blocked "30 min ago"` lists blocked domains with how often they were asked for, for a look further back.

`focus pause` turns blocking off for a while, but only after you type a sentence and then wait out a countdown, 10 minutes by default. Ctrl-c during the countdown cancels it. `focus resume` ends a pause early.

## What it doesn't stop

focus is a speed bump for yourself, not a lock. Anyone with root can stop the service or edit the allowlist, and some traffic never goes through port 53 DNS:

- DNS over HTTPS in apps other than Firefox, like Chrome's secure DNS setting
- DNS over TLS on port 853
- sites reached by a hard coded IP address, or cached in a program that already resolved them
- a VPN that brings its own resolver

If you notice yourself working around it, that's usually the sign the block was needed.

## License

MIT
