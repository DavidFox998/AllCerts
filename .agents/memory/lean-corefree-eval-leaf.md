---
name: Compiling a mathlib-free Lean #eval leaf in this env
description: How to author + compile a Lean-core-only computational leaf (large data + #eval) without lake, and the elaboration/toolchain traps.
---

A mathlib-free Lean leaf that holds a large data table and runs `#eval`
computations (e.g. the W(H₄) `H4_Strata_Ztau.lean` stabilizer leaf) hits three
non-obvious traps in this environment. The rule for each:

## 1. Large nested anonymous-constructor list literals blow up elaboration
A `def V : List Quat := [⟨⟨1,0⟩,…⟩, … 120 elems]` of nested `⟨…⟩` literals takes
**>100s just to ELABORATE** (super-linear unification of anonymous constructors
against the expected element type). Even pure elaboration (no `#eval`, no theorem)
times out.
**Fix:** store the raw data as a FLAT `List Int` (e.g. 960 ints, 8 per record) —
`Int` is a builtin, so each literal elaborates in O(1) and the whole list is
linear/fast. Reshape with a STRUCTURAL recursion (`def chunk : List Int → …`
matching N elements then recursing on `rest`; the tail is structurally smaller so
NO `partial` is needed and it stays kernel-reducible). Keep the kernel-checked
length fact on the flat list (`vflat.length = 960 := by rfl`) and treat the
reshaped `V.length` as an `#eval` measurement.
**Why:** anonymous-constructor elaboration cost compounds; flat builtin literals
do not.

## 2. elan re-downloads an incomplete toolchain and dies under the 120s bash cap
If a prior `lean` invocation was killed mid-install, the elan shim (`lean` on
PATH = the nix elan proxy) sees a missing `~/.elan/update-hashes` marker and
**re-downloads the whole toolchain every run** (>120s ⟹ killed by the bash tool's
max timeout ⟹ leaves it incomplete again — a death loop; it can even wipe the
toolchain dir entirely). A truncated/partial `bin/lean` (~8KB instead of ~100MB)
is the tell.
**Fix:** complete the install in ONE uninterrupted run via a temporary CONSOLE
**workflow** (no 120s cap): `configureWorkflow({name, command: "… lean file >
/tmp/out.txt 2>&1; echo ===EXIT $?=== >> /tmp/out.txt", outputType:"console"})`,
then poll `/tmp/out.txt` with `bash cat` (reading the file needs no toolchain).
Once installed, the cached toolchain compiles fast. The toolchain's OWN
`bin/lean` (once complete) bypasses the elan re-download shim, but only AFTER the
install is whole.

## 3. v4.12.0 name gaps
`List.flatMap` does NOT exist in Lean core v4.12.0 — use `List.bind`. (An
unresolved name elaborates to `sorry`, which then cascades "cannot evaluate
expression that depends on the `sorry` axiom" into every dependent `#eval`, even
though the real bug is the one missing identifier.)

## 4. Compiling a TWO-FILE mathlib-free split (importable core + leaf)
To factor an engine into a shared core and have a leaf `import Towers.YM.<Core>`
WITHOUT lake (the v4.12.0 pin is unsafe to touch), compile direct with a
mirrored build tree + `LEAN_PATH`:
- From the package root (`lean-proof-towers/`), `lean` derives the olean module
  name from the *given relative path* (`Towers/YM/H4Core.lean` -> module
  `Towers.YM.H4Core`). So build into a dir mirroring that path:
  `mkdir -p /tmp/h4build/Towers/YM`
  `lean Towers/YM/H4Core.lean -o /tmp/h4build/Towers/YM/H4Core.olean`
- Then compile the leaf with that root on the path; the import resolves against
  `/tmp/h4build/Towers/YM/H4Core.olean`:
  `LEAN_PATH=/tmp/h4build lean Towers/YM/H4_Strata_Ztau.lean`
- Cross-module `by rfl` / `by decide` on imported defs (e.g. `vflat.length=960`,
  `zmul ... = ...`) still work — the olean carries the (reducible) definitions.
- Timings in this env: core ~7s, leaf-with-#evals ~12s (well under the 120s bash
  cap, so no console-workflow needed for THIS size).
