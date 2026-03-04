#!/usr/bin/env bash
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
exec sudo -E "$ROOT_DIR/result/nodes/$1/qemu"
