"""Task #72: end-to-end wire-format tests for the ledger alert path.

The task #63 tests in `tests/test_kernel.py` monkeypatch
`kernel._post_webhook` and `kernel._send_email` directly, so they pin
the dispatch logic but not the actual HTTP body or SMTP envelope that
hits the wire. A regression in the JSON payload shape, the
`EmailMessage` headers, or the `urllib`/`smtplib` timeout handling
would slip through.

These tests boot a real `http.server.HTTPServer` and a minimal
`socketserver`-based SMTP capture sink on `127.0.0.1` ephemeral ports,
point the `MORNINGSTAR_ALERT_*` env vars at them, trip
`_verify_checkpoint` by truncating the ledger, then assert the
documented payload shape on both transports.
"""

from __future__ import annotations

import json
import socket
import threading
from email import message_from_bytes, policy
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

import pytest

import kernel


@pytest.fixture
def tmp_hits(tmp_path, monkeypatch):
    """Mirror of `tests/test_kernel.py::tmp_hits` — redirect the ledger,
    checkpoint, and alerts log to throwaway paths, and stub the
    Genesis-seal subprocess (which hardcodes `data/hits.txt`)."""
    fake = tmp_path / "hits.txt"
    monkeypatch.setattr(kernel, "HITS", fake)
    monkeypatch.setattr(kernel, "CHECKPOINT", tmp_path / "hits.txt.checkpoint")
    monkeypatch.setattr(kernel, "ALERTS_LOG", tmp_path / "ledger-alerts.jsonl")
    monkeypatch.setattr(kernel, "_verify_seal", lambda: None)
    return fake


class _CapturingWebhookHandler(BaseHTTPRequestHandler):
    """HTTP handler that stashes the raw POST body on the server."""

    def do_POST(self):  # noqa: N802 - BaseHTTPRequestHandler API
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length) if length else b""
        self.server.captured.append(  # type: ignore[attr-defined]
            {
                "path": self.path,
                "content_type": self.headers.get("Content-Type", ""),
                "body": body,
            }
        )
        self.send_response(200)
        self.send_header("Content-Length", "2")
        self.end_headers()
        self.wfile.write(b"ok")

    def log_message(self, *args, **kwargs):  # silence per-request stderr
        pass


@pytest.fixture
def webhook_server():
    server = HTTPServer(("127.0.0.1", 0), _CapturingWebhookHandler)
    server.captured = []  # type: ignore[attr-defined]
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        host, port = server.server_address
        yield f"http://{host}:{port}/alert", server.captured  # type: ignore[attr-defined]
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=5)


class _MiniSMTPServer:
    """Minimal single-connection SMTP sink. Speaks just enough of RFC
    5321 for `smtplib.SMTP.send_message` to complete: EHLO/HELO →
    MAIL FROM → RCPT TO → DATA → QUIT. Captures the raw DATA payload
    plus the MAIL/RCPT addresses for assertion."""

    def __init__(self):
        self._sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self._sock.bind(("127.0.0.1", 0))
        self._sock.listen(1)
        self._sock.settimeout(10)
        self.host, self.port = self._sock.getsockname()
        self.messages: list[dict] = []
        self._thread = threading.Thread(target=self._run, daemon=True)

    def start(self):
        self._thread.start()

    def stop(self):
        try:
            self._sock.close()
        except OSError:
            pass
        self._thread.join(timeout=5)

    def _run(self):
        try:
            conn, _ = self._sock.accept()
        except OSError:
            return
        conn.settimeout(10)
        rfile = conn.makefile("rb")
        wfile = conn.makefile("wb")

        def send(line: str) -> None:
            wfile.write(line.encode("ascii") + b"\r\n")
            wfile.flush()

        send("220 mini.smtp ready")
        mail_from = ""
        rcpts: list[str] = []
        try:
            while True:
                raw = rfile.readline()
                if not raw:
                    break
                line = raw.decode("ascii", errors="replace").rstrip("\r\n")
                upper = line.upper()
                if upper.startswith("EHLO") or upper.startswith("HELO"):
                    send("250 hello")
                elif upper.startswith("MAIL FROM:"):
                    mail_from = line.split(":", 1)[1].strip().strip("<>")
                    send("250 ok")
                elif upper.startswith("RCPT TO:"):
                    rcpts.append(line.split(":", 1)[1].strip().strip("<>"))
                    send("250 ok")
                elif upper.startswith("DATA"):
                    send("354 send data")
                    chunks: list[bytes] = []
                    while True:
                        dline = rfile.readline()
                        if not dline or dline == b".\r\n" or dline == b".\n":
                            break
                        if dline.startswith(b".."):
                            dline = dline[1:]
                        chunks.append(dline)
                    self.messages.append(
                        {
                            "mail_from": mail_from,
                            "rcpts": list(rcpts),
                            "data": b"".join(chunks),
                        }
                    )
                    mail_from = ""
                    rcpts = []
                    send("250 queued")
                elif upper.startswith("QUIT"):
                    send("221 bye")
                    break
                elif upper.startswith("RSET"):
                    mail_from = ""
                    rcpts = []
                    send("250 ok")
                elif upper.startswith("NOOP"):
                    send("250 ok")
                else:
                    send("250 ok")
        except (OSError, socket.timeout):
            return
        finally:
            try:
                conn.close()
            except OSError:
                pass


@pytest.fixture
def smtp_server():
    srv = _MiniSMTPServer()
    srv.start()
    try:
        yield srv
    finally:
        srv.stop()


def _seed_and_truncate(tmp_hits: Path) -> None:
    kernel._append_line("seed line ok")
    tmp_hits.write_bytes(tmp_hits.read_bytes()[:1])


