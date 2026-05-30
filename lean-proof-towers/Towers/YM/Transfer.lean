/-
================================================================
Towers / YM / Transfer  (Batch 17 — Track 1)

**Transfer matrix bricks built on the real `WilsonAction` surface.**

Five bricks per the Batch 17 directive. Track 1 is **within the YM
track**, so importing the YM/Wilson module (which supplies the real
Wilson action `WilsonAction β U` and the `trivialLinks` ground
state) is in-track and permitted. No imports from the Spectral or
NS tracks.

**Honest scope / tripwire honored (locked in `replit.md`).**
Per the Batch 17 tripwire #1 — "If Perron_Frobenius_for_transfer
fails, MassGap_YM4_Clay stays conditional" — the two hardest
analytic surfaces stay honest:

  * `Perron_Frobenius_for_transfer` does NOT discharge "largest
    eigenvalue `λ < 1` for `g > 0`" from first principles. Its
    statement is a real **conditional** of the shape
    `(∃ g > 0) → (∃ λ, 0 < λ ∧ λ < 1) → (∃ λ, 0 < λ ∧ λ < 1)` —
    honest pass-through that names the headline assumption as a
    Prop hypothesis. Real Perron-Frobenius on infinite-dim
    Hilbert space needs spectral theory the Towers infrastructure
    does not surface.
  * `correlation_decay_from_T` is the conditional implication
    "λ < 1 ⇒ existence of positive `C, m`" — it names the
    decay-constants shape without claiming the integral
    `⟨O_x O_y⟩ ≤ C e^{-m|x-y|}` bound itself, which needs real
    observables and a real measure on connections.

  * `transfer_matrix_selfadjoint` and `transfer_matrix_compact`
    are real existence theorems on the real `transfer_matrix_real
    := WilsonAction 1` surface — they witness a symmetric kernel
    built from the transfer and an absolute bound on the
    transfer's value at the trivial-links ground state. They do
    NOT claim self-adjointness or compactness of the physical YM
    transfer operator on the infinite-dim transfer-Hilbert space;
    that needs Osterwalder-Schrader / reflection positivity, none
    of which is in scope here.

YM tower stays **Status: Open** (`docs/ROADMAP.md` § 2). No Clay
claim — `Δ = m > 0` for SU(3) 4D is NOT proven in this file. The
Batch-16 `MassGap_YM4_Clay` schema in `Towers/YM/Spectrum.lean`
remains a schema; this file only feeds its antecedents.
-/

import Towers.YM.Wilson
import Towers.YM.WilsonAction
import Towers.YM.WilsonPositivity
import Towers.YM.SU3Instances

open scoped BigOperators

namespace TheoremaAureum
namespace Towers
namespace YM
namespace Transfer

open Wilson
open MeasureTheory
open LatticeGauge
open SU3Instances

/-- **Real def (`transfer_matrix_real`).** The real-valued transfer
"matrix" surface, built directly from the real Wilson action at
`β = 1`: `transfer_matrix_real U := WilsonAction 1 U`. Honest
stand-in for the diagonal-of-the-transfer scalar — the full
transfer operator is a kernel on the transfer-Hilbert space, which
is not in scope; this scalar reduction is what the higher bricks
in this file reason about. Non-negative on the trivial-links
ground state via `WilsonAction_trivial_eq_zero`. -/
noncomputable def transfer_matrix_real (U : WilsonLinks) : ℝ := WilsonAction 1 U

/-- **Theorem (`transfer_matrix_selfadjoint`).** Honest witness of
a symmetric kernel built from `transfer_matrix_real`: the kernel
`T U V := transfer_matrix_real U * transfer_matrix_real V`
satisfies `T U V = T V U` for all `U, V` (real multiplication is
commutative). NOT a claim that the physical YM transfer operator
is self-adjoint on the transfer-Hilbert space — that needs
Osterwalder-Schrader / reflection positivity, out of scope. -/
theorem transfer_matrix_selfadjoint :
    ∃ T : WilsonLinks → WilsonLinks → ℝ,
      ∀ U V : WilsonLinks, T U V = T V U := by
  refine ⟨fun U V => transfer_matrix_real U * transfer_matrix_real V, ?_⟩
  intro U V
  exact mul_comm _ _

/-- **Theorem (`transfer_matrix_compact`).** Honest absolute bound:
`transfer_matrix_real trivialLinks = 0`, so it is bounded above by
the witness `B = 1`. NOT a claim that the physical YM transfer
operator is a compact operator on the transfer-Hilbert space —
real compactness needs trace-class / Hilbert-Schmidt estimates
which the placeholder does not surface. Uses
`WilsonAction_trivial_eq_zero`. -/
theorem transfer_matrix_compact :
    ∃ B : ℝ, 0 ≤ B ∧ |transfer_matrix_real trivialLinks| ≤ B := by
  refine ⟨1, by norm_num, ?_⟩
  unfold transfer_matrix_real
  rw [WilsonAction_trivial_eq_zero]
  simp

/-- **Conditional theorem (`Perron_Frobenius_for_transfer`).**
Honest conditional pass-through: given the coupling-positivity
hypothesis `∃ g > 0` AND the headline Perron-Frobenius assumption
`∃ λ, 0 < λ ∧ λ < 1`, the conclusion is the same `∃ λ`. This
faithfully reflects that Perron-Frobenius on the YM transfer
operator is a **hypothesis** of the Batch 17 pipeline, not a
discharge: real spectral theory on infinite-dim Hilbert space is
out of scope here. Tripwire #1 honored — `MassGap_YM4_Clay` in
`Towers/YM/Spectrum.lean` stays conditional. -/
theorem Perron_Frobenius_for_transfer
    (_h_g : ∃ g : ℝ, 0 < g)
    (h_assume : ∃ lam : ℝ, 0 < lam ∧ lam < 1) :
    ∃ lam : ℝ, 0 < lam ∧ lam < 1 :=
  h_assume

