#include <stdio.h>
#include <stdlib.h>
#include <libgen.h>
#include <math.h>
#include <mruby.h>
#include <mruby/array.h>
#include <mruby/variable.h>
#include <mruby/iv_benchmark.h>

static void
measurement(mrb_state *mrb, mrb_int max_iv_size, int max_count,
            int *counts, mrb_int *times)
{
  mrb_int iv_size, i, t;
  int ai = mrb_gc_arena_save(mrb), loop_count, c;
  mrb_value symbol_ary = mrb_ivbm_create_symbols(mrb, max_iv_size+1);
  mrb_value *symbols = RARRAY_PTR(symbol_ary);
  mrb_value obj = mrb_obj_new(mrb, mrb->object_class, 0, NULL);
  struct RObject *o = mrb_obj_ptr(obj);
  for (iv_size = 0; iv_size <= max_iv_size; ++iv_size) {
    if (iv_size != 0) {
      mrb_value v = symbols[iv_size-1];
      mrb_obj_iv_set(mrb, o, mrb_symbol(v), v);
    }
    loop_count = max_count/(iv_size+1);
    t = mrb_ivbm_time();
    for (c = 0; c < loop_count; ++c) {
      for (i = 0; i <= iv_size; ++i) {
        mrb_value v = symbols[i];
        mrb_obj_iv_get(mrb, o, mrb_symbol(v));
      }
    }
    times[iv_size] = mrb_ivbm_time() - t;
    counts[iv_size] = loop_count*(iv_size+1);
  }
  mrb_gc_arena_restore(mrb, ai);
}

static int
estimate_count(mrb_state *mrb, mrb_int max_iv_size, mrb_int measurement_time)
{
  int estimation_count = 2500000/max_iv_size;
  int counts[max_iv_size+1];
  mrb_int times[max_iv_size+1], total_time = 0, i;
  measurement(mrb, max_iv_size, estimation_count, counts, times);
  for (i = 0; i <= max_iv_size; ++i) total_time += times[i];
  DPRINTF("estimate time: %"MRB_PRId"\n", total_time);
  return (int)ceil((double)estimation_count / total_time * measurement_time);
}

int
main(int argc, char **argv)
{
  mrb_int max_iv_size = DEFAULT_IV_SIZE;
  mrb_int measurement_msec = DEFAULT_MEASUREMENT_MSEC;
  mrb_state *mrb = NULL;
  if (mrb_ivbm_parse_arg(argc, argv, "[IV-SIZE] [MEASUREMENT-MSEC]",
                         &max_iv_size, &measurement_msec)) {
    mrb_int measurement_time = measurement_msec * 1000;
    mrb_int iv_size, times[max_iv_size+1];
    int counts[max_iv_size+1];
    int max_count;  /* max iteration per iv size */
    if (!(mrb = mrb_ivbm_open_mruby(NULL))) goto final;
    mrb_ivbm_disable_gc(mrb);
    max_count = estimate_count(mrb, max_iv_size, measurement_time);
    DPRINTF("max_count: %d\n", max_count);
    mrb_ivbm_disable_gc(mrb);
    measurement(mrb, max_iv_size, max_count, counts, times);
    puts("# iv size\ti/s\titerations\tseconds");
    for (iv_size = 0; iv_size <= max_iv_size; ++iv_size) {
      mrb_int t = times[iv_size];
      int c = counts[iv_size];
      printf("%"MRB_PRId"\t"MRB_IVBM_IPS_FMT"\t%d\t"MRB_IVBM_ELAPSED_SEC_FMT"\n",
             iv_size, c*1e6/t, c, t/1e6);
    }
  }

 final:
  return mrb_ivbm_close_mruby(mrb);
}
