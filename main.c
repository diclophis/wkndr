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


// ruby lib stuff
#include "globals.h"
#include "stack_blocker.h"
#include "markaby.h"
#include "wkndr.h"
#include "ecs.h"
#include "client_side.h"
#include "game_loop.h"


//server stuff
#ifdef TARGET_DESKTOP

#include "connection.h"
#include "server.h"
#include "server_side.h"
#include "uv_io.h"
#include "wslay_socket_stream.h"
#include "embed_static.h"
#include "protocol.h"

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


static void crisscross_data_destructor(mrb_state *mrb, void *p_) {
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
  mrb_define_method(mrb, stack_blocker_class, "signal", platform_bits_update, MRB_ARGS_NONE());

  struct RClass *stack_blocker_class_client = mrb_define_class(mrb_client, "StackBlocker", mrb_client->object_class);
  mrb_define_method(mrb_client, stack_blocker_class_client, "signal", platform_bits_update, MRB_ARGS_NONE());

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
  //eval_static_libs(mrb, game_loop, NULL);

  eval_static_libs(mrb_client, stack_blocker, NULL);
  eval_static_libs(mrb_client, game_loop, NULL);
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
  //mrb_define_class_method(mrb_client, thor_class_client, "show!", global_show, MRB_ARGS_REQ(1));

  struct RClass *socket_stream_class = mrb_define_class(mrb, "SocketStream", mrb->object_class);
  struct RClass *socket_stream_class_client = mrb_define_class(mrb_client, "SocketStream", mrb_client->object_class);

  //mrb_define_method(mrb_client, socket_stream_class_client, "connect!", socket_stream_connect, MRB_ARGS_REQ(0));
  //mrb_define_method(mrb_client, socket_stream_class_client, "write_packed", socket_stream_write_packed, MRB_ARGS_REQ(1));
  //mrb_define_method(mrb_client, socket_stream_class_client, "write_tty", socket_stream_unpack_inbound_tty, MRB_ARGS_REQ(1));

  //eval_static_libs(mrb_client, socket_stream, NULL);

  struct RClass *client_side_top_most_thor = mrb_define_class(mrb_client, "ClientSide", thor_class_client);

#ifdef TARGET_DESKTOP

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

  //mrb_define_class_method(mrb, thor_class, "cheese_cross!", cheese_cross, MRB_ARGS_REQ(0));

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
    mrb_print_backtrace(mrb);
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

  fprintf(stderr, "closing ... \n");

  mrb_close(mrb);
  mrb_close(mrb_client);

  ////NOTE: when libuv binds to fd=0 it sets modes that cause /usr/bin/read to break
  //fcntl(0, F_SETFL, fcntl(0, F_GETFL) & ~O_NONBLOCK);

  fprintf(stderr, "exiting ... \n");

  return 33;
}