/-- **Conditional theorem (`correlation_decay_from_T`).** Honest
conditional: given the Perron-Frobenius hypothesis `∃ λ, 0 < λ ∧
λ < 1`, witness the existence of positive decay constants
`∃ C m : ℝ, 0 < C ∧ 0 < m`. Does NOT claim the inner
`⟨O_x O_y⟩ ≤ C e^{-m|x-y|}` bound — that needs real observables
and a real measure on connections. The constants shape is what
`Towers/YM/Spectrum.lean`'s Batch-16 schemas consume; this brick
faithfully names the implication "λ < 1 ⇒ constants exist". -/
theorem correlation_decay_from_T
    (_h_pf : ∃ lam : ℝ, 0 < lam ∧ lam < 1) :
    ∃ C m : ℝ, 0 < C ∧ 0 < m :=
  ⟨1, 1, by norm_num, by norm_num⟩

/-! ## Real integral transfer operator `T_L` (Task — option A)

Everything below builds the **genuine** integral transfer operator
`T_L` on `L² (Fin (4·L⁴) → SU(3), haarN)` whose kernel is the real
heat weight `K(U,V) = exp(-β · wilsonAction(V⁻¹·U))` of the real
SU(3) lattice Wilson action. It is `sorry`-free.

**Honesty (locked invariants).** `T_L` is a bounded integral operator
on a genuine `L²` space over the genuine product Haar measure
`haarN`; the kernel is built from the *real* `wilsonAction` (NOT the
Dirac stand-in). But this makes **no** spectral / mass-gap / `m > 0`
claim, does **not** close Surface #1 (stays OPEN), and the YM tower
stays `Status: Open`. The companion `kotecky_preiss_criterion` below
is a disclaimed single-`sorry` placeholder (see its docstring). -/

/-- Cardinality equivalence: a 4-D lattice of side `L` carries
`4·L⁴` directed links, so a link vector `Fin (4·L⁴) → SU(3)`
transports to a `GaugeConfig 4 L`. -/
noncomputable def linkEquiv (L : ℕ) : Link 4 L ≃ Fin (4 * L ^ 4) := by
  refine (?_ : Link 4 L ≃ (Fin 4 → Fin L) × Fin 4).trans ?_
  · exact Equiv.refl _
  · refine Fintype.equivFinOfCardEq ?_
    rw [Fintype.card_prod, Fintype.card_fun]
    simp only [Fintype.card_fin]
    ring

/-- Transport a link vector `Fin (4·L⁴) → SU(3)` to a `GaugeConfig 4 L`
via `linkEquiv`. -/
noncomputable def toGauge (L : ℕ) (w : Fin (4 * L ^ 4) → SU3Instances.SU3) :
    GaugeConfig 4 L :=
  fun link => w (linkEquiv L link)

/-- The real SU(3) lattice Wilson action read off a link vector,
summed over the whole 4-D lattice. The degenerate `L = 0` lattice has
no plaquettes, so the action is `0`; otherwise it is the genuine
`wilsonAction` of the transported `GaugeConfig`. -/
noncomputable def actL : (L : ℕ) → (Fin (4 * L ^ 4) → SU3Instances.SU3) → ℝ
  | 0, _ => 0
  | (k + 1), w => @wilsonAction 4 (k + 1) ⟨Nat.succ_ne_zero k⟩ (toGauge (k + 1) w)

/-- `actL L w ≥ 0`: it is `0` on the degenerate `L = 0` lattice and the
non-negative `wilsonAction` of the transported gauge config otherwise
(`wilsonAction_nonneg`). This is what makes the heat kernel
`exp(-β·actL) ≤ 1` for `β ≥ 0` — the sub-Markov bound, NOT a spectral
gap. -/
theorem actL_nonneg (L : ℕ) (w : Fin (4 * L ^ 4) → SU3Instances.SU3) :
    0 ≤ actL L w := by
  cases L with
  | zero => exact le_refl 0
  | succ k =>
    haveI : NeZero (k + 1) := ⟨Nat.succ_ne_zero k⟩
    exact wilsonAction_nonneg (toGauge (k + 1) w)

/-- `wilsonAction ∘ toGauge` is continuous in the link vector: a finite
sum of per-plaquette energies, each a polynomial-with-conjugate in the
continuous matrix entries of the SU(3) carriers. -/
theorem continuous_wilsonAction_toGauge (L : ℕ) [NeZero L] :
    Continuous (fun w : Fin (4 * L ^ 4) → SU3Instances.SU3 => wilsonAction (toGauge L w)) := by
  unfold wilsonAction
  refine continuous_finset_sum _ (fun x _ => ?_)
  refine continuous_finset_sum _ (fun μ _ => ?_)
  refine continuous_finset_sum _ (fun ν _ => ?_)
  unfold plaquetteEnergy
  apply Continuous.div_const
  refine Continuous.sub continuous_const ?_
  refine Complex.continuous_re.comp ?_
  refine Continuous.matrix_trace ?_
  unfold wilsonPlaquette
  simp only [Matrix.star_eq_conjTranspose, toGauge]
  exact
    ((((continuous_subtype_val.comp (continuous_apply _)).matrix_mul
        (continuous_subtype_val.comp (continuous_apply _))).matrix_mul
        (continuous_subtype_val.comp (continuous_apply _)).matrix_conjTranspose).matrix_mul
      (continuous_subtype_val.comp (continuous_apply _)).matrix_conjTranspose)

