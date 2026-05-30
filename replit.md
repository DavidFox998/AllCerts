# Morning Star Project · Theorema Aureum 143 (Volume I)

**Full history → `docs/CHANGELOG.md`** (per-batch wall-jump tables, tactic
notes, proof sketches, drift footnotes, env vars, stack, where-things-live,
gotchas). `replit.md` is the live-ops doc; the CHANGELOG is the version
history. Roadmap → `docs/ROADMAP.md`.

## Current status — 2026-05-30

- **Wall:** 539 BRICKS (`${#BRICKS[@]}` in `scripts/check-towers.sh`). The
  source of truth for the count is the script, not this file.
- **Axiom debt:** `[]` on `TheoremaAureum.main_theorem` (`#print axioms`
  returns `[]`; also `[]` on `H2_WeilTransfer` and `M9_WeilTransfer_All`).
  Every landed brick is classical-trio-only.
- **Mathlib:** v4.12.0 only.
- **YM Surface #1: OPEN.** No `m > 0` claim while the `sorry` stands.
- **Wall 574 `[YM1]`** (`Towers/YM/MassGap574.lean`) elaborates against the
  real Step-4/5 `H` / `spectrum_bound` and carries `(hpos : 0 < wilsonAction U)`,
  but still carries a `sorry`; INVARIANT-LOCKED, NOT in BRICKS, not a lakefile
  root. The companion `YM_mass_gap_nontrivial` discharges `hpos` for
  non-trivial `U` and is `sorry`-free, but `H = wilsonAction U • 𝟙` is the
  scalar shadow, NOT the real Wilson transfer operator — so no mass-gap claim.
- **Registered YM walls** (tagged files, lake-gated `[YM1-*]`, NOT in BRICKS):
  571-B `[YM1-LB-Core]` (`lattice_positivity`, axioms `[]`), 572 `[YM1-LB-Real]`
  (`hamiltonian_pos`), 573 `[YM1-GR]` (`gap_reduction`), 575 `[YM1-SB]`
  (`spectrum_bound` + `spectrum_bound_H_iff`). All classical trio.
