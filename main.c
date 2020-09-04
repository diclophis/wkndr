// stdlib stuff


#include <stdio.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <assert.h>


// mruby stuff
#include <mruby.h>
#include <mruby/array.h>
#include <mruby/irep.h>
#include <mruby/compile.h>
#include <mruby/string.h>
#include <mruby/error.h>
#include <mruby/data.h>
#include <mruby/class.h>
#include <mruby/value.h>
#include <mruby/variable.h>
#include <mruby/error.h>
#include <mruby/array.h>
#include <mruby/irep.h>
#include <mruby/compile.h>
#include <mruby/string.h>
#include <mruby/numeric.h>
#include <mruby/array.h>
#include <mruby/irep.h>
#include <mruby/compile.h>
#include <mruby/string.h>
#include <mruby/error.h>
#include <mruby/data.h>
#include <mruby/class.h>
#include <mruby/value.h>
#include <mruby/variable.h>
#include <mruby/string.h>
#include <mruby/hash.h>
#include <string.h>


// raylib stuff
#include <raylib.h>
#include <raymath.h>
//#include <raygui.h>


// emscripten/wasm stuff
#ifdef PLATFORM_WEB
  #include <emscripten/emscripten.h>
  #include <emscripten/html5.h>
#endif


// other stuff
#ifndef FLT_MAX
  #define FLT_MAX 3.40282347E+38F
#endif


// internal wkndr stuff
#include "mrb_web_socket.h"
#include "mrb_stack_blocker.h"
#include "mrb_game_loop.h"
#include "mrb_model.h"


// ruby lib stuff
#include "globals.h"
#include "stack_blocker.h"
#include "markaby.h"
#include "wkndr.h"
#include "ecs.h"
#include "client_side.h"
#include "game_loop.h"
#include "socket_stream.h"
#include "camera.h"
#include "aabb.h"


//server stuff
#ifdef TARGET_DESKTOP

#include "connection.h"
#include "server.h"
#include "server_side.h"
#include "uv_io.h"
#include "wslay_socket_stream.h"
#include "embed_static.h"
#include "protocol.h"
#include "mrb_uv.h"

#endif


typedef struct {
 mrb_state* mrb_pointer;
 struct RObject* self_pointer;
} loop_data_s;
static void crisscross_data_destructor(mrb_state *mrb, void *p_);
const struct mrb_data_type crisscross_data_type = {"crisscross_data", crisscross_data_destructor};


static void if_exception_error_and_exit(mrb_state* mrb, char *context) {
  // check for exception, only one can exist at any point in time
  if (mrb->exc) {
    fprintf(stderr, "Exception in %s", context);
    mrb_print_error(mrb);
    exit(2);
  }
}


//TODO
static void crisscross_data_destructor(mrb_state *mrb, void *p_) {
}


//TODO
mrb_value cheese_cross(mrb_state* mrb, mrb_value self) {
  loop_data_s *loop_data = NULL;

  mrb_value data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@flip_pointer"));

  Data_Get_Struct(mrb, data_value, &crisscross_data_type, loop_data);
  if (!loop_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @flip_pointer");
  }

  //TODO
  mrb_value wiz_return_halt = mrb_funcall(loop_data->mrb_pointer, mrb_obj_value(loop_data->self_pointer), "process_stacks!", 0, 0);

  if (loop_data->mrb_pointer->exc) {
    fprintf(stderr, "Exception in SERVER_SIDE_TRY_CRISS_CROSS_PROCESS_STACKS!\n");
    mrb_print_error(loop_data->mrb_pointer);
    //mrb_print_backtrace(loop_data->mrb_pointer);
    return mrb_false_value();
  }

  //if (mrb_test(wiz_return_halt)) {
    return mrb_true_value();
  //} else {
  //  return mrb_false_value();
  //}
}


