"""Тесты для gui/server.py — REST API и HTTP-обработчик."""

import json
import subprocess
import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

# Добавляем корень проекта в путь для импорта gui.server
PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

import gui.server as server  # noqa: E402 — sys.path hack до импорта

# ─── Фикстуры ─────────────────────────────────────────────


@pytest.fixture(autouse=True)
def reset_globals():
    """Сброс глобальных переменных перед каждым тестом."""
    server.GUI_TOKEN = ""
    yield


@pytest.fixture
def mock_subprocess_run():
    """Мок для subprocess.run — возвращает управляемый результат."""
    with patch("gui.server.subprocess.run") as mock:
        yield mock


@pytest.fixture
def mock_handler():
    """Создаёт экземпляр Handler с замоканным сокетом."""
    with patch("gui.server.Handler") as mock_handler_var:
        handler = mock_handler_var.return_value
        handler.path = "/"
        handler.headers = {}
        handler.send_response = MagicMock()
        handler.send_header = MagicMock()
        handler.end_headers = MagicMock()
        handler.wfile = MagicMock()
        yield handler


# ─── Тесты _run() ─────────────────────────────────────────


class TestRun:
    def test_success(self, mock_subprocess_run):
        """Успешное выполнение команды."""
        mock_subprocess_run.return_value = MagicMock(
            returncode=0, stdout="ok\n", stderr=""
        )
        result = server._run(["echo", "ok"])
        assert result == {"rc": 0, "stdout": "ok\n", "stderr": ""}
        mock_subprocess_run.assert_called_once_with(
            ["echo", "ok"],
            capture_output=True,
            text=True,
            timeout=30,
            cwd=server.ROOT,
        )

    def test_timeout(self, mock_subprocess_run):
        """Таймаут команды."""
        mock_subprocess_run.side_effect = subprocess.TimeoutExpired(
            cmd=["sleep", "999"], timeout=5, output="", stderr=""
        )
        result = server._run(["sleep", "999"], timeout=5)
        assert result["rc"] == -2
        assert "Таймаут" in result["stderr"]

    def test_file_not_found(self, mock_subprocess_run):
        """Команда не найдена."""
        mock_subprocess_run.side_effect = FileNotFoundError()
        result = server._run(["nonexistent_cmd"])
        assert result["rc"] == -1
        assert "не найдена" in result["stderr"]

    def test_timeout_parameter(self, mock_subprocess_run):
        """Кастомный таймаут передаётся в subprocess."""
        mock_subprocess_run.return_value = MagicMock(returncode=0, stdout="", stderr="")
        server._run(["make", "test"], timeout=120)
        assert mock_subprocess_run.call_args[1]["timeout"] == 120

    def test_working_directory(self, mock_subprocess_run):
        """Команда выполняется в ROOT проекта."""
        mock_subprocess_run.return_value = MagicMock(returncode=0, stdout="", stderr="")
        server._run(["pwd"])
        cwd = mock_subprocess_run.call_args[1]["cwd"]
        assert cwd == server.ROOT
        assert (cwd / "Makefile").exists() or (cwd / ".git").exists()


# ─── Тесты api_status() ───────────────────────────────────


class TestApiStatus:
    def test_returns_dict(self):
        """api_status возвращает словарь с ожидаемыми ключами."""
        status = server.api_status()
        expected_keys = {
            "branch",
            "commit",
            "recent_commits",
            "tag",
            "uncommitted",
            "unstaged",
            "staged",
            "untracked",
        }
        assert expected_keys.issubset(status.keys())
        assert isinstance(status["branch"], str)
        assert isinstance(status["recent_commits"], list)
        assert isinstance(status["uncommitted"], bool)

    def test_branch_not_empty(self):
        """Ветка непустая (если есть .git)."""
        status = server.api_status()
        # В тестовом окружении может не быть git репозитория
        if (server.ROOT / ".git").exists():
            assert status["branch"] != "—"

    def test_no_git_repo(self, mock_subprocess_run):
        """Поведение при отсутствии git."""
        mock_subprocess_run.return_value = MagicMock(
            returncode=128, stdout="", stderr="fatal: not a git repository"
        )
        status = server.api_status()
        assert status["branch"] == "—"
        assert status["commit"] == "—"


