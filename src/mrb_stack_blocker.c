//


// system stuff
#include <stdlib.h>
#include <time.h>
#include <sys/time.h>


// mruby stuff
#include <mruby.h>
#include <mruby/numeric.h>
#include <mruby/array.h>


// raylib stuff
#include <raylib.h>


// emscripten/wasm stuff
#ifdef PLATFORM_WEB
  #include <emscripten/emscripten.h>
  #include <emscripten/html5.h>
#endif

static double globalTime = 0;
static double startTime = -1;
static double latestTime = -1;

//NOTE: this is the client side per every frame, double C-hop possibly???
mrb_value platform_bits_signal(mrb_state* mrb, mrb_value self) {
  mrb_value signal_return = mrb_nil_value();

  double time = 0.0;
  double dt = 0.0;

  int sw,sh;

  double currentTime = 0.0;

#if defined(__EMSCRIPTEN__)
  currentTime = (double)(emscripten_get_now() / 1000.0);
#else
  struct timespec _t;
  clock_gettime(CLOCK_REALTIME, &_t);
  currentTime = (_t.tv_sec*1000 + lround(_t.tv_nsec/1e6)) / 1000.0;
#endif

  if (latestTime == -1) {
    latestTime = currentTime;
  }

  if (startTime == -1) {
    startTime = currentTime;
  }

  dt = (currentTime - latestTime);

  if (dt > (1.0 / 59.0)) {
    sw = GetScreenWidth();
    sh = GetScreenHeight();
  
    mrb_value touchpoints = mrb_ary_new(mrb);
  
    for (int i = 0; i < GetTouchPointCount(); ++i) {
      Vector2 touchPosition = GetTouchPosition(i);
    
      mrb_value touchxy = mrb_ary_new(mrb);
      mrb_ary_set(mrb, touchxy, 0, mrb_float_value(mrb, touchPosition.x));
      mrb_ary_set(mrb, touchxy, 1, mrb_float_value(mrb, touchPosition.y));
      mrb_ary_set(mrb, touchxy, 2, mrb_float_value(mrb, 0));
  
      mrb_ary_set(mrb, touchpoints, i, touchxy);
    }
 
    //fprintf(stderr, "before_signal_return\n");

    signal_return = mrb_funcall(mrb, self, "update", 6, mrb_false_value(), mrb_float_value(mrb, currentTime - startTime), mrb_float_value(mrb, dt), mrb_int_value(mrb, sw), mrb_int_value(mrb, sh), touchpoints);
    if (mrb->exc) {
      fprintf(stderr, "Exception in CLIENT_FOO_CLIENT_BITS");
      mrb_print_error(mrb);
      mrb_print_backtrace(mrb);
      return mrb_nil_value();
    }

    //fprintf(stderr, "after_signal_return\n");
  
  #if defined(__EMSCRIPTEN__)
    latestTime = (double)(emscripten_get_now() / 1000.0);
  #else
    clock_gettime(CLOCK_REALTIME, &_t);
    latestTime = (_t.tv_sec*1000 + lround(_t.tv_nsec/1e6)) / 1000.0;
  #endif
  
  }

  //return mrb_true_value();
  return signal_return;
}


mrb_value platform_bits_server(mrb_state* mrb, mrb_value self) {
  double time;
  double dt;
  int sw,sh;

  mrb_value platformBitsServerResult = mrb_nil_value();

  sw = sh = time = dt = -22;

  platformBitsServerResult = mrb_funcall(mrb, self, "update", 6, mrb_false_value(), mrb_float_value(mrb, time), mrb_float_value(mrb, dt), mrb_int_value(mrb, sw), mrb_int_value(mrb, sh), mrb_nil_value());
  if (mrb->exc) {
    fprintf(stderr, "Exception in SERVER_UPDATE_BITS");
    mrb_print_error(mrb);
    mrb_print_backtrace(mrb);
    return mrb_nil_value();
  }

  return platformBitsServerResult;
}
