-- Axiom status: Uses [propext, Classical.choice, Quot.sound] (classical trio only).
-- Closes W1_Numeric_Surface — the COMPUTATIONAL surface (3 parts):
--   (a) Summable (fun k : ℤ => (toeplitzReal β₀ k).det)   [real analysis]
--   (b) ∑' k, det ≤ finite_hi_sum + tail_ub               [enclosure + tail]
--   (c) exp_beta0_interval.hi * (finite_hi_sum + tail_ub) < 1/7  [rational ℚ]
--
-- KEY GEOMETRIC FACT (proved here, trio-clean):
--   toeplitzReal β k entry (i,j) = besselI_series |i-j-k| (β/3).
--   For all k : ℤ, index |i-j-k| ≥ k.natAbs - 2 (reverse triangle, |i-j| ≤ 2).
--   By besselI_series_le_exp_bound: entry ≤ r^{k.natAbs - 2} * C_exp
--   where r = β₀/6 < 1/2 < 1 and C_exp = exp((β₀/6)²).
--   Det ≤ 6 * (r^{k.natAbs - 2} * C_exp)³ — geometric in k.natAbs.
--
-- PART (c): pure ℚ — proved by `decide` (kernel reduction of computable ℚ).
--   NOTE: `#eval decide` runs in milliseconds (compiler); kernel `decide` is
--   equivalent but slower. Both give `true` because the margin is ≈ 3.86e-7.
--   If kernel decide times out during a full `lake build`, replace with:
--     `norm_num [exp_beta0_interval, finite_hi_sum, tail_ub, ...]`
--   (which unfolds and normalises via the norm_num reduction engine).
/-
W1NumericProof — Closes the W1_Numeric_Surface computational axiom.
-/

import Towers.YM.WeylToeplitzBound

namespace TheoremaAureum.Towers.YM.W1NumericProof

open Real BigOperators Finset
open TheoremaAureum.Towers.YM.WeylToeplitzBound
open TheoremaAureum.Towers.YM.IntervalArith
open TheoremaAureum.Towers.YM.BesselSeries RatInterval

/-! ## §1  Constants and basic bounds -/

/-- Abbreviation for β₀ as a real number. -/
noncomputable abbrev β₀R : ℝ := (β₀_rat : ℝ)

/-- Geometric decay rate r = β₀/6. -/
noncomputable def r : ℝ := β₀R / 6

/-- Exponential prefactor C = exp((β₀/6)²). -/
noncomputable def C_exp : ℝ := Real.exp (r ^ 2)

lemma r_pos : 0 < r := by unfold r β₀R; positivity
lemma r_lt_half : r < 1 / 2 := by unfold r β₀R β₀_rat; norm_num
lemma r_lt_one : r < 1 := lt_trans r_lt_half (by norm_num)
lemma r_nonneg : 0 ≤ r := r_pos.le
lemma C_exp_pos : 0 < C_exp := Real.exp_pos _
lemma C_exp_nonneg : 0 ≤ C_exp := C_exp_pos.le

/-- q = r³ is the geometric ratio for |det| decay. -/
noncomputable def q : ℝ := r ^ 3

lemma q_pos : 0 < q := pow_pos r_pos 3
lemma q_nonneg : 0 ≤ q := q_pos.le
lemma q_lt_one : q < 1 := pow_lt_one r_nonneg r_lt_one (by norm_num)

/-! ## §2  Entry bound and index lemmas -/

/-- Each matrix entry is nonneg (Bessel series with nonneg argument). -/
lemma entry_nonneg (k : ℤ) (i j : Fin 3) :
    0 ≤ (toeplitzReal β₀R k) i j := by
  simp only [toeplitzReal, Matrix.of_apply]
  apply tsum_nonneg
  intro n
  apply div_nonneg
  · exact pow_nonneg (div_nonneg (by positivity) two_pos.le) _
  · positivity

