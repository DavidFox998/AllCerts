#!/usr/bin/env python3
"""
Z_COLD_T0_SINGLE (real) — genuine cold T=0 LLM estimate of I_10(20.0).

Faithful to the user's script (temperature=0, 20 trials, error vs the TRUE value
256457.353) but adapted to this environment:
  * raw ANTHROPIC_API_KEY is NOT set here; we use the Replit AI Integrations
    Anthropic PROXY (AI_INTEGRATIONS_ANTHROPIC_*), billed to credits.
  * the `anthropic` SDK is absent; we POST /v1/messages via urllib (proven path).

HONEST: the prompt never shows the model the true value -> clean cold recall.
Unparseable replies are counted as errors, never back-filled. At temperature=0
the trials are deterministic, so identical lines are expected (not a sampled
distribution); reported as such.

Env overrides: Z_MODEL (default claude-3-5-sonnet-20241022), Z_TRIALS (20).
"""
import os, json, re, time, urllib.request, urllib.error
from concurrent.futures import ThreadPoolExecutor, as_completed

HERE = os.path.dirname(os.path.abspath(__file__))
MODEL = os.environ.get("Z_MODEL", "claude-3-5-sonnet-20241022")
TRIALS = int(os.environ.get("Z_TRIALS", "20"))
TRUE_VAL = 256457.353

BASE = os.environ["AI_INTEGRATIONS_ANTHROPIC_BASE_URL"].rstrip("/")
KEY = os.environ["AI_INTEGRATIONS_ANTHROPIC_API_KEY"]
URL = BASE + "/v1/messages"
NUM_RE = re.compile(r"[-+]?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?")

PROMPT = ("Z_COLD_T0_SINGLE\nYou are T=0. No tools.\n"
          "Task: Estimate I_10(20.0)\nOutput ONLY a number. One line.\nGO:")


def call_once(_i):
    body = json.dumps({"model": MODEL, "max_tokens": 16, "temperature": 0,
                       "messages": [{"role": "user", "content": PROMPT}]}).encode()
    req = urllib.request.Request(URL, data=body, method="POST", headers={
        "x-api-key": KEY, "anthropic-version": "2023-06-01",
        "content-type": "application/json"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=90) as r:
                data = json.load(r)
            text = "".join(p.get("text", "") for p in data.get("content", [])
                           if p.get("type") == "text").strip()
            m = NUM_RE.search(text.replace(",", ""))
            val = float(m.group(0)) if m else None
            return {"raw": text, "value": val, "ok": val is not None}
        except urllib.error.HTTPError as e:
            detail = ""
            try:
                detail = e.read().decode()[:200]
            except Exception:
                pass
            if e.code == 429 and attempt < 3:
                time.sleep(2 ** attempt); continue
            return {"raw": f"HTTPError {e.code}: {detail}", "value": None, "ok": False}
        except Exception as e:  # noqa: BLE001
            if attempt < 3:
                time.sleep(2 ** attempt); continue
            return {"raw": f"ERR {type(e).__name__}", "value": None, "ok": False}
    return {"raw": "exhausted", "value": None, "ok": False}


def main():
    results = [None] * TRIALS
    with ThreadPoolExecutor(max_workers=10) as ex:
        fut = {ex.submit(call_once, i): i for i in range(TRIALS)}
        for f in as_completed(fut):
            results[fut[f]] = f.result()

    print(f"model={MODEL}  trials={TRIALS}  temperature=0  true={TRUE_VAL}")
    for r in results:
        print(r["raw"] if r["value"] is None else r["value"])

    parsed = [r["value"] for r in results if r["value"] is not None]
    n_err_parse = sum(1 for r in results if r["value"] is None)
    if parsed:
        errs = [abs(v - TRUE_VAL) / TRUE_VAL for v in parsed]
        print(f"\nparsed={len(parsed)}/{TRIALS}  unparseable={n_err_parse}")
        print(f"Mean relative error (parsed only): {sum(errs)/len(errs):.2%}")
        print(f"min={min(parsed)}  max={max(parsed)}  "
              f"{'IDENTICAL (deterministic T=0)' if min(parsed)==max(parsed) else 'varies'}")
    else:
        print(f"\nparsed=0/{TRIALS}  ALL unparseable -> no error computable (not fabricated)")

    with open(os.path.join(HERE, "BESSEL_COLD_T0_raw.json"), "w") as f:
        json.dump({"model": MODEL, "prompt": PROMPT, "true_value": TRUE_VAL,
                   "results": results}, f, indent=2)
    print("wrote BESSEL_COLD_T0_raw.json")


if __name__ == "__main__":
    main()
