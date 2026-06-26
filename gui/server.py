#!/usr/bin/env python3
"""Минимальный бэкенд для GUI — REST API + статика."""

import json
import os
import re
import subprocess  # nosec B404 — безопасно: shell=False, аргументы не из пользовательского ввода
import sys
from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PORT = int(os.environ.get("GUI_PORT", "8088"))
# Токен для защиты POST-запросов от CSRF/XSRF
# Установи GUI_TOKEN для доп. защиты. Без токена работает только GET.
GUI_TOKEN = os.environ.get("GUI_TOKEN", "")


def _run(cmd: list[str], timeout: int = 30) -> dict:
    """Запустить команду, вернуть {rc, stdout, stderr}."""
    try:
        r = subprocess.run(
            cmd,
            capture_output=True,
            text=True,  # nosec B603 — shell=False, cmd из валидированных источников
            timeout=timeout,
            cwd=ROOT,
        )
        return {"rc": r.returncode, "stdout": r.stdout, "stderr": r.stderr}
    except FileNotFoundError:
        return {"rc": -1, "stdout": "", "stderr": f"Команда не найдена: {cmd[0]}"}
    except subprocess.TimeoutExpired:
        return {"rc": -2, "stdout": "", "stderr": f"Таймаут ({timeout}с)"}


def api_status() -> dict:
    """Статус проекта: ветка, коммит, изменения."""
    branch = _run(["git", "rev-parse", "--abbrev-ref", "HEAD"])
    log = _run(["git", "log", "--oneline", "-5"])
    tag = _run(["git", "describe", "--tags", "--abbrev=0"])
    diff = _run(["git", "diff", "--stat"])
    staged = _run(["git", "diff", "--cached", "--stat"])
    untracked = _run(["git", "ls-files", "--others", "--exclude-standard"])

    return {
        "branch": branch["stdout"].strip() or "—",
        "commit": log["stdout"].strip().split("\n")[0] if log["stdout"] else "—",
        "recent_commits": log["stdout"].strip().split("\n") if log["stdout"] else [],
        "tag": tag["stdout"].strip() if tag["stdout"] else "—",
        "uncommitted": bool(diff["stdout"].strip()),
        "unstaged": diff["stdout"].strip().split("\n") if diff["stdout"] else [],
        "staged": staged["stdout"].strip().split("\n") if staged["stdout"] else [],
        "untracked": [f for f in untracked["stdout"].strip().split("\n") if f],
    }


def api_targets() -> list[dict]:
    """Парсинг Makefile целей с описаниями."""
    result = _run(["make", "-qp", "help"])
    targets = []
    for line in result["stdout"].split("\n"):
        m = re.match(r"^([a-zA-Z0-9_-]+):.*##\s*(.*)$", line)
        if m:
            targets.append({"name": m.group(1), "desc": m.group(2).strip()})
    # Если make -qp не выдал описания — парсим Makefile напрямую
    if not targets:
        mf = ROOT / "Makefile"
        if mf.exists():
            for line in mf.read_text().split("\n"):
                m = re.match(r"^([a-zA-Z0-9_-]+):.*##\s*(.*)$", line)
                if m:
                    targets.append({"name": m.group(1), "desc": m.group(2).strip()})
    return targets


def api_run(target: str) -> dict:
    """Запустить Make-цель."""
    return _run(["make", target], timeout=120)


def api_version() -> dict:
    """Версия проекта из Makefile."""
    result = _run(["make", "version"])
    return {"version": result["stdout"].strip() or "—"}


class Handler(SimpleHTTPRequestHandler):
    """HTTP-обработчик: статика + API."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT / "gui"), **kwargs)

    CSP = (
        "default-src 'self'; "
        "script-src 'self' 'unsafe-inline'; "
        "style-src 'self' 'unsafe-inline'; "
        "img-src 'self' data:; "
        "connect-src 'self'; "
        "form-action 'none'; "
        "frame-ancestors 'none'; "
        "base-uri 'self'"
    )

    def _send_csp(self):
        self.send_header("Content-Security-Policy", self.CSP)

    def end_headers(self):
        self._send_csp()
        super().end_headers()

    def _json(self, data: dict | list, status: int = 200):
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Access-Control-Allow-Origin", "http://localhost:8088")
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False, indent=2).encode())

    def _error(self, msg: str, status: int = 400):
        self._json({"error": msg}, status)

    def do_GET(self):  # noqa: N802 — стандарт http.server
        path = self.path.rstrip("/")

        if path == "/api/status":
            return self._json(api_status())
        if path == "/api/targets":
            return self._json(api_targets())
        if path == "/api/version":
            return self._json(api_version())
        if path.startswith("/api/git-log"):
            n = 10
            result = _run(
                ["git", "log", f"--max-count={n}", "--pretty=format:%h %s (%ar)"]
            )
            commits = [c for c in result["stdout"].strip().split("\n") if c]
            return self._json(commits)

        return super().do_GET()

    def do_POST(self):  # noqa: N802 — стандарт http.server
        # Базовая защита POST-запросов: проверка токена (если GUI_TOKEN установлен)
        if GUI_TOKEN:
            sent_token = self.headers.get("X-GUI-Token", "")
            if sent_token != GUI_TOKEN:
                return self._error("Unauthorized", 401)
        if self.path.startswith("/api/run/"):
            target = self.path.removeprefix("/api/run/")
            if not re.match(r"^[a-zA-Z0-9_-]+$", target):
                return self._error(f"Недопустимое имя цели: {target}")
            return self._json(api_run(target))
        return self._error("Not found", 404)

    def log_message(self, fmt: str, *args):
        """Тихий лог — форматируем и пишем в stderr."""
        sys.stderr.write(f"[gui] {fmt % args}\n")


def main():
    os.chdir(ROOT)
    server = HTTPServer(("127.0.0.1", PORT), Handler)  # только localhost
    print(f"  K_I_L_O GUI: http://localhost:{PORT}/")
    print("  Нажми Ctrl+C для остановки")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n  Остановлено.")
        server.server_close()


if __name__ == "__main__":
    main()