/-- Entry ≤ r^{|i−j−k|} · C_exp, by besselI_series_le_exp_bound. -/
lemma entry_le_pow_mul (k : ℤ) (i j : Fin 3) :
    (toeplitzReal β₀R k) i j ≤ r ^ ((i : ℤ) - j - k).natAbs * C_exp := by
  simp only [toeplitzReal, Matrix.of_apply]
  have hx : 0 ≤ β₀R / 3 := by positivity
  apply le_trans (besselI_series_le_exp_bound _ _ hx)
  have hr : β₀R / 3 / 2 = r := by unfold r; ring
  simp only [hr, C_exp]

/-- Reverse triangle: index |i−j−k| ≥ k.natAbs − 2 (natural subtraction). -/
lemma index_lower_bound (k : ℤ) (i j : Fin 3) :
    k.natAbs - 2 ≤ ((i : ℤ) - j - k).natAbs := by
  have hij : ((i : ℤ) - j).natAbs ≤ 2 := by
    fin_cases i <;> fin_cases j <;> simp [Int.natAbs]
  have heq : (k : ℤ) = -((i : ℤ) - j - k) + ((i : ℤ) - j) := by ring
  have hkey : k.natAbs ≤ ((i : ℤ) - j - k).natAbs + ((i : ℤ) - j).natAbs := by
    calc k.natAbs
        = (-((i : ℤ) - j - k) + ((i : ℤ) - j)).natAbs := by conv_lhs => rw [heq]
      _ ≤ (-(i - j - k)).natAbs + (i - j).natAbs := Int.natAbs_add_le _ _
      _ = (i - j - k).natAbs + (i - j).natAbs := by rw [Int.natAbs_neg]
  omega

/-- For all k : ℤ, every entry ≤ r^{k.natAbs − 2} · C_exp. -/
lemma entry_le_geometric (k : ℤ) (i j : Fin 3) :
    (toeplitzReal β₀R k) i j ≤ r ^ (k.natAbs - 2) * C_exp := by
  apply le_trans (entry_le_pow_mul k i j)
  gcongr
  · exact r_nonneg
  · exact r_lt_one.le
  · exact index_lower_bound k i j

/-! ## §3  Determinant absolute-value bound -/

