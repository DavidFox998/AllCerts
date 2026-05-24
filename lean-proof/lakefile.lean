import Lake
open Lake DSL
package «theorema-aureum» where
-- The structural / axiom-debt verification in TheoremaAureum/*.lean carries
-- no Mathlib imports, so the standard `lake build` + `lake env lean Verify.lean`
-- pipeline does not need Mathlib at all. To run the *full semantic* build
-- (with real `riemannZeta` / `riemannXi` from Mathlib) uncomment the require
-- below and then `lake exe cache get && lake build` (~2 GB prebuilt oleans).
-- require mathlib from git "https://github.com/leanprover-community/mathlib4.git" @ "v4.12.0"
@[default_target]
lean_lib TheoremaAureum where
