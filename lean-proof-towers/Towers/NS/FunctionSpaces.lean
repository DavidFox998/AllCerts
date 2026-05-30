/-
================================================================
Towers / NS / FunctionSpaces  (Tower 540, Phase 1 — SORRY #1)

**Navier–Stokes function spaces: the divergence-free Sobolev
space `Hdiv_free s`, built the honest way.**

This file defines `Hdiv_free (s : ℝ)` — the order-`s` Sobolev
space of divergence-free vector fields on `ℝ³` — as the genuine
**Fourier-side model** and proves the structure mathlib v4.12.0
actually delivers. It does NOT fake the space with a vacuous
stand-in (`V → V` ignoring `s`, etc.); every instance below is
inherited from a real `L²` Hilbert space, not asserted.

------------------------------------------------------------------
## The construction (no hand-waving)

On the Fourier side, the homogeneous-weight `Hˢ` inner product is
  `⟪u, v⟫_{Hˢ} = ∫_{ℝ³} ⟨ξ⟩^{2s} · (û(ξ) · v̂(ξ)) dξ`,
where `⟨ξ⟩^{2s} = (1 + |ξ|²)^s` is the Japanese-bracket weight.
That is exactly the `L²` inner product of the Fourier transforms
against the **weighted measure**
  `μ_s := volume.withDensity (ξ ↦ (1 + |ξ|²)^s)`.
So we MODEL `Hˢ(ℝ³; ℂ³)` directly as
  `Hsv s := Lp (EuclideanSpace ℂ (Fin 3)) 2 μ_s`
— the value space `ℂ³` because the Fourier transform of a real
field is complex-valued. mathlib gives this object a genuine
Hilbert structure for free:
  * `InnerProductSpace ℂ (Lp _ 2 μ_s)` — `MeasureTheory.L2.innerProductSpace`;
  * `CompleteSpace (Lp _ 2 μ_s)`        — `Lp` is complete.

The **divergence-free** constraint is, in Fourier variables,
`ξ · û(ξ) = 0` (since `div u ↔ i ξ · û = 0`). We carve this out as
a `Submodule ℂ (Hsv s)` — `divFreeSubmodule s` — and PROVE it is a
linear subspace (closed under `0`, `+`, `•`). Then
  `Hdiv_free s := ↥(divFreeSubmodule s)`
inherits `NormedAddCommGroup`, `InnerProductSpace ℂ`, and (once the
subspace is closed) `CompleteSpace` — i.e. it is genuinely a
Hilbert space.

------------------------------------------------------------------
## What is PROVED here (real, `sorry`-free)

  * `divFreeSubmodule s` is a genuine `Submodule ℂ (Hsv s)`:
    `zero_mem'`, `add_mem'`, `smul_mem'` are all proved from the
    `Lp` coe-fn calculus (`Lp.coeFn_zero/add/smul`).
  * `Hdiv_free s` is a `NormedAddCommGroup` and an
    `InnerProductSpace ℂ` — inherited from the ambient `L²` space,
    NOT asserted (see the `example`s at the end).

## The two Clay-adjacent `sorry`s (≤ 2 per file, per directive)

  1. `divFreeSubmodule_isClosed` — the div-free subspace is closed.
     **Needed for the Leray projection** (`leray_proj`, SORRY #2):
     the `L²`-orthogonal projection onto a subspace exists exactly
     when that subspace is closed (`HasOrthogonalProjection`). TRUE
     — the div-free space is the range of the bounded Leray
     multiplier `ξ ↦ (𝟙 - ξξᵀ/|ξ|²)` — but the full proof is a
     Fourier-multiplier argument, not a one-liner. Deferred.

  2. `embed` — the continuous embedding `Hˢ ↪ Hˢ'` for `s' ≤ s`.
     **Needed for the energy inequality**: the dissipation gains
     two derivatives, so estimates live across orders. TRUE because
     `(1+|ξ|²)^{s'} ≤ (1+|ξ|²)^s` pointwise (base `≥ 1`), giving a
     norm-`≤ 1` inclusion; the honest proof compares `Lp` norms
     across the two weighted measures `μ_{s'} ≤ μ_s`. Deferred.

------------------------------------------------------------------
## Honest scope (tripwires)

  * **No existence/regularity claim.** This file builds spaces and
    names operators only; it proves NO Navier–Stokes result.
  * The two `sorry`s above are Clay-adjacent analysis, NOT bricks.
    This file ships with `sorryAx` BY DESIGN and is excluded from
    `BRICKS` in `scripts/check-towers.sh`.
  * `Hsv s` / `Hdiv_free s` is the **Fourier-side model** of `Hˢ`.
    We make NO claim that it is isometric to the physical-space
    `Hˢ(ℝ³;ℝ³)` (that is the Fourier–Plancherel isometry, a
    separate future brick). It IS a real, non-trivial Hilbert space
    of `ℂ³`-valued frequency fields under the genuine weighted `L²`
    inner product — not a stand-in.
  * NS tower stays `Status: Open`.
================================================================
-/

import Mathlib.MeasureTheory.Function.L2Space
import Mathlib.MeasureTheory.Measure.Haar.InnerProductSpace
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.InnerProductSpace.Projection
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open MeasureTheory
open scoped BigOperators ENNReal

namespace TheoremaAureum
namespace Towers
namespace NS
namespace FunctionSpaces

/-- Frequency space `ℝ³` (the domain of the Fourier transform). -/
abbrev Freq : Type := EuclideanSpace ℝ (Fin 3)

/-- Value space `ℂ³` for the (complex) Fourier transform of a real
    vector field. -/
abbrev Val : Type := EuclideanSpace ℂ (Fin 3)

/-- **Japanese-bracket Sobolev weight** `⟨ξ⟩^{2s} = (1 + |ξ|²)^s`,
    as an `ℝ≥0∞`-valued density. The base `1 + |ξ|² ≥ 1 > 0`, so the
    real power `Real.rpow … s` is well defined for every `s : ℝ`. -/
noncomputable def weight (s : ℝ) (ξ : Freq) : ℝ≥0∞ :=
  ENNReal.ofReal ((1 + ‖ξ‖ ^ 2) ^ s)

/-- **Weighted frequency measure** `μ_s := volume · ⟨ξ⟩^{2s}` on
    `ℝ³`. The order-`s` Sobolev inner product is the `L²(μ_s)` inner
    product of Fourier transforms. -/
noncomputable def mu (s : ℝ) : Measure Freq :=
  (volume : Measure Freq).withDensity (weight s)

/-- **`Hˢ(ℝ³; ℂ³)`, Fourier-side model** — the weighted `L²` space
    of `ℂ³`-valued frequency fields. mathlib makes this a genuine
    Hilbert space (`InnerProductSpace ℂ` + `CompleteSpace`). -/
abbrev Hsv (s : ℝ) : Type := Lp Val 2 (mu s)

/-- **Complexified frequency vector** `ξ ↦ (ξ : ℂ³)` — the real
    frequency `ξ ∈ ℝ³` embedded componentwise into the value space
    `ℂ³`. Because each component is a *real* number coerced into `ℂ`,
    conjugation fixes it, so the Hermitian inner product
    `⟪toVal ξ, û⟫_ℂ` used below equals the *bilinear* divergence
    pairing `∑ i, ξ_i · û_i = ξ · û`. -/
noncomputable def toVal (ξ : Freq) : Val :=
  (WithLp.equiv 2 (Fin 3 → ℂ)).symm (fun i => (ξ i : ℂ))

/-- **Divergence-free predicate** in Fourier variables: `ξ · û(ξ) = 0`
    for a.e. `ξ`. This is the frequency-side form of `div u = 0`
    (`div u ↔ i ξ · û = 0`). We phrase the pairing as the Hermitian
    inner product `⟪toVal ξ, û(ξ)⟫_ℂ`, which — since `toVal ξ` has
    real (conjugation-fixed) components — equals the bilinear
    divergence `∑ i, ξ_i · û(ξ)_i`. Phrasing it through `inner` makes
    linearity in `û` (used in `divFreeSubmodule`) immediate. -/
def IsDivFree {s : ℝ} (f : Hsv s) : Prop :=
  ∀ᵐ ξ ∂(mu s), @inner ℂ Val _ (toVal ξ) (f ξ) = 0

/-- **The divergence-free subspace** of `Hˢ`, as a genuine
    `Submodule ℂ (Hsv s)`. Linearity (`0`, `+`, `•` closure) is
    PROVED below from the `Lp` coe-fn calculus; closedness is the
    Clay-adjacent `divFreeSubmodule_isClosed`. -/
noncomputable def divFreeSubmodule (s : ℝ) : Submodule ℂ (Hsv s) where
  carrier := {f | IsDivFree f}
  zero_mem' := by
    show IsDivFree (0 : Hsv s)
    filter_upwards [Lp.coeFn_zero Val 2 (mu s)] with ξ hξ
    rw [hξ, Pi.zero_apply, inner_zero_right]
  add_mem' := by
    intro f g hf hg
    show IsDivFree (f + g)
    filter_upwards [Lp.coeFn_add f g, hf, hg] with ξ hadd hfξ hgξ
    rw [hadd, Pi.add_apply, inner_add_right, hfξ, hgξ, add_zero]
  smul_mem' := by
    intro c f hf
    show IsDivFree (c • f)
    filter_upwards [Lp.coeFn_smul c f, hf] with ξ hsmul hfξ
    rw [hsmul, Pi.smul_apply, inner_smul_right, hfξ, mul_zero]

@[simp] theorem mem_divFreeSubmodule {s : ℝ} (f : Hsv s) :
    f ∈ divFreeSubmodule s ↔ IsDivFree f := Iff.rfl

/-- **Clay-adjacent SORRY (a).** The divergence-free subspace is
    closed in `Hˢ`. **Needed for `leray_proj` (SORRY #2):** the
    `L²`-orthogonal projection onto a subspace requires the subspace
    to be closed (`HasOrthogonalProjection`/`CompleteSpace`). TRUE —
    it is the range of the bounded Leray multiplier
    `ξ ↦ 𝟙 - ξξᵀ/|ξ|²` — but the proof is a Fourier-multiplier
    argument. Deferred, NOT a brick. -/
theorem divFreeSubmodule_isClosed (s : ℝ) :
    IsClosed (divFreeSubmodule s : Set (Hsv s)) := by
  apply IsSeqClosed.isClosed
  intro F g hF hFg
  -- `L²` convergence yields an a.e.-convergent subsequence (via convergence in
  -- measure): pick `ns` with `⇑(F (ns i)) ξ → ⇑g ξ` for a.e. `ξ`.
  obtain ⟨ns, _hmono, hae⟩ :=
    (tendstoInMeasure_of_tendsto_Lp hFg).exists_seq_tendsto_ae
  -- every term of the subsequence is divergence-free
  have hdiv : ∀ i, IsDivFree (F (ns i)) := fun i => hF (ns i)
  have hall : ∀ᵐ ξ ∂(mu s),
      ∀ i, @inner ℂ Val _ (toVal ξ) ((F (ns i)) ξ) = 0 :=
    ae_all_iff.mpr hdiv
  -- pass the linear constraint to the limit pointwise, using continuity of the
  -- inner product in its second argument and uniqueness of limits.
  show IsDivFree g
  filter_upwards [hae, hall] with ξ hξtend hξall
  have hcont : Continuous (fun v : Val => @inner ℂ Val _ (toVal ξ) v) :=
    continuous_const.inner continuous_id
  have htend :
      Tendsto (fun i => @inner ℂ Val _ (toVal ξ) ((F (ns i)) ξ)) atTop
        (𝓝 (@inner ℂ Val _ (toVal ξ) (g ξ))) :=
    (hcont.tendsto _).comp hξtend
  have h0 :
      Tendsto (fun i => @inner ℂ Val _ (toVal ξ) ((F (ns i)) ξ)) atTop (𝓝 0) := by
    simp only [hξall]
    exact tendsto_const_nhds
  exact tendsto_nhds_unique htend h0

/-- The divergence-free subspace is complete (from closedness). -/
theorem divFreeSubmodule_isComplete (s : ℝ) :
    IsComplete (divFreeSubmodule s : Set (Hsv s)) :=
  (divFreeSubmodule_isClosed s).isComplete

noncomputable instance instCompleteSpaceDivFree (s : ℝ) :
    CompleteSpace (divFreeSubmodule s) :=
  completeSpace_coe_iff_isComplete.mpr (divFreeSubmodule_isComplete s)

/-- **`Hdiv_free s` — the order-`s` divergence-free Sobolev space.**
    The carrier type of the closed div-free subspace of the weighted
    `L²` Fourier model. A genuine Hilbert space (see instances and
    the `example`s below). -/
def Hdiv_free (s : ℝ) : Type := (divFreeSubmodule s)

noncomputable instance (s : ℝ) : NormedAddCommGroup (Hdiv_free s) :=
  inferInstanceAs (NormedAddCommGroup (divFreeSubmodule s))

noncomputable instance (s : ℝ) : InnerProductSpace ℂ (Hdiv_free s) :=
  inferInstanceAs (InnerProductSpace ℂ (divFreeSubmodule s))

noncomputable instance (s : ℝ) : CompleteSpace (Hdiv_free s) :=
  inferInstanceAs (CompleteSpace (divFreeSubmodule s))

/-- **Clay-adjacent SORRY (b).** The continuous Sobolev embedding
    `Hˢ ↪ Hˢ'` for `s' ≤ s`. **Needed for the energy inequality:**
    the viscous dissipation gains two derivatives, so the energy
    estimate compares norms across Sobolev orders. TRUE because
    `(1+|ξ|²)^{s'} ≤ (1+|ξ|²)^s` pointwise (base `≥ 1`), so the
    inclusion is norm-`≤ 1`; the honest proof compares the `Lp`
    norms across `μ_{s'} ≤ μ_s`. Deferred, NOT a brick. -/
noncomputable def embed {s s' : ℝ} (_h : s' ≤ s) :
    Hdiv_free s →L[ℂ] Hdiv_free s' :=
  sorry

-- The Hilbert structure is genuinely present, not asserted:
noncomputable example (s : ℝ) : NormedAddCommGroup (Hdiv_free s) := inferInstance
noncomputable example (s : ℝ) : InnerProductSpace ℂ (Hdiv_free s) := inferInstance
example (s : ℝ) : CompleteSpace (Hdiv_free s) := inferInstance

end FunctionSpaces
end NS
end Towers
end TheoremaAureum
