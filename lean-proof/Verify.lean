import TheoremaAureum

/-!
  ## Verify.lean — Audit Certificate

  Run with:  lake env lean Verify.lean

  Expected outputs shown in comments below each command.
-/

-- ── 1. AXIOM CHECK: main_theorem (the conditional implication) ───────────────
-- main_theorem = (H2_Prop → GRH) → RH
-- The implication itself carries zero axiom debt.
-- Expected output:
--   'TheoremaAureum.main_theorem' does not depend on any axioms
#print axioms TheoremaAureum.main_theorem


-- ── 2. AXIOM CHECK: applying main_theorem to H2_WeilTransfer ─────────────────
-- To see the axiom debt of the *applied* result, name the application first.
-- Expected output:
--   'TheoremaAureum.rh_via_weil' depends on axioms:
--       [TheoremaAureum.H2_WeilTransfer]
theorem TheoremaAureum.rh_via_weil : TheoremaAureum.RiemannHypothesis :=
  TheoremaAureum.main_theorem TheoremaAureum.H2_WeilTransfer

#print axioms TheoremaAureum.rh_via_weil


-- ── 3. VALOR / H1 EVALUATION ────────────────────────────────────────────────
-- VALOR_M5 = 42110  (= floor(4.2110461381 × 10^4))
-- C(S_4) − 2·√13 = 11.4221... − 7.2111... = 4.2110...
-- M5 SHA: 9df98a3970acbb6942770a6cdd42fb21b009f9a5f45a222dd963e98ba4cb7a13
-- Expected: 42110
#eval TheoremaAureum.Certificates.VALOR_M5

-- Decidable evaluation of the H1 positivity condition:
-- Expected: true
#eval decide (0 < TheoremaAureum.VALOR)


-- ── 4. TYPE CHECKS ───────────────────────────────────────────────────────────
-- H1: theorem (not axiom) — proved by M5 certificate via `decide`
-- Expected:
--   TheoremaAureum.H1_ArakelovPositivity : 0 < TheoremaAureum.VALOR
#check TheoremaAureum.H1_ArakelovPositivity

-- main_theorem: the conditional implication (H2 → RH)
-- Expected:
--   TheoremaAureum.main_theorem :
--     (0 < TheoremaAureum.VALOR → TheoremaAureum.GRH_E_143a1) →
--     TheoremaAureum.RiemannHypothesis
#check TheoremaAureum.main_theorem