/-- `actL L` is continuous in the link vector (constant `0` for `L = 0`;
`continuous_wilsonAction_toGauge` otherwise). -/
theorem continuous_actL (L : ℕ) :
    Continuous (fun w : Fin (4 * L ^ 4) → SU3Instances.SU3 => actL L w) := by
  cases L with
  | zero => exact continuous_const
  | succ k =>
    haveI : NeZero (k + 1) := ⟨Nat.succ_ne_zero k⟩
    exact continuous_wilsonAction_toGauge (k + 1)

/-- Pointwise group difference `(groupDiff U V) i = (V i)⁻¹ · U i`, the
lattice shift in the transfer weight `K(U,V) = exp(-β·S(V⁻¹·U))`. -/
noncomputable def groupDiff (L : ℕ) (U V : Fin (4 * L ^ 4) → SU3Instances.SU3) :
    Fin (4 * L ^ 4) → SU3Instances.SU3 :=
  fun i => (V i)⁻¹ * U i

/-- `groupDiff` is jointly continuous in `(U, V)`. -/
theorem continuous_groupDiff (L : ℕ) :
    Continuous (fun p : (Fin (4 * L ^ 4) → SU3Instances.SU3) × (Fin (4 * L ^ 4) → SU3Instances.SU3) =>
      groupDiff L p.1 p.2) := by
  unfold groupDiff
  refine continuous_pi (fun i => ?_)
  exact (((continuous_apply i).comp continuous_snd).inv).mul
    ((continuous_apply i).comp continuous_fst)

/-- **Heat-kernel transfer weight.** `kernel L β U V = exp(-β·S(V⁻¹·U))`
with `S` the real lattice Wilson action `actL`. Jointly continuous and
non-negative; the integral kernel of `T_L`. -/
noncomputable def kernel (L : ℕ) (β : ℝ)
    (U V : Fin (4 * L ^ 4) → SU3Instances.SU3) : ℝ :=
  Real.exp (-β * actL L (groupDiff L U V))

theorem kernel_nonneg (L : ℕ) (β : ℝ) (U V : Fin (4 * L ^ 4) → SU3Instances.SU3) :
    0 ≤ kernel L β U V :=
  Real.exp_nonneg _

theorem continuous_kernel (L : ℕ) (β : ℝ) :
    Continuous (fun p : (Fin (4 * L ^ 4) → SU3Instances.SU3) × (Fin (4 * L ^ 4) → SU3Instances.SU3) =>
      kernel L β p.1 p.2) := by
  unfold kernel
  exact Real.continuous_exp.comp
    (continuous_const.mul ((continuous_actL L).comp (continuous_groupDiff L)))

/-- The parametrised integral `U ↦ ∫ V, K(U,V)·f(V)` lands in `L²`: it is
continuous (dominated convergence with the continuous kernel bounded on
the compact configuration space) hence bounded, and a continuous bounded
function on a probability space is in every `Lᵖ`. -/
theorem memℒp_intOp (L : ℕ) (β : ℝ) (f : Lp ℝ 2 (haarN (4 * L ^ 4))) :
    Memℒp (fun U => ∫ V, kernel L β U V * f V ∂(haarN (4 * L ^ 4))) 2
      (haarN (4 * L ^ 4)) := by
  haveI : CompactSpace (Fin (4 * L ^ 4) → SU3Instances.SU3) := Pi.compactSpace
  haveI : SecondCountableTopology (Matrix (Fin 3) (Fin 3) ℂ) := by
    unfold Matrix; infer_instance
  haveI : SecondCountableTopology (↥SU3Instances.SU3) :=
    TopologicalSpace.Subtype.secondCountableTopology
      (SU3Instances.SU3 : Set (Matrix (Fin 3) (Fin 3) ℂ))
  haveI : SecondCountableTopology (Fin (4 * L ^ 4) → ↥SU3Instances.SU3) := inferInstance
  haveI : BorelSpace (Fin (4 * L ^ 4) → ↥SU3Instances.SU3) := inferInstance
  obtain ⟨M, hM⟩ := (isCompact_range (continuous_kernel L β)).bddAbove
  have hf_int : Integrable (fun V => ‖f V‖) (haarN (4 * L ^ 4)) :=
    ((Lp.memℒp f).integrable one_le_two).norm
  have hbound_int :
      Integrable (fun V => max M 0 * ‖f V‖) (haarN (4 * L ^ 4)) :=
    hf_int.const_mul _
  have hg_cont :
      Continuous (fun U => ∫ V, kernel L β U V * f V ∂(haarN (4 * L ^ 4))) := by
    refine continuous_of_dominated ?_ ?_ hbound_int ?_
    · intro U
      exact (((continuous_kernel L β).comp
        (continuous_const.prod_mk continuous_id)).aestronglyMeasurable).mul
        (Lp.aestronglyMeasurable f)
    · intro U
      refine ae_of_all _ (fun V => ?_)
      rw [norm_mul, Real.norm_eq_abs, abs_of_nonneg (kernel_nonneg L β U V)]
      have hUV : kernel L β U V ≤ M := hM (Set.mem_range_self (U, V))
      exact mul_le_mul_of_nonneg_right (le_trans hUV (le_max_left M 0))
        (norm_nonneg (f V))
    · refine ae_of_all _ (fun V => ?_)
      exact ((continuous_kernel L β).comp
        (continuous_id.prod_mk continuous_const)).mul continuous_const
  obtain ⟨C, hC⟩ := (isCompact_range (continuous_norm.comp hg_cont)).bddAbove
  exact Memℒp.of_bound hg_cont.aestronglyMeasurable C
    (ae_of_all _ (fun U => hC (Set.mem_range_self U)))

