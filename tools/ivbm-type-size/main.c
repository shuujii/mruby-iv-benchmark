#include <stdio.h>
#include <stdlib.h>
#include <mruby.h>

#define PRINT_TYPE_SIZE(type) printf("%s\t%zu\n", #type, sizeof(type));

int
main(int argc, char **argv)
{
  puts("# type\tsize");
  PRINT_TYPE_SIZE(void*);
  PRINT_TYPE_SIZE(mrb_value);
  PRINT_TYPE_SIZE(mrb_int);
  return EXIT_SUCCESS;
}
