#include <stdlib.h>
#include <stdint.h>
#include <stdarg.h>
#include <string.h>
#include <time.h>
#include <libgen.h>
#include <mruby.h>
#include <mruby/array.h>
#include <mruby/hash.h>
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
    if (*endp != 0 || v <= 0) {va_end(ap); goto failure;}
    *(va_arg(ap, mrb_int*)) = v;
  }
  va_end(ap);
  return TRUE;

 failure:
  fprintf(stderr, "Usage: %s %s\n", basename(argv[0]), spec);
  return FALSE;
}

uint32_t
mrb_ivbm_random(void)
{
  /* https://ja.wikipedia.org/wiki/Xorshift */
  static uint32_t v = 2463534242;
  v ^= (v<<13);
  v ^= (v>>17);
  v ^= (v<<5);
  return v;
}

mrb_value
mrb_ivbm_create_symbols(mrb_state *mrb, mrb_int size)
{
  mrb_value hash = mrb_hash_new_capa(mrb, size);
  do {
    mrb_sym v = mrb_ivbm_random() & 0xffffff;  /* non-inline */
    if (v != 0) mrb_hash_set(mrb, hash, mrb_symbol_value(v), mrb_true_value());
  } while (mrb_hash_size(mrb, hash) < size);
  return mrb_hash_keys(mrb, hash);
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