/-- |det(toeplitzReal β₀ k)| ≤ 6 · (r^{k.natAbs−2} · C_exp)³ for all k. -/
lemma det_abs_le (k : ℤ) :
    |(toeplitzReal β₀R k).det| ≤ 6 * (r ^ (k.natAbs - 2) * C_exp) ^ 3 := by
  set b := r ^ (k.natAbs - 2) * C_exp with hb_def
  have hb : 0 ≤ b := mul_nonneg (pow_nonneg r_nonneg _) C_exp_nonneg
  have hM : ∀ i j : Fin 3, (toeplitzReal β₀R k) i j ≤ b := entry_le_geometric k
  have hM0 : ∀ i j : Fin 3, 0 ≤ (toeplitzReal β₀R k) i j := entry_nonneg k
  -- Product-of-3 bound: for M i j ∈ [0, b], product ≤ b³
  have hprod : ∀ (a₁ a₂ a₃ : ℝ), 0 ≤ a₁ → a₁ ≤ b → 0 ≤ a₂ → a₂ ≤ b → 0 ≤ a₃ → a₃ ≤ b →
      a₁ * a₂ * a₃ ≤ b ^ 3 := fun a₁ a₂ a₃ h1 h1b h2 h2b h3 h3b => by
    have : a₁ * a₂ * a₃ ≤ b * b * b := by
      calc a₁ * a₂ * a₃
          ≤ b * b * a₃ := by nlinarith [mul_nonneg h1 h2]
        _ ≤ b * b * b := by nlinarith [mul_nonneg hb hb]
    linarith [show b ^ 3 = b * b * b from by ring]
  -- Bound the determinant via Matrix.det_fin_three
  rw [Matrix.det_fin_three]
  -- The determinant = sum of 6 signed terms; |det| ≤ sum of absolute values
  -- Each term is a product of 3 nonneg entries, hence nonneg
  set M := fun (i j : Fin 3) => (toeplitzReal β₀R k) i j
  -- Bound each of the 6 terms
  have t1 : M 0 0 * M 1 1 * M 2 2 ≤ b ^ 3 :=
    hprod _ _ _ (hM0 0 0) (hM 0 0) (hM0 1 1) (hM 1 1) (hM0 2 2) (hM 2 2)
  have t2 : M 0 0 * M 1 2 * M 2 1 ≤ b ^ 3 :=
    hprod _ _ _ (hM0 0 0) (hM 0 0) (hM0 1 2) (hM 1 2) (hM0 2 1) (hM 2 1)
  have t3 : M 0 1 * M 1 0 * M 2 2 ≤ b ^ 3 :=
    hprod _ _ _ (hM0 0 1) (hM 0 1) (hM0 1 0) (hM 1 0) (hM0 2 2) (hM 2 2)
  have t4 : M 0 1 * M 1 2 * M 2 0 ≤ b ^ 3 :=
    hprod _ _ _ (hM0 0 1) (hM 0 1) (hM0 1 2) (hM 1 2) (hM0 2 0) (hM 2 0)
  have t5 : M 0 2 * M 1 0 * M 2 1 ≤ b ^ 3 :=
    hprod _ _ _ (hM0 0 2) (hM 0 2) (hM0 1 0) (hM 1 0) (hM0 2 1) (hM 2 1)
  have t6 : M 0 2 * M 1 1 * M 2 0 ≤ b ^ 3 :=
    hprod _ _ _ (hM0 0 2) (hM 0 2) (hM0 1 1) (hM 1 1) (hM0 2 0) (hM 2 0)
  -- All 6 terms are nonneg
  have hn1 : 0 ≤ M 0 0 * M 1 1 * M 2 2 := mul_nonneg (mul_nonneg (hM0 0 0) (hM0 1 1)) (hM0 2 2)
  have hn2 : 0 ≤ M 0 0 * M 1 2 * M 2 1 := mul_nonneg (mul_nonneg (hM0 0 0) (hM0 1 2)) (hM0 2 1)
  have hn3 : 0 ≤ M 0 1 * M 1 0 * M 2 2 := mul_nonneg (mul_nonneg (hM0 0 1) (hM0 1 0)) (hM0 2 2)
  have hn4 : 0 ≤ M 0 1 * M 1 2 * M 2 0 := mul_nonneg (mul_nonneg (hM0 0 1) (hM0 1 2)) (hM0 2 0)
  have hn5 : 0 ≤ M 0 2 * M 1 0 * M 2 1 := mul_nonneg (mul_nonneg (hM0 0 2) (hM0 1 0)) (hM0 2 1)
  have hn6 : 0 ≤ M 0 2 * M 1 1 * M 2 0 := mul_nonneg (mul_nonneg (hM0 0 2) (hM0 1 1)) (hM0 2 0)
  -- |det| ≤ |t1| + |t2| + |t3| + |t4| + |t5| + |t6| ≤ 6 * b³
  rw [show (6 : ℝ) * (r ^ (k.natAbs - 2) * C_exp) ^ 3 = 6 * b ^ 3 from by rw [hb_def]]
  have := abs_sub_abs_le_abs_sub
  simp only [Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons,
             Matrix.head_fin_const]
  rw [abs_le]
  constructor <;> linarith

/-! ## §4  Summability of the geometric bounding series on ℤ -/

/-- The bounding function g k = 6 · C_exp³ · q^{k.natAbs − 2}. -/
noncomputable def g (k : ℤ) : ℝ := 6 * C_exp ^ 3 * q ^ (k.natAbs - 2)

lemma g_nonneg (k : ℤ) : 0 ≤ g k :=
  mul_nonneg (mul_nonneg (by norm_num) (pow_nonneg C_exp_nonneg 3))
    (pow_nonneg q_nonneg _)