def test_webhook_wire_format_end_to_end(tmp_hits, monkeypatch, webhook_server):
    """The real `_post_webhook` ⇒ `http.server` round trip must deliver
    a JSON POST with `Content-Type: application/json` and the full
    documented payload shape (workflow/timestamp/failure_mode/
    expected_size/actual_size/expected_sha/recovery)."""
    url, captured = webhook_server
    monkeypatch.setenv("MORNINGSTAR_ALERT_WEBHOOK_URL", url)
    monkeypatch.setenv("MORNINGSTAR_WORKFLOW_NAME", "zeta-burst-101-10000")
    monkeypatch.delenv("MORNINGSTAR_ALERT_EMAIL_TO", raising=False)

    _seed_and_truncate(tmp_hits)

    with pytest.raises(kernel.LedgerIntegrityError):
        kernel._append_line("second line")

    assert len(captured) == 1, captured
    req = captured[0]
    assert req["path"] == "/alert"
    assert req["content_type"] == "application/json"
    payload = json.loads(req["body"].decode("utf-8"))

    assert payload["workflow"] == "zeta-burst-101-10000"
    assert payload["failure_mode"] in {
        "hits_truncated",
        "hits_rewritten_in_place",
    }
    assert isinstance(payload["expected_size"], int)
    assert isinstance(payload["actual_size"], int)
    assert payload["actual_size"] == 1
    assert payload["expected_size"] > payload["actual_size"]
    assert isinstance(payload["expected_sha"], str)
    assert len(payload["expected_sha"]) == 64
    # `actual_sha` is only populated on in-place rewrites, not pure truncation.
    if payload["failure_mode"] == "hits_rewritten_in_place":
        assert len(payload["actual_sha"]) == 64
    assert "REPRODUCE.md" in payload["recovery"]
    # `timestamp` must be an ISO-8601 UTC string the dashboard can parse.
    assert "T" in payload["timestamp"]
    assert payload["timestamp"].endswith("+00:00")
    # `message` carries the human-readable failure text.
    assert isinstance(payload["message"], str) and payload["message"]


def test_smtp_wire_format_end_to_end(tmp_hits, monkeypatch, smtp_server):
    """The real `_send_email` ⇒ stdlib `smtplib` round trip must deliver
    a well-formed RFC 5322 message with Subject / From / To headers
    and a body containing the documented fields."""
    monkeypatch.setenv("MORNINGSTAR_ALERT_EMAIL_TO", "ops@example.com")
    monkeypatch.setenv("MORNINGSTAR_ALERT_EMAIL_FROM", "ledger@example.com")
    monkeypatch.setenv("MORNINGSTAR_ALERT_SMTP_HOST", smtp_server.host)
    monkeypatch.setenv("MORNINGSTAR_ALERT_SMTP_PORT", str(smtp_server.port))
    monkeypatch.setenv("MORNINGSTAR_WORKFLOW_NAME", "zeta-sieve-14159-100000")
    monkeypatch.delenv("MORNINGSTAR_ALERT_WEBHOOK_URL", raising=False)
    monkeypatch.delenv("MORNINGSTAR_ALERT_SMTP_USER", raising=False)
    monkeypatch.delenv("MORNINGSTAR_ALERT_SMTP_PASSWORD", raising=False)

    _seed_and_truncate(tmp_hits)

    with pytest.raises(kernel.LedgerIntegrityError):
        kernel._append_line("second line")

    # Give the SMTP server thread a moment to drain.
    smtp_server._thread.join(timeout=5)

    assert len(smtp_server.messages) == 1, smtp_server.messages
    captured = smtp_server.messages[0]
    assert captured["mail_from"] == "ledger@example.com"
    assert captured["rcpts"] == ["ops@example.com"]

    parsed = message_from_bytes(captured["data"], policy=policy.default)
    assert parsed["From"] == "ledger@example.com"
    assert parsed["To"] == "ops@example.com"
    subject = parsed["Subject"]
    assert subject is not None
    assert "[MorningStar]" in subject
    assert "Ledger integrity alert" in subject
    assert "zeta-sieve-14159-100000" in subject

    body = parsed.get_content() if parsed.get_content_maintype() == "text" else ""
    assert "workflow: zeta-sieve-14159-100000" in body
    assert "timestamp:" in body
    assert "expected_size:" in body
    assert "actual_size:" in body
    assert "expected_sha:" in body
    assert "failure_mode:" in body
    assert "REPRODUCE.md" in body


def test_webhook_and_smtp_both_fire_end_to_end(
    tmp_hits, monkeypatch, webhook_server, smtp_server
):
    """Both transports are independent — configuring both must deliver
    to both wires on a single integrity failure. This is the path the
    docs describe ("Set alongside or instead of the webhook")."""
    url, captured = webhook_server
    monkeypatch.setenv("MORNINGSTAR_ALERT_WEBHOOK_URL", url)
    monkeypatch.setenv("MORNINGSTAR_ALERT_EMAIL_TO", "ops@example.com")
    monkeypatch.setenv("MORNINGSTAR_ALERT_SMTP_HOST", smtp_server.host)
    monkeypatch.setenv("MORNINGSTAR_ALERT_SMTP_PORT", str(smtp_server.port))
    monkeypatch.setenv("MORNINGSTAR_WORKFLOW_NAME", "dual-transport")

    _seed_and_truncate(tmp_hits)

    with pytest.raises(kernel.LedgerIntegrityError):
        kernel._append_line("second line")

    smtp_server._thread.join(timeout=5)

    assert len(captured) == 1
    assert len(smtp_server.messages) == 1
    payload = json.loads(captured[0]["body"].decode("utf-8"))
    assert payload["workflow"] == "dual-transport"
    parsed = message_from_bytes(smtp_server.messages[0]["data"])
    assert "dual-transport" in (parsed["Subject"] or "")