# ─── Тесты api_targets() ──────────────────────────────────


class TestApiTargets:
    def test_returns_list_of_dicts(self):
        """api_targets возвращает список целей."""
        targets = server.api_targets()
        assert isinstance(targets, list)
        if targets:
            assert "name" in targets[0]
            assert "desc" in targets[0]

    def test_includes_lint(self):
        """Цель lint присутствует в списке."""
        targets = server.api_targets()
        names = [t["name"] for t in targets]
        assert "lint" in names

    def test_empty_on_missing_makefile(self):
        """Пустой список, если Makefile не найден."""
        with patch("gui.server.ROOT", Path("/tmp/nonexistent")):
            targets = server.api_targets()
            assert targets == []


# ─── Тесты api_run() ──────────────────────────────────────


class TestApiRun:
    def test_runs_make_target(self, mock_subprocess_run):
        """api_run выполняет make с указанной целью."""
        mock_subprocess_run.return_value = MagicMock(
            returncode=0, stdout="done\n", stderr=""
        )
        result = server.api_run("test")
        assert result["rc"] == 0
        mock_subprocess_run.assert_called_once()
        args = mock_subprocess_run.call_args[0][0]
        assert args == ["make", "test"]

    def test_long_timeout(self, mock_subprocess_run):
        """Таймаут для make — 120 секунд."""
        mock_subprocess_run.return_value = MagicMock(returncode=0, stdout="", stderr="")
        server.api_run("lint")
        assert mock_subprocess_run.call_args[1]["timeout"] == 120


# ─── Тесты api_version() ──────────────────────────────────


class TestApiVersion:
    def test_returns_version_string(self):
        """api_version возвращает версию."""
        result = server.api_version()
        assert "version" in result
        assert isinstance(result["version"], str)
        assert result["version"] != ""


# ─── Вспомогательные функции для тестов Handler ──────────


def _make_mock_handler():
    """Создаёт минимальный объект Handler с перехваченными сетевыми методами.

    Используем MagicMock для request/connection, чтобы __init__ не падал,
    и переопределяем handle() чтобы он ничего не делал при создании.
    """
    with (
        patch("gui.server.Handler.handle", lambda self: None),
        patch("gui.server.Handler.flush_headers", lambda self: None),
    ):
        handler = server.Handler(MagicMock(), ("127.0.0.1", 0), MagicMock())
        handler.send_response = MagicMock()  # type: ignore[method-assign]
        handler.send_header = MagicMock()  # type: ignore[method-assign]
        handler.end_headers = MagicMock()  # type: ignore[method-assign]
        handler.wfile = MagicMock()
        handler.path = "/"
        handler.headers = {}  # type: ignore[assignment]
        handler.request_version = "HTTP/1.1"
        handler.close_connection = True
        return handler


def make_handler_with_route(
    method="GET", path="/", headers=None, body=None, token=None
):
    """Создаёт Handler с заданным путём/методом и перехватом вывода."""
    handler = _make_mock_handler()
    handler.path = path
    handler.command = method
    if headers:
        handler.headers = headers
    return handler


# ─── Тесты Handler (HTTP routing) ─────────────────────────


class TestHandlerRouting:
    @patch("gui.server.Handler._json")
    @patch("gui.server.api_status")
    def test_get_status(self, mock_api, mock_json):
        """GET /api/status вызывает api_status()."""
        mock_api.return_value = {"branch": "main"}
        handler = make_handler_with_route("GET", "/api/status")
        handler.do_GET()
        mock_api.assert_called_once()

    @patch("gui.server.Handler._json")
    @patch("gui.server.api_targets")
    def test_get_targets(self, mock_api, mock_json):
        """GET /api/targets вызывает api_targets()."""
        handler = make_handler_with_route("GET", "/api/targets")
        handler.do_GET()
        mock_api.assert_called_once()

    @patch("gui.server.Handler._json")
    @patch("gui.server.api_run")
    def test_post_run_valid(self, mock_api, mock_json):
        """POST /api/run/lint выполняет api_run('lint')."""
        mock_api.return_value = {"rc": 0}
        handler = make_handler_with_route("POST", "/api/run/lint")
        handler.do_POST()
        mock_api.assert_called_once_with("lint")

    @patch("gui.server.Handler._error")
    def test_post_run_invalid_target(self, mock_error):
        """POST /api/run/../etc возвращает ошибку."""
        handler = make_handler_with_route("POST", "/api/run/../etc")
        handler.do_POST()
        mock_error.assert_called_once()

    @patch("gui.server.Handler._error")
    def test_post_not_found(self, mock_error):
        """POST /api/unknown возвращает 404."""
        handler = make_handler_with_route("POST", "/api/unknown")
        handler.do_POST()
        mock_error.assert_called_once_with("Not found", 404)


