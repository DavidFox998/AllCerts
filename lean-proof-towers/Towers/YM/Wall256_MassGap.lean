-- Wall256_MassGap.lean -- abstract lattice mass gap, all open inputs as hypotheses.
-- Axiom footprint: {propext, Classical.choice, Quot.sound} only. No sorry. No axiom.
-- W1_Surface_cert, hBridge_Surface, ClusteringDecay_Surface were axioms; now:
--   * hw1fn : w1_fn β < 1/7        (explicit open hypothesis, not axiom)
--   * hbridge : Summable ... → ... (explicit open hypothesis, not axiom)
--   * ClusteringDecay_Surface conjunct removed (was a bookkeeping tautology)
-- LATTICE ONLY. NOT Clay. NOT HasMassGap. YM tower: OPEN. Surface #1: OPEN.
import Towers.YM.Wall256_Scaffold

namespace TheoremaAureum.Towers.YM.Wall256MassGap

open Real
open TheoremaAureum.Towers.YM
open TheoremaAureum.Towers.YM.Wall256Note
open TheoremaAureum.Towers.YM.Wall256Scaffold

/-!
## Wall256_MassGap -- abstract lattice decay, all open inputs as hypotheses

### Chain

```
hw1fn   : w1_fn β < 1/7               (open hypothesis, not axiom)
  + hOS : w1_fn β < 1/7 → TruncatedActivityBound a   (open hypothesis)
  + hbridge : Summable (...) → ...     (open hypothesis, Brydges-Federbush E3)
  ->  exists Delta > 0,
        forall x y, |corr x y| <= C * exp(-Delta * sep x y)
```

via `Wall256Scaffold.strong_coupling_decay_of_open_inputs`.

All formerly-axiomatized open inputs (W1_Surface_cert, hBridge_Surface,
ClusteringDecay_Surface) are now explicit hypothesis parameters. The
`ClusteringDecay_Surface` tautology conjunct is removed entirely.

### What this does NOT do

* Does NOT prove a Clay mass gap.
* Does NOT discharge Surface #1 (OPEN).
* Does NOT use `HasMassGap` (undefined in Mathlib).
* `hOS` (OS abstract cluster step, E4) remains an explicit HYPOTHESIS.
* `corr`/`sep` are abstract; no real Wilson-loop correlator constructed.

### Axiom footprint: {propext, Classical.choice, Quot.sound}

Verify with: `#print axioms TheoremaAureum.Towers.YM.Wall256MassGap.YM_mass_gap`
-/

/-- **YM_mass_gap** -- abstract lattice two-point decay, trio-only.

    LATTICE ONLY. NOT Clay. NOT Surface #1. NOT `HasMassGap`. YM tower: OPEN.

    All open mathematical inputs are explicit hypothesis parameters:
    * `hw1fn : w1_fn β < 1/7`        -- SU(3) weight bound (open: CERT_Arb.pdf L38)
    * `hOS`                           -- OS cluster step (open: E4)
    * `hbridge`                       -- Brydges-Federbush E3 (open: KP-summability)
    * entropy bounds `hN0`, `hN`

    the abstract lattice two-point decay
      `exists Delta > 0, forall x y, |corr x y| <= C * exp(-Delta * sep x y)`
    follows from `Wall256Scaffold.strong_coupling_decay_of_open_inputs`.

    Axiom footprint: {propext, Classical.choice, Quot.sound} only. -/
theorem YM_mass_gap
    {E : Type*} (corr sep : E → E → ℝ) (C ρ : ℝ)
    {N a : ℕ → ℝ} (hN0 : ∀ n, 0 ≤ N n) (hN : ∀ n, N n ≤ (7 : ℝ) ^ n)
    (w1_fn : ℝ → ℝ) (β : ℝ)
    (hw1fn : w1_fn β < 1 / 7)
    (hOS : w1_fn β < 1 / 7 →
        TheoremaAureum.Towers.YM.Wall256Note.TruncatedActivityBound a)
    (hbridge : Summable (fun n : ℕ => N n * a n) →
        0 < ρ ∧ ρ < 1 ∧ ∀ x y : E, |corr x y| ≤ C * ρ ^ (sep x y)) :
    ∃ Δ : ℝ, 0 < Δ ∧ ∀ x y, |corr x y| ≤ C * Real.exp (-Δ * sep x y) :=
  strong_coupling_decay_of_open_inputs corr sep C ρ (w1_fn β) hN0 hN hw1fn hOS hbridge

end TheoremaAureum.Towers.YM.Wall256MassGap
