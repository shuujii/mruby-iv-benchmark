#ifndef MRUBY_IV_BENCHMARK_H
#define MRUBY_IV_BENCHMARK_H

//#define MRB_IVBM_DEBUG

#define DEFAULT_IV_SIZE 200
#define DEFAULT_MEASUREMENT_MSEC 10000
#define MRB_IVBM_IPS_FMT "%.17g"
#define MRB_IVBM_ELAPSED_SEC_FMT "%.17g"

#ifdef MRB_IVBM_DEBUG
# define DPRINTF(...) fprintf(stderr, __VA_ARGS__)
#else
# define DPRINTF(...) (void)0
#endif

mrb_state* mrb_ivbm_open_mruby(mrb_allocf alloc_func);
int mrb_ivbm_close_mruby(mrb_state *mrb);
mrb_bool mrb_ivbm_parse_arg(int argc, char **argv, const char *spec, ...);
mrb_int mrb_ivbm_time(void);
mrb_value mrb_ivbm_create_symbols(mrb_state *mrb, mrb_int size);

static inline void
mrb_ivbm_disable_gc(mrb_state *mrb)
{
  mrb->gc.disabled = FALSE;
  mrb_full_gc(mrb);
  mrb->gc.disabled = TRUE;
}

#endif  /* MRUBY_IV_BENCHMARK_H */