# ─── Тесты GUI_TOKEN защиты ───────────────────────────────


class TestGuiTokenProtection:
    @patch("gui.server.Handler._error")
    def test_post_without_token_when_required(self, mock_error):
        """POST без токена при GUI_TOKEN=secret — 401."""
        server.GUI_TOKEN = "secret"
        handler = make_handler_with_route("POST", "/api/run/lint")
        handler.do_POST()
        mock_error.assert_called_once_with("Unauthorized", 401)

    @patch("gui.server.Handler._json")
    @patch("gui.server.api_run")
    def test_post_with_valid_token(self, mock_api, mock_json):
        """POST с корректным токеном при GUI_TOKEN=secret проходит."""
        server.GUI_TOKEN = "secret"
        mock_api.return_value = {"rc": 0}
        handler = make_handler_with_route(
            "POST", "/api/run/lint", headers={"X-GUI-Token": "secret"}
        )
        handler.do_POST()
        mock_api.assert_called_once_with("lint")

    @patch("gui.server.api_status")
    def test_get_without_token_allowed(self, mock_api):
        """GET без токена работает всегда."""
        server.GUI_TOKEN = "secret"
        mock_api.return_value = {"branch": "main"}
        handler = make_handler_with_route("GET", "/api/status")
        handler.do_GET()
        mock_api.assert_called_once()


# ─── Тесты _json и _error ─────────────────────────────────


class TestJsonError:
    def test_json_sends_utf8(self):
        """_json отправляет Content-Type: application/json; charset=utf-8."""
        handler = make_handler_with_route()
        handler._json({"key": "value"})
        calls = [
            c for c in handler.send_header.call_args_list if c[0][0] == "Content-Type"
        ]
        assert calls, "Content-Type header not set"
        assert calls[0][0][1] == "application/json; charset=utf-8"

    def test_json_sends_cors(self):
        """_json отправляет CORS-заголовок."""
        handler = make_handler_with_route()
        handler._json({})
        calls = [
            c
            for c in handler.send_header.call_args_list
            if c[0][0] == "Access-Control-Allow-Origin"
        ]
        assert calls

    def test_json_cache_control(self):
        """_json отправляет Cache-Control: no-cache."""
        handler = make_handler_with_route()
        handler._json({})
        calls = [
            c for c in handler.send_header.call_args_list if c[0][0] == "Cache-Control"
        ]
        assert calls
        assert calls[0][0][1] == "no-cache"

    def test_error_sends_error_key(self):
        """_error отправляет JSON с ключом error."""
        handler = make_handler_with_route()
        handler._error("test error", 400)
        written = handler.wfile.write.call_args[0][0]
        data = json.loads(written)
        assert data == {"error": "test error"}

    def test_error_custom_status(self):
        """_error использует переданный HTTP-статус."""
        handler = make_handler_with_route()
        handler._error("not found", 404)
        handler.send_response.assert_called_once_with(404)


# ─── Тесты log_message ────────────────────────────────────


class TestLogMessage:
    def test_logs_to_stderr(self, capsys):
        """log_message пишет в stderr с префиксом [gui]."""
        handler = make_handler_with_route()
        handler.log_message("test %s", "message")
        _unused, stderr = capsys.readouterr()
        assert "[gui] test message\n" in stderr

    def test_log_multiple_args(self, capsys):
        """log_message корректно форматирует множественные аргументы."""
        handler = make_handler_with_route()
        handler.log_message("%s %d %s", "GET", 200, "OK")
        _unused, stderr = capsys.readouterr()
        assert "[gui] GET 200 OK\n" in stderr