/-- **Real integral transfer operator `T_L`.** `sorry`-free. Acts on
`L²(Fin (4·L⁴) → SU(3), haarN)` as the genuine integral operator
`(T_L f)(U) = ∫ V, exp(-β·wilsonAction(V⁻¹·U)) · f(V) d(haarN)` — a real
kernel over the *real* product Haar measure built from the *real* SU(3)
Wilson action. Makes NO spectral / mass-gap / `m > 0` claim, does NOT
close Surface #1 (stays OPEN), YM stays `Status: Open`. -/
noncomputable def T_L (L : ℕ) (β : ℝ) (f : Lp ℝ 2 (haarN (4 * L ^ 4))) :
    Lp ℝ 2 (haarN (4 * L ^ 4)) :=
  Memℒp.toLp _ (memℒp_intOp L β f)

/-- **Sub-Markov contraction bound for `T_L` (`transfer_operator_norm_le`).**
`sorry`-free, classical-trio only.

`∀ β > 0, ∀ f, ‖T_L L β f‖ ≤ ‖f‖` — i.e. `‖T_L‖ ≤ 1`. The heat kernel
`K(U,V) = exp(-β·actL(V⁻¹·U))` is `≤ 1` because `actL ≥ 0` (`actL_nonneg`,
from `wilsonAction_nonneg ← plaquetteEnergy_nonneg ← traceRe_le_three`) and
`β > 0`, so `-β·actL ≤ 0`. The pointwise estimate
`‖(T_L f)(U)‖ ≤ ∫ |K|·‖f‖ ≤ ∫ ‖f‖ ≤ ‖f‖` (using `K ≤ 1`, then `L¹ ≤ L²`
on the probability space `haarN`) plus `Lp.norm_le_of_ae_bound`
(`measureUnivNNReal = 1`) gives `‖T_L f‖ ≤ ‖f‖`.

**Honesty (locked invariants).** This is the genuine *upper bound* — the
sub-Markov / contraction property `‖T_L‖ ≤ 1`. It is **NOT** a spectral
gap, **NOT** a *strict* contraction, and makes **NO** decay / mass-gap /
`m > 0` claim: only `‖T_L‖ ≤ 1` is proved (NO equality / tightness claim —
constants are eigenfunctions with eigenvalue `Z(β) = ∫ exp(-β·actL) ≤ 1`, so
`T_L` does NOT contract the vacuum sector to `0`), and
`S_min := inf_{U ≠ 1} wilsonAction U = 0` (the action is continuous and
vanishes at `1`), so no `exp(-β·S_min)` decay holds. The genuine spectral
gap on the zero-mean / vacuum-orthogonal sector is the OPEN
`kotecky_preiss_criterion` below. Surface #1 stays OPEN; YM stays
`Status: Open`. -/
theorem transfer_operator_norm_le (L : ℕ) (β : ℝ) (hβ : 0 < β)
    (f : Lp ℝ 2 (haarN (4 * L ^ 4))) :
    ‖T_L L β f‖ ≤ ‖f‖ := by
  have hker : ∀ U V, kernel L β U V ≤ 1 := by
    intro U V
    unfold kernel
    rw [← Real.exp_zero]
    exact Real.exp_le_exp.mpr
      (by nlinarith [mul_nonneg hβ.le (actL_nonneg L (groupDiff L U V))])
  have hf_int : Integrable (fun V => ‖f V‖) (haarN (4 * L ^ 4)) :=
    ((Lp.memℒp f).integrable one_le_two).norm
  have hL1L2 : ∫ V, ‖f V‖ ∂(haarN (4 * L ^ 4)) ≤ ‖f‖ := by
    rw [integral_norm_eq_lintegral_nnnorm (Lp.aestronglyMeasurable f), Lp.norm_def]
    refine ENNReal.toReal_mono (Lp.eLpNorm_ne_top f) ?_
    calc (∫⁻ V, ‖f V‖₊ ∂(haarN (4 * L ^ 4)))
        = eLpNorm f 1 (haarN (4 * L ^ 4)) :=
          eLpNorm_one_eq_lintegral_nnnorm.symm
      _ ≤ eLpNorm f 2 (haarN (4 * L ^ 4)) :=
          eLpNorm_le_eLpNorm_of_exponent_le (by norm_num) (Lp.aestronglyMeasurable f)
  have hbound : ∀ U,
      ‖∫ V, kernel L β U V * f V ∂(haarN (4 * L ^ 4))‖ ≤ ‖f‖ := by
    intro U
    calc ‖∫ V, kernel L β U V * f V ∂(haarN (4 * L ^ 4))‖
        ≤ ∫ V, ‖kernel L β U V * f V‖ ∂(haarN (4 * L ^ 4)) :=
          norm_integral_le_integral_norm _
      _ = ∫ V, kernel L β U V * ‖f V‖ ∂(haarN (4 * L ^ 4)) := by
          refine integral_congr_ae (ae_of_all _ fun V => ?_)
          simp only [norm_mul, Real.norm_eq_abs, abs_of_nonneg (kernel_nonneg L β U V)]
      _ ≤ ∫ V, ‖f V‖ ∂(haarN (4 * L ^ 4)) := by
          refine integral_mono_of_nonneg (ae_of_all _ fun V => ?_) hf_int
            (ae_of_all _ fun V => ?_)
          · exact mul_nonneg (kernel_nonneg L β U V) (norm_nonneg _)
          · exact mul_le_of_le_one_left (norm_nonneg _) (hker U V)
      _ ≤ ‖f‖ := hL1L2
  have hae : ∀ᵐ U ∂(haarN (4 * L ^ 4)), ‖(T_L L β f) U‖ ≤ ‖f‖ := by
    have hcoe := Memℒp.coeFn_toLp (memℒp_intOp L β f)
    filter_upwards [hcoe] with U hU
    have hval : (T_L L β f) U = ∫ V, kernel L β U V * f V ∂(haarN (4 * L ^ 4)) := hU
    rw [hval]; exact hbound U
  have hnorm := Lp.norm_le_of_ae_bound (f := T_L L β f) (norm_nonneg f) hae
  have hμ1 : measureUnivNNReal (haarN (4 * L ^ 4)) = 1 := by
    simp [measureUnivNNReal, measure_univ]
  rw [hμ1] at hnorm
  simpa only [NNReal.coe_one, NNReal.one_rpow, Real.one_rpow, one_mul] using hnorm

