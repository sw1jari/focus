#!/bin/sh
# run as root from the repo: sudo sh install.sh (or doas)
# existing files in /etc/focus are never overwritten
set -e
cd "$(dirname "$0")"

die() {
    echo "install: $*" >&2
    exit 1
}

[ "$(id -u)" -eq 0 ] || die "run this as root"

missing=
for cmd in dnsmasq nft systemctl journalctl; do
    command -v "$cmd" >/dev/null || missing="$missing $cmd"
done
[ -z "$missing" ] || die "install these first:$missing (dnsmasq and nftables packages)"
command -v fzf >/dev/null || echo "install: fzf is missing, everything works except focus learn"

# dnsmasq runs as its own user so the nft redirect can let its upstream queries through
if ! getent passwd dnsmasq >/dev/null; then
    command -v systemd-sysusers >/dev/null && systemd-sysusers
    getent passwd dnsmasq >/dev/null || die "there is no dnsmasq user, create one with useradd -r -s /usr/bin/nologin dnsmasq"
fi

install -Dm755 focus /usr/local/bin/focus
install -d /etc/focus

# your own copy next to this script wins over the example
for f in allow.txt schedule config; do
    [ -e "/etc/focus/$f" ] && continue
    case $f in
        allow.txt) example=allow.example.txt ;;
        *) example=$f.example ;;
    esac
    if [ -e "$f" ]; then
        install -m644 "$f" "/etc/focus/$f"
    else
        install -m644 "$example" "/etc/focus/$f"
    fi
done
[ -e until ] && [ ! -e /etc/focus/until ] && install -m644 until /etc/focus/until

install -m644 redirect.nft /etc/focus/redirect.nft
install -m644 focus-dns.service focus.service focus.timer /etc/systemd/system/

# firefox uses its own dns over https by default, which would skip focus completely
policy=/etc/firefox/policies/policies.json
if [ ! -e "$policy" ]; then
    install -Dm644 firefox-policies.json "$policy"
elif ! grep -q DNSOverHTTPS "$policy"; then
    echo "install: $policy already exists, add the DNSOverHTTPS part of firefox-policies.json to it yourself"
fi

systemctl daemon-reload
systemctl enable --now focus.timer
focus tick
focus status
