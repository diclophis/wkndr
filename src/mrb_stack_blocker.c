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


// emscripten/wasm stuff
#ifdef PLATFORM_WEB
  #include <emscripten/emscripten.h>
  #include <emscripten/html5.h>
#endif

static double globalTime = 0;
static double startTime = -1;
static double latestTime = -1;

mrb_value platform_bits_signal(mrb_state* mrb, mrb_value self) {
  double time = 0.0;
  double dt = 0.0;

  int sw,sh;

  double currentTime = 0.0;

#if defined(__EMSCRIPTEN__)
  currentTime = (double)(emscripten_get_now() / 1000.0);
#else
//  struct timeval timev;
//  gettimeofday(&timev, NULL);
//  currentTime = (timev.tv_sec * 1000000LL + timev.tv_usec) / 1000000.0;
////  //time = (currentTime - startTime) 
    //long            ms; // Milliseconds
    //time_t          s;  // Seconds
    //struct timespec spec;

    //clock_gettime(CLOCK_REALTIME, &spec);

    //s  = spec.tv_sec;
    //ms = round(spec.tv_nsec / 1.0e6); // Convert nanoseconds to milliseconds
    //if (ms > 999) {
    //    s++;
    //    ms = 0;
    //}
    struct timespec _t;
    clock_gettime(CLOCK_REALTIME, &_t);
    currentTime = (_t.tv_sec*1000 + lround(_t.tv_nsec/1e6)) / 1000.0;

#endif

//
//  //time = currentTime;
//
  if (latestTime == -1) {
    latestTime = currentTime;
  }

//  //time = (currentTime - startTime) / 1000000.0;
  if (startTime == -1) {
    startTime = currentTime;
  }
//
  dt = (currentTime - latestTime);

  sw = GetScreenWidth();
  sh = GetScreenHeight();

  mrb_funcall(mrb, self, "update", 5, mrb_false_value(), mrb_float_value(mrb, currentTime - startTime), mrb_float_value(mrb, dt), mrb_int_value(mrb, sw), mrb_int_value(mrb, sh));

#if defined(__EMSCRIPTEN__)
  latestTime = (double)(emscripten_get_now() / 1000.0);
#else
    clock_gettime(CLOCK_REALTIME, &_t);
    latestTime = (_t.tv_sec*1000 + lround(_t.tv_nsec/1e6)) / 1000.0;
#endif

  if (mrb->exc) {
    fprintf(stderr, "Exception in SERVER_UPDATE_BITS");
    mrb_print_error(mrb);
    mrb_print_backtrace(mrb);
    return mrb_nil_value();
  }

  return mrb_true_value();
}


mrb_value platform_bits_server(mrb_state* mrb, mrb_value self) {
  double time;
  double dt;
  int sw,sh;

  sw = sh = time = dt = -22;

  mrb_funcall(mrb, self, "update", 5, mrb_false_value(), mrb_float_value(mrb, time), mrb_float_value(mrb, dt), mrb_int_value(mrb, sw), mrb_int_value(mrb, sh));
  if (mrb->exc) {
    fprintf(stderr, "Exception in SERVER_UPDATE_BITS");
    mrb_print_error(mrb);
    mrb_print_backtrace(mrb);
    return mrb_nil_value();
  }

  return mrb_true_value();
}