static mrb_value eval_static_libs(mrb_state* mrb, ...) {
  va_list argp;
  va_start(argp, mrb);

  int end_of_static_libs = 0;
  uint8_t const *p;

  mrb_value ret;

  while(!end_of_static_libs) {
    p = va_arg(argp, uint8_t const*);
    if (NULL == p) {
      end_of_static_libs = 1;
    } else {
      ret = mrb_load_irep(mrb, p);
      if_exception_error_and_exit(mrb, "bundled ruby static lib\n");
    }
  }

  va_end(argp);

  return ret;
}


#ifdef PLATFORM_WEB

EMSCRIPTEN_KEEPALIVE
size_t handle_js_websocket_event(mrb_state* mrb, struct RObject* selfP, const char* buf, size_t n) {
  //mrb_value cstrlikebuf = mrb_str_new(mrb, buf, n);
  mrb_value empty_string = mrb_str_new_lit(mrb, "");
  mrb_value clikestr_as_string = mrb_str_cat(mrb, empty_string, buf, n);
  mrb_funcall(mrb, mrb_obj_value(selfP), "dispatch_next_events", 1, clikestr_as_string);
  return 0;
}

EMSCRIPTEN_KEEPALIVE
size_t pack_outbound_tty(mrb_state* mrb, struct RObject* selfP, const char* buf, size_t n) {
  mrb_value empty_string = mrb_str_new_lit(mrb, "");
  mrb_value clikestr_as_string = mrb_str_cat(mrb, empty_string, buf, n);

  mrb_value outbound_tty_msg = mrb_hash_new(mrb);
  mrb_hash_set(mrb, outbound_tty_msg, mrb_fixnum_value(0), clikestr_as_string);
  
  mrb_funcall(mrb, mrb_obj_value(selfP), "write_typed", 1, outbound_tty_msg);

  return 0;
}

EMSCRIPTEN_KEEPALIVE
size_t resize_tty(mrb_state* mrb, struct RObject* selfP, int w, int h) {

  mrb_value outbound_resize_msg = mrb_ary_new(mrb);
  //mrb_ary_push(mrb, outbound_resize_msg, mrb_fixnum_value(cols));
  //mrb_ary_push(mrb, outbound_resize_msg, mrb_fixnum_value(rows));
  mrb_ary_push(mrb, outbound_resize_msg, mrb_fixnum_value(w));
  mrb_ary_push(mrb, outbound_resize_msg, mrb_fixnum_value(h));

 
  //TODO: determine if resize event made sense ....!!!!????
  //mrb_value outbound_msg = mrb_hash_new(mrb);
  //mrb_hash_set(mrb, outbound_msg, mrb_fixnum_value(3), outbound_resize_msg);
  //mrb_funcall(mrb, mrb_obj_value(selfP), "write_typed", 1, outbound_msg);

  if (IsWindowReady()) {
    SetWindowSize(w, h);
  }

  return 0;
}

EMSCRIPTEN_KEEPALIVE
size_t socket_connected(mrb_state* mrb, struct RObject* selfP, const char* buf, size_t n) {
  mrb_value empty_string = mrb_str_new_lit(mrb, "");
  mrb_value clikestr_as_string = mrb_str_cat(mrb, empty_string, buf, n);

  mrb_funcall(mrb, mrb_obj_value(selfP), "did_connect", 1, clikestr_as_string);

  return 0;
}

// Function to trigger alerts straight from C++
EMSCRIPTEN_KEEPALIVE
void Alert(const char *msg) {
  EM_ASM_ARGS({
    var msg = Pointer_stringify($0); // Convert message to JS string
    alert(msg);                      // Use JS version of alert
  }, msg);
}

#endif


mrb_value socket_stream_connect(mrb_state* mrb, mrb_value self) {
  long int write_packed_pointer = 0;

fprintf(stderr, "BEFEB\n");

#ifdef PLATFORM_WEB
  write_packed_pointer = EM_ASM_INT({
    return window.startConnection($0, $1);
  }, mrb, mrb_obj_ptr(self));
#endif

fprintf(stderr, "GOTHERE\n");

  mrb_iv_set(
      mrb, self, mrb_intern_lit(mrb, "@client"), // set @data
      mrb_fixnum_value(write_packed_pointer));

  return self;
}