- **Deferred:** 24 OS/KP modules unregistered (Task #208); `.lean` files kept
  on disk, await Wall 570+/574 with the real SU(3) `H`.
- **Infra:** mathlib cache self-heal landed (`scripts/fetch-mathlib-oleans.sh`:
  authoritative `lake exe cache get`, no from-source fallback).
- **Honest measure infra (NOT a brick, not in BRICKS):**
  `Towers/YM/SU3Instances.lean` carries the real `SU(3)` instance stack
  (`Group` / `TopologicalGroup` / `CompactSpace` / `BorelSpace`), `haarSU3 =
  haarMeasure ⊤`, and now `haarN n := Measure.pi (fun _ : Fin n => haarSU3)` —
  the product Haar measure on `Fin n → SU(3)` link configurations — plus
  `IsProbabilityMeasure` instances for both. `#print axioms` on `haarSU3` /
  `haarN` = classical trio (`[propext, Classical.choice, Quot.sound]`), verified
  live. This is measure-theoretic scaffolding ONLY: built on the *real* Haar
  measure (NOT the Dirac stand-in), but it makes **no** `m > 0` / mass-gap /
  `μ > 0` claim and does **not** touch Surface #1 (stays OPEN).
- **Real integral transfer operator `T_L` (NOT a brick, not in BRICKS):**
  `Towers/YM/Transfer.lean` now carries a `sorry`-free `noncomputable def T_L
  (L β) : Lp ℝ 2 (haarN (4·L⁴)) → Lp ℝ 2 (haarN (4·L⁴))`, the genuine integral
  operator `(T_L f)(U) = ∫ V, exp(-β·wilsonAction(V⁻¹·U))·f(V) d(haarN)` — a real
  heat kernel over the *real* product Haar measure built from the *real* SU(3)
  Wilson action (via `linkEquiv`/`toGauge`, continuity + `Memℒp` proofs). `#print
  axioms T_L` = classical trio (no `sorryAx`), verified live. Makes **no**
  spectral / mass-gap / `m > 0` claim; Surface #1 stays OPEN; YM stays
  `Status: Open`. The companion `Transfer.transfer_operator_norm_le` is now
  **TIGHTENED** to the genuine sub-Markov **contraction** (it was an `exp(a·β)`
  growth bound): `∀ β > 0, ∀ f, ‖T_L L β f‖ ≤ ‖f‖` — i.e. `‖T_L‖ ≤ 1`.
  `sorry`-free, classical-trio only (`#print axioms` = trio, verified live).
  Proof: the heat kernel `exp(-β·actL) ≤ 1` because `actL ≥ 0`
  (`Transfer.actL_nonneg ← WilsonPositivity.wilsonAction_nonneg`), then
  `L¹ ≤ L²` on the probability measure `haarN`. It is explicitly **NOT** a
  *strict* contraction, decay, spectral-gap, or mass-gap claim: only
  `‖T_L‖ ≤ 1` is proved (no equality / tightness claim — constants are
  eigenfunctions with eigenvalue `Z(β) = ∫ exp(-β·actL) ≤ 1`, so `T_L` does
  **not** contract the vacuum sector to `0`), and
  `S_min := inf_{U ≠ 1} wilsonAction U = 0` (the action is continuous and
  vanishes at the vacuum), so no `exp(-β·S_min)` decay holds. The genuine mass gap would be the OPPOSITE inequality — a
  spectral *lower* bound `T_L ≥ c·𝟙` on the zero-mean sector — and stays OPEN
  in the NEW `Transfer.kotecky_preiss_criterion`, a **disclaimed
  single-`sorry` placeholder** (own namespace `…YM.Transfer`, reports `sorryAx`,
  NOT a brick): `∃ β₀ > 0, ∀ β > β₀, ∃ gap > 0, ∀ L f, (∫ f d(haarN) = 0) →
  ‖T_L L β f‖ ≤ exp(-(β·gap))·‖f‖`. OPEN — it does NOT close Surface #1, does
  NOT prove the mass gap, and does NOT touch the invariant-locked
  `kotecky_preiss_criterion` `sorry` in `Towers/Attempts/ClusterExpansion.lean`.
- **Honest positivity scaffolding (NOT bricks, not in BRICKS):**
  `Towers/YM/WilsonPositivity.lean` adds `wilsonAction_nonneg`,
  `plaquetteEnergy_eq_zero_iff`, and `wilsonAction_eq_zero_iff` — the LAST
  states `wilsonAction U = 0 ↔ ∀ x μ ν, wilsonPlaquette U x μ ν = 1` (all
  plaquettes trivial), HONESTLY **NOT** `↔ U = 1`. Plus a polymer-energy
  functional `polymerEnergy` with `polymerEnergy_nonneg` and
  `polymerEnergy_pos_of_nontrivial` (the latter needs an explicit
  non-trivial-plaquette hypothesis). `Transfer.actL_nonneg` lifts
  `wilsonAction_nonneg` through `toGauge`. All classical-trio, verified live;
  every lemma is *necessary-not-sufficient* — pointwise positivity is NOT a
  uniform spectral gap, since the off-vacuum infimum of `wilsonAction` is `0`.
- **Polymer-activity scaffolding (NOT bricks, not in BRICKS):**
  `Towers/YM/Transfer.lean` adds the cluster-expansion *activity* functional
  `polymerActivity L β γ := ∫ w, exp(-β·polymerEnergy (toGauge w) γ) d(haarN)`
  (real `polymerEnergy`, real product Haar `haarN`), with `sorry`-free,
  classical-trio (`#print axioms` = trio, verified live) companions:
  `polymerActivity_nonneg` (`integral_nonneg`), `integrable_polymerWeight`
  (continuity on the compact config space ⇒ bounded ⇒ `L¹`), `polymerActivity_empty`
  (`= 1` for `γ = ∅`, the one *proven* value), and `polymerActivity_antitone_in_beta`
  (`β₁ ≤ β₂ ⟹ activity β₂ ≤ activity β₁`, from `polymerEnergy ≥ 0`). HONEST
  scope: nonneg + antitone are *necessary-not-sufficient* — NO convergence,
  decay, spectral gap, or `m > 0`. The `β → ∞` limit is `haarN {polymerEnergy =
  0}`; this file asserts **neither** that it is `0` nor that it is positive (for
  non-empty `γ` the trivial-plaquette set is a positive-codimension, plausibly
  Haar-null subvariety). KP convergence needs a uniform SUM over *connected /
  truncated* weights — the OPEN content of `Transfer.kotecky_preiss_criterion`,
  which stays a disclaimed `sorry` (UNTOUCHED). Surface #1 stays OPEN.
- **Single-polymer activity decay — honest DCT reduction (1 brick-grade
  trio-clean lemma + 2 disclaimed OPEN `sorry`s, NONE in BRICKS):**
  `Towers/YM/Transfer.lean` now factors the integral route into its *proven*
  and its *open* halves.
  - `continuous_polymerEnergy_toGauge` (NEW, trio-clean): the per-config map
    `w ↦ polymerEnergy (toGauge L w) γ` is continuous (factored out of
    `integrable_polymerWeight`, which now calls it).
  - `polymerActivity_tendsto_zero_of_null` (NEW, **`sorry`-free, classical
    trio**, verified live): the genuine, fully-proved content of the integral
    route — *IF* `haarN {w | polymerEnergy (toGauge L w) γ = 0} = 0` *THEN*
    `polymerActivity L β γ → 0` as `β → ∞`. Proof = dominated convergence
    (`tendsto_integral_filter_of_dominated_convergence`): the heat weight
    `exp(-β·polymerEnergy) → 𝟙[polymerEnergy = 0]` pointwise (`exp_zero` on the
    null set; `Real.tendsto_exp_atBot ∘ const_mul_atTop_of_neg` off it),
    dominated by the constant `1` (integrable on the probability measure
    `haarN`), so the limit integral is `(haarN {…=0}).toReal = 0`.
  - `trivial_polymer_set_null` (NEW, **disclaimed OPEN `sorry`**, reports
    `sorryAx`, NOT a brick): for `γ ≠ ∅`, `haarN {…polymerEnergy = 0} = 0`.
    TRUE but a genuine measure-theoretic theorem, not a short trio proof:
    needs `NoAtoms haarSU3` (only via `IsHaarMeasure.noAtoms`, requiring the
    identity non-isolated, unproved here) PLUS a `Measure.pi` single-coordinate
    marginal argument (`NoAtoms` alone kills only *countable* sets; the trivial
    set is an *uncountable* positive-codim subvariety). The naive
    "codimension `8·|γ|`" count is **lattice-size dependent**: on `L = 1` a
    plaquette degenerates to a commutator `[g,h]`, so the triviality set is the
    *commuting variety* and the four plaquette links are NOT four freely-varying
    coordinates — needs the harder regular-element analysis. Left OPEN.
  - `polymerActivity_tendsto_zero` (NEW, OPEN, inherits `sorryAx` from
    `trivial_polymer_set_null`, NOT a brick): `γ ≠ ∅ ⟹ polymerActivity L β γ →
    0`. Just the trio-clean DCT reduction fed the OPEN null-set input.
  - **Why this is NOT the mass gap (the finite-`β₀` point):** even the full
    `polymerActivity_tendsto_zero` is a **single** polymer's `β → ∞` limit.
    Kotecký–Preiss is strictly stronger and different in kind — a *uniform*
    convergent SUM `∑_{γ ∋ 0} |z(γ)| e^{|γ|} < ∞` at a **finite** `β₀ < ∞` over
    *connected / truncated* weights — driven by "few small-energy polymers at
    large-but-finite `β`", NOT by any single activity's `β → ∞` limit, and NOT
    by `inf_{U≠1} wilsonAction U > 0` (that infimum is `0`). So
    `kotecky_preiss_criterion` stays a disclaimed OPEN `sorry` (UNTOUCHED), no
    Surface #1 closure, YM stays `Status: Open`, no `m > 0` / mass-gap claim.

## Locked invariants (every batch must hold these)

- Axiom footprint = classical trio `{propext, Classical.choice, Quot.sound}`;
  no new research-grade axioms.
- Mathlib v4.12.0 only; no `sorry` / `admit` / `sorryAx` in any landed brick.
- YM and NS towers stay `Status: Open` in `docs/ROADMAP.md`; Surface #1 and
  Surface #2 stay OPEN. "Surface #1 CLOSED" / "μ > 0" / "removes the Attempts
  sorry" / "Mass Gap proven" claims are REFUSED — every YM Measure-surface
  brick is trivially or vacuously true under the Dirac haar stand-in
  (`T_OS = 0` / `T_real = 0`), NOT under any real Wilson transfer operator.
- `kotecky_preiss_criterion` remains a `sorry` in
  `Towers/Attempts/ClusterExpansion.lean` (invariant-locked).

## Operational gotchas

- **Do NOT run `towers-build` / `lake update` casually.** Both re-clone the
  vendored mathlib checkout and wipe its oleans, requiring a `lake-recovery`
  (`lake exe cache get`) pass. Verify bricks via direct `lake env lean <file>`
  + `#print axioms` — **but `lake env` is ALSO destructive when the
  `v4.12.0` tag is missing.** `lake env` re-resolves `inputRev: v4.12.0` from
  the mathlib git; if the tag does not resolve it fetches from remote and wipes
  the oleans, exactly like `lake update` (confirmed 2026-05-30). So BEFORE any
  `lake env lean`, assert `git -C lean-proof-towers/.lake/packages/mathlib
  rev-parse v4.12.0` succeeds. Recovery if wiped: `scripts/restore-lake-git.sh`
  (run it TWICE — first run restores `.git` at the pinned rev, second run
  rehydrates the empty worktree via its `git checkout -- .` heal), then recreate
  the tag (`git -C lean-proof-towers/.lake/packages/mathlib tag -f v4.12.0
  809c3fb3b5c8f5d7dace56e200b426187516535a`), then run
  `scripts/fetch-mathlib-oleans.sh` to re-download the oleans.
- The destructive mathlib re-clone is triggered when the restore-tar's vendored
  mathlib `.git` lacks the `v4.12.0` tag (lake fetches from remote to resolve
  `inputRev: v4.12.0`). Fix: recreate the tag locally after any
  `restore-lake-git.sh` worktree rebuild —
  `git -C .lake/packages/mathlib tag v4.12.0 <HEAD>` (manifest `rev` already =
  HEAD). It is NOT persisted in the restore tar.

## User preferences

- Ship clean: no `sorryAx`, no `sorry` / `admit` in any landed/registered brick.
- Be honest about scope — never overstate a placeholder/stand-in as a real
  result (no false "mass gap proven" / "Surface #1 closed" claims).

## theorema-certs dashboard

Web artifact (`artifacts/theorema-certs`) — the certificate-ledger dashboard.
Has e2e Playwright specs under `tests/e2e/`. Run a spec with:
`PLAYWRIGHT_MANAGED_WEB_SERVER=1 pnpm --filter @workspace/theorema-certs exec playwright test <name>`.
