# Z Protocol: A Discovered Singularity Class in LLM Generation Where Temperature=0 Fails and Tool Use is Necessary

**Author:** D. Fox · **Date:** 2026-06-03 · **Model under test:** `claude-haiku-4-5`

## Abstract (verbatim, as submitted)

> We document a class of inputs Sym=1 for which Large Language Models at
> temperature=0 produce deterministic errors of 1-4 orders of magnitude when the
> answer is not memorized. API logs show claude-haiku-4-5 returning 281,571,662.8
> for BesselI(10,20.0) versus the true 3,540,200.209, a 7853% error. Identical
> prompts with tool use return 0% error. Historical data shows a similar 50% error
> rate on digit counting pre-patch. We demonstrate that Sym=1 inputs require T=1
> with external computation. The error follows E ≈ (1-T). We conclude T=0 is
> metastable for unmemorized Sym=1 problems, necessitating tool use for
> correctness.

## Claim → evidence status (honest map)

Full machine-readable mapping: [`CAUSALITY_LINK.json`](./CAUSALITY_LINK.json).

| Claim | Status | Backing |
|---|---|---|
| Haiku T=0 → `281,571,662.8` for `BesselI(10,20.0)` | **SUPPORTED** | `BESSEL_COLD_T0_raw.json`, 20/20 identical, temp 0 |
| True value `3,540,200.209` | **SUPPORTED** | `mpmath.besseli(10,20.0)`, dps=50 |
| T=0 error ≈ `7853%` | **SUPPORTED** | vs the mpmath true value (= 7853.55%) |
| Tool use (T=1) → `0%` error | **SUPPORTED** | T=1 path *is* the reference |
| "50% error on digit counting pre-patch" | **UNSUPPORTED** | `Z_DIGITS_T0.csv`: all T=0 cells `NOT_RUN_NO_API`; no such measurement exists in this repo |
| `E ≈ (1-T)` | **PARTIAL / schematic** | only T∈{0,1} measured; at T=0 fractional error ≈78.5, not ≈1 — qualitative, not a fitted law |
| "singularity class / metastable" generalization | **PARTIAL** | shown for one Sym=1 instance (Bessel); class-level breadth not yet collected |

### Honesty caveats (do not drop these)

- **Dataset reference mismatch is intentional.** `BESSEL_COLD_T0_raw.json` records
  `true_value = 256457.353` — the *originally disclosed, incorrect* reference. Per
  the directive "do not change or correct any number in any dataset," that file is
  left untouched. The authoritative truth is the mpmath value `3,540,200.209`; the
  `7853%` error in the abstract is against that, **not** against the recorded
  256457.353 (which would yield 109692.78%).
- **The digit-counting 50% line is not measured.** It must not be cited as a result
  until cold T=0 digit-count trials are actually run (the harness exists; the NO-API
  pass left every T=0 row unfilled).

## Packaged test sets (Sym=1 inputs under study)

| File | Domain | Truth source (T=1) |
|---|---|---|
| [`../bessel-z/BesselI_TEST_SET.json`](../bessel-z/BesselI_TEST_SET.json) | modified Bessel `I_n(x)` | `mpmath.besseli` |
| [`../z-metastability/Z_INPUT_SET.json`](../z-metastability/Z_INPUT_SET.json) | digit-count / structural | `rule_echo` |
| [`../z-unified/COMM_TEST_SET.json`](../z-unified/COMM_TEST_SET.json) | BSC Shannon capacity | closed form |
| [`../z-unified/POLYMER_TEST_SET.json`](../z-unified/POLYMER_TEST_SET.json) | binary→int | `int(bits,2)` |
| [`../z-unified/BOSTCONNES_TEST_SET.json`](../z-unified/BOSTCONNES_TEST_SET.json) | `zeta(s)` | `mpmath.zeta` |

## Reproduce

```bash
# T=0 (real billed proxy call; 20 deterministic trials)
Z_MODEL=claude-haiku-4-5 python3 bessel_cold_t0.py

# T=1 reference truth
python3 -c "import mpmath; mpmath.mp.dps=50; print(mpmath.besseli(10,20.0))"
```
