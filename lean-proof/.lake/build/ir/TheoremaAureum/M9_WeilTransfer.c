// Lean compiler output
// Module: TheoremaAureum.M9_WeilTransfer
// Imports: Init TheoremaAureum.Certificates
#include <lean/lean.h>
#if defined(__clang__)
#pragma clang diagnostic ignored "-Wunused-parameter"
#pragma clang diagnostic ignored "-Wunused-label"
#elif defined(__GNUC__) && !defined(__CLANG__)
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wunused-label"
#pragma GCC diagnostic ignored "-Wunused-but-set-variable"
#endif
#ifdef __cplusplus
extern "C" {
#endif
LEAN_EXPORT lean_object* l_TheoremaAureum_VALOR__M9__min;
static lean_object* _init_l_TheoremaAureum_VALOR__M9__min() {
_start:
{
lean_object* x_1; 
x_1 = lean_unsigned_to_nat(1084u);
return x_1;
}
}
lean_object* initialize_Init(uint8_t builtin, lean_object*);
lean_object* initialize_TheoremaAureum_Certificates(uint8_t builtin, lean_object*);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_TheoremaAureum_M9__WeilTransfer(uint8_t builtin, lean_object* w) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_TheoremaAureum_Certificates(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
l_TheoremaAureum_VALOR__M9__min = _init_l_TheoremaAureum_VALOR__M9__min();
lean_mark_persistent(l_TheoremaAureum_VALOR__M9__min);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
