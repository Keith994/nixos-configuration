#!/usr/bin/env bash
# 本地 Redis（docker compose）一键起停。
# 用法: redis.sh [up|down|restart|logs|status|ps]（不带参数 = up）
set -euo pipefail

COMPOSE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/deploy/redis/docker-compose.yml"

case "${1:-up}" in
  up) shift 2>/dev/null || true; docker compose -f "$COMPOSE_FILE" up -d "$@" ;;
  *)  docker compose -f "$COMPOSE_FILE" "$@" ;;
esac
