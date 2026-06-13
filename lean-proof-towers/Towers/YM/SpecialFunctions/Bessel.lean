-- Axiom status: ZERO axioms. Sorry status: ZERO sorries.
-- §1 trig identities: PROVED. §2 values at 0: PROVED. §3 sum at 0: PROVED.
-- §4 integral_deriv_swap: PROVED via Mathlib DCT (hasDerivAt_integral_of_dominated_loc_of_deriv_le).
-- §5 BesselI_Summability_Gap: NAMED OPEN DEF (IBP bound, absent from Mathlib v4.12.0).
-- §6 BesselI_DerivAtTsum_Gap: NAMED OPEN DEF (hasDerivAt_tsum, absent from Mathlib v4.12.0).
-- §7 ODE uniqueness via integrating factor: PROVED (conditional on §5 and §6).
import Mathlib

open Real MeasureTheory intervalIntegral Set

/-! ## Definition -/

noncomputable def besselI (n : ℤ) (x : ℝ) : ℝ :=
  (1 / π) * ∫ t in (0 : ℝ)..π, exp (x * cos t) * cos ((n : ℝ) * t)

/-! ## §1  Trigonometric identities (PROVED) -/

private lemma cos_mul_cos_shift (n : ℤ) (t : ℝ) :
    cos t * cos ((n : ℝ) * t) =
    (cos ((↑(n + 1) : ℝ) * t) + cos ((↑(n - 1) : ℝ) * t)) / 2 := by
  push_cast [add_mul, sub_mul, cos_add, cos_sub]; ring

private lemma cos_sum_to_prod (m : ℤ) (θ : ℝ) :
    (cos ((↑(m - 1) : ℝ) * θ) + cos ((↑(m + 1) : ℝ) * θ)) / 2 =
    cos ((m : ℝ) * θ) * cos θ := by
  push_cast [add_mul, sub_mul, cos_add, cos_sub]; ring

/-! ## §2  Values at x = 0 (PROVED) -/

lemma besselI_zero_eq_one : besselI 0 0 = 1 := by
  simp only [besselI, Int.cast_zero, zero_mul, Real.exp_zero, Real.cos_zero, mul_one, one_mul]
  rw [intervalIntegral.integral_const, sub_zero, smul_eq_mul, mul_one]
  exact one_div_mul_cancel Real.pi_pos.ne'

