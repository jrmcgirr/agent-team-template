# Overnight swarm agent image. One container = one agent = one BeadHub identity.
# Build: docker build -t __PROJECT__-night night/
# Versions are pinned to what passed the dry run; bump them deliberately.
FROM node:22-bookworm-slim

ARG BDH_VERSION=0.12.3
ARG BD_VERSION=1.3.4
ARG GH_VERSION=2.103.3
ARG CLAUDE_CODE_VERSION=2.1.319
ARG TARGETARCH

RUN apt-get update \
 && apt-get install -y --no-install-recommends git curl ca-certificates make jq python3 coreutils openssh-client \
    iptables ipset bind9-dnsutils util-linux \
 && rm -rf /var/lib/apt/lists/*

# uv (Python toolchain), pinned
COPY --from=ghcr.io/astral-sh/uv:0.12.15 /uv /uvx /usr/local/bin/

# bdh, bd and gh from pinned GitHub releases
RUN set -eux; arch="${TARGETARCH:-$(dpkg --print-architecture)}"; \
    curl -fsSL "https://github.com/awebai/bdh/releases/download/v${BDH_VERSION}/bdh_${BDH_VERSION}_linux_${arch}.tar.gz" | tar -xz -C /usr/local/bin bdh; \
    curl -fsSL "https://github.com/gastownhall/beads/releases/download/v${BD_VERSION}/beads_${BD_VERSION}_linux_${arch}.tar.gz" | tar -xz -C /usr/local/bin bd; \
    curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${arch}.tar.gz" | tar -xz -C /tmp; \
    mv "/tmp/gh_${GH_VERSION}_linux_${arch}/bin/gh" /usr/local/bin/gh; rm -rf /tmp/gh_*; \
    corepack enable; \
    npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}"; \
    command -v bdh; bd --version; gh --version; claude --version

# Claude Code refuses --dangerously-skip-permissions as root, so the work runs as `agent`.
# The entrypoint starts as root only to set up the egress firewall, then drops to `agent`
# with no capabilities (see entrypoint.sh). Needs --cap-add NET_ADMIN --cap-add NET_RAW.
RUN useradd -m -s /bin/bash agent
ENV CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
COPY init-firewall.sh entrypoint.sh /usr/local/bin/
COPY --chown=agent:agent loop.sh preflight.sh /home/agent/
RUN chmod 755 /usr/local/bin/init-firewall.sh /usr/local/bin/entrypoint.sh /home/agent/loop.sh /home/agent/preflight.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
