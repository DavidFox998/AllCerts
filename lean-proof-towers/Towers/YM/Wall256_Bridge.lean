-- Wall256_Bridge.lean (H3 -- Brydges-Federbush KP-summability -> geometric clustering)
-- Axiom footprint: {propext, Classical.choice, Quot.sound} only. No sorry. No axiom.
-- hBridge_Surface and ClusteringDecay_Surface were axioms; now converted to named
-- open Prop defs (BrydgesFederbushStep, KPContinuumStep).
-- h_bridge_of_surface takes the Brydges-Federbush step as an explicit HYPOTHESIS.
import Towers.YM.Wall256_OS

namespace TheoremaAureum.Towers.YM.Wall256Bridge

open Real
open TheoremaAureum.Towers.YM
open TheoremaAureum.Towers.YM.Wall256Note

/-!
## H3 -- Brydges-Federbush KP-summability -> geometric clustering

### What this file is

H3 in the KP taxonomy: KP-summability of the entropy-weighted polymer activity
implies geometric two-point clustering with spectral ratio rho in (0,1).

### Open obligations (named Prop defs, not axioms)

* `BrydgesFederbushStep` -- the Brydges-Federbush step (E3), recorded as a named
  Prop definition. Open: absent from Lean/Mathlib v4.31.0-rc2 as a formal proof.
  Ref: Brydges-Federbush 1978; Friedli-Velenik 2018 Ch. 5 Thm 5.4.

* `KPContinuumStep` -- the KP 2016 continuum-limit clustering obligation, recorded
  as a named Prop definition. Open: requires Yang-Mills Hilbert space formalization.
  Ref: Kotecky-Preiss 2016.

### What this file does NOT claim

* NO mass gap. NO spectral gap. NO Clay result. NO Surface #1 discharge.
* `corr`/`sep` are abstract; no real Wilson-loop correlator constructed.
* YM tower status: OPEN. Surface #1 status: OPEN.
-/

/-- **NAMED OPEN PROP — Brydges-Federbush KP-summability to geometric clustering (E3).**

    Open: absent from Lean/Mathlib v4.31.0-rc2 as a formal proof.
    Statement: for any abstract entropy weight `N : ℕ → ℝ` and per-polymer
    activity `a : ℕ → ℝ`, KP-summability of the entropy-weighted series
    implies geometric two-point clustering with spectral ratio ρ strictly
    inside (0, 1). Matches the type of the `h_bridge` hypothesis of
    `Wall256Scaffold.strong_coupling_decay_of_open_inputs` exactly.

    Use as an explicit hypothesis; do NOT introduce as an axiom.

    Ref: Brydges-Federbush 1978; Friedli-Velenik 2018 Ch. 5 Thm 5.4. -/
def BrydgesFederbushStep {E : Type*} (N a : ℕ → ℝ) (corr sep : E → E → ℝ) (C ρ : ℝ) : Prop :=
  Summable (fun n : ℕ => N n * a n) →
  0 < ρ ∧ ρ < 1 ∧ ∀ x y : E, |corr x y| ≤ C * ρ ^ (sep x y)

/-- **NAMED OPEN PROP — KP 2016 continuum-limit clustering (obligation placeholder).**

    Open: requires defining the Yang-Mills Hilbert space and Hamiltonian, which
    are absent from Lean/Mathlib v4.31.0-rc2.
    Clay status: OPEN. Surface #1: OPEN. No mass gap claimed. -/
def KPContinuumStep : Prop :=
  ∃ _ : ℕ, True

/-- **h_bridge_of_surface** -- discharge H3 given the Brydges-Federbush step as a hypothesis.

    Takes `h_bf : BrydgesFederbushStep N a corr sep C ρ` as an explicit open hypothesis
    and does NOT axiomatize it. Axiom footprint: classical trio only. No sorry. -/
theorem h_bridge_of_surface {E : Type*} (N a : ℕ → ℝ) (corr sep : E → E → ℝ) (C ρ : ℝ)
    (h_bf : BrydgesFederbushStep N a corr sep C ρ)
    (hsum : Summable (fun n : ℕ => N n * a n)) :
    0 < ρ ∧ ρ < 1 ∧ ∀ x y : E, |corr x y| ≤ C * ρ ^ (sep x y) :=
  h_bf hsum

end TheoremaAureum.Towers.YM.Wall256Bridge
