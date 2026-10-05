@echo off
cd /d "%~dp0.."
python -m venv .venv 2>nul
call .venv\Scripts\activate
pip install -r backend\requirements.txt
python backend\server.py