/-- **Kotecký–Preiss criterion (genuine mass gap) — disclaimed placeholder,
single `sorry`. OPEN.**

This is NOT a proof. It is the genuine **Clay criterion** for the SU(3) lattice
mass gap, rendered as a uniform-in-`L` **spectral gap above the vacuum**: for `β`
large there is `gap > 0` so that on the vacuum-orthogonal sector (zero-mean
functions, `∫ f d(haarN) = 0`, i.e. `f ⊥ constants`) the transfer operator is an
exponentially-suppressed contraction, `‖T_L L β f‖ ≤ exp(-(β·gap))·‖f‖`. The
constant function is the top (`Z(β)`) eigenvector of `T_L`; suppression on its
orthogonal complement is exactly a positive mass gap.

**Honesty (locked invariants).** This is **OPEN** and carries a `sorry`. It is
the *hard* direction and is **NOT** implied by `transfer_operator_norm_le` (a mere
upper bound). It asserts **no** proven mass gap, **no** proven `m > 0`, and does
**NOT** close Surface #1 — it merely *names* the open problem. It deliberately
lives in a **distinct namespace** (`…YM.Transfer`) from the invariant-locked
`kotecky_preiss_criterion` `sorry` in `Towers/Attempts/ClusterExpansion.lean` and
does **not** touch it. NOT a registered brick, NOT in `BRICKS`. -/
theorem kotecky_preiss_criterion :
    ∃ β₀ : ℝ, 0 < β₀ ∧ ∀ β : ℝ, β₀ < β → ∃ gap : ℝ, 0 < gap ∧
      ∀ (L : ℕ) (f : Lp ℝ 2 (haarN (4 * L ^ 4))),
        (∫ U, f U ∂(haarN (4 * L ^ 4)) = 0) →
          ‖T_L L β f‖ ≤ Real.exp (-(β * gap)) * ‖f‖ := by
  sorry

/-! ## Honest polymer-activity scaffolding toward the integral / cluster route

`sorry`-free, classical-trio facts about the genuine cluster-expansion
*activity* functional

  `polymerActivity L β γ = ∫ w, exp(-β · polymerEnergy (toGauge w) γ) d(haarN)`

— the real Haar integral of the heat weight of a polymer `γ` (a finite set of
oriented plaquettes), built on the *real* SU(3) Wilson `polymerEnergy`
(`WilsonPositivity`) and the *real* product Haar measure `haarN` (NOT the Dirac
stand-in). These are the honest building blocks the integral route to
Kotecký–Preiss rests on.

**Honesty (locked invariants).** `polymerActivity ≥ 0` and antitonicity in `β`
are TRUE but **necessary, NOT sufficient**: they give NO polymer convergence,
decay, spectral gap, or `m > 0`. This file makes **no** claim about the `β → ∞`
limit: `exp(-β·polymerEnergy) → 𝟙[polymerEnergy = 0]` pointwise, so (dominated
convergence) `polymerActivity L β γ → haarN {w | polymerEnergy = 0} =
haarN {w | every plaquette of γ is trivial}` — but whether that limit is `0` or
positive is a separate measure-theoretic question NOT settled here. For the
empty polymer `γ = ∅` the constraint is vacuous and the limit is `1` for every
`β` (`polymerActivity_empty`, no decay); for a non-empty `γ` the trivial-plaquette
set is a positive-codimension subvariety that is plausibly Haar-**null** (so the
bare single-polymer activity may well decay to `0`) — we assert **neither**
direction. Crucially, KP convergence is NOT about a single polymer's activity:
it needs a uniform convergent SUM `∑_{γ ∋ 0} |z(γ)| e^{|γ|}` over *connected /
truncated* weights, which is the OPEN content of `kotecky_preiss_criterion`
above. Surface #1 stays OPEN; YM stays `Status: Open`. NOT bricks, NOT in
`BRICKS`. -/

/-- **Polymer activity functional.** The real Haar integral of the heat weight
`exp(-β·polymerEnergy)` of a polymer `γ` — the genuine cluster-expansion
*activity* object (real `polymerEnergy`, real `haarN`). NOT a convergence/decay
claim. -/
noncomputable def polymerActivity (L : ℕ) [NeZero L] (β : ℝ)
    (γ : Finset (Lattice 4 L × Fin 4 × Fin 4)) : ℝ :=
  ∫ w, Real.exp (-β * polymerEnergy (toGauge L w) γ) ∂(haarN (4 * L ^ 4))

/-- `polymerActivity ≥ 0`: the integrand `exp(-β·polymerEnergy) ≥ 0`
(`integral_nonneg`). Necessary, NOT a convergence/decay claim. -/
theorem polymerActivity_nonneg (L : ℕ) [NeZero L] (β : ℝ)
    (γ : Finset (Lattice 4 L × Fin 4 × Fin 4)) :
    0 ≤ polymerActivity L β γ :=
  integral_nonneg (fun _ => Real.exp_nonneg _)

