//


// system stuff
#include <stdlib.h>
#include <time.h>
#include <sys/time.h>


// mruby stuff
#include <mruby.h>
#include <mruby/numeric.h>


// raylib stuff
#include <raylib.h>

static double globalTime = 0;
static double startTime = -1;
static double latestTime = -1;

mrb_value platform_bits_update(mrb_state* mrb, mrb_value self) {
  double time;
  double dt;

  int sw,sh;

double currentTime;

#if defined(__EMSCRIPTEN__)
  currentTime = (double)(emscripten_get_now() * 1000.0); // +
#else
  struct timeval timev;
  gettimeofday(&timev, NULL);
  currentTime = timev.tv_sec * 1000000LL + timev.tv_usec;
#endif

  if (startTime == -1) {
    startTime = currentTime;
  }

  time = (currentTime - startTime) / 1000000.0;

  if (latestTime == -1) {
    latestTime = time;
  }

  dt = (time - latestTime);
  //dt = time;

  sw = GetScreenWidth();
  sh = GetScreenHeight();

  mrb_funcall(mrb, self, "update", 4, mrb_float_value(mrb, time), mrb_float_value(mrb, dt), mrb_int_value(mrb, sw), mrb_int_value(mrb, sh));

  latestTime = time;

  if (mrb->exc) {
    fprintf(stderr, "Exception in SERVER_UPDATE_BITS");
    mrb_print_error(mrb);
    mrb_print_backtrace(mrb);
    return mrb_nil_value();
  }

  return mrb_true_value();
}