mrb_value socket_stream_write_packed(mrb_state* mrb, mrb_value self) {
  mrb_value data_value;

  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@client"));

  mrb_int fp = mrb_int(mrb, data_value);

  void (*write_packed_pointer)(int, const void*, int) = (void (*)(int, const void*, int))fp;

  mrb_value packed_bytes;
  mrb_get_args(mrb, "o", &packed_bytes);

  const char *foo = mrb_string_value_ptr(mrb, packed_bytes);
  int len = mrb_string_value_len(mrb, packed_bytes);

  write_packed_pointer(1, foo, len);

  return self;
}


//TODO
void platform_bits_update_void(void* arg) {
  loop_data_s* loop_data = arg;

  mrb_state* mrb = loop_data->mrb_pointer;
  struct RObject* self = loop_data->self_pointer;
  mrb_value selfV = mrb_obj_value(self);

  platform_bits_signal(mrb, selfV);
}


//TODO
mrb_value global_show(mrb_state* mrb, mrb_value self) {
  fprintf(stderr, "preShowShoSshow!\n");

  mrb_value stack_self;

  mrb_get_args(mrb, "o", &stack_self);

  loop_data_s* loop_data = (loop_data_s*)malloc(sizeof(loop_data_s));


  loop_data->mrb_pointer = mrb;
  loop_data->self_pointer = mrb_obj_ptr(stack_self);

#ifdef PLATFORM_WEB
  //emscripten_sample_gamepad_data();

  emscripten_set_main_loop_timing(EM_TIMING_RAF, 1);
  emscripten_set_main_loop_arg(platform_bits_update_void, loop_data, 0, 1);

#endif

#ifdef PLATFORM_DESKTOP
  
#endif

  //fprintf(stderr, "wtf show!\n");

  return self;
}


