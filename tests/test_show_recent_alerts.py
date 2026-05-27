"""Task #107: unit coverage for `scripts/show-recent-alerts.py`.

The CLI is operator-facing and is the SSH fallback for the dashboard's
alerts panel. Regressions in the formatter or the empty-log exit-0
contract would only surface to a human on-call engineer, so pin the
shape here.

Each test patches `kernel.ALERTS_LOG` (and the CLI's
`ALERTS_ACK_PATH`) to `tmp_path`, never touching the real ring
buffer.
"""
from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

import pytest

import kernel

REPO_ROOT = Path(__file__).resolve().parent.parent
_CLI_PATH = REPO_ROOT / "scripts" / "show-recent-alerts.py"


def _load_cli():
    """Import `scripts/show-recent-alerts.py` as a module despite the
    hyphenated filename / non-package directory."""
    spec = importlib.util.spec_from_file_location(
        "show_recent_alerts", _CLI_PATH
    )
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    sys.modules["show_recent_alerts"] = mod
    spec.loader.exec_module(mod)
    return mod


@pytest.fixture
def cli(tmp_path, monkeypatch):
    mod = _load_cli()
    alerts_log = tmp_path / "ledger-alerts.jsonl"
    ack_path = tmp_path / "ledger-alerts.ack.json"
    monkeypatch.setattr(kernel, "ALERTS_LOG", alerts_log)
    monkeypatch.setattr(mod, "ALERTS_ACK_PATH", ack_path)
    return mod, alerts_log, ack_path


def _write_entries(path: Path, entries: "list[dict]") -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        for e in entries:
            fh.write(json.dumps(e) + "\n")


SAMPLE = [
    {
        "timestamp": "2026-05-26T00:00:00+00:00",
        "workflow": "zeta-burst",
        "failure_mode": "hits_truncated",
        "message": "ledger shrank",
        "delivery": {
            "webhook": {"status": "ok"},
            "email": {"status": "failed", "error": "smtp refused"},
        },
    },
    {
        "timestamp": "2026-05-26T01:00:00+00:00",
        "workflow": "zeta-sieve",
        "failure_mode": "hits_rewritten",
        "message": "sha mismatch",
        "delivery": {
            "webhook": {"status": "ok"},
            "email": {"status": "ok"},
        },
    },
]


def test_empty_log_exits_zero_table(cli, capsys):
    mod, _, _ = cli
    rc = mod.main([])
    captured = capsys.readouterr()
    assert rc == 0
    assert captured.out == ""
    assert "No alerts recorded" in captured.err


def test_empty_log_exits_zero_json(cli, capsys):
    mod, _, _ = cli
    rc = mod.main(["--json"])
    captured = capsys.readouterr()
    assert rc == 0
    assert json.loads(captured.out) == []


def test_table_mode_renders_newest_first(cli, capsys):
    mod, alerts_log, _ = cli
    _write_entries(alerts_log, SAMPLE)
    rc = mod.main([])
    captured = capsys.readouterr()
    assert rc == 0
    lines = [l for l in captured.out.splitlines() if not l.startswith("#")]
    assert len(lines) == 2
    # Newest entry (01:00) prints first.
    assert "2026-05-26T01:00:00+00:00" in lines[0]
    assert "zeta-sieve" in lines[0]
    assert "hits_rewritten" in lines[0]
    assert "webhook=ok" in lines[0]
    assert "email=ok" in lines[0]
    # Older entry (00:00) prints second; failed transport carries error.
    assert "2026-05-26T00:00:00+00:00" in lines[1]
    assert "email=failed(smtp refused)" in lines[1]


def test_json_mode_emits_array_of_entries(cli, capsys):
    mod, alerts_log, _ = cli
    _write_entries(alerts_log, SAMPLE)
    rc = mod.main(["--json"])
    captured = capsys.readouterr()
    assert rc == 0
    parsed = json.loads(captured.out)
    assert isinstance(parsed, list)
    assert len(parsed) == 2
    # Newest first; structure preserved.
    assert parsed[0]["timestamp"] == "2026-05-26T01:00:00+00:00"
    assert parsed[0]["workflow"] == "zeta-sieve"
    assert parsed[1]["delivery"]["email"]["error"] == "smtp refused"


def test_limit_zero_short_circuits(cli, capsys):
    mod, alerts_log, _ = cli
    _write_entries(alerts_log, SAMPLE)
    rc = mod.main(["--limit", "0", "--json"])
    captured = capsys.readouterr()
    assert rc == 0
    assert json.loads(captured.out) == []

    rc = mod.main(["--limit", "0"])
    captured = capsys.readouterr()
    assert rc == 0
    # Table mode with no entries prints the "no alerts" stderr notice.
    assert captured.out == ""
    assert "No alerts recorded" in captured.err


# --- Task #121: --since and --failure-mode coverage --------------------

from datetime import datetime, timedelta, timezone


def _now_minus(minutes: int) -> str:
    return (
        datetime.now(timezone.utc) - timedelta(minutes=minutes)
    ).isoformat()