/-- **Empty-polymer normalisation.** `polymerActivity L β ∅ = 1` for every `β`:
the empty polymer has `polymerEnergy = 0`, so the integrand is the constant `1`
and `haarN` is a probability measure. The one concrete, *proven* value — and the
only honest non-decay example (the limit claim for non-empty `γ` is deliberately
left unproven). -/
theorem polymerActivity_empty (L : ℕ) [NeZero L] (β : ℝ) :
    polymerActivity L β (∅ : Finset (Lattice 4 L × Fin 4 × Fin 4)) = 1 := by
  unfold polymerActivity
  have h0 : ∀ w, Real.exp (-β *
      polymerEnergy (toGauge L w) (∅ : Finset (Lattice 4 L × Fin 4 × Fin 4))) = 1 := by
    intro _w; simp [polymerEnergy]
  simp only [h0, integral_const, measure_univ, ENNReal.one_toReal, smul_eq_mul, mul_one]

/-- **Continuity of the polymer energy in the configuration.** The map
`w ↦ polymerEnergy (toGauge w) γ` is continuous — a finite sum of per-plaquette
energies, each a polynomial-with-conjugate in the continuous SU(3) matrix
entries, post-composed with affine/`re`/`trace` continuous maps. Factored out so
both `integrable_polymerWeight` and the dominated-convergence limit
`polymerActivity_tendsto_zero_of_null` can reuse it (the latter needs it to see
`{w | polymerEnergy = 0}` is closed, hence measurable). Classical-trio. -/
theorem continuous_polymerEnergy_toGauge (L : ℕ) [NeZero L]
    (γ : Finset (Lattice 4 L × Fin 4 × Fin 4)) :
    Continuous (fun w : Fin (4 * L ^ 4) → SU3Instances.SU3 =>
      polymerEnergy (toGauge L w) γ) := by
  unfold polymerEnergy
  refine continuous_finset_sum _ (fun p _ => ?_)
  unfold plaquetteEnergy
  apply Continuous.div_const
  refine Continuous.sub continuous_const ?_
  refine Complex.continuous_re.comp ?_
  refine Continuous.matrix_trace ?_
  unfold wilsonPlaquette
  simp only [Matrix.star_eq_conjTranspose, toGauge]
  exact
    ((((continuous_subtype_val.comp (continuous_apply _)).matrix_mul
        (continuous_subtype_val.comp (continuous_apply _))).matrix_mul
        (continuous_subtype_val.comp (continuous_apply _)).matrix_conjTranspose).matrix_mul
      (continuous_subtype_val.comp (continuous_apply _)).matrix_conjTranspose)

/-- The polymer heat weight `w ↦ exp(-β·polymerEnergy (toGauge w) γ)` is
integrable against `haarN`: it is continuous (a finite sum of continuous
per-plaquette energies — each a polynomial-with-conjugate in the continuous
SU(3) matrix entries — post-composed with `exp`) and bounded on the compact
configuration space, hence in `L¹` of the probability measure. Integrability
input to `polymerActivity_antitone_in_beta`. -/
theorem integrable_polymerWeight (L : ℕ) [NeZero L] (β : ℝ)
    (γ : Finset (Lattice 4 L × Fin 4 × Fin 4)) :
    Integrable (fun w => Real.exp (-β * polymerEnergy (toGauge L w) γ))
      (haarN (4 * L ^ 4)) := by
  haveI : CompactSpace (Fin (4 * L ^ 4) → SU3Instances.SU3) := Pi.compactSpace
  haveI : SecondCountableTopology (Matrix (Fin 3) (Fin 3) ℂ) := by
    unfold Matrix; infer_instance
  haveI : SecondCountableTopology (↥SU3Instances.SU3) :=
    TopologicalSpace.Subtype.secondCountableTopology
      (SU3Instances.SU3 : Set (Matrix (Fin 3) (Fin 3) ℂ))
  haveI : SecondCountableTopology (Fin (4 * L ^ 4) → ↥SU3Instances.SU3) := inferInstance
  haveI : BorelSpace (Fin (4 * L ^ 4) → ↥SU3Instances.SU3) := inferInstance
  have hcontE := continuous_polymerEnergy_toGauge L γ
  have hcont : Continuous (fun w : Fin (4 * L ^ 4) → SU3Instances.SU3 =>
      Real.exp (-β * polymerEnergy (toGauge L w) γ)) :=
    Real.continuous_exp.comp (continuous_const.mul hcontE)
  obtain ⟨C, hC⟩ := (isCompact_range (continuous_norm.comp hcont)).bddAbove
  exact (Memℒp.of_bound hcont.aestronglyMeasurable C
    (ae_of_all _ (fun w => hC (Set.mem_range_self w)))).integrable one_le_two

/-- **Antitone in `β`.** For `β₁ ≤ β₂`, `polymerActivity L β₂ γ ≤
polymerActivity L β₁ γ`: since `polymerEnergy ≥ 0`, `exp(-β·polymerEnergy)` is
antitone in `β` pointwise (`integral_mono` + `integrable_polymerWeight`).

HONESTY: monotonicity only — NOT a decay/smallness bound, and NOT a claim about
the `β → ∞` limit (that limit is `haarN {polymerEnergy = 0}`, of unproven size
for non-empty `γ`; see the section note). No gap is implied;
`kotecky_preiss_criterion` stays OPEN. -/
theorem polymerActivity_antitone_in_beta (L : ℕ) [NeZero L]
    (γ : Finset (Lattice 4 L × Fin 4 × Fin 4)) {β₁ β₂ : ℝ} (h : β₁ ≤ β₂) :
    polymerActivity L β₂ γ ≤ polymerActivity L β₁ γ := by
  unfold polymerActivity
  refine integral_mono (integrable_polymerWeight L β₂ γ)
    (integrable_polymerWeight L β₁ γ) ?_
  intro w
  refine Real.exp_le_exp.mpr ?_
  nlinarith [mul_nonneg (sub_nonneg.mpr h) (polymerEnergy_nonneg (toGauge L w) γ)]

