#!/usr/bin/env bash
# Run Codex with this repository's skills inside a Kali + Playwright container.
# Usage: bash scripts/kali-codex-setup.sh projects/pentest [--rebuild]

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: bash scripts/kali-codex-setup.sh <project-folder> [--rebuild]" >&2
  exit 1
fi

PROJECT_DIR=$1
REBUILD=${2:-}
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

if [[ ! -d "$REPO_ROOT/$PROJECT_DIR" ]]; then
  echo "Project folder not found: $PROJECT_DIR" >&2
  exit 1
fi
if [[ ! -f "$REPO_ROOT/AGENTS.md" || ! -d "$REPO_ROOT/.agents/skills" ]]; then
  echo "Run this from a Codex-enabled checkout containing AGENTS.md and .agents/skills/." >&2
  exit 1
fi

PROJECT_REL=${PROJECT_DIR#./}
PROJECT_NAME=$(basename "$PROJECT_REL")
IMAGE_NAME="kali-codex:latest"
CONTAINER_NAME="kali-codex-${PROJECT_NAME}"

if [[ "$REBUILD" == "--rebuild" || -z "$(docker images -q "$IMAGE_NAME" 2>/dev/null)" ]]; then
  echo "[*] Building Kali + Codex + Playwright image..."
  docker build -t "$IMAGE_NAME" -f - "$REPO_ROOT" <<'DOCKERFILE'
FROM kalilinux/kali-rolling

RUN apt-get update -qq && \
    apt-get install -y -qq curl git sudo python3 python3-pip xvfb ca-certificates > /dev/null && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1 && \
    apt-get install -y -qq nodejs > /dev/null && \
    npx -y playwright install-deps chromium > /dev/null 2>&1 && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

RUN useradd -m -s /bin/bash -G sudo codex && \
    echo "codex ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER codex
RUN curl -fsSL https://chatgpt.com/codex/install.sh | sh && \
    npm install -g @playwright/mcp --silent && \
    npx playwright install chromium

ENV PATH="/home/codex/.local/bin:${PATH}"
ENV TMPDIR=/workspace/.tmp
WORKDIR /workspace
USER root
RUN mkdir -p /workspace/.tmp && chown -R codex:codex /workspace
USER codex
DOCKERFILE
else
  echo "[*] Using existing $IMAGE_NAME image. Use --rebuild to refresh it."
fi

docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
echo "[*] Starting Codex in /workspace/$PROJECT_REL"
DOCKER_ARGS=()
if [[ -f "$REPO_ROOT/$PROJECT_REL/.env" ]]; then
  DOCKER_ARGS+=(--env-file "$REPO_ROOT/$PROJECT_REL/.env")
fi
docker run -it --rm \
  --name "$CONTAINER_NAME" \
  --network host \
  --tmpfs /tmp:exec,size=2g \
  -v "$REPO_ROOT:/workspace" \
  -w "/workspace/$PROJECT_REL" \
  "${DOCKER_ARGS[@]}" \
  "$IMAGE_NAME" \
  bash -lc 'Xvfb :99 -screen 0 1920x1080x24 >/dev/null 2>&1 & export DISPLAY=:99; mkdir -p /workspace/.tmp; codex'
