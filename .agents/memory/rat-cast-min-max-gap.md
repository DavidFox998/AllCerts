---
name: Rat.cast_min/max gap (mathlib v4.12.0)
description: v4.12.0 has no Rat.cast_min/Rat.cast_max for ℚ→ℝ; prove the cast/min(max) commute inline.
---

mathlib v4.12.0 ships `Nat.cast_min`/`Nat.cast_max` but **no** `Rat.cast_min` /
`Rat.cast_max` (the ℚ→ℝ versions). So `((min p q : ℚ) : ℝ) = min (p:ℝ) (q:ℝ)`
is NOT a named simp lemma — a `simp only [Rat.cast_min]` fails with "unknown
identifier".

**How to apply:** prove it inline in one line each, since the ℚ→ℝ cast is
order-preserving:

```
private theorem cast_min (p q : ℚ) : ((min p q : ℚ):ℝ) = min (p:ℝ) (q:ℝ) := by
  rcases le_total p q with h | h
  · rw [min_eq_left h,  min_eq_left  (by exact_mod_cast h : (p:ℝ) ≤ q)]
  · rw [min_eq_right h, min_eq_right (by exact_mod_cast h : (q:ℝ) ≤ p)]
-- cast_max: swap min→max, min_eq_left→max_eq_right, min_eq_right→max_eq_left.
```

**Why it matters:** any rational interval-arithmetic over ℝ (e.g. a `mul` that
encloses by min/max of the four corner products) needs to push the ℚ endpoint
`min`/`max` through the cast to line up with a real-valued bilinear bound. Without
these you can't close the soundness goal by `rw` + the corner `min_le`/`le_max`
lemmas. General pattern for "missing cast lemma": case on `le_total` and rewrite
both sides with the `_eq_left`/`_eq_right` selectors.
