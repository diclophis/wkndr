//


// system stuff
#include <stdlib.h>
#include <time.h>


// mruby stuff
#include <mruby.h>
#include <mruby/numeric.h>


// raylib stuff
#include <raylib.h>

mrb_value platform_bits_update(mrb_state* mrb, mrb_value self) {
  double time;
  float dt;

  int sw,sh;

  time = GetTime();
  dt = GetFrameTime();

  sw = GetScreenWidth();
  sh = GetScreenHeight();

  mrb_funcall(mrb, self, "update", 4, mrb_float_value(mrb, time), mrb_float_value(mrb, dt), mrb_int_value(mrb, sw), mrb_int_value(mrb, sh));

  if (mrb->exc) {
    fprintf(stderr, "Exception in SERVER_UPDATE_BITS");
    mrb_print_error(mrb);
    mrb_print_backtrace(mrb);
    return mrb_nil_value();
  }

  return mrb_true_value();
}