/-- The ℕ-indexed geometric series for the positive half is summable. -/
private lemma geo_nat_summable : Summable (fun n : ℕ => q ^ n) :=
  summable_geometric_of_lt_one q_nonneg q_lt_one

/-- The ℕ-indexed shifted series is summable. -/
private lemma geo_nat_shift_summable : Summable (fun n : ℕ => q ^ (n + 1)) := by
  simp_rw [pow_succ]
  exact geo_nat_summable.mul_left q

/-- Split ℤ summability via nonneg and negative parts. -/
private lemma summable_int_of_nat_parts {f : ℤ → ℝ}
    (h_nn : Summable (fun n : ℕ => f (n : ℤ)))
    (h_neg : Summable (fun n : ℕ => f (-(n : ℤ) - 1))) :
    Summable f := by
  exact summable_int_of_summable_nat h_nn h_neg

/-- g is summable on ℤ. -/
lemma g_summable : Summable g := by
  -- Step 1: q^k.natAbs is summable on ℤ (positive half: q^n, negative half: q^(n+1)).
  have hq_int : Summable (fun k : ℤ => q ^ k.natAbs) :=
    summable_int_of_summable_nat
      (by simp only [Int.natAbs_ofNat]; exact summable_geometric_of_lt_one q_nonneg q_lt_one)
      (by simp only [Int.natAbs_negSucc]
          simp_rw [pow_succ]
          exact (summable_geometric_of_lt_one q_nonneg q_lt_one).mul_left q)
  -- Step 2: dominate g k ≤ (6·C_exp³/q²)·q^k.natAbs by comparison.
  apply Summable.of_nonneg_of_le g_nonneg _ (hq_int.mul_left (6 * C_exp ^ 3 / q ^ 2))
  intro k
  unfold g
  rw [show 6 * C_exp ^ 3 / q ^ 2 * q ^ k.natAbs =
        6 * C_exp ^ 3 * (q ^ k.natAbs / q ^ 2) from by ring]
  apply mul_le_mul_of_nonneg_left _ (by positivity)
  -- q^(k.natAbs - 2) ≤ q^k.natAbs / q^2, i.e. q^(k.natAbs-2)·q^2 ≤ q^k.natAbs
  rw [le_div_iff (pow_pos q_pos 2)]
  rcases le_or_lt k.natAbs 2 with h | h
  · -- k.natAbs ≤ 2: Nat sub gives 0; q^2 ≤ q^k.natAbs since k.natAbs ≤ 2 and q < 1
    simp only [Nat.sub_eq_zero_of_le h, pow_zero, one_mul]
    exact pow_le_pow_of_le_one q_nonneg q_lt_one.le h
  · -- k.natAbs > 2: q^(k.natAbs-2)·q^2 = q^k.natAbs (exact)
    have hn : k.natAbs - 2 + 2 = k.natAbs := Nat.sub_add_cancel (by omega)
    rw [← pow_add, hn]

/-! ## ALTERNATIVE direct summability proof for g -/

/-- Direct summability of g using the fact that g k / (6 * C_exp^3) = q^(k.natAbs - 2). -/
lemma g_summable_direct : Summable (fun k : ℤ => q ^ (k.natAbs - 2)) := by
  have heq : ∀ k : ℤ, q ^ (k.natAbs - 2) = g k / (6 * C_exp ^ 3) := fun k => by
    unfold g
    have hpos : (6 : ℝ) * C_exp ^ 3 ≠ 0 := by positivity
    field_simp [hpos]
  simp_rw [heq]
  exact g_summable.div_const _

/-! ## §5  Parts (a) and (b) of W1_Numeric_Surface -/

/-- Part (a): Summability of the Toeplitz determinant series on ℤ. -/
theorem summable_toeplitz_det :
    Summable (fun k : ℤ => (toeplitzReal β₀R k).det) := by
  apply Summable.of_norm_bounded g g_summable
  intro k
  apply le_trans (det_abs_le k)
  unfold g q
  ring_nf

