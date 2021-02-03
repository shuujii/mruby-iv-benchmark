#include <stdio.h>
#include <stdlib.h>
#include <mruby.h>
#include <mruby/array.h>
#include <mruby/variable.h>
#include <mruby/iv_benchmark.h>

#define ALLOC_OFFSET 8

static size_t gTotalAllocSize;
static size_t gMaxAllocSize;

static size_t
mem_total_alloc_size(void)
{
  return gTotalAllocSize;
}

static size_t
mem_max_alloc_size(void)
{
  return gMaxAllocSize;
}

static void
mem_reset_alloc_size(void)
{
  gTotalAllocSize = gMaxAllocSize = 0;
}

static size_t
mem_alloc_size(void *ptr)
{
  return *(size_t*)(ptr - ALLOC_OFFSET);
}

static void*
mem_alloc(mrb_state *mrb, void *ptr, size_t size, void* ud)
{
  if (size == 0) {
    if (ptr) {
      gTotalAllocSize -= mem_alloc_size(ptr);
      free(ptr - ALLOC_OFFSET);
    }
    return NULL;
  }
  else {
    size_t old_size;
    void *new_ptr;
    if (ptr) {
      old_size = mem_alloc_size(ptr);
      new_ptr = realloc(ptr - ALLOC_OFFSET, size + ALLOC_OFFSET);
    }
    else {
      old_size = 0;
      new_ptr = malloc(size + ALLOC_OFFSET);
    }
    if (!new_ptr) return NULL;
    *(size_t*)new_ptr = size;
    gTotalAllocSize += size - old_size;
    if (gMaxAllocSize < gTotalAllocSize) gMaxAllocSize = gTotalAllocSize;
    return new_ptr + ALLOC_OFFSET;
  }
}

static void
print_alloc_size(mrb_int iv_size)
{
  printf("%"MRB_PRId"\t%zu\t%zu\n",
         iv_size, mem_total_alloc_size(), mem_max_alloc_size());
}

int
main(int argc, char **argv)
{
  mrb_int max_iv_size = DEFAULT_IV_SIZE, iv_size = 0;
  mrb_state *mrb = NULL;

  if (!mrb_ivbm_parse_arg(argc, argv, "[IV-SIZE]", &max_iv_size)) goto final;
  if (!(mrb = mrb_ivbm_open_mruby(mem_alloc))) goto final;
  mrb_value symbol_ary = mrb_ivbm_create_symbols(mrb, max_iv_size);
  mrb_value *symbols = RARRAY_PTR(symbol_ary);
  mrb_value obj = mrb_obj_new(mrb, mrb->object_class, 0, NULL);
  mrb_ivbm_disable_gc(mrb);
  mem_reset_alloc_size();
  puts("# iv size\ttotal alloc size\tmax alloc size");
  print_alloc_size(iv_size);
  for (iv_size = 1; iv_size <= max_iv_size; ++iv_size) {
    mrb_value v = symbols[iv_size-1];
    mrb_iv_set(mrb, obj, mrb_symbol(v), v);
    print_alloc_size(iv_size);
  }

 final:
  return mrb_ivbm_close_mruby(mrb);
}