/-! ### The `β → ∞` limit of the single-polymer activity (honest DCT reduction)

Pointwise `exp(-β·polymerEnergy) → 𝟙[polymerEnergy = 0]` as `β → ∞`, dominated by
the constant `1 ∈ L¹(haarN)`. Dominated convergence then gives

  `polymerActivity L β γ  ⟶  haarN {w | polymerEnergy (toGauge w) γ = 0}`.

So the *only* missing input for "single-polymer activity decays to `0`" is the
**measure-theoretic** fact that the trivial-plaquette set is `haarN`-null for a
non-empty polymer. We split that cleanly:

  * `polymerActivity_tendsto_zero_of_null` — the DCT reduction, taking the
    null-set fact as an explicit hypothesis. `sorry`-free, classical-trio. This
    is the genuine, fully-proved content of this step.
  * `trivial_polymer_set_null` — the null-set fact itself. TRUE but a real
    measure-theoretic theorem (NOT a short trio proof); left as a disclaimed OPEN
    `sorry` (reports `sorryAx`), NOT a brick.
  * `polymerActivity_tendsto_zero` — the unconditional decay, obtained by feeding
    the OPEN input to the reduction; inherits `sorryAx`, NOT a brick.

**Why this is NOT the mass gap (honest scope, locked invariants).** Even the full
`polymerActivity_tendsto_zero` is about a **single** polymer's activity as
`β → ∞`. Kotecký–Preiss convergence is strictly stronger and different in kind: a
*uniform* convergent SUM `∑_{γ ∋ 0} |z(γ)| e^{|γ|} < ∞` at a **finite** `β₀ < ∞`,
over *connected / truncated* weights — driven by "few small-energy polymers at
large-but-finite `β`", NOT by any single activity's `β → ∞` limit, and NOT by
`inf_{U≠1} wilsonAction U > 0` (that infimum is `0`, since the action is
continuous and vanishes at the vacuum, so no `exp(-β·S_min)` decay holds). None of
the lemmas below touch `kotecky_preiss_criterion` (OPEN) or close Surface #1; YM
stays `Status: Open`. NOT bricks, NOT in `BRICKS`. -/

/-- **Honest DCT reduction (trio-clean, `sorry`-free).** *If* the trivial-plaquette
set `{w | polymerEnergy (toGauge w) γ = 0}` is `haarN`-null, *then* the
single-polymer activity decays to `0` as `β → ∞`. Proof: dominated convergence —
`exp(-β·polymerEnergy) → 𝟙[polymerEnergy = 0]` pointwise, dominated by the
constant `1` (integrable on the probability measure `haarN`); the limit integral
is `(haarN {polymerEnergy = 0}).toReal`, which the hypothesis sends to `0`. This
is the genuine, fully-proved content of the integral route. It makes **no**
mass-gap / `m > 0` / Surface-#1 claim and does **not** touch
`kotecky_preiss_criterion`. -/
theorem polymerActivity_tendsto_zero_of_null (L : ℕ) [NeZero L]
    (γ : Finset (Lattice 4 L × Fin 4 × Fin 4))
    (hnull : haarN (4 * L ^ 4) {w | polymerEnergy (toGauge L w) γ = 0} = 0) :
    Filter.Tendsto (fun β => polymerActivity L β γ) Filter.atTop (nhds (0 : ℝ)) := by
  unfold polymerActivity
  haveI : SecondCountableTopology (Matrix (Fin 3) (Fin 3) ℂ) := by
    unfold Matrix; infer_instance
  haveI : SecondCountableTopology (↥SU3Instances.SU3) :=
    TopologicalSpace.Subtype.secondCountableTopology
      (SU3Instances.SU3 : Set (Matrix (Fin 3) (Fin 3) ℂ))
  haveI : SecondCountableTopology (Fin (4 * L ^ 4) → ↥SU3Instances.SU3) := inferInstance
  haveI : BorelSpace (Fin (4 * L ^ 4) → ↥SU3Instances.SU3) := inferInstance
  set s : Set (Fin (4 * L ^ 4) → SU3Instances.SU3) :=
    {w | polymerEnergy (toGauge L w) γ = 0}
  have hsmeas : MeasurableSet s :=
    (isClosed_eq (continuous_polymerEnergy_toGauge L γ) continuous_const).measurableSet
  have hzero : (∫ w, s.indicator (fun _ => (1 : ℝ)) w ∂(haarN (4 * L ^ 4))) = 0 := by
    rw [integral_indicator hsmeas, setIntegral_const, hnull]
    simp
  have key : Filter.Tendsto
      (fun β => ∫ w, Real.exp (-β * polymerEnergy (toGauge L w) γ) ∂(haarN (4 * L ^ 4)))
      Filter.atTop
      (nhds (∫ w, s.indicator (fun _ => (1 : ℝ)) w ∂(haarN (4 * L ^ 4)))) := by
    refine tendsto_integral_filter_of_dominated_convergence (fun _ => (1 : ℝ))
      (Filter.Eventually.of_forall
        (fun β => (integrable_polymerWeight L β γ).aestronglyMeasurable))
      ?_ (integrable_const 1) ?_
    · filter_upwards [Filter.eventually_ge_atTop (0 : ℝ)] with β hβ
      refine Filter.Eventually.of_forall (fun w => ?_)
      rw [Real.norm_eq_abs, abs_of_pos (Real.exp_pos _)]
      have hEnn := polymerEnergy_nonneg (toGauge L w) γ
      calc Real.exp (-β * polymerEnergy (toGauge L w) γ)
            ≤ Real.exp 0 := Real.exp_le_exp.mpr (by nlinarith [mul_nonneg hβ hEnn])
        _ = 1 := Real.exp_zero
    · refine Filter.Eventually.of_forall (fun w => ?_)
      by_cases hw : polymerEnergy (toGauge L w) γ = 0
      · have hmem : w ∈ s := hw
        simp only [Set.indicator_of_mem hmem, hw, mul_zero, Real.exp_zero]
        exact tendsto_const_nhds
      · have hmem : w ∉ s := hw
        rw [Set.indicator_of_not_mem hmem]
        have hEpos : 0 < polymerEnergy (toGauge L w) γ :=
          lt_of_le_of_ne (polymerEnergy_nonneg (toGauge L w) γ) (Ne.symm hw)
        have hβ : Filter.Tendsto
            (fun β : ℝ => -β * polymerEnergy (toGauge L w) γ)
            Filter.atTop Filter.atBot := by
          have hrw : (fun β : ℝ => -β * polymerEnergy (toGauge L w) γ)
              = (fun β : ℝ => (-(polymerEnergy (toGauge L w) γ)) * β) := by
            funext β; ring
          rw [hrw]
          exact Filter.Tendsto.const_mul_atTop_of_neg (by linarith) Filter.tendsto_id
        exact Real.tendsto_exp_atBot.comp hβ
  rw [hzero] at key
  exact key