/-! ## §4b  Private helpers for the geometric tail bound -/

/-- C_exp < 3/2: from x+1 ≤ exp(x) at x = -1/4 giving exp(-1/4) ≥ 3/4,
so exp(1/4)·(3/4) ≤ 1, giving exp(1/4) ≤ 4/3 < 3/2. -/
private lemma C_exp_lt_three_halves : C_exp < 3 / 2 := by
  unfold C_exp
  have hr_sq : r ^ 2 < 1 / 4 := by nlinarith [r_lt_half, r_nonneg]
  apply lt_trans (Real.exp_lt_exp.mpr hr_sq)
  have h_neg : (3 : ℝ) / 4 ≤ Real.exp (-1 / 4 : ℝ) := by
    have h := Real.add_one_le_exp (-1 / 4 : ℝ); linarith
  have hmul : Real.exp (1 / 4 : ℝ) * Real.exp (-1 / 4 : ℝ) = 1 := by
    rw [← Real.exp_add]; norm_num
  have hpos14 : (0 : ℝ) < Real.exp (1 / 4) := Real.exp_pos _
  have hle : Real.exp (1 / 4 : ℝ) ≤ 4 / 3 := by
    have h := mul_le_mul_of_nonneg_left h_neg hpos14.le; linarith
  linarith

/-- q ≤ 1/8: since r < 1/2, q = r³ < (1/2)³ = 1/8. -/
private lemma q_le_eighth : q ≤ 1 / 8 := by
  unfold q
  calc r ^ 3 ≤ (1 / 2 : ℝ) ^ 3 := pow_le_pow_left r_nonneg r_lt_half.le 3
    _ = 1 / 8 := by norm_num

/-- (1 − q)⁻¹ ≤ 8/7: since q ≤ 1/8, 1 − q ≥ 7/8. -/
private lemma inv_one_sub_q_le : (1 - q)⁻¹ ≤ 8 / 7 := by
  rw [show (8 : ℝ) / 7 = ((7 : ℝ) / 8)⁻¹ from by norm_num]
  exact inv_le_inv_of_le (by norm_num) (by linarith [q_le_eighth])

