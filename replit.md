# Morning Star Project · Theorema Aureum 143 (Volume I)

**Full history → `docs/CHANGELOG.md`** (per-batch wall-jump tables, tactic
notes, proof sketches, drift footnotes, env vars, stack, where-things-live,
gotchas). `replit.md` is the live-ops doc; the CHANGELOG is the version
history. Roadmap → `docs/ROADMAP.md`.

## Current status — 2026-05-30

- **NS Tower 540 — honest weak→strong chain, Phases 1–6 COMPLETE** (NONE are
  bricks / in BRICKS / lakefile roots; all classical-trio, no `sorryAx`,
  verified live; full per-phase detail → `docs/CHANGELOG.md` +
  `docs/ROADMAP.md`). Fourier-side model on `Hdiv_free (s+2)`, `ν = 1`:
  - **P1** `FunctionSpaces.lean` (Hˢ as weighted `L²`; `divFreeSubmodule`
    PROVED-closed; bounded `embed` — NOT a compact embedding). **P2**
    `Leray.lean` (`leray_proj`; 1 documented `sorry` `leray_proj_ker_eq_grad`)
    + `Stokes.lean` (`stokes_op`, fully `sorry`-free; NAMES/BOUNDS the operator
    only — no self-adjointness / semigroup). **P3** `Energy.lean` (`energy`,
    `energy_inequality` combinator; NAMED `integration_by_parts`). **P4**
    `GalerkinApprox.lean` (finite-dim `galerkinProj`, a-priori bounds) +
    `Compactness.lean` (NAMED `AubinLionsCriterion`; `galerkin_strong_convergence`
    combinator).
  - **P5** `WeakSolution.lean` — `weak_solution_exists : ∃ u, WeakNS u u₀ f`, an
    honest combinator from THREE NAMED Props (`galerkin_subsequence_converges`,
    `limit_satisfies_weak_form`, `energy_inequality_passes_to_limit`).
    `WeakMomentum`/`WeakNS` are MODELED surrogates (linear weak form — nonlinear
    `(u·∇)u` DROPPED; force-free energy bound), NOT literal Leray–Hopf.
  - **P6** `Regularity.lean` — `weak_implies_strong (h : global_smooth_exists)
    (w : WeakSolution s) : ∃ T > 0, IsSmoothOn w.u T`, an honest combinator from
    the SINGLE NAMED Prop `global_smooth_exists` (the NS global-regularity
    surface). `IsSmoothOn` is a MODELED surrogate for `C^∞((0,T) × ℝ³)` (temporal
    `ContDiffOn ℝ ⊤` of tested profiles `t ↦ ⟪u t, φ⟫` only). `#print axioms` on
    both `weak_implies_strong` and `global_smooth_exists` = classical trio.
    Because the single sorry IS the surface, **NS Tower 540 is FROZEN at 251**
    (milestone `NS-540-phase6-regularity`): the regularity surface is reached,
    left OPEN.
  - HONEST scope: these build spaces, name/bound operators, and assemble the
    Galerkin weak-existence + conditional-regularity combinators from NAMED
    inputs; they prove NO NS existence/uniqueness/regularity result. NS stays
    `Status: Open`; Surface #1/#2 stay OPEN; YM untouched.

- **Wall:** 550 BRICKS (`${#BRICKS[@]}` in `scripts/check-towers.sh`). The
  source of truth for the count is the script, not this file.
- **Real SU(3) chordal distance is a genuine metric (brick, in BRICKS):**
  `Towers/YM/RiemannianGeometry.lean` lands `d_SU3_isMetric : IsMetricOnSU3
  d_SU3` — the chordal distance `d_SU3 g h = ‖↑g - ↑h‖_HS` PROVES the full metric
  predicate (pseudo-distance clauses + separation + triangle), routed through
  the genuine L² structure of `EuclideanSpace ℂ (Fin 3 × Fin 3)` via `toEuc`.
  `#print axioms` = classical trio, no `sorry`. HONEST: the CHORDAL metric, NOT
  the Killing-form GEODESIC distance (open — needs the Riemannian exponential /
  cut-locus, absent from mathlib v4.12.0). NO mass-gap / μ>0 / Surface-#1 claim.
- **Axiom debt:** `[]` on `TheoremaAureum.main_theorem` (also `[]` on
  `H2_WeilTransfer`, `M9_WeilTransfer_All`). Every landed brick is
  classical-trio-only.
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
- **YM Transfer / polymer / positivity / measure scaffolding (NONE bricks, none
  in BRICKS; all classical-trio, verified live; full detail →
  `docs/CHANGELOG.md`).** Real SU(3) Haar stack (`SU3Instances.lean`: `haarSU3`,
  product `haarN`, probability instances); the real integral transfer operator
  `T_L` with the genuine sub-Markov contraction `‖T_L‖ ≤ 1` (`Transfer.lean` —
  explicitly NOT strict / decay / spectral-gap; `S_min := inf_{U≠1} wilsonAction
  U = 0`); Wilson positivity (`WilsonPositivity.lean`: `wilsonAction_nonneg`,
  `wilsonAction_eq_zero_iff` = all-plaquettes-trivial, NOT `U = 1`); and the
  cluster-expansion `polymerActivity` (nonneg, antitone, empty `= 1`, DCT
  reduction `polymerActivity_tendsto_zero_of_null`). Every lemma is
  necessary-not-sufficient: pointwise positivity / single-polymer `β→∞` decay is
  NOT the mass gap. The OPPOSITE spectral lower bound stays OPEN in the
  disclaimed `sorry` `Transfer.kotecky_preiss_criterion` (downstream of one
  unproved cluster-entropy / Peierls counting bound
  `#{γ : |γ|=n, energy<ε} ≤ Cⁿ·ε^{α·n}`), distinct from the invariant-locked
  `Towers/Attempts/ClusterExpansion.lean` `sorry`. NO `m>0` / μ>0 / mass-gap /
  Surface-#1 claim; Surface #1 stays OPEN.

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

- **Git-tag creation is restricted for the main agent.** `git tag` (and other
  git writes) are blocked with "Destructive git operations are not allowed in
  the main agent" — they must go through a background Project Task. This repo's
  working convention is therefore to track milestones as **prose + SHA** in
  `replit.md` / `docs/ROADMAP.md` / `docs/CHANGELOG.md` (e.g. "YM frozen at
  `c8f6a7ed`", "milestone `NS-540-phase2b-stokes` @ checkpoint `f4becd5`"),
  NOT as literal git refs. Replit checkpoints already capture the merged state.
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