int main(int argc, char** argv) {
  mrb_state *mrb;
  mrb_state *mrb_client;
  int i;

  // initialize mruby serverside
  if (!(mrb = mrb_open())) {
    fprintf(stderr,"%s: could not initialize mruby\n",argv[0]);
    return -1;
  }

  // initialize mruby clientside
  if (!(mrb_client = mrb_open())) {
    fprintf(stderr,"%s: could not initialize mruby client\n",argv[0]);
    return -1;
  }

  mrb_value args = mrb_ary_new(mrb_client);
  mrb_value args_server = mrb_ary_new(mrb);

  // convert argv into mruby strings
  for (i=1; i<argc; i++) {
    mrb_ary_push(mrb_client, args, mrb_str_new_cstr(mrb_client, argv[i]));
    mrb_ary_push(mrb, args_server, mrb_str_new_cstr(mrb, argv[i]));
  }

  mrb_define_global_const(mrb, "ARGV", args_server);
  mrb_define_global_const(mrb_client, "ARGV", args);

  eval_static_libs(mrb, globals, NULL);
  eval_static_libs(mrb_client, globals, NULL);

  fprintf(stderr, "loaded globals ... \n");

  //struct RClass *fast_utmp = mrb_define_class(mrb, "FastUTMP", mrb->object_class);
  //mrb_define_class_method(mrb, fast_utmp, "utmps", fast_utmp_utmps, MRB_ARGS_NONE());

  //struct RClass *fast_tty = mrb_define_class(mrb, "FastTTY", mrb->object_class);
  //mrb_define_class_method(mrb, fast_tty, "fd", fast_tty_fd, MRB_ARGS_NONE());
  //mrb_define_class_method(mrb, fast_tty, "close", fast_tty_close, MRB_ARGS_REQ(2));
  //mrb_define_class_method(mrb, fast_tty, "resize", fast_tty_resize, MRB_ARGS_REQ(3));

  struct RClass *websocket_mod = mrb_define_module(mrb, "WebSocket");
  mrb_define_class_under(mrb, websocket_mod, "Error", E_RUNTIME_ERROR);
  mrb_define_module_function(mrb, websocket_mod, "create_accept", mrb_websocket_create_accept, MRB_ARGS_REQ(1));

  //TODO: create class PlatformBits
  struct RClass *stack_blocker_class = mrb_define_class(mrb, "StackBlocker", mrb->object_class);
  mrb_define_method(mrb, stack_blocker_class, "signal", platform_bits_server, MRB_ARGS_NONE());

  struct RClass *stack_blocker_class_client = mrb_define_class(mrb_client, "StackBlocker", mrb_client->object_class);
  mrb_define_method(mrb_client, stack_blocker_class_client, "signal", platform_bits_signal, MRB_ARGS_NONE());

  //// class GameLoop
  mrb_define_game_loop(mrb_client);

  //// class Model
  //struct RClass *model_class = mrb_define_class(mrb_client, "Model", mrb->object_class);
  //mrb_define_method(mrb_client, model_class, "initialize", model_initialize, MRB_ARGS_REQ(3));
  //mrb_define_method(mrb_client, model_class, "draw", model_draw, MRB_ARGS_NONE());
  //mrb_define_method(mrb_client, model_class, "deltap", model_deltap, MRB_ARGS_REQ(3));
  //mrb_define_method(mrb_client, model_class, "deltar", model_deltar, MRB_ARGS_REQ(4));
  //mrb_define_method(mrb_client, model_class, "deltas", model_deltas, MRB_ARGS_REQ(3));
  //mrb_define_method(mrb_client, model_class, "yawpitchroll", model_yawpitchroll, MRB_ARGS_REQ(6));
  //mrb_define_method(mrb_client, model_class, "label", model_label, MRB_ARGS_REQ(1));

  //// class Cube
  //struct RClass *cube_class = mrb_define_class(mrb_client, "Cube", model_class);
  //mrb_define_method(mrb_client, cube_class, "initialize", cube_initialize, MRB_ARGS_REQ(4));

  //// class Sphere
  //struct RClass *sphere_class = mrb_define_class(mrb_client, "Sphere", model_class);
  //mrb_define_method(mrb_client, sphere_class, "initialize", sphere_initialize, MRB_ARGS_REQ(4));

  eval_static_libs(mrb, markaby, NULL);
  eval_static_libs(mrb, stack_blocker, NULL);
  eval_static_libs(mrb, game_loop, NULL);

  eval_static_libs(mrb_client, stack_blocker, NULL);
  eval_static_libs(mrb_client, game_loop, NULL);
  eval_static_libs(mrb_client, camera, NULL);
  eval_static_libs(mrb_client, aabb, NULL);
  //eval_static_libs(mrb_client, window, NULL);
  //eval_static_libs(mrb_client, box, NULL);
  //eval_static_libs(mrb_client, theseus, NULL);

  struct RClass *thor_class = mrb_define_class(mrb, "Wkndr", mrb->object_class);
  struct RClass *thor_class_client = mrb_define_class(mrb_client, "Wkndr", mrb_client->object_class);

  eval_static_libs(mrb, wkndr, NULL);
  eval_static_libs(mrb_client, wkndr, NULL);

  eval_static_libs(mrb, ecs, NULL);
  eval_static_libs(mrb_client, ecs, NULL);

  ////TODO: this is related to Window
  mrb_define_class_method(mrb_client, thor_class_client, "show!", global_show, MRB_ARGS_REQ(1));

  struct RClass *socket_stream_class = mrb_define_class(mrb, "SocketStream", mrb->object_class);
  struct RClass *socket_stream_class_client = mrb_define_class(mrb_client, "SocketStream", mrb_client->object_class);

  mrb_define_method(mrb_client, socket_stream_class_client, "connect!", socket_stream_connect, MRB_ARGS_REQ(1));
  mrb_define_method(mrb_client, socket_stream_class_client, "write_packed", socket_stream_write_packed, MRB_ARGS_REQ(1));
  //mrb_define_method(mrb_client, socket_stream_class_client, "write_tty", socket_stream_unpack_inbound_tty, MRB_ARGS_REQ(1));

  eval_static_libs(mrb_client, socket_stream, NULL);

  struct RClass *client_side_top_most_thor = mrb_define_class(mrb_client, "ClientSide", thor_class_client);

  mrb_mruby_model_gem_init(mrb_client);

#ifdef TARGET_DESKTOP

  // libuv stuff
  mrb_mruby_uv_gem_init(mrb);
  mrb_mruby_uv_gem_init(mrb_client);

  eval_static_libs(mrb, embed_static_js, embed_static_txt, embed_static_css, embed_static_ico, NULL);

  eval_static_libs(mrb, wslay_socket_stream, uv_io, NULL);
  eval_static_libs(mrb, connection, NULL);
  eval_static_libs(mrb, server, NULL);
  eval_static_libs(mrb, protocol, NULL);

  eval_static_libs(mrb_client, wslay_socket_stream, uv_io, NULL);

  struct RClass *server_side_top_most_thor = mrb_define_class(mrb, "ServerSide", thor_class);

  loop_data_s* loop_data = (loop_data_s*)malloc(sizeof(loop_data_s));
  loop_data->mrb_pointer = mrb_client;
  loop_data->self_pointer = mrb_obj_ptr(mrb_obj_value(client_side_top_most_thor));

  mrb_iv_set(
      mrb, mrb_obj_value(server_side_top_most_thor), mrb_intern_lit(mrb, "@flip_pointer"),
      mrb_obj_value(
          Data_Wrap_Struct(mrb, mrb->object_class, &crisscross_data_type, loop_data)));

  mrb_define_class_method(mrb, thor_class, "server_side_tick!", cheese_cross, MRB_ARGS_REQ(0));

  mrb_value retret_stack_server = eval_static_libs(mrb, server_side, NULL);

  ////TODO: re-bootstrap centalized shell3
  mrb_funcall(mrb, mrb_obj_value(server_side_top_most_thor), "startup_serverside", 1, args_server);
  if (mrb->exc) {
    fprintf(stderr, "Exception in SERVERSTARTUP\n");
    mrb_print_error(mrb);
    mrb_print_backtrace(mrb);
  }

#endif

  mrb_value retret_stack = eval_static_libs(mrb_client, client_side, NULL);

  ////TODO: re-bootstrap centalized shell3
  mrb_funcall(mrb_client, mrb_obj_value(client_side_top_most_thor), "startup_clientside", 1, args);
  if (mrb_client->exc) {
    fprintf(stderr, "Exception in CLIENTSTARTUP\n");
    mrb_print_error(mrb_client);
    mrb_print_backtrace(mrb_client);
  }

#ifdef TARGET_DESKTOP

  mrb_funcall(mrb, mrb_obj_value(server_side_top_most_thor), "block!", 0, 0);
  if (mrb->exc) {
    fprintf(stderr, "Exception in SERVERBLOCKINIT\n");
    mrb_print_error(mrb);
    //mrb_print_backtrace(mrb);
  }

#endif

#ifdef PLATFORM_WEB

  fprintf(stderr, "going for wizbang ... \n");

  mrb_funcall(mrb_client, mrb_obj_value(client_side_top_most_thor), "wizbang!", 0, 0);
  if (mrb_client->exc) {
    fprintf(stderr, "Exception in CLIENTBLOCK\n");
    mrb_print_error(mrb_client);
    mrb_print_backtrace(mrb_client);
  }

#endif

  fprintf(stderr, "no more blocking operations, closing contexts ... \n");

  mrb_close(mrb);
  mrb_close(mrb_client);

  ////NOTE: when libuv binds to fd=0 it sets modes that cause /usr/bin/read to break
  //fcntl(0, F_SETFL, fcntl(0, F_GETFL) & ~O_NONBLOCK);

  fprintf(stderr, "exiting ... \n");

  return 33;
}