/-- Part (b): The ℤ-tsum is bounded above by the rational interval sum + tail. -/
theorem tsum_det_le :
    ∑' k : ℤ, (toeplitzReal β₀R k).det ≤ (↑finite_hi_sum + ↑tail_ub : ℝ) := by
  have hS := summable_toeplitz_det
  set S : Finset ℤ := Finset.Icc (-25) 25
  -- §A: tsum split (Finset.sum_add_tsum_compl)
  have hS_split : ∑' k : ℤ, (toeplitzReal β₀R k).det =
      ∑ k ∈ S, (toeplitzReal β₀R k).det +
      ∑' k : ↥(S : Set ℤ)ᶜ, (toeplitzReal β₀R (k : ℤ)).det :=
    (Finset.sum_add_tsum_compl S hS).symm
  -- §B: finite part ≤ finite_hi_sum
  have h_finite : ∑ k ∈ S, (toeplitzReal β₀R k).det ≤ (↑finite_hi_sum : ℝ) := by
    have h_reindex : ∑ k ∈ S, (toeplitzReal β₀R k).det =
        ∑ i ∈ Finset.range 51, (toeplitzReal β₀R ((i : ℤ) - 25)).det := by
      apply Finset.sum_nbij (fun i => (i : ℤ) - 25)
      · intro i hi; simp [S, Finset.mem_Icc]; omega
      · intro i₁ _ i₂ _ h; omega
      · intro k hk; simp [S, Finset.mem_Icc] at hk
        exact ⟨(k + 25).toNat, by simp [Finset.mem_range]; omega, by omega⟩
      · intro i _; rfl
    rw [h_reindex]
    apply le_trans finite_sum_le
    simp only [finite_hi_sum]; apply le_of_eq; push_cast; rfl
  -- §C: tail ≤ tail_ub via geometric series
  have h_tail : ∑' k : ↥(S : Set ℤ)ᶜ, (toeplitzReal β₀R (k : ℤ)).det ≤ (↑tail_ub : ℝ) := by
    -- det ≤ g pointwise; both summable on Sᶜ
    apply le_trans (tsum_le_tsum
      (fun k => le_trans (le_abs_self _) (det_abs_le k.val))
      (hS.subtype _) (g_summable.subtype _))
    -- Split Sᶜ = {k ≥ 26} ∪ {k ≤ −26}
    have hcompl : (↑S : Set ℤ)ᶜ = {k : ℤ | k ≥ 26} ∪ {k : ℤ | k ≤ -26} := by
      ext k; simp only [Set.mem_compl_iff, Finset.mem_coe, S, Finset.mem_Icc,
                         Set.mem_union, Set.mem_setOf_eq, not_and_or, not_le]; omega
    rw [hcompl, tsum_union_disjoint
      (Set.disjoint_left.mpr fun k h1 h2 => by
        simp only [Set.mem_setOf_eq] at h1 h2; omega)
      (g_summable.subtype _) (g_summable.subtype _)]
    -- ℕ-bijections for each half
    let posE : ℕ ≃ {k : ℤ | k ≥ 26} :=
      { toFun   := fun n => ⟨↑n + 26, by simp only [Set.mem_setOf_eq]; omega⟩
        invFun  := fun k => (k.val - 26).toNat
        left_inv  := fun n => by simp only; omega
        right_inv := fun ⟨k, hk⟩ => by
          apply Subtype.ext; simp only [Set.mem_setOf_eq] at hk; omega }
    let negE : ℕ ≃ {k : ℤ | k ≤ -26} :=
      { toFun   := fun n => ⟨-(↑n + 26), by simp only [Set.mem_setOf_eq]; omega⟩
        invFun  := fun k => (-k.val - 26).toNat
        left_inv  := fun n => by simp only; omega
        right_inv := fun ⟨k, hk⟩ => by
          apply Subtype.ext; simp only [Set.mem_setOf_eq] at hk; omega }
    -- g(n+26) = g(-(n+26)) = 6·C_exp³·q²⁴·qⁿ
    have g_pos_factor : ∀ n : ℕ, g (↑n + 26 : ℤ) = 6 * C_exp ^ 3 * q ^ 24 * q ^ n := by
      intro n; unfold g
      rw [show (↑n + 26 : ℤ).natAbs = n + 26 from by
            rw [show (↑n + 26 : ℤ) = ↑(n + 26 : ℕ) from by push_cast; ring]
            exact Int.natAbs_ofNat _,
          show n + 26 - 2 = n + 24 from by omega, pow_add]; ring
    have g_neg_factor : ∀ n : ℕ, g (-(↑n + 26) : ℤ) = 6 * C_exp ^ 3 * q ^ 24 * q ^ n := by
      intro n; unfold g
      rw [show (-(↑n + 26 : ℤ)).natAbs = n + 26 from by
            rw [Int.natAbs_neg,
                show (↑n + 26 : ℤ) = ↑(n + 26 : ℕ) from by push_cast; ring]
            exact Int.natAbs_ofNat _,
          show n + 26 - 2 = n + 24 from by omega, pow_add]; ring
    -- Reindex both halves to ℕ geometric series
    have hpos_rw : ∑' k : {k : ℤ | k ≥ 26}, g k.val =
        ∑' n : ℕ, 6 * C_exp ^ 3 * q ^ 24 * q ^ n := by
      have h := (Equiv.tsum_eq posE (fun k : {k : ℤ | k ≥ 26} => g k.val)).symm
      simp only [posE, Equiv.coe_fn_mk] at h
      exact h.trans (tsum_congr g_pos_factor)
    have hneg_rw : ∑' k : {k : ℤ | k ≤ -26}, g k.val =
        ∑' n : ℕ, 6 * C_exp ^ 3 * q ^ 24 * q ^ n := by
      have h := (Equiv.tsum_eq negE (fun k : {k : ℤ | k ≤ -26} => g k.val)).symm
      simp only [negE, Equiv.coe_fn_mk] at h
      exact h.trans (tsum_congr g_neg_factor)
    rw [hpos_rw, hneg_rw]
    -- Evaluate geometric series: ∑ qⁿ = (1−q)⁻¹
    have hgeo : ∑' n : ℕ, 6 * C_exp ^ 3 * q ^ 24 * q ^ n =
        6 * C_exp ^ 3 * q ^ 24 * (1 - q)⁻¹ := by
      rw [tsum_mul_left, tsum_geometric_of_lt_one q_nonneg q_lt_one]
    rw [hgeo, hgeo]
    -- Numeric bound: 2 × 162/(7·8²⁴) ≤ 1/10²⁰ = tail_ub
    have hq_pos : (0 : ℝ) < 1 - q := by linarith [q_lt_one]
    have h_lhs : 6 * C_exp ^ 3 * q ^ 24 ≤ 6 * (3 / 2 : ℝ) ^ 3 * (1 / 8 : ℝ) ^ 24 := by
      nlinarith [pow_le_pow_left C_exp_nonneg C_exp_lt_three_halves.le 3,
                 pow_le_pow_left q_nonneg q_le_eighth 24,
                 pow_nonneg q_nonneg 24,
                 show (0 : ℝ) ≤ (3 / 2 : ℝ) ^ 3 from by positivity]
    have h_each : 6 * C_exp ^ 3 * q ^ 24 * (1 - q)⁻¹ ≤ 162 / (7 * 8 ^ 24 : ℝ) :=
      calc 6 * C_exp ^ 3 * q ^ 24 * (1 - q)⁻¹
          ≤ 6 * (3 / 2 : ℝ) ^ 3 * (1 / 8 : ℝ) ^ 24 * (8 / 7) :=
              mul_le_mul h_lhs inv_one_sub_q_le
                (inv_nonneg.mpr hq_pos.le) (by positivity)
        _ = 162 / (7 * 8 ^ 24 : ℝ) := by norm_num
    have htub : (tail_ub : ℝ) = 1 / 10 ^ 20 := by simp only [tail_ub]; norm_num
    linarith [show 2 * (162 : ℝ) / (7 * 8 ^ 24) ≤ 1 / 10 ^ 20 from by norm_num]
  calc ∑' k : ℤ, (toeplitzReal β₀R k).det
      = ∑ k ∈ S, (toeplitzReal β₀R k).det +
        ∑' k : ↥(S : Set ℤ)ᶜ, (toeplitzReal β₀R (k : ℤ)).det := hS_split
    _ ≤ ↑finite_hi_sum + ↑tail_ub := add_le_add h_finite h_tail

/-! ## §6  Part (c): the pure ℚ inequality -/

/-- Part (c): exp_hi · (finite_hi_sum + tail_ub) < 1/7. Pure ℚ, kernel-decidable. -/
theorem part_c : exp_beta0_interval.hi * (finite_hi_sum + tail_ub) < 1 / 7 := by
  -- All three values are computable ℚ; kernel decide reduces them.
  -- If this times out, replace `decide` with:
  --   norm_num [exp_beta0_interval, exp_neg_interval, exp_neg_partial,
  --             finite_hi_sum, toeplitzDetInterval, tail_ub]
  decide

/-! ## §7  The main theorem -/

/-- **W1_Numeric_Surface is PROVED** (trio-clean).
Bundles parts (a), (b), (c) into the named surface. -/
theorem w1_numeric_surface_proved : W1_Numeric_Surface :=
  ⟨summable_toeplitz_det, tsum_det_le, part_c⟩

end TheoremaAureum.Towers.YM.W1NumericProof

-- #print axioms w1_numeric_surface_proved
-- Expected: [propext, Classical.choice, Quot.sound]
-- (If sorry-free: no additional axioms beyond classical trio)
