#!/usr/bin/env bash
# Default-deny egress for a night container. Runs as root before the agent starts
# (see entrypoint.sh); needs --cap-add NET_ADMIN --cap-add NET_RAW.
# Allows DNS, GitHub's published IP ranges, and the IPs of ALLOWED_DOMAINS.
#   init-firewall.sh            set up the firewall, then verify it
#   init-firewall.sh --refresh  re-resolve ALLOWED_DOMAINS (CDN IPs rotate)
set -euo pipefail

ALLOWED_DOMAINS=(
  api.anthropic.com
  app.beadhub.ai
  github.com api.github.com codeload.github.com uploads.github.com
  objects.githubusercontent.com raw.githubusercontent.com release-assets.githubusercontent.com
  registry.npmjs.org
  pypi.org files.pythonhosted.org
)

add_domains() {
  local d ip
  for d in "${ALLOWED_DOMAINS[@]}"; do
    for ip in $(dig +short A "$d" | grep -E '^[0-9]+(\.[0-9]+){3}$' || true); do
      ipset add -exist allowed "$ip"
    done
  done
}

if [ "${1:-}" = "--refresh" ]; then
  add_domains
  exit 0
fi

# Fetch GitHub's ranges while the network is still open.
gh_ranges=$(curl -fsS --max-time 20 https://api.github.com/meta | jq -r '(.web + .api + .git)[]' | grep -v ':')

iptables -F
iptables -X
ipset destroy allowed 2>/dev/null || true
ipset create allowed hash:net
for r in $gh_ranges; do ipset add -exist allowed "$r"; done
add_domains

iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m set --match-set allowed dst -j ACCEPT
iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# No IPv6 egress at all.
if command -v ip6tables >/dev/null && ip6tables -L >/dev/null 2>&1; then
  ip6tables -F
  ip6tables -A OUTPUT -o lo -j ACCEPT
  ip6tables -P OUTPUT DROP
  ip6tables -P INPUT DROP
  ip6tables -P FORWARD DROP
fi

# Verify: something off the list must fail, and GitHub must work.
if curl -s --max-time 5 https://example.com >/dev/null; then
  echo "ERROR: firewall check failed: example.com is reachable" >&2
  exit 1
fi
if ! curl -fs --max-time 10 https://api.github.com/zen >/dev/null; then
  echo "ERROR: firewall check failed: api.github.com is blocked" >&2
  exit 1
fi
echo "firewall: on ($(ipset list allowed | grep -c '^[0-9]') allowed ranges/IPs)"