FILTER_SAMPLE = [
    {
        "timestamp": "2026-05-20T00:00:00+00:00",
        "workflow": "zeta-burst",
        "failure_mode": "hits_truncated",
        "message": "old truncated",
        "delivery": {"webhook": {"status": "ok"}, "email": {"status": "ok"}},
    },
    {
        "timestamp": "2026-05-25T00:00:00+00:00",
        "workflow": "zeta-sieve",
        "failure_mode": "hits_rewritten",
        "message": "mid rewritten",
        "delivery": {"webhook": {"status": "ok"}, "email": {"status": "ok"}},
    },
    {
        "timestamp": "2026-05-26T12:00:00+00:00",
        "workflow": "zeta-burst",
        "failure_mode": "sink_wedged",
        "message": "recent wedged",
        "delivery": {"webhook": {"status": "ok"}, "email": {"status": "ok"}},
    },
]


def test_since_absolute_iso_filters_older_entries(cli, capsys):
    mod, alerts_log, _ = cli
    _write_entries(alerts_log, FILTER_SAMPLE)
    rc = mod.main(["--since", "2026-05-26T00:00Z", "--json"])
    captured = capsys.readouterr()
    assert rc == 0
    parsed = json.loads(captured.out)
    assert [e["message"] for e in parsed] == ["recent wedged"]


def test_since_duration_filters_relative_to_now(cli, capsys, monkeypatch):
    mod, alerts_log, _ = cli
    recent_ts = _now_minus(5)
    old_ts = _now_minus(120)
    entries = [
        {
            "timestamp": old_ts,
            "workflow": "w",
            "failure_mode": "hits_truncated",
            "message": "old",
            "delivery": {},
        },
        {
            "timestamp": recent_ts,
            "workflow": "w",
            "failure_mode": "hits_truncated",
            "message": "new",
            "delivery": {},
        },
    ]
    _write_entries(alerts_log, entries)
    rc = mod.main(["--since", "30m", "--json"])
    captured = capsys.readouterr()
    assert rc == 0
    parsed = json.loads(captured.out)
    assert [e["message"] for e in parsed] == ["new"]


def test_failure_mode_single_filters_other_modes(cli, capsys):
    mod, alerts_log, _ = cli
    _write_entries(alerts_log, FILTER_SAMPLE)
    rc = mod.main(["--failure-mode", "hits_rewritten", "--json"])
    captured = capsys.readouterr()
    assert rc == 0
    parsed = json.loads(captured.out)
    assert [e["message"] for e in parsed] == ["mid rewritten"]


def test_failure_mode_repeated_unions_modes(cli, capsys):
    mod, alerts_log, _ = cli
    _write_entries(alerts_log, FILTER_SAMPLE)
    rc = mod.main(
        [
            "--failure-mode",
            "hits_truncated",
            "--failure-mode",
            "sink_wedged",
            "--json",
        ]
    )
    captured = capsys.readouterr()
    assert rc == 0
    parsed = json.loads(captured.out)
    # Newest-first ordering preserved from the ring buffer.
    assert [e["message"] for e in parsed] == ["recent wedged", "old truncated"]


def test_since_and_failure_mode_compose(cli, capsys):
    mod, alerts_log, _ = cli
    _write_entries(alerts_log, FILTER_SAMPLE)
    rc = mod.main(
        [
            "--since",
            "2026-05-24T00:00Z",
            "--failure-mode",
            "hits_rewritten",
            "--failure-mode",
            "sink_wedged",
            "--json",
        ]
    )
    captured = capsys.readouterr()
    assert rc == 0
    parsed = json.loads(captured.out)
    assert [e["message"] for e in parsed] == ["recent wedged", "mid rewritten"]


def test_limit_caps_results_after_filtering(cli, capsys):
    mod, alerts_log, _ = cli
    _write_entries(alerts_log, FILTER_SAMPLE)
    # Two entries match the filter; --limit 1 must return just one of
    # them (the newest), NOT silently fail because the over-fetch
    # window happened to include a filtered-out row.
    rc = mod.main(
        [
            "--failure-mode",
            "hits_truncated",
            "--failure-mode",
            "sink_wedged",
            "--limit",
            "1",
            "--json",
        ]
    )
    captured = capsys.readouterr()
    assert rc == 0
    parsed = json.loads(captured.out)
    assert len(parsed) == 1
    assert parsed[0]["message"] == "recent wedged"


def test_malformed_since_exits_nonzero(cli, capsys):
    mod, alerts_log, _ = cli
    _write_entries(alerts_log, FILTER_SAMPLE)
    with pytest.raises(SystemExit) as excinfo:
        mod.main(["--since", "not-a-real-timestamp"])
    assert excinfo.value.code != 0
    captured = capsys.readouterr()
    assert "--since" in captured.err


def test_empty_since_exits_nonzero(cli, capsys):
    mod, _, _ = cli
    with pytest.raises(SystemExit) as excinfo:
        mod.main(["--since", "   "])
    assert excinfo.value.code != 0


def test_failure_mode_no_match_returns_empty_json(cli, capsys):
    mod, alerts_log, _ = cli
    _write_entries(alerts_log, FILTER_SAMPLE)
    rc = mod.main(["--failure-mode", "nonexistent_mode", "--json"])
    captured = capsys.readouterr()
    assert rc == 0
    assert json.loads(captured.out) == []
