//


// system stuff
#include <stdlib.h>
#include <time.h>


// mruby stuff
#include <mruby.h>


mrb_value platform_bits_update(mrb_state* mrb, mrb_value self) {
  double time;
  float dt;

  //time = GetTime();
  //dt = GetFrameTime();

#ifdef PLATFORM_DESKTOP
  struct timespec spend;
  struct timespec rem;
  spend.tv_nsec = 10000000;
  nanosleep(&spend, &rem);
#endif

  mrb_funcall(mrb, self, "update", 2, mrb_float_value(mrb, time), mrb_float_value(mrb, dt));

  if (mrb->exc) {
    fprintf(stderr, "Exception in SERVER_UPDATE_BITS");
    mrb_print_error(mrb);
    mrb_print_backtrace(mrb);
    return mrb_nil_value();
  }

  return mrb_true_value();
}
