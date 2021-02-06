#include <stdlib.h>
#include <stdint.h>
#include <stdarg.h>
#include <string.h>
#include <time.h>
#include <libgen.h>
#include <mruby.h>
#include <mruby/array.h>
#include <mruby/iv_benchmark.h>

static uint64_t gBaseTime;

static uint64_t
time_get_absolute(void)
{
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return ts.tv_sec * 1000000 + ts.tv_nsec / 1000;
}

mrb_state*
mrb_ivbm_open_mruby(mrb_allocf alloc_func)
{
  mrb_state *mrb = mrb_open_allocf(alloc_func, NULL);
  if (!mrb) fputs("mrb_open_allocf() failure\n", stderr);
  return mrb;
}

int
mrb_ivbm_close_mruby(mrb_state *mrb)
{
  if (mrb) {
    mrb_close(mrb);
    return EXIT_SUCCESS;
  }
  else {
    return EXIT_FAILURE;
  }
}

/* return microseconds */
mrb_int
mrb_ivbm_time(void)
{
  return (mrb_int)(time_get_absolute() - gBaseTime);
}

mrb_bool
mrb_ivbm_parse_arg(int argc, char **argv, const char *spec, ...)
{
  int max_argc, i;
  const char *p;
  va_list ap;
  for (p = spec, max_argc = 2; (p = strchr(p, ' ')); ++p, ++max_argc);
  if (max_argc < argc) goto failure;
  va_start(ap, spec);
  for (i = 1; i < argc; ++i) {
    char *endp;
    mrb_int v = (mrb_int)strtol(argv[i], &endp, 10);
    if (*endp != 0 && v <= 0) goto failure;
    *(va_arg(ap, mrb_int*)) = v;
  }
  va_end(ap);
  return TRUE;

 failure:
  fprintf(stderr, "Usage: %s %s\n", basename(argv[0]), spec);
  return FALSE;
}

mrb_value
mrb_ivbm_create_symbols(mrb_state *mrb, mrb_int size)
{
  mrb_value symbol_ary = mrb_ary_new_capa(mrb, size);
  mrb_value *symbols = RARRAY_PTR(symbol_ary);
  char buf[32];
  for (mrb_int i = 0; i < size; i++) {
    /*
     * Because inline symbols are used from high-order bits, at least
     * low-order 6 bits are always 0 when name length < 5. At this time,
     * even in hash code, the lower 0 remains as it is, so hash bucket index
     * becomes all 0 and collisions occur frequently. Therefore, it is fixed
     * at 5 digits.
     */
    sprintf(buf, "%05" MRB_PRId, i+1);
    symbols[i] = mrb_symbol_value(mrb_intern_cstr(mrb, buf));
  }
  ARY_SET_LEN(mrb_ary_ptr(symbol_ary), size);
  return symbol_ary;
}

void
mrb_mruby_iv_benchmark_gem_init(mrb_state* mrb)
{
  gBaseTime = time_get_absolute();
}

void
mrb_mruby_iv_benchmark_gem_final(mrb_state* mrb)
{
}