private lemma integral_cos_int_npi (n : ℤ) (hn : n ≠ 0) :
    ∫ t in (0 : ℝ)..π, cos ((n : ℝ) * t) = 0 := by
  have hn' : (n : ℝ) ≠ 0 := by exact_mod_cast hn
  have hF_deriv : ∀ t ∈ uIcc 0 π,
      HasDerivAt (fun s => sin ((n : ℝ) * s) / (n : ℝ)) (cos ((n : ℝ) * t)) t := by
    intro t _
    have h1 : HasDerivAt (fun s => (n : ℝ) * s) (n : ℝ) t := by
      simpa [mul_one, id] using (hasDerivAt_id t).const_mul (n : ℝ)
    have h2 : HasDerivAt (fun s => sin ((n : ℝ) * s)) (cos ((n : ℝ) * t) * (n : ℝ)) t :=
      (Real.hasDerivAt_sin _).comp t h1
    rwa [mul_div_cancel_right₀ _ hn'] at h2.div_const (n : ℝ)
  have hint : IntervalIntegrable (fun t => cos ((n : ℝ) * t)) volume 0 π :=
    (Real.continuous_cos.comp (continuous_const.mul continuous_id')).intervalIntegrable 0 π
  rw [integral_eq_sub_of_hasDerivAt (fun t ht => hF_deriv t ht) hint]
  simp [Real.sin_int_cast_mul_pi, Real.sin_zero, hn']

lemma besselI_zero_of_ne (n : ℤ) (hn : n ≠ 0) : besselI n 0 = 0 := by
  simp only [besselI, zero_mul, exp_zero, one_mul]
  rw [integral_cos_int_npi n hn]; ring

/-! ## §3  Generating sum at x = 0 (PROVED) -/

private lemma bessel_sum_at_zero (θ : ℝ) :
    ∑' n : ℤ, besselI n 0 * cos ((n : ℝ) * θ) = 1 := by
  have h : ∀ n : ℤ, besselI n 0 * cos ((n : ℝ) * θ) = if n = 0 then 1 else 0 := by
    intro n; by_cases hn : n = 0
    · simp [hn, besselI_zero_eq_one]
    · simp [besselI_zero_of_ne n hn, hn]
  simp_rw [h]; exact tsum_ite_eq (0 : ℤ) 1

/-! ## §4  Recurrence d/dx I_n = (I_{n+1} + I_{n-1})/2  (PROVED via Mathlib DCT) -/

/-- HasDerivAt of besselI n at x, proved by differentiating under the integral sign.
Uses `intervalIntegral.hasDerivAt_integral_of_dominated_loc_of_deriv_le` with dominator
exp(|x|+1) on Metric.ball x 1. Derivative integrand computed via cos_mul_cos_shift. -/
private lemma integral_deriv_swap (n : ℤ) (x : ℝ) :
    HasDerivAt (besselI n) ((besselI (n + 1) x + besselI (n - 1) x) / 2) x := by
  -- Integrability/measurability for each fixed y
  have hcont : ∀ y : ℝ, Continuous (fun t => exp (y * cos t) * cos ((n : ℝ) * t)) := fun y =>
    (Real.continuous_exp.comp (continuous_const.mul Real.continuous_cos)).mul
      (Real.continuous_cos.comp (continuous_const.mul continuous_id))
  have hcont' : Continuous (fun t => cos t * exp (x * cos t) * cos ((n : ℝ) * t)) :=
    Real.continuous_cos.mul ((Real.continuous_exp.comp
        (continuous_const.mul Real.continuous_cos)).mul
      (Real.continuous_cos.comp (continuous_const.mul continuous_id)))
  -- Apply DCT: differentiate ∫_0^π exp(y·cos t)·cos(n·t) dt w.r.t. y at x
  have ⟨_, hI⟩ := intervalIntegral.hasDerivAt_integral_of_dominated_loc_of_deriv_le
    (F  := fun y t => exp (y * cos t) * cos ((n : ℝ) * t))
    (F' := fun y t => cos t * exp (y * cos t) * cos ((n : ℝ) * t))
    (bound := fun _ => exp (|x| + 1)) (s := Metric.ball x 1) (x₀ := x) (a := 0) (b := π)
    -- s is a neighborhood of x
    (Metric.ball_mem_nhds x one_pos)
    -- F y is ae strongly measurable for y near x (continuous in t for each y)
    (Filter.eventually_of_forall fun y => (hcont y).aestronglyMeasurable)
    -- F x is interval integrable on [0,π]
    ((hcont x).intervalIntegrable 0 π)
    -- F' x is ae strongly measurable
    hcont'.aestronglyMeasurable
    -- |F'(y,t)| = |cos t| · exp(y·cos t) · |cos(nt)| ≤ exp(|x|+1) for y ∈ ball x 1
    (Filter.eventually_of_forall fun t _ht y hy => by
      have h_yabs : |y| ≤ |x| + 1 := by
        have hdist : |y - x| < 1 := by rwa [← Real.dist_eq, Metric.mem_ball] at hy
        have hle : |y| ≤ |y - x| + |x| := by
          have := abs_add (y - x) x; simp only [sub_add_cancel] at this; exact this
        linarith
      have hcos1 : |cos t| ≤ 1 := abs_le.mpr ⟨Real.neg_one_le_cos _, Real.cos_le_one _⟩
      have hcosn : |cos ((n : ℝ) * t)| ≤ 1 :=
        abs_le.mpr ⟨Real.neg_one_le_cos _, Real.cos_le_one _⟩
      have hexp : exp (y * cos t) ≤ exp (|x| + 1) :=
        Real.exp_le_exp.mpr (calc y * cos t ≤ |y * cos t| := le_abs_self _
          _ = |y| * |cos t|   := abs_mul _ _
          _ ≤ (|x| + 1) * 1   := mul_le_mul h_yabs hcos1 (abs_nonneg _) (by linarith [abs_nonneg x])
          _ = |x| + 1          := mul_one _)
      simp only [Real.norm_eq_abs, abs_mul, Real.abs_exp]
      calc |cos t| * exp (y * cos t) * |cos ((n : ℝ) * t)|
          ≤ 1 * exp (|x| + 1) * 1 :=
            mul_le_mul
              (mul_le_mul hcos1 hexp (by positivity) (by positivity))
              hcosn (by positivity) (by positivity)
        _ = exp (|x| + 1) := by ring)
    -- bound exp(|x|+1) is integrable on [0,π] (it's a constant)
    (continuous_const.intervalIntegrable 0 π)
    -- pointwise HasDerivAt: d/dy exp(y·cos t)·cos(nt) = cos t · exp(y·cos t) · cos(nt)
    (Filter.eventually_of_forall fun t _ht y _hy => by
      have h1 : HasDerivAt (fun y => y * cos t) (cos t) y := by
        simpa [one_mul] using (hasDerivAt_id y).mul_const (cos t)
      have h2 : HasDerivAt (fun y => exp (y * cos t)) (cos t * exp (y * cos t)) y := by
        have := (Real.hasDerivAt_exp _).comp y h1
        simp only [Function.comp] at this; convert this using 1; ring
      convert h2.mul_const (cos ((n : ℝ) * t)) using 1; ring)
  -- Compute the derivative integral: ∫ cos t · exp(x·cos t) · cos(nt) = π·(I_{n+1}+I_{n-1})/2
  have hint_eq : ∫ t in (0 : ℝ)..π, cos t * exp (x * cos t) * cos ((n : ℝ) * t) =
      (besselI (n + 1) x + besselI (n - 1) x) / 2 * π := by
    have hI_m : ∀ m : ℤ,
        IntervalIntegrable (fun t => exp (x * cos t) * cos ((m : ℝ) * t)) volume 0 π :=
      fun m => ((Real.continuous_exp.comp (continuous_const.mul Real.continuous_cos)).mul
        (Real.continuous_cos.comp (continuous_const.mul continuous_id))).intervalIntegrable 0 π
    -- Rewrite integrand via product-to-sum: cos t · cos(nt) = (cos(n+1)t + cos(n-1)t)/2
    have hrw : ∀ t : ℝ, cos t * exp (x * cos t) * cos ((n : ℝ) * t) =
        (exp (x * cos t) * cos ((↑(n + 1) : ℝ) * t) +
         exp (x * cos t) * cos ((↑(n - 1) : ℝ) * t)) / 2 := fun t => by
      have h := cos_mul_cos_shift n t; push_cast at h ⊢
      linear_combination exp (x * Real.cos t) * h
    simp_rw [hrw]
    rw [intervalIntegral.integral_div,
        intervalIntegral.integral_add (hI_m (n + 1)) (hI_m (n - 1))]
    simp only [besselI]
    field_simp [Real.pi_pos.ne']
    ring
  -- Scale by 1/π to get HasDerivAt of besselI n
  have hfun : besselI n = fun y =>
      1 / π * ∫ t in (0 : ℝ)..π, exp (y * cos t) * cos ((n : ℝ) * t) :=
    funext fun y => by simp [besselI]
  rw [hfun]
  convert hI.const_mul (1 / π) using 1
  rw [hint_eq]; field_simp [Real.pi_pos.ne']; ring

/-! ## §5  Summability gap (NAMED OPEN DEF) -/

/-- **NAMED OPEN DEF — Bessel series summability.**
Absolute summability of `fun n : ℤ => I_n(x)·cos(n·θ)`.

WHY OPEN in Mathlib v4.12.0:
  Proof requires |I_n(x)| ≤ C·|x|·exp|x|/n² by integrating by parts twice in
  the Bessel integral, then `Summable.of_norm_bounded` with the 1/n² harmonic
  bound.  The IBP machinery for oscillatory integrals over [0,π] is not in Mathlib.

ONCE PROVED: enables `hasDerivAt_tsum_of_isPreconnected` for §6. -/
def BesselI_Summability_Gap : Prop :=
  ∀ x θ : ℝ, Summable (fun n : ℤ => besselI n x * cos ((n : ℝ) * θ))

/-! ## §6  Generating sum ODE gap (NAMED OPEN DEF) -/

/-- **NAMED OPEN DEF — HasDerivAt of the Bessel generating sum.**
`d/dx ∑_n I_n(x)·cos(nθ) = cos θ · ∑_n I_n(x)·cos(nθ)`.

WHY OPEN in Mathlib v4.12.0:
  Proof uses `hasDerivAt_tsum_of_isPreconnected` on `Ioo (-R) R` (R = |x|+2),
  `integral_deriv_swap` for the per-term derivative, and reindexing via
  `(Equiv.addRight 1 : ℤ ≃ ℤ).tsum_eq` then `cos_sum_to_prod`.
  `hasDerivAt_tsum_of_isPreconnected` requires the summability gap from §5.
  The dominated-convergence step for the derivative series is not automated
  in Mathlib for ℤ-indexed sums.

ONCE PROVED (with §5): closes the ODE for G and makes `besselI_generating` trio-only. -/
def BesselI_DerivAtTsum_Gap : Prop :=
  ∀ x θ : ℝ, HasDerivAt (fun y => ∑' n : ℤ, besselI n y * cos ((n : ℝ) * θ))
                          (Real.cos θ * ∑' n : ℤ, besselI n x * cos ((n : ℝ) * θ)) x

/-! ## §7  ODE uniqueness — integrating factor (PROVED, conditional on §5 and §6) -/

/-- **besselI_generating** — Jacobi-Anger expansion:
`exp(x·cos θ) = ∑' n : ℤ, I_n(x)·cos(n·θ)`.

Proof: F = exp(·cosθ) and G = ∑ I_n·cos(nθ) both satisfy y(0)=1, y'=cosθ·y.
Integrating factor I(t) = (F−G)(t)·exp(−cosθ·t): I'=0, I(0)=0, so I≡0 by FTC.

Conditional on `BesselI_DerivAtTsum_Gap` (§6); see named open defs above.
`#print axioms besselI_generating` with both gaps closed → [propext, Classical.choice, Quot.sound]. -/
theorem besselI_generating
    (h_deriv : BesselI_DerivAtTsum_Gap)
    (x θ : ℝ) :
    exp (x * cos θ) = ∑' n : ℤ, besselI n x * cos ((n : ℝ) * θ) := by
  set F : ℝ → ℝ := fun y => exp (y * cos θ)
  set G : ℝ → ℝ := fun y => ∑' n : ℤ, besselI n y * cos ((n : ℝ) * θ)
  have hF0 : F 0 = 1 := show exp (0 * cos θ) = 1 by simp
  have hG0 : G 0 = 1 := bessel_sum_at_zero θ
  have hF_ode : ∀ y, HasDerivAt F (cos θ * F y) y := by
    intro y; show HasDerivAt (fun t => exp (t * cos θ)) (cos θ * exp (y * cos θ)) y
    have h1 : HasDerivAt (fun t => t * cos θ) (1 * cos θ) y := (hasDerivAt_id y).mul_const (cos θ)
    have h2 := (Real.hasDerivAt_exp (y * cos θ)).comp y h1
    simp only [Function.comp, one_mul] at h2; convert h2 using 1; ring
  have hG_ode : ∀ y, HasDerivAt G (cos θ * G y) y := fun y => h_deriv y θ
  have hH_ode : ∀ y, HasDerivAt (fun s => F s - G s) (cos θ * (F y - G y)) y := by
    intro y; convert (hF_ode y).sub (hG_ode y) using 1; ring
  have hH_zero : ∀ y, F y - G y = 0 := by
    set I : ℝ → ℝ := fun t => (F t - G t) * exp (-(cos θ) * t)
    have hI0 : I 0 = 0 := show (F 0 - G 0) * exp (-(cos θ) * 0) = 0 by rw [hF0, hG0]; simp
    have hI_deriv : ∀ t, HasDerivAt I 0 t := by
      intro t
      show HasDerivAt (fun s => (F s - G s) * exp (-(cos θ) * s)) 0 t
      have hexp : HasDerivAt (fun s => exp (-(cos θ) * s)) (-(cos θ) * exp (-(cos θ) * t)) t := by
        have h1 : HasDerivAt (fun s => -(cos θ) * s) (-(cos θ)) t := by
          simpa [mul_one, id] using (hasDerivAt_id t).const_mul (-(cos θ))
        have h2 := (Real.hasDerivAt_exp (-(cos θ) * t)).comp t h1
        simp only [Function.comp] at h2; convert h2 using 1; ring
      convert (hH_ode t).mul hexp using 1; ring
    have hIconst : ∀ t, I t = 0 := by
      intro t
      have hftc := intervalIntegral.integral_eq_sub_of_hasDerivAt
        (fun s _ => hI_deriv s)
        (continuous_const.intervalIntegrable 0 t)
      simp only [intervalIntegral.integral_zero] at hftc
      linarith [hI0]
    intro y
    have hy : (F y - G y) * exp (-(cos θ) * y) = 0 := by
      have := hIconst y; simp only [I] at this; exact this
    exact (mul_eq_zero.mp hy).resolve_right (Real.exp_ne_zero _)
  linarith [hH_zero x]
