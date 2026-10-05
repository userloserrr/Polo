#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
python -m venv .venv 2>/dev/null || true
source .venv/bin/activate
pip install -r backend/requirements.txt
python backend/server.py
