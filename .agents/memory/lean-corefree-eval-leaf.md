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
