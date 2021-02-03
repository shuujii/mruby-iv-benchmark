#include <stdio.h>
#include <stdlib.h>
#include <libgen.h>
#include <mruby.h>
#include <mruby/array.h>
#include <mruby/variable.h>
#include <mruby/iv_benchmark.h>

#define MIN_COUNT 2000

static mrb_value
create_objects(mrb_state *mrb, mrb_int size)
{
  mrb_value object_ary = mrb_ary_new_capa(mrb, size);
  mrb_value *objects = RARRAY_PTR(object_ary);
  for (mrb_int i = 0; i < size; ++i) {
    objects[i] = mrb_obj_new(mrb, mrb->object_class, 0, NULL);
  }
  return object_ary;
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
    mrb_int times[max_iv_size], iv_size, elapsed_time = 0, total_time = 0;
    int i, c, total_count;
    mrb_value symbol_ary, object_ary, *symbols, *objects;
    if (!(mrb = mrb_ivbm_open_mruby(NULL))) goto final;
    mrb_ivbm_disable_gc(mrb);
    for (iv_size = 0; iv_size < max_iv_size; ++iv_size) times[iv_size] = 0;
    symbol_ary = mrb_ivbm_create_symbols(mrb, max_iv_size);
    symbols = RARRAY_PTR(symbol_ary);
    object_ary = create_objects(mrb, MIN_COUNT);
    objects = RARRAY_PTR(object_ary);
    for (c = 1; elapsed_time < measurement_time; ++c) {
      for (i = 0; i < MIN_COUNT; ++i) {
        struct RObject *o = mrb_obj_ptr(objects[i]);
        mrb_gc_free_iv(mrb, o);
        o->iv = NULL;
      }
      for (iv_size = 1; iv_size <= max_iv_size; ++iv_size) {
        mrb_value sym_obj = symbols[iv_size-1];
        mrb_sym sym = mrb_symbol(sym_obj);
        mrb_int t = mrb_ivbm_time();
        for (i = 0; i < MIN_COUNT; ++i) {
          mrb_obj_iv_set(mrb, mrb_obj_ptr(objects[i]), sym, sym_obj);
        }
        t = mrb_ivbm_time() - t;
        times[iv_size-1] += t;
        elapsed_time += t;
      }
    }
    total_count = c * MIN_COUNT;
    printf("# %d times\n", total_count);
    puts("# hash size\teach i/s\teach seconds\ttotal i/s\ttotal seconds");
    for (iv_size = 1; iv_size <= max_iv_size; ++iv_size) {
      mrb_int t = times[iv_size-1];
      total_time += t;
      printf("%"MRB_PRId"\t"
             MRB_IVBM_IPS_FMT"\t"
             MRB_IVBM_ELAPSED_SEC_FMT"\t"
             MRB_IVBM_IPS_FMT"\t"
             MRB_IVBM_ELAPSED_SEC_FMT"\n",
             iv_size,
             total_count*1e6/t,
             t/1e6,
             total_count*1e6/total_time,
             total_time/1e6);
    }
  }

 final:
  return mrb_ivbm_close_mruby(mrb);
}
