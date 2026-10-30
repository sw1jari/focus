# focus

A DNS level website blocker for Linux. During focus blocks only allowlisted domains resolve, for every program. Breaks work as usual.

![focus learn making a blocked site load](docs/focus-learn.gif)

![focus status, learn and pause in a terminal](docs/focus-terminal.gif)

## Features

- Blocks in DNS, so it covers every browser, profile and app
- Follows a daily schedule, with an optional end date
- `focus learn` picks up what a page needs while you reload it
- Pausing takes a typed sentence and a 10 minute wait
- Config is root owned, so changing it takes a deliberate step

## Install

```sh
git clone https://github.com/sw1jari/focus
cd focus
sudo sh install.sh
```

Restart Firefox afterwards.

| Needs | For |
|---|---|
| dnsmasq, nftables, systemd | the blocking itself |
| fzf | `focus learn` |
| NetworkManager | finding your DNS servers (falls back to `/etc/resolv.conf`) |
| doas or sudo | commands that need root |

The installer:
- copies `focus` to `/usr/local/bin`
- fills `/etc/focus` from the example files, never overwriting existing ones
- uses your own `allow.txt`, `schedule`, `config` or `until` instead, if they sit next to `install.sh`
- installs and starts the systemd timer
- installs a Firefox policy that turns off Firefox's own DNS over HTTPS, which would skip focus

If `focus blocked` shows nothing, add yourself to the `systemd-journal` group.

## Usage

| Command | What it does |
|---|---|
| `focus` | show whether blocking is on, any pause and the schedule |
| `focus learn` | record what gets blocked while you reload a page, then pick what to allow |
| `focus allow github.com` | add domains to the allowlist right away |
| `focus blocked "30 min ago"` | list blocked domains and how often they were asked for |
| `focus pause` | type the sentence, wait out the countdown, then a pause (30 minutes by default) |
| `focus resume` | end a pause early |

In `focus learn` everything starts selected. Tab or space toggles, enter allows.

## Configuration

Everything lives in `/etc/focus`.

| File | Contents |
|---|---|
| `schedule` | one block per line, `HH:MM-HH:MM`, may cross midnight |
| `allow.txt` | one domain per line, subdomains included, `#` for comments |
| `config` | pause sentence, cooldown and pause length, see `config.example` |
| `until` | optional end date like `2026-11-03 13:30`, focus turns itself off then |

## How it works

- A systemd timer runs `focus tick` every minute
- Inside a block, a dnsmasq instance forwards only allowlisted domains and refuses the rest
- An nftables rule sends all outgoing DNS on port 53 to that dnsmasq
- Outside a block both are removed

## Limits

focus is a speed bump, not a lock. It doesn't stop:
- DNS over HTTPS in other apps, like Chrome's secure DNS
- DNS over TLS on port 853
- hard coded IP addresses, or lookups a program already cached
- a VPN with its own resolver
- anyone with root

## License

MIT
