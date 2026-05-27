/-
================================================================
Towers / Attempts / T_g  (Batch 19.1c — Track 3)

**The two hard surfaces for the transfer operator `T_g`.**

Parked here as `sorry`-bearing stubs. NOT registered in BRICKS —
see `scripts/check-towers.sh`. Their presence does NOT promote
any tower; YM stays `Status: Open` (`docs/ROADMAP.md` § 2) and
`MassGap_YM4_Clay` stays a schema.

  1. `Transfer_compact` — `T_g` is compact on `ℋ_phys`. **This is
     the mass gap for `g > 0`.** Cluster expansion / Glimm-Jaffe
     ch. 19 surface; no honest one-batch discharge.

  2. `Perron_Frobenius_for_transfer` — the real bound
     `0 < g → spectral_radius_def D g < 1`. Requires the cluster
     expansion plus the Perron-Frobenius theorem for positive
     compact operators on the OS-reconstructed Hilbert space.

These sit alongside the three Batch 18 stubs (`Perron.lean`,
`UniformGap.lean`, `Enstrophy.lean`) — same discipline, same
no-auto-promotion guarantee.
================================================================
-/

import Towers.YM.OSReconstruction
import Towers.YM.SpectralGap

namespace TheoremaAureum
namespace Towers
namespace Attempts
namespace T_g

open TheoremaAureum.Towers.YM.OSReconstruction
open TheoremaAureum.Towers.YM.SpectralGap

/-- **`T_g` is compact on `ℋ_phys`.** Cluster-expansion surface;
the named witness here is the still-NAMED `physHilbert_isHilbert`
Prop, used as a Prop-level stand-in for "the construction has
produced a real compact operator on a real Hilbert space". The
proof is left as `sorry`.

**Batch 19.1d / 19.1e note:** the cluster-expansion *skeleton*
now lives in `Towers/YM/ClusterExpansion.lean` (20 bricks: 8 from
19.1d + 12 from 19.1e). Discharging this sorry is the
Arzelà-Ascoli argument applied to the `Transfer_from_measure` of
that file together with the `Cluster_estimate_base` /
`Base_case_discharge` bound at `K = mayer_K_constant = 1` — both
currently honest placeholders. The real discharge needs (a) a
real Wilson measure, (b) the Brydges-Federbush convergent polymer
expansion at general `K * e * Δ ≤ 1` (the Kotecky-Preiss
criterion; 19.1e ships the `e = 1`, `Δ = 0` slice), (c) a real
operator-norm on `physHilbert`. -/
theorem Transfer_compact (D : OSPreHilbert) (_g : ℝ) :
    D.physHilbert_isHilbert := by
  sorry

/-- **Real Perron–Frobenius bound: `r(T_g) < 1` for `g > 0`.**

Honest scope: with the current placeholder `spectral_radius_def := 1`,
this statement is **false on its face** (`(1 : ℝ) < 1` is `False`).
That mismatch is intentional — it is the tripwire telling the next
batch that promoting `spectral_radius_def` away from the literal
`1` placeholder will require landing the real cluster-expansion
bound here. Marked `sorry`; lives outside BRICKS so the axiom
footprint of the green wall is untouched.

**Batch 19.1d / 19.1e note:** the cluster-expansion skeleton
ships in `Towers/YM/ClusterExpansion.lean` (20 bricks). Two
named bridges land the explicit reduction:
`Transfer_bound_from_CE` reduces `r(T_g) < 1` to the Prop
`spectral_radius_def D g < 1` (19.1d); `Transfer_contraction_from_CE`
ships the K=1 trivial slice `g < Small_g_regime_def → r(T_g) ≤ 1`
(19.1e — note `≤`, not `<`, that gap *is* this sorry). Real
discharge = Brydges-Federbush convergent polymer expansion for
`g < g₀` at general `K * e * Δ ≤ 1` (the `Cluster_convergence_radius`
witness, currently placeholder = 1; the `Kotecky_Preiss_criterion`
of 19.1e ships only the `e = 1`, `Δ = 0` slice). -/
theorem Perron_Frobenius_for_transfer (D : OSPreHilbert)
    (g : ℝ) (_hg : 0 < g) :
    spectral_radius_def D g < 1 := by
  sorry

end T_g
end Attempts
end Towers
end TheoremaAureum