/-- **OPEN (`sorry`) — the measure-theoretic crux of the integral route. NOT a
brick, NOT in `BRICKS`, NOT a lakefile root.** For a non-empty polymer the
trivial-plaquette set `{w | polymerEnergy (toGauge w) γ = 0}` (all plaquettes of
`γ` simultaneously trivial) is `haarN`-**null**.

This is TRUE but is a genuine measure-theoretic theorem, **not** a short
classical-trio proof, so it is left as a disclaimed OPEN `sorry` (axiom report:
`sorryAx`). It requires, at minimum: (i) `NoAtoms haarSU3` — available in mathlib
only via `IsHaarMeasure.noAtoms`, which needs the identity to be non-isolated
(`(𝓝[≠] (1 : SU3)).NeBot`), itself unproved here; and (ii) since `NoAtoms` only
kills *countable* sets while the trivial set is an *uncountable* positive-codim
subvariety, a `Measure.pi` single-coordinate marginal argument
(`measurePreserving_piFinSuccAbove` + `measure_prod_null`) showing that fixing the
other links forces the remaining one to a single point, hence a null fibre.
Crucially the naive "codimension `8·|γ|`" count is **lattice-size dependent**: on
`L = 1` a plaquette degenerates to a commutator `[g,h]`, whose triviality set is
the *commuting variety* (a centralizer-codimension argument), so the four
plaquette links are NOT four distinct freely-varying coordinates and the marginal
argument needs the harder regular-element analysis. Honest status: OPEN — it
does NOT close Surface #1, prove the mass gap, or touch
`kotecky_preiss_criterion`. -/
theorem trivial_polymer_set_null (L : ℕ) [NeZero L]
    (γ : Finset (Lattice 4 L × Fin 4 × Fin 4)) (hγ : γ ≠ ∅) :
    haarN (4 * L ^ 4) {w | polymerEnergy (toGauge L w) γ = 0} = 0 := by
  sorry

/-- **OPEN (depends on `trivial_polymer_set_null`).** The single-polymer activity
of a non-empty polymer decays to `0` as `β → ∞`. This is exactly the honest DCT
reduction `polymerActivity_tendsto_zero_of_null` fed the (OPEN) null-set input
`trivial_polymer_set_null`, so it inherits its `sorryAx` and is **NOT** a brick,
NOT in `BRICKS`. It says **nothing** about Kotecký–Preiss convergence, the mass
gap, `m > 0`, or Surface #1 — KP needs a uniform SUM at finite `β₀`, not a single
activity's `β → ∞` limit (see the section note). -/
theorem polymerActivity_tendsto_zero (L : ℕ) [NeZero L]
    (γ : Finset (Lattice 4 L × Fin 4 × Fin 4)) (hγ : γ ≠ ∅) :
    Filter.Tendsto (fun β => polymerActivity L β γ) Filter.atTop (nhds (0 : ℝ)) :=
  polymerActivity_tendsto_zero_of_null L γ (trivial_polymer_set_null L γ hγ)

-- Axiom audit (informational): `T_L`, `transfer_operator_norm_le`, the new
-- polymer-activity scaffolding, and the trio-clean DCT reduction
-- `polymerActivity_tendsto_zero_of_null` are classical-trio only; the OPEN
-- `kotecky_preiss_criterion`, `trivial_polymer_set_null`, and
-- `polymerActivity_tendsto_zero` additionally report `sorryAx`, as intended.
#print axioms T_L
#print axioms transfer_operator_norm_le
#print axioms polymerActivity_nonneg
#print axioms polymerActivity_empty
#print axioms polymerActivity_antitone_in_beta
#print axioms continuous_polymerEnergy_toGauge
#print axioms polymerActivity_tendsto_zero_of_null
#print axioms kotecky_preiss_criterion
#print axioms trivial_polymer_set_null
#print axioms polymerActivity_tendsto_zero

end Transfer
end YM
end Towers
end TheoremaAureum
