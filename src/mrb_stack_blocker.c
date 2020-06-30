//

// system stuff
#include <stdlib.h>


// mruby stuff
#include <mruby.h>


mrb_value platform_bits_update(mrb_state* mrb, mrb_value self) {
  double time;
  float dt;

  //time = GetTime();
  //dt = GetFrameTime();

  mrb_funcall(mrb, self, "update", 2, mrb_float_value(mrb, time), mrb_float_value(mrb, dt));

  if (mrb->exc) {
    fprintf(stderr, "Exception in SERVER_UPDATE_BITS");
    mrb_print_error(mrb);
    mrb_print_backtrace(mrb);
    return mrb_nil_value();
  }

  return mrb_true_value();
}
