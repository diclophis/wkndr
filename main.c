// stdlib stuff


#include <stdio.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <assert.h>
#include <time.h>
#include <unistd.h>


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
#include <mruby/internal.h>
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
#include <mruby/throw.h>

#include <string.h>


// raylib stuff
#include <raylib.h>
#include <raymath.h>


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
#include "mrb_editor.h"


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
#include "polygon.h"


//server stuff
#ifdef TARGET_HEAVY

#include "connection.h"
#include "server.h"
#include "server_side.h"
#include "uv_io.h"
#include "wslay_socket_stream.h"
#include "embed_static.h"
#include "protocol.h"
#include "mrb_uv.h"

#endif

//#define DEBUG 0

/* See LICENSE for licence details. */
/* color: index number of color_palette[] (see color.h) */
enum {
	DEFAULT_FG           = 7,
	DEFAULT_BG           = 0,
	ACTIVE_CURSOR_COLOR  = 2,
	PASSIVE_CURSOR_COLOR = 1,
};

/* misc */
enum {
	DEBUG            = false,  /* write dump of input to stdout, debug message to stderr */
	TABSTOP          = 8,      /* hardware tabstop */
	//LAZY_DRAW        = false,  /* don't draw when input data size is larger than BUFSIZE */
	//BACKGROUND_DRAW  = true,   /* always draw even if vt is not active */
	//WALLPAPER        = true,   /* copy framebuffer before startup, and use it as wallpaper */
	SUBSTITUTE_HALF  = 0xFFFD, /* used for missing glyph(single width): U+FFFD (REPLACEMENT CHARACTER)) */
	SUBSTITUTE_WIDE  = 0x3013, /* used for missing glyph(double width): U+3013 (GETA MARK) */
	REPLACEMENT_CHAR = 0xFFFD, /* used for malformed UTF-8 sequence   : U+FFFD (REPLACEMENT CHARACTER)  */
};

/* TERM value */
const char *term_name = "yaft-256color";

//////* shell */
/////#if defined(__linux__) || defined(__MACH__)
/////	const char *shell_cmd = "/bin/bash";
/////#elif defined(__FreeBSD__) || defined(__NetBSD__) || defined(__OpenBSD__)
/////	const char *shell_cmd = "/bin/csh";
/////#elif defined(__ANDROID__)
/////	const char *shell_cmd = "/system/bin/sh"; /* for Android: not tested */
/////#endif


typedef struct {
 mrb_state* mrb_pointer;
 struct RObject* self_pointer;
} loop_data_s;
static void crisscross_data_destructor(mrb_state *mrb, void *p_);
const struct mrb_data_type crisscross_data_type = {"crisscross_data", crisscross_data_destructor};


//TODO: make this work
static void
print_backtrace_XXX(mrb_state *mrb, struct RObject *exc, struct RArray *backtrace)
{
  mrb_int i;
  mrb_int n = (backtrace ? ARY_LEN(backtrace) : 0);
  mrb_value *loc, mesg;

  if (n != 0) {
    if (n > 1) {
      fputs("trace (most recent call last):\n", stderr);
    }
    for (i=n-1,loc=&ARY_PTR(backtrace)[i]; i>0; i--,loc--) {
      if (mrb_string_p(*loc)) {
        fprintf(stderr, "\t[%d] ", (int)i);
        fwrite(RSTRING_PTR(*loc), (int)RSTRING_LEN(*loc), 1, stderr);
        fputc('\n', stderr);
      }
    }
    if (mrb_string_p(*loc)) {
      fwrite(RSTRING_PTR(*loc), (int)RSTRING_LEN(*loc), 1, stderr);
      fputs(": ", stderr);
    }
  }
  else {
    fputs("(unknown):0: ", stderr);
  }

  if (exc == mrb->nomem_err) {
    static const char nomem[] = "Out of memory (NoMemoryError)\n";
    fwrite(nomem, sizeof(nomem)-1, 1, stderr);
  }
  else {
    mesg = mrb_exc_inspect(mrb, mrb_obj_value(exc));
    fwrite(RSTRING_PTR(mesg), RSTRING_LEN(mesg), 1, stderr);
    fputc('\n', stderr);
  }
}

struct backtrace_location {
  int32_t lineno;
  mrb_sym method_id;
  const char *filename;
};
static const mrb_data_type bt_type = { "Backtrace", mrb_free };

struct RObject*
mrb_unpack_backtrace_XXX(mrb_state *mrb, struct RObject *backtrace)
{
  const struct backtrace_location *bt;
  mrb_int n, i;
  int ai;

  if (backtrace == NULL) {
  empty_backtrace:
    return mrb_obj_ptr(mrb_ary_new_capa(mrb, 0));
  }
  if (backtrace->tt == MRB_TT_ARRAY) return backtrace;
  bt = (struct backtrace_location*)mrb_data_check_get_ptr(mrb, mrb_obj_value(backtrace), &bt_type);
  if (bt == NULL) goto empty_backtrace;
  n = (mrb_int)backtrace->flags;
  if (n == 0) goto empty_backtrace;
  backtrace = mrb_obj_ptr(mrb_ary_new_capa(mrb, n));
  ai = mrb_gc_arena_save(mrb);
  for (i = 0; i < n; i++) {
    const struct backtrace_location *entry = &bt[i];
    mrb_value btline;

    if (entry->lineno != -1) {//debug info was available
      btline = mrb_format(mrb, "%s:%d", entry->filename, (int)entry->lineno);
    }
    else { //all that was left was the stack frame
      btline = mrb_format(mrb, "%s:0", entry->filename);
    }
    if (entry->method_id != 0) {
      mrb_str_cat_lit(mrb, btline, ":in ");
      mrb_str_cat_cstr(mrb, btline, mrb_sym_name(mrb, entry->method_id));
    }
    mrb_ary_push(mrb, mrb_obj_value(backtrace), btline);
    mrb_gc_arena_restore(mrb, ai);
  }

  return backtrace;
}

MRB_API void
mrb_print_backtrace_XXX(mrb_state *mrb)
{
  if (!mrb->exc || mrb->exc->tt != MRB_TT_EXCEPTION) {
    return;
  }

  struct RObject *backtrace = ((struct RException*)mrb->exc)->backtrace;
  if (backtrace && backtrace->tt != MRB_TT_ARRAY) backtrace = mrb_unpack_backtrace_XXX(mrb, backtrace);
  print_backtrace_XXX(mrb, mrb->exc, (struct RArray*)backtrace);
}

MRB_API void
mrb_print_error_XXX(mrb_state *mrb)
{
  //if (mrb->jmp == NULL) {
  //  struct mrb_jmpbuf c_jmp;
  //  MRB_TRY(&c_jmp) {
  //    mrb->jmp = &c_jmp;
  //    mrb_print_backtrace(mrb);
  //  } MRB_CATCH(&c_jmp) {
  //    /* ignore exception during print_backtrace() */
  //  } MRB_END_EXC(&c_jmp);
  //  mrb->jmp = NULL;
  //}
  //else {
    mrb_print_backtrace_XXX(mrb);
  //}
}


static void if_exception_error_and_exit(mrb_state* mrb, char *context) {
  // check for exception, only one can exist at any point in time
  if (mrb->exc) {
    fprintf(stderr, "Exception in %s", context);
    mrb_print_error_XXX(mrb);
    mrb_print_backtrace(mrb);
    exit(2);
  }
}


//TODO
static void crisscross_data_destructor(mrb_state *mrb, void *p_) {
}


mrb_value wkndr_log(mrb_state* mrb, mrb_value self) {
  mrb_value msg = mrb_nil_value();

  mrb_get_args(mrb, "o", &msg);
  mrb_value msg_inspected = mrb_funcall(mrb, msg, "inspect", 0);

  fprintf(stdout, "%s\n", RSTRING_PTR(msg_inspected));

  return mrb_true_value();
}


//TODO
mrb_value cheese_cross(mrb_state* mrb, mrb_value self) {
  loop_data_s *loop_data = NULL;

  //TODO fprintf(stderr, "CHEESE_CROSS flip_pointer process_stacks! on the fps timer\n");

  mrb_value data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@flip_pointer"));

  Data_Get_Struct(mrb, data_value, &crisscross_data_type, loop_data);
  if (!loop_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @flip_pointer");
  }


/*
  //TODO

  //TODO.... pass

  //printf("wtf22222\n");
  //this block is called in a fast loop

  if (mrb->exc) {
    mrb_print_error_XXX(mrb);
  }

  if (loop_data->mrb_pointer->exc) {
    fprintf(stderr, "Exception in SERVER_SIDE_TRY_CRISS_CROSS_PROCESS_STACKS!\n");
    mrb_print_error_XXX(loop_data->mrb_pointer);

          //mrb_print_error(loop_data->mrb_pointer);
          //mrb_print_backtrace(loop_data->mrb_pointer);

          ////mrb_value mesg = mrb_exc_inspect(mrb, mrb_obj_value(mrb->exc));
          mrb_value mesg = mrb_funcall(loop_data->mrb_pointer, mrb_obj_value(loop_data->mrb_pointer->exc), "inspect", 0);
          editorSetStatusMessage(RSTRING_PTR(mesg));

    //TODO: exit runtime, unhandled exception
    //CloseSurface();
    //CloseWindow();
    //return mrb_false_value();
  }
*/

  mrb_value wiz_return_halt = mrb_nil_value();

    //TODO: !!!! wiz_return_halt = mrb_funcall(loop_data->mrb_pointer, mrb_obj_value(loop_data->self_pointer), "process_stacks!", 0, 0);

  struct mrb_jmpbuf *prev_jmp = loop_data->mrb_pointer->jmp;
  struct mrb_jmpbuf c_jmp;
  int err = 1;

  MRB_TRY(&c_jmp) {
    loop_data->mrb_pointer->jmp = &c_jmp;

    //body(loop_data->mrb_pointer, opaque);

    wiz_return_halt = mrb_funcall(loop_data->mrb_pointer, mrb_obj_value(loop_data->self_pointer), "process_stacks!", 0, 0);

    //mrb_value wiz_return_halt2 = mrb_funcall(loop_data->mrb_pointer, mrb_obj_value(loop_data->self_pointer), "fiberz", 0, 0);

    err = 0;
  } MRB_CATCH(&c_jmp) {
    if (loop_data->mrb_pointer->exc) {

      //mrb_print_error(mrb);
    fprintf(stderr, "Exception in SERVER_SIDE_TRY_CRISS_CROSS_PROCESS_STACKS!\n");
    mrb_print_error_XXX(loop_data->mrb_pointer);

      loop_data->mrb_pointer->exc = NULL;
    }
    else {
      //TODO
    }
  } MRB_END_EXC(&c_jmp);

  loop_data->mrb_pointer->jmp = prev_jmp;


  //if (loop_data->mrb_pointer->exc) {
  //  fprintf(stderr, "Exception in SERVER_SIDE_TRY_CRISS_CROSS_PROCESS_STACKS_FIBERZ!\n");
  //  mrb_print_error_XXX(loop_data->mrb_pointer);

  //        //mrb_print_error(loop_data->mrb_pointer);
  //        //mrb_print_backtrace(loop_data->mrb_pointer);

  //        ////mrb_value mesg = mrb_exc_inspect(mrb, mrb_obj_value(mrb->exc));
  //        mrb_value mesg = mrb_funcall(loop_data->mrb_pointer, mrb_obj_value(loop_data->mrb_pointer->exc), "inspect", 0);
  //        editorSetStatusMessage(RSTRING_PTR(mesg));

  //  //TODO: exit runtime, unhandled exception
  //  //CloseSurface();
  //  //CloseWindow();
  //  //return mrb_false_value();
  //}


  return wiz_return_halt;
  //return mrb_nil_value();
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
size_t handle_js_websocket_event(mrb_state* mrb, struct RObject* selfP, char* buf, size_t n) {
  mrb_value empty_string = mrb_str_new_lit(mrb, "");
  mrb_value clikestr_as_string = mrb_str_cat(mrb, empty_string, buf, n);

  mrb_funcall(mrb, mrb_obj_value(selfP), "dispatch_next_events", 1, clikestr_as_string);
  return 0;
}


char last_typed = 0;


EMSCRIPTEN_KEEPALIVE
size_t pack_outbound_tty(mrb_state* mrb, struct RObject* selfP, char *buf) {

  //TODO: do other stuff with this websocket bit
  //......... pipe remote process shell through???????? !!!!!

  //int i = 0;
  //int n = strlen(buf);

  //if (n == 0) {
  //  return 0;
  //}

  //mrb_value data_value;
  //data_value = mrb_iv_get(mrb, mrb_obj_value(selfP), mrb_intern_lit(mrb, "@client"));
  //mrb_int fp = mrb_int(mrb, data_value);

  //void (*write_packed_pointer)(int, const void*, int) = (void (*)(int, const void*, int))fp;

  ////fprintf(stderr, "FOOOO %ld %ld\n", n, buf[0]);
  ////write_packed_pointer(0, buf, strlen(buf));

  //struct abuf *ab2 = malloc(sizeof(struct abuf));
  //ab2->b = NULL;
  //ab2->len = 0;

  //if ((n > 2) && (buf[1] == 'O' || buf[1] == '[')) {
  //  int bbb = 0;
  //  buf = (buf + 1); // ... YEAaahahAHAa + sunglasses + explosion

  //  //DEL OVERIDE 1008 [ 3 ~
  //  if (buf[0] == '[') { /* ESC [ sequences. */
  //    if (buf[1] >= '0' && buf[1] <= '9') {
  //      if (buf[2] == '~') { /* Extended escape, read additional byte. */
  //        switch(buf[1]) {
  //          case '3': bbb = DEL_KEY; break;
  //          case '5': bbb = PAGE_UP; break;
  //          case '6': bbb = PAGE_DOWN; break;
  //        }
  //      }
  //    } else {
  //      switch(buf[1]) {
  //        case 'A': bbb = ARROW_UP; break;
  //        case 'B': bbb = ARROW_DOWN; break;
  //        case 'C': bbb = ARROW_RIGHT; break;
  //        case 'D': bbb = ARROW_LEFT; break;
  //        case 'H': bbb = HOME_KEY; break;
  //        case 'F': bbb = END_KEY; break;
  //      }
  //    }
  //  } else if (buf[0] == 'O') { /* ESC O sequences. */
  //    switch(buf[1]) {
  //      case 'H': bbb = HOME_KEY; break;
  //      case 'F': bbb = END_KEY; break;
  //    }
  //  }

  //  if (bbb) {
  //    editorProcessKeypress(bbb);
  //  } else {
  //    fprintf(stderr, "WTF %d\n", buf[0]);
  //  }
  //} else {
  //  if (
  //    buf[0] == 12 ||
  //    buf[0] == 13 ||
  //    buf[0] == 19 ||
  //    buf[0] > 31) {
	//		for (int i=0; i<n; i++) {
	//			editorProcessKeypress(buf[i]);
	//		}
  //  } else if (
  //    buf[0] == 24
  //  ) {

  //    ////////////
  //    //run Wkndrfile
  //    mrb_value empty_string = mrb_str_new_lit(mrb, "");

  //    int codelen;
  //    char *codebuf = editorRowsToString(&codelen);

  //    mrb_value clikestr_as_string = mrb_str_cat(mrb, empty_string, codebuf, codelen);
  //    mrb_value editr_eval = mrb_funcall(mrb, mrb_obj_value(mrb_class_get(mrb, "Wkndr")), "wkndr_client_eval", 1, clikestr_as_string);

  //    if (mrb->exc) {
  //      //mrb_print_error(mrb_client);
  //      //mrb_print_backtrace(mrb_client);
  //      //mrb_value mesg = mrb_exc_inspect(mrb, mrb_obj_value(mrb->exc));
  //      //mrb_value mesg = mrb_funcall(mrb, mrb_obj_value(mrb->exc), "inspect", 0);
  //      //editorSetStatusMessage(RSTRING_PTR(mesg));
  //      //"XXX %.*s\n", (int)RSTRING_LEN(mesg), RSTRING_PTR(mesg));
  //    } else {
  //      if (!mrb_nil_p(editr_eval)) {
  //        mrb_value rezstr = mrb_funcall(mrb, editr_eval, "to_s", 0);

  //        const char *foo = mrb_string_value_ptr(mrb, rezstr);
  //        int len = mrb_string_value_len(mrb, rezstr);
  //        editorSetStatusMessage(foo, len);
  //      }
  //    }
  //  }
  //}

  ////mrb_sym sym = mrb_intern_lit(mrb, "$cheese");
  ////mrb_value varff = mrb_gv_get(mrb, sym);
  ////const char *foofff = mrb_string_value_ptr(mrb, varff);
  ////int lenfff = mrb_string_value_len(mrb, varff);
  ////editorSetStatusMessage(foofff, lenfff);

  ////editorRefreshScreen(ab2);

  ////Image fooBuf = terminalRender(ab2->b, ab2->len);
  ////Texture2D thisTerm = LoadTextureFromImage(fooBuf);

  ////DrawTexture(thisTerm, 0, 0, WHITE);

  ///////////This is the websocket back to render xtermjs!!! !!!! write_packed_pointer(0, ab2->b, ab2->len);

  //free(ab2);

  /////////This is the websocket back to !!!!! js !!!!!!! write_packed_pointer(0, ab2->b, ab2->len);

  return 0;
}


EMSCRIPTEN_KEEPALIVE
size_t resize_tty(mrb_state* mrb, struct RObject* selfP, int w, int h, int r, int c) {
  //TODO: this happens client-side... no ws needed

  //TODO support remove vt100 tty
  //  mrb_value outbound_resize_msg = mrb_ary_new(mrb);
  //  //mrb_ary_push(mrb, outbound_resize_msg, mrb_fixnum_value(cols));
  //  //mrb_ary_push(mrb, outbound_resize_msg, mrb_fixnum_value(rows));
  //  mrb_ary_push(mrb, outbound_resize_msg, mrb_fixnum_value(w));
  //  mrb_ary_push(mrb, outbound_resize_msg, mrb_fixnum_value(h));
  //  //TODO: determine if resize event made sense ....!!!!????
  //  //mrb_value outbound_msg = mrb_hash_new(mrb);
  //  //mrb_hash_set(mrb, outbound_msg, mrb_fixnum_value(3), outbound_resize_msg);
  //  //mrb_funcall(mrb, mrb_obj_value(selfP), "write_typed", 1, outbound_msg);

  //fprintf(stdout, "WTFRESIZETTY!!!!!\n")
  //fprintf(stdout, "WTFRESIZETTY!!!!!\n")
  //fprintf(stdout, "WTFRESIZETTY!!!!!\n")

  if (IsWindowReady()) {
    SetWindowSize(w, h);
  }

  updateWindowSize(r, c);

  mrb_value data_value;
  data_value = mrb_iv_get(mrb, mrb_obj_value(selfP), mrb_intern_lit(mrb, "@client"));

  if (mrb_nil_p(data_value)) {
  } else {
    mrb_int fp = mrb_int(mrb, data_value);
    void (*write_packed_pointer)(int, const void*, int) = (void (*)(int, const void*, int))fp;

    struct abuf *ab = malloc(sizeof(struct abuf) * 1);
    ab->b = NULL; //malloc(sizeof(char *) * 0);
    ab->len = 0;
    editorRefreshScreen(ab);
    write_packed_pointer(0, ab->b, ab->len);
    free(ab);
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
  long int start_connection_js_c = 0;

  //write_packed_pointer is created in js, as addFunction
#ifdef PLATFORM_WEB
  start_connection_js_c = EM_ASM_INT({
    return window.startConnection($0, $1);
  }, mrb, mrb_obj_ptr(self));
#endif

  mrb_iv_set(
      mrb, self, mrb_intern_lit(mrb, "@client"), // set @data
      mrb_fixnum_value(start_connection_js_c));

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

  //NOTE: this is sent to the JS for outbound on a websocket connect !!!
  write_packed_pointer(1, foo, len);

  return self;
}


void platform_bits_update_void(void* arg) {
  loop_data_s* loop_data = arg;

  mrb_state* mrb = loop_data->mrb_pointer;
  struct RObject* self = loop_data->self_pointer;
  mrb_value selfV = mrb_obj_value(self);

  fprintf(stderr, "void platform_bits_update_void\n");

  platform_bits_signal(mrb, selfV);
}


mrb_value global_show(mrb_state* mrb, mrb_value self) {
  mrb_value stack_self;

  mrb_get_args(mrb, "o", &stack_self);

  loop_data_s* loop_data = (loop_data_s*)malloc(sizeof(loop_data_s));

  loop_data->mrb_pointer = mrb;
  loop_data->self_pointer = mrb_obj_ptr(stack_self);

#ifdef PLATFORM_WEB

  emscripten_set_main_loop_arg(platform_bits_update_void, loop_data, 0, 1);
  emscripten_set_main_loop_timing(EM_TIMING_RAF, 1);

#endif

  return self;
}


#include "gifsave89.h"
#include "glyph/glyph.h"
#include "glyph/ambiguous_half.h"
#include "glyph/ambiguous_wide.h"


enum {
	TERM_WIDTH  = 640,
	TERM_HEIGHT = 384,
	TERM_COLS   = 80,
	TERM_ROWS   = 24,
	INPUT_SIZE  = 1,
	MIN_DELAY   = 5,
};


enum char_code {
	/* 7 bit */
	BEL = 0x07, BS  = 0x08, HT  = 0x09,
	LF  = 0x0A, VT  = 0x0B, FF  = 0x0C,
	CR  = 0x0D, ESCT = 0x1B, DEL = 0x7F,
	/* others */
	SPACE     = 0x20,
	BACKSLASH = 0x5C,
};

enum misc {
	BUFSIZE           = 1024,    /* read, esc, various buffer size */
	BITS_PER_BYTE     = 8,
	BYTES_PER_PIXEL   = 3,       /* pixel size of sixel bitmap data */
	BITS_PER_SIXEL    = 6,       /* number of bits of a sixel */
	ESCSEQ_SIZE       = 1024,    /* limit size of terminal escape sequence */
	SELECT_TIMEOUT    = 15000,   /* used by select() */
	MAX_ARGS          = 16,      /* max parameters of csi/osc sequence */
	COLORS            = 256,     /* number of color */
	UCS2_CHARS        = 0x10000, /* number of UCS2 glyph */
	CTRL_CHARS        = 0x20,    /* number of ctrl_func */
	ESC_CHARS         = 0x80,    /* number of esc_func */
	DRCS_CHARSETS     = 63,      /* number of charset of DRCS (according to DRCSMMv1) */
	GLYPH_PER_CHARSET = 96,      /* number of glyph of each DRCS charset */
	DEFAULT_CHAR      = SPACE,   /* used for erase char */
	BRIGHT_INC        = 8,       /* value used for brightening color */
	OSC_GWREPT        = 8900,    /* OSC Ps: mode number of yaft GWREPT */
};

enum char_attr {
	ATTR_RESET     = 0,
	ATTR_BOLD      = 1, /* brighten foreground */
	ATTR_UNDERLINE = 4,
	ATTR_BLINK     = 5, /* brighten background */
	ATTR_REVERSE   = 7,
};

const uint8_t attr_mask[] = {
	0x00, 0x01, 0x00, 0x00, /* 0:none      1:bold  2:none 3:none */
	0x02, 0x04, 0x00, 0x08, /* 4:underline 5:blink 6:none 7:reverse */
};

const uint32_t bit_mask[] = {
	0x00,
	0x01,       0x03,       0x07,       0x0F,
	0x1F,       0x3F,       0x7F,       0xFF,
	0x1FF,      0x3FF,      0x7FF,      0xFFF,
	0x1FFF,     0x3FFF,     0x7FFF,     0xFFFF,
	0x1FFFF,    0x3FFFF,    0x7FFFF,    0xFFFFF,
	0x1FFFFF,   0x3FFFFF,   0x7FFFFF,   0xFFFFFF,
	0x1FFFFFF,  0x3FFFFFF,  0x7FFFFFF,  0xFFFFFFF,
	0x1FFFFFFF, 0x3FFFFFFF, 0x7FFFFFFF, 0xFFFFFFFF,
};

enum term_mode {
	MODE_RESET   = 0x00,
	MODE_ORIGIN  = 0x01, /* origin mode: DECOM */
	MODE_CURSOR  = 0x02, /* cursor visible: DECTCEM */
	MODE_AMRIGHT = 0x04, /* auto wrap: DECAWM */
};

enum esc_state {
	STATE_RESET  = 0x00,
	STATE_ESC    = 0x01, /* 0x1B, \033, ESC */
	STATE_CSI    = 0x02, /* ESC [ */
	STATE_OSC    = 0x04, /* ESC ] */
	STATE_DCS    = 0x08, /* ESC P */
};

enum glyph_width_t {
	NEXT_TO_WIDE = 0,
	HALF,
	WIDE,
};

struct margin { uint16_t top, bottom; };
struct point_t { uint16_t x, y; };
struct color_pair_t { uint8_t fg, bg; };

struct cell_t {
	const struct glyph_t *glyphp;   /* pointer to glyph */
	struct color_pair_t color_pair; /* color (fg, bg) */
	enum char_attr attribute;       /* bold, underscore, etc... */
	enum glyph_width_t width;       /* wide char flag: WIDE, NEXT_TO_WIDE, HALF */
	bool has_bitmap;
	/* must be statically allocated for copy_cell() */
	uint8_t bitmap[BYTES_PER_PIXEL * CELL_WIDTH * CELL_HEIGHT];
};

struct esc_t {
	char *buf;
	char *bp;
	int size;
	enum esc_state state;
};

struct charset_t {
	uint32_t code; /* UCS4 code point: yaft only prints UCS2 and DRCSMMv1 */
	int following_byte, count;
	bool is_valid;
};

struct state_t {   /* for save, restore state */
	struct point_t cursor;
	enum term_mode mode;
	enum char_attr attribute;
};

struct sixel_canvas_t {
	uint8_t *bitmap;
	struct point_t point;
	int width, height;
	int line_length;
	uint8_t color_index;
	uint32_t color_table[COLORS];
};

struct terminal {
	int fd;                                      /* master fd */
	int width, height;                           /* terminal size (pixel) */
	int cols, lines;                             /* terminal size (cell) */
	struct cell_t *cells;                        /* pointer to each cell: cells[cols + lines * num_of_cols] */
	struct margin scroll;                        /* scroll margin */
	struct point_t cursor;                       /* cursor pos (x, y) */
	bool *line_dirty;                            /* dirty flag */
	bool *tabstop;                               /* tabstop flag */
	enum term_mode mode;                         /* for set/reset mode */
	bool wrap_occured;                           /* whether auto wrap occured or not */
	struct state_t state;                        /* for restore */
	struct color_pair_t color_pair;              /* color (fg, bg) */
	enum char_attr attribute;                    /* bold, underscore, etc... */
	struct charset_t charset;                    /* store UTF-8 byte stream */
	struct esc_t esc;                            /* store escape sequence */
	uint32_t color_palette[COLORS];              /* 256 color palette */
	const struct glyph_t *glyph_map[UCS2_CHARS]; /* array of pointer to glyphs[] */
	struct glyph_t *drcs[DRCS_CHARSETS];         /* DRCS chars */
	struct sixel_canvas_t sixel;
};

struct parm_t { /* for parse_arg() */
	int argc;
	char *argv[MAX_ARGS];
};

int (*my_wcwidth)(uint32_t ucs);

struct pseudobuffer {
	uint8_t *buf;        /* copy of framebuffer */
	int width, height;   /* display resolution */
	int line_length;     /* line length (byte) */
	int bytes_per_pixel; /* BYTES per pixel */
};





/* See LICENSE for licence details. */
enum gif_option {
	GIF_REPEAT      = 1,
	GIF_DELAY       = 0,
	GIF_TRANSPARENT = 0,
	GIF_DISPOSAL    = 2,
};

enum cmap_bitfield {
	RED_SHIFT   = 5,
	GREEN_SHIFT = 2,
	BLUE_SHIFT  = 0,
	RED_MASK	= 3,
	GREEN_MASK  = 3,
	BLUE_MASK   = 2
};

struct gif_t {
	void *data;
	unsigned char *image;
	int colormap[COLORS * BYTES_PER_PIXEL + 1];
};

const uint32_t color_list[256] = {
	/* system color: 16 */
	0x000000, 0xAA0000, 0x00AA00, 0xAA5500, 0x0000AA, 0xAA00AA, 0x00AAAA, 0xAAAAAA/* 0xAAAAAA */,
	0x555555, 0xFF5555, 0x55FF55, 0xFFFF55, 0x5555FF, 0xFF55FF, 0x55FFFF, 0xDFDFDF/* 0xFFFFFF */,
	/* color cube: 216 */
	0x000000, 0x00005F, 0x000087, 0x0000AF, 0x0000D7, 0x0000FF, 0x005F00, 0x005F5F,
	0x005F87, 0x005FAF, 0x005FD7, 0x005FFF, 0x008700, 0x00875F, 0x008787, 0x0087AF,
	0x0087D7, 0x0087FF, 0x00AF00, 0x00AF5F, 0x00AF87, 0x00AFAF, 0x00AFD7, 0x00AFFF,
	0x00D700, 0x00D75F, 0x00D787, 0x00D7AF, 0x00D7D7, 0x00D7FF, 0x00FF00, 0x00FF5F,
	0x00FF87, 0x00FFAF, 0x00FFD7, 0x00FFFF, 0x5F0000, 0x5F005F, 0x5F0087, 0x5F00AF,
	0x5F00D7, 0x5F00FF, 0x5F5F00, 0x5F5F5F, 0x5F5F87, 0x5F5FAF, 0x5F5FD7, 0x5F5FFF,
	0x5F8700, 0x5F875F, 0x5F8787, 0x5F87AF, 0x5F87D7, 0x5F87FF, 0x5FAF00, 0x5FAF5F,
	0x5FAF87, 0x5FAFAF, 0x5FAFD7, 0x5FAFFF, 0x5FD700, 0x5FD75F, 0x5FD787, 0x5FD7AF,
	0x5FD7D7, 0x5FD7FF, 0x5FFF00, 0x5FFF5F, 0x5FFF87, 0x5FFFAF, 0x5FFFD7, 0x5FFFFF,
	0x870000, 0x87005F, 0x870087, 0x8700AF, 0x8700D7, 0x8700FF, 0x875F00, 0x875F5F,
	0x875F87, 0x875FAF, 0x875FD7, 0x875FFF, 0x878700, 0x87875F, 0x878787, 0x8787AF,
	0x8787D7, 0x8787FF, 0x87AF00, 0x87AF5F, 0x87AF87, 0x87AFAF, 0x87AFD7, 0x87AFFF,
	0x87D700, 0x87D75F, 0x87D787, 0x87D7AF, 0x87D7D7, 0x87D7FF, 0x87FF00, 0x87FF5F,
	0x87FF87, 0x87FFAF, 0x87FFD7, 0x87FFFF, 0xAF0000, 0xAF005F, 0xAF0087, 0xAF00AF,
	0xAF00D7, 0xAF00FF, 0xAF5F00, 0xAF5F5F, 0xAF5F87, 0xAF5FAF, 0xAF5FD7, 0xAF5FFF,
	0xAF8700, 0xAF875F, 0xAF8787, 0xAF87AF, 0xAF87D7, 0xAF87FF, 0xAFAF00, 0xAFAF5F,
	0xAFAF87, 0xAFAFAF, 0xAFAFD7, 0xAFAFFF, 0xAFD700, 0xAFD75F, 0xAFD787, 0xAFD7AF,
	0xAFD7D7, 0xAFD7FF, 0xAFFF00, 0xAFFF5F, 0xAFFF87, 0xAFFFAF, 0xAFFFD7, 0xAFFFFF,
	0xD70000, 0xD7005F, 0xD70087, 0xD700AF, 0xD700D7, 0xD700FF, 0xD75F00, 0xD75F5F,
	0xD75F87, 0xD75FAF, 0xD75FD7, 0xD75FFF, 0xD78700, 0xD7875F, 0xD78787, 0xD787AF,
	0xD787D7, 0xD787FF, 0xD7AF00, 0xD7AF5F, 0xD7AF87, 0xD7AFAF, 0xD7AFD7, 0xD7AFFF,
	0xD7D700, 0xD7D75F, 0xD7D787, 0xD7D7AF, 0xD7D7D7, 0xD7D7FF, 0xD7FF00, 0xD7FF5F,
	0xD7FF87, 0xD7FFAF, 0xD7FFD7, 0xD7FFFF, 0xFF0000, 0xFF005F, 0xFF0087, 0xFF00AF,
	0xFF00D7, 0xFF00FF, 0xFF5F00, 0xFF5F5F, 0xFF5F87, 0xFF5FAF, 0xFF5FD7, 0xFF5FFF,
	0xFF8700, 0xFF875F, 0xFF8787, 0xFF87AF, 0xFF87D7, 0xFF87FF, 0xFFAF00, 0xFFAF5F,
	0xFFAF87, 0xFFAFAF, 0xFFAFD7, 0xFFAFFF, 0xFFD700, 0xFFD75F, 0xFFD787, 0xFFD7AF,
	0xFFD7D7, 0xFFD7FF, 0xFFFF00, 0xFFFF5F, 0xFFFF87, 0xFFFFAF, 0xFFFFD7, 0xFFFFFF,
	/* gray scale: 24 */
	0x080808, 0x121212, 0x1C1C1C, 0x262626, 0x303030, 0x3A3A3A, 0x444444, 0x4E4E4E,
	0x585858, 0x626262, 0x6C6C6C, 0x767676, 0x808080, 0x8A8A8A, 0x949494, 0x9E9E9E,
	0xA8A8A8, 0xB2B2B2, 0xBCBCBC, 0xC6C6C6, 0xD0D0D0, 0xDADADA, 0xE4E4E4, 0xEEEEEE,
};

void error(char *str)
{
	//perror(str);
	exit(EXIT_FAILURE);
}

void fatal(char *str)
{
	fprintf(stderr, "%s\n", str);
	exit(EXIT_FAILURE);
}

void *erealloc(void *ptr, size_t size)
{
	void *new;
	errno = 0;

	if ((new = realloc(ptr, size)) == NULL)
		error("realloc");

	return new;
}

void *ecalloc(size_t nmemb, size_t size)
{
	void *ptr;
	errno = 0;

	if ((ptr = calloc(nmemb, size)) == NULL)
		error("calloc");

	return ptr;
}

void ewrite(int fd, const void *buf, int size)
{
	int ret;
	errno = 0;

	if ((ret = write(fd, buf, size)) < 0)
		error("write");
	else if (ret < size)
		ewrite(fd, (char *) buf + ret, size - ret);
}


long estrtol(const char *nptr, char **endptr, int base)
{
	long int ret;
	errno = 0;

	ret = strtol(nptr, endptr, base);
	if (ret == LONG_MIN || ret == LONG_MAX) {
		perror("strtol");
		return 0;
	}

	return ret;
}

int dec2num(char *str)
{
	if (str == NULL)
		return 0;

	return estrtol(str, NULL, 10);
}

/* See LICENSE for licence details. */
/* misc */
int sum(struct parm_t *parm)
{
	int i, sum = 0;

	for (i = 0; i < parm->argc; i++)
		sum += dec2num(parm->argv[i]);

	return sum;
}

/* See LICENSE for licence details. */
void erase_cell(struct terminal *term, int y, int x)
{
	struct cell_t *cellp;

	cellp             = &term->cells[x + y * term->cols];
	cellp->glyphp     = term->glyph_map[DEFAULT_CHAR];
	cellp->color_pair = term->color_pair; /* bce */
	cellp->attribute  = ATTR_RESET;
	cellp->width      = HALF;
	cellp->has_bitmap = false;

	term->line_dirty[y] = true;
}

void scroll(struct terminal *term, int from, int to, int offset)
{
	int i, j, size, abs_offset;
	struct cell_t *dst, *src;

	if (offset == 0 || from >= to)
		return;

	if (DEBUG)
		fprintf(stderr, "scroll from:%d to:%d offset:%d\n", from, to, offset);

	for (i = from; i <= to; i++)
		term->line_dirty[i] = true;

	abs_offset = abs(offset);
	size = sizeof(struct cell_t) * ((to - from + 1) - abs_offset) * term->cols;

	dst = term->cells + from * term->cols;
	src = term->cells + (from + abs_offset) * term->cols;

	if (offset > 0) {
		memmove(dst, src, size);
		for (i = (to - offset + 1); i <= to; i++)
			for (j = 0; j < term->cols; j++)
				erase_cell(term, i, j);
	}
	else {
		memmove(src, dst, size);
		for (i = from; i < from + abs_offset; i++)
			for (j = 0; j < term->cols; j++)
				erase_cell(term, i, j);
	}
}


/* relative movement: cause scrolling */
void move_cursor(struct terminal *term, int y_offset, int x_offset)
{
	int x, y, top, bottom;

	x = term->cursor.x + x_offset;
	y = term->cursor.y + y_offset;

	top = term->scroll.top;
	bottom = term->scroll.bottom;

	if (x < 0)
		x = 0;
	else if (x >= term->cols) {
		if (term->mode & MODE_AMRIGHT)
			term->wrap_occured = true;
		x = term->cols - 1;
	}
	term->cursor.x = x;

	y = (y < 0) ? 0:
		(y >= term->lines) ? term->lines - 1: y;

	if (term->cursor.y == top && y_offset < 0) {
		y = top;
		scroll(term, top, bottom, y_offset);
	}
	else if (term->cursor.y == bottom && y_offset > 0) {
		y = bottom;
		scroll(term, top, bottom, y_offset);
	}
	term->cursor.y = y;
}

/* absolute movement: never scroll */
void set_cursor(struct terminal *term, int y, int x)
{
	int top, bottom;

	if (term->mode & MODE_ORIGIN) {
		top = term->scroll.top;
		bottom = term->scroll.bottom;
		y += term->scroll.top;
	}
	else {
		top = 0;
		bottom = term->lines - 1;
	}

	x = (x < 0) ? 0: (x >= term->cols) ? term->cols - 1: x;
	y = (y < top) ? top: (y > bottom) ? bottom: y;

	term->cursor.x = x;
	term->cursor.y = y;
	term->wrap_occured = false;
}

const struct glyph_t *drcsch(struct terminal *term, uint32_t code)
{
	/* DRCSMMv1
		ESC ( SP <\xXX> <\xYY> ESC ( B
		<===> U+10XXYY ( 0x40 <= 0xXX <=0x7E, 0x20 <= 0xYY <= 0x7F )
	*/
	int ku, ten;

	ku  = (0xFF00 & code) >> 8;
	ten = 0xFF & code;

	if (DEBUG)
		fprintf(stderr, "drcs ku:0x%.2X ten:0x%.2X\n", ku, ten);

	if ((0x40 <= ku && ku <= 0x7E)
		&& (0x20 <= ten && ten <= 0x7F)
		&& (term->drcs[ku - 0x40] != NULL))
		return &term->drcs[ku - 0x40][ten - 0x20]; /* sub each offset */
	else {
		if (DEBUG)
			fprintf(stderr, "drcs char not found\n");
		return term->glyph_map[SUBSTITUTE_HALF];
	}
}


/* function for control character */
void bs(struct terminal *term)
{
	move_cursor(term, 0, -1);
}

void tab(struct terminal *term)
{
	int i;

	for (i = term->cursor.x + 1; i < term->cols; i++) {
		if (term->tabstop[i]) {
			set_cursor(term, term->cursor.y, i);
			return;
		}
	}
	set_cursor(term, term->cursor.y, term->cols - 1);
}

void nl(struct terminal *term)
{
	move_cursor(term, 1, 0);
}

void cr(struct terminal *term)
{
	set_cursor(term, term->cursor.y, 0);
}

void enter_esc(struct terminal *term)
{
	term->esc.state = STATE_ESC;
}

/* function for escape sequence */
void save_state(struct terminal *term)
{
	term->state.mode = term->mode & MODE_ORIGIN;
	term->state.cursor = term->cursor;
	term->state.attribute = term->attribute;
}

void restore_state(struct terminal *term)
{
	/* restore state */
	if (term->state.mode & MODE_ORIGIN)
		term->mode |= MODE_ORIGIN;
	else
		term->mode &= ~MODE_ORIGIN;
	term->cursor    = term->state.cursor;
	term->attribute = term->state.attribute;
}

void crnl(struct terminal *term)
{
	cr(term);
	nl(term);
}

void set_tabstop(struct terminal *term)
{
	term->tabstop[term->cursor.x] = true;
}

void reverse_nl(struct terminal *term)
{
	move_cursor(term, -1, 0);
}

void identify(struct terminal *term)
{
	ewrite(term->fd, "\033[?6c", 5); /* "I am a VT102" */
}

void enter_csi(struct terminal *term)
{
	term->esc.state = STATE_CSI;
}

void enter_osc(struct terminal *term)
{
	term->esc.state = STATE_OSC;
}

void enter_dcs(struct terminal *term)
{
	term->esc.state = STATE_DCS;
}

void reset_esc(struct terminal *term)
{
	if (DEBUG)
		fprintf(stderr, "*esc reset*\n");

	term->esc.bp = term->esc.buf;
	term->esc.state = STATE_RESET;
}

void reset_charset(struct terminal *term)
{
	term->charset.code = term->charset.count = term->charset.following_byte = 0;
	term->charset.is_valid = true;
}


void reset(struct terminal *term)
{
	int i, j;

	term->mode = MODE_RESET;
	term->mode |= (MODE_CURSOR | MODE_AMRIGHT);
	term->wrap_occured = false;

	term->scroll.top = 0;
	term->scroll.bottom = term->lines - 1;

	term->cursor.x = term->cursor.y = 0;

	term->state.mode = term->mode;
	term->state.cursor = term->cursor;
	term->state.attribute = ATTR_RESET;

	term->color_pair.fg = DEFAULT_FG;
	term->color_pair.bg = DEFAULT_BG;

	term->attribute = ATTR_RESET;

	for (i = 0; i < term->lines; i++) {
		for (j = 0; j < term->cols; j++) {
			erase_cell(term, i, j);
			if ((j % TABSTOP) == 0)
				term->tabstop[j] = true;
			else
				term->tabstop[j] = false;
		}
		term->line_dirty[i] = true;
	}

	reset_esc(term);
	reset_charset(term);
}


void ris(struct terminal *term)
{
	reset(term);
}

void copy_cell(struct terminal *term, int dst_y, int dst_x, int src_y, int src_x)
{
	struct cell_t *dst, *src;

	dst = &term->cells[dst_x + dst_y * term->cols];
	src = &term->cells[src_x + src_y * term->cols];

	if (src->width == NEXT_TO_WIDE)
		return;
	else if (src->width == WIDE && dst_x == (term->cols - 1))
		erase_cell(term, dst_y, dst_x);
	else {
		*dst = *src;
		if (src->width == WIDE) {
			*(dst + 1) = *src;
			(dst + 1)->width = NEXT_TO_WIDE;
		}
		term->line_dirty[dst_y] = true;
	}
}

/* function for csi sequence */
void insert_blank(struct terminal *term, struct parm_t *parm)
{
	int i, num = sum(parm);

	if (num <= 0)
		num = 1;

	for (i = term->cols - 1; term->cursor.x <= i; i--) {
		if (term->cursor.x <= (i - num))
			copy_cell(term, term->cursor.y, i, term->cursor.y, i - num);
		else
			erase_cell(term, term->cursor.y, i);
	}
}

void curs_up(struct terminal *term, struct parm_t *parm)
{
	int num = sum(parm);

	if (num <= 0)
		num = 1;
	move_cursor(term, -num, 0);
}

void curs_down(struct terminal *term, struct parm_t *parm)
{
	int num = sum(parm);

	if (num <= 0)
		num = 1;
	move_cursor(term, num, 0);
}

void curs_forward(struct terminal *term, struct parm_t *parm)
{
	int num = sum(parm);

	if (num <= 0)
		num = 1;
	move_cursor(term, 0, num);
}

void curs_back(struct terminal *term, struct parm_t *parm)
{
	int num = sum(parm);

	if (num <= 0)
		num = 1;
	move_cursor(term, 0, -num);
}

void curs_nl(struct terminal *term, struct parm_t *parm)
{
	int num = sum(parm);

	if (num <= 0)
		num = 1;
	move_cursor(term, num, 0);
	cr(term);
}

void curs_pl(struct terminal *term, struct parm_t *parm)
{
	int num = sum(parm);

	if (num <= 0)
		num = 1;
	move_cursor(term, -num, 0);
	cr(term);
}

void curs_col(struct terminal *term, struct parm_t *parm)
{
	int num, last = parm->argc - 1;

	if (parm->argc <= 0)
		num = 0;
	else
		num = dec2num(parm->argv[last]) - 1;

	set_cursor(term, term->cursor.y, num);
}

void curs_pos(struct terminal *term, struct parm_t *parm)
{
	int line, col;

	if (parm->argc <= 0) {
		set_cursor(term, 0, 0);
		return;
	}

	if (parm->argc != 2)
		return;

	line = dec2num(parm->argv[0]) - 1;
	col  = dec2num(parm->argv[1]) - 1;
	set_cursor(term, line, col);
}

void erase_display(struct terminal *term, struct parm_t *parm)
{
	int i, j, mode, last = parm->argc - 1;

	mode = (parm->argc == 0) ? 0: dec2num(parm->argv[last]);

	if (mode < 0 || 2 < mode)
		return;

	if (mode == 0) {
		for (i = term->cursor.y; i < term->lines; i++)
			for (j = 0; j < term->cols; j++)
				if (i > term->cursor.y || (i == term->cursor.y && j >= term->cursor.x))
					erase_cell(term, i, j);
	}
	else if (mode == 1) {
		for (i = 0; i <= term->cursor.y; i++)
			for (j = 0; j < term->cols; j++)
				if (i < term->cursor.y || (i == term->cursor.y && j <= term->cursor.x))
					erase_cell(term, i, j);
	}
	else if (mode == 2) {
		for (i = 0; i < term->lines; i++)
			for (j = 0; j < term->cols; j++)
				erase_cell(term, i, j);
	}
}

void erase_line(struct terminal *term, struct parm_t *parm)
{
	int i, mode, last = parm->argc - 1;

	mode = (parm->argc == 0) ? 0: dec2num(parm->argv[last]);

	if (mode < 0 || 2 < mode)
		return;

	if (mode == 0) {
		for (i = term->cursor.x; i < term->cols; i++)
			erase_cell(term, term->cursor.y, i);
	}
	else if (mode == 1) {
		for (i = 0; i <= term->cursor.x; i++)
			erase_cell(term, term->cursor.y, i);
	}
	else if (mode == 2) {
		for (i = 0; i < term->cols; i++)
			erase_cell(term, term->cursor.y, i);
	}
}


void insert_line(struct terminal *term, struct parm_t *parm)
{
	int num = sum(parm);

	if (term->mode & MODE_ORIGIN) {
		if (term->cursor.y < term->scroll.top
			|| term->cursor.y > term->scroll.bottom)
			return;
	}

	num = (num <= 0) ? 1 : num;
	scroll(term, term->cursor.y, term->scroll.bottom, -num);
}

void delete_line(struct terminal *term, struct parm_t *parm)
{
	int num = sum(parm);

	if (term->mode & MODE_ORIGIN) {
		if (term->cursor.y < term->scroll.top
			|| term->cursor.y > term->scroll.bottom)
			return;
	}

	num = (num <= 0) ? 1 : num;
	scroll(term, term->cursor.y, term->scroll.bottom, num);
}

void delete_char(struct terminal *term, struct parm_t *parm)
{
	int i, num = sum(parm);

	num = (num <= 0) ? 1 : num;

	for (i = term->cursor.x; i < term->cols; i++) {
		if ((i + num) < term->cols)
			copy_cell(term, term->cursor.y, i, term->cursor.y, i + num);
		else
			erase_cell(term, term->cursor.y, i);
	}
}

void erase_char(struct terminal *term, struct parm_t *parm)
{
	int i, num = sum(parm);

	if (num <= 0)
		num = 1;
	else if (num + term->cursor.x > term->cols)
		num = term->cols - term->cursor.x;

	for (i = term->cursor.x; i < term->cursor.x + num; i++)
		erase_cell(term, term->cursor.y, i);
}

void curs_line(struct terminal *term, struct parm_t *parm)
{
	int num, last = parm->argc - 1;

	if (parm->argc == 0)
		num = 0;
	else
		num = dec2num(parm->argv[last]) - 1;

	set_cursor(term, num, term->cursor.x);
}

void set_attr(struct terminal *term, struct parm_t *parm)
{
	int i, num;

	if (parm->argc == 0) {
		term->attribute = ATTR_RESET;
		term->color_pair.fg = DEFAULT_FG;
		term->color_pair.bg = DEFAULT_BG;
		return;
	}

	for (i = 0; i < parm->argc; i++) {
		num = dec2num(parm->argv[i]);

		if (num == 0) {                    /* reset all attribute and color */
			term->attribute = ATTR_RESET;
			term->color_pair.fg = DEFAULT_FG;
			term->color_pair.bg = DEFAULT_BG;
		}
		else if (1 <= num && num <= 7)     /* set attribute */
			term->attribute |= attr_mask[num];
		else if (21 <= num && num <= 27)   /* reset attribute */
			term->attribute &= ~attr_mask[num - 20];
		else if (30 <= num && num <= 37)   /* set foreground */
			term->color_pair.fg = (num - 30);
		else if (num == 38) {              /* set 256 color to foreground */
			if ((i + 2) < parm->argc && dec2num(parm->argv[i + 1]) == 5) {
				term->color_pair.fg = dec2num(parm->argv[i + 2]);
				i += 2;
			}
		}
		else if (num == 39)                /* reset foreground */
			term->color_pair.fg = DEFAULT_FG;
		else if (40 <= num && num <= 47)   /* set background */
			term->color_pair.bg = (num - 40);
		else if (num == 48) {              /* set 256 color to background */
			if ((i + 2) < parm->argc && dec2num(parm->argv[i + 1]) == 5) {
				term->color_pair.bg = dec2num(parm->argv[i + 2]);
				i += 2;
			}
		}
		else if (num == 49)                /* reset background */
			term->color_pair.bg = DEFAULT_BG;
		else if (90 <= num && num <= 97)   /* set bright foreground */
			term->color_pair.fg = (num - 90) + BRIGHT_INC;
		else if (100 <= num && num <= 107) /* set bright background */
			term->color_pair.bg = (num - 100) + BRIGHT_INC;
	}
}

void status_report(struct terminal *term, struct parm_t *parm)
{
	int i, num;
	char buf[BUFSIZE];

	for (i = 0; i < parm->argc; i++) {
		num = dec2num(parm->argv[i]);
		if (num == 5)        /* terminal response: ready */
			ewrite(term->fd, "\033[0n", 4);
		else if (num == 6) { /* cursor position report */
			snprintf(buf, BUFSIZE, "\033[%d;%dR", term->cursor.y + 1, term->cursor.x + 1);
			ewrite(term->fd, buf, strlen(buf));
		}
		else if (num == 15)  /* terminal response: printer not connected */
			ewrite(term->fd, "\033[?13n", 6);
	}
}

void set_mode(struct terminal *term, struct parm_t *parm)
{
	int i, mode;

	for (i = 0; i < parm->argc; i++) {
		mode = dec2num(parm->argv[i]);
		if (*(term->esc.buf + 1) != '?')
			continue; /* not supported */

		if (mode == 6) { /* private mode */
			term->mode |= MODE_ORIGIN;
			set_cursor(term, 0, 0);
		}
		else if (mode == 7)
			term->mode |= MODE_AMRIGHT;
		else if (mode == 25)
			term->mode |= MODE_CURSOR;
	}

}

void reset_mode(struct terminal *term, struct parm_t *parm)
{
	int i, mode;

	for (i = 0; i < parm->argc; i++) {
		mode = dec2num(parm->argv[i]);
		if (*(term->esc.buf + 1) != '?')
			continue; /* not supported */

		if (mode == 6) { /* private mode */
			term->mode &= ~MODE_ORIGIN;
			set_cursor(term, 0, 0);
		}
		else if (mode == 7) {
			term->mode &= ~MODE_AMRIGHT;
			term->wrap_occured = false;
		}
		else if (mode == 25)
			term->mode &= ~MODE_CURSOR;
	}

}

void set_margin(struct terminal *term, struct parm_t *parm)
{
	int top, bottom;

	if (parm->argc != 2)
		return;

	top    = dec2num(parm->argv[0]) - 1;
	bottom = dec2num(parm->argv[1]) - 1;

	if (top >= bottom)
		return;

	top = (top < 0) ? 0 : (top >= term->lines) ? term->lines - 1 : top;

	bottom = (bottom < 0) ? 0 :
		(bottom >= term->lines) ? term->lines - 1 : bottom;

	term->scroll.top = top;
	term->scroll.bottom = bottom;

	set_cursor(term, 0, 0); /* move cursor to home */
}

void clear_tabstop(struct terminal *term, struct parm_t *parm)
{
	int i, j, num;

	if (parm->argc == 0)
		term->tabstop[term->cursor.x] = false;
	else {
		for (i = 0; i < parm->argc; i++) {
			num = dec2num(parm->argv[i]);
			if (num == 0)
				term->tabstop[term->cursor.x] = false;
			else if (num == 3) {
				for (j = 0; j < term->cols; j++)
					term->tabstop[j] = false;
				return;
			}
		}
	}
}

/* See LICENSE for licence details. */
void (*ctrl_func[CTRL_CHARS])(struct terminal *term) = {
	[BS]  = bs,
	[HT]  = tab,
	[LF]  = nl,
	[VT]  = nl,
	[FF]  = nl,
	[CR]  = cr,
	[ESC] = enter_esc,
};

void (*esc_func[ESC_CHARS])(struct terminal *term) = {
	['7'] = save_state,
	['8'] = restore_state,
	['D'] = nl,
	['E'] = crnl,
	['H'] = set_tabstop,
	['M'] = reverse_nl,
	['P'] = enter_dcs,
	['Z'] = identify,
	['['] = enter_csi,
	[']'] = enter_osc,
	['c'] = ris,
};

void (*csi_func[ESC_CHARS])(struct terminal *term, struct parm_t *) = {
	['@'] = insert_blank,
	['A'] = curs_up,
	['B'] = curs_down,
	['C'] = curs_forward,
	['D'] = curs_back,
	['E'] = curs_nl,
	['F'] = curs_pl,
	['G'] = curs_col,
	['H'] = curs_pos,
	['J'] = erase_display,
	['K'] = erase_line,
	['L'] = insert_line,
	['M'] = delete_line,
	['P'] = delete_char,
	['X'] = erase_char,
	['a'] = curs_forward,
	//['c'] = identify,
	['d'] = curs_line,
	['e'] = curs_down,
	['f'] = curs_pos,
	['g'] = clear_tabstop,
	['h'] = set_mode,
	['l'] = reset_mode,
	['m'] = set_attr,
	['n'] = status_report,
	['r'] = set_margin,
	//['s'] = save_state,
	//['u'] = restore_state,
	['`'] = curs_col,
};

/* ctr char/esc sequence/charset function */
void control_character(struct terminal *term, uint8_t ch)
{
	static const char *ctrl_char[] = {
		"NUL", "SOH", "STX", "ETX", "EOT", "ENQ", "ACK", "BEL",
		"BS ", "HT ", "LF ", "VT ", "FF ", "CR ", "SO ", "SI ",
		"DLE", "DC1", "DC2", "DC3", "DC4", "NAK", "SYN", "ETB",
		"CAN", "EM ", "SUB", "ESC", "FS ", "GS ", "RS ", "US ",
	};

	*term->esc.bp = '\0';

	if (DEBUG)
		fprintf(stderr, "ctl: %s\n", ctrl_char[ch]);

	if (ctrl_func[ch])
		ctrl_func[ch](term);
}

void esc_sequence(struct terminal *term, uint8_t ch)
{
	*term->esc.bp = '\0';

	if (DEBUG)
		fprintf(stderr, "esc: ESC %s\n", term->esc.buf);

	if (strlen(term->esc.buf) == 1 && esc_func[ch])
		esc_func[ch](term);

	/* not reset if csi/osc/dcs seqence */
	if (ch == '[' || ch == ']' || ch == 'P')
		return;

	reset_esc(term);
}




void reset_parm(struct parm_t *pt)
{
	int i;

	pt->argc = 0;
	for (i = 0; i < MAX_ARGS; i++)
		pt->argv[i] = NULL;
}

int hex2num(char *str)
{
	if (str == NULL)
		return 0;

	return estrtol(str, NULL, 16);
}



void add_parm(struct parm_t *pt, char *cp)
{
	if (pt->argc >= MAX_ARGS)
		return;

	if (DEBUG)
		fprintf(stderr, "argv[%d]: %s\n",
			pt->argc, (cp == NULL) ? "NULL": cp);

	pt->argv[pt->argc] = cp;
	pt->argc++;
}



void parse_arg(char *buf, struct parm_t *pt, int delim, int (is_valid)(int c))
{
	/*
		v..........v d           v.....v d v.....v ... d
		(valid char) (delimiter)
		argv[0]                  argv[1]   argv[2] ...   argv[argc - 1]
	*/
	size_t i, length;
	char *cp, *vp;

	if (buf == NULL)
		return;

	length = strlen(buf);
	if (DEBUG)
		fprintf(stderr, "parse_arg()\nlength:%u\n", (unsigned) length);

	vp = NULL;
	for (i = 0; i < length; i++) {
		cp = buf + i;

		if (vp == NULL && is_valid(*cp))
			vp = cp;

		if (*cp == delim) {
			*cp = '\0';
			add_parm(pt, vp);
			vp = NULL;
		}

		if (i == (length - 1) && (vp != NULL || *cp == '\0'))
			add_parm(pt, vp);
	}

	if (DEBUG)
		fprintf(stderr, "argc:%d\n", pt->argc);
}







/* See LICENSE for licence details. */
/* function for osc sequence */
int32_t parse_color1(char *seq)
{
	/*
	format
		rgb:r/g/b
		rgb:rr/gg/bb
		rgb:rrr/ggg/bbb
		rgb:rrrr/gggg/bbbb
	*/
	int i, length, value;
	int32_t color;
	uint32_t rgb[3];
	struct parm_t parm;

	reset_parm(&parm);
	parse_arg(seq, &parm, '/', isalnum);

	if (DEBUG)
		for (i = 0; i < parm.argc; i++)
			fprintf(stderr, "parm.argv[%d]: %s\n", i, parm.argv[i]);

	if (parm.argc != 3)
		return -1;

	length = strlen(parm.argv[0]);

	for (i = 0; i < 3; i++) {
		value = hex2num(parm.argv[i]);
		if (DEBUG)
			fprintf(stderr, "value:%d\n", value);

		if (length == 1)      /* r/g/b/ */
			rgb[i] = bit_mask[8] & (value * 0xFF / 0x0F);
		else if (length == 2) /* rr/gg/bb */
			rgb[i] = bit_mask[8] & value;
		else if (length == 3) /* rrr/ggg/bbb */
			rgb[i] = bit_mask[8] & (value * 0xFF / 0xFFF);
		else if (length == 4) /* rrrr/gggg/bbbb */
			rgb[i] = bit_mask[8] & (value * 0xFF / 0xFFFF);
		else
			return -1;
	}

	color = (rgb[0] << 16) + (rgb[1] << 8) + rgb[2];
	if (DEBUG)
		fprintf(stderr, "color:0x%.6X\n", color);

	return color;
}

int32_t parse_color2(char *seq)
{
	/*
	format
		#rgb
		#rrggbb
		#rrrgggbbb
		#rrrrggggbbbb
	*/
	int i, length;
	uint32_t rgb[3];
	int32_t color;
	char buf[BUFSIZE];

	length = strlen(seq);
	memset(buf, '\0', BUFSIZE);

	if (length == 3) {       /* rgb */
		for (i = 0; i < 3; i++) {
			strncpy(buf, seq + i, 1);
			rgb[i] = bit_mask[8] & hex2num(buf) * 0xFF / 0x0F;
		}
	}
	else if (length == 6) {  /* rrggbb */
		for (i = 0; i < 3; i++) { /* rrggbb */
			strncpy(buf, seq + i * 2, 2);
			rgb[i] = bit_mask[8] & hex2num(buf);
		}
	}
	else if (length == 9) {  /* rrrgggbbb */
		for (i = 0; i < 3; i++) {
			strncpy(buf, seq + i * 3, 3);
			rgb[i] = bit_mask[8] & hex2num(buf) * 0xFF / 0xFFF;
		}
	}
	else if (length == 12) { /* rrrrggggbbbb */
		for (i = 0; i < 3; i++) {
			strncpy(buf, seq + i * 4, 4);
			rgb[i] = bit_mask[8] & hex2num(buf) * 0xFF / 0xFFFF;
		}
	}
	else
		return -1;

	color = (rgb[0] << 16) + (rgb[1] << 8) + rgb[2];
	if (DEBUG)
		fprintf(stderr, "color:0x%.6X\n", color);

	return color;
}

void set_palette(struct terminal *term, void *arg)
{
	/*
	OSC Ps ; Pt ST
	ref: http://invisible-island.net/xterm/ctlseqs/ctlseqs.html
	ref: http://ttssh2.sourceforge.jp/manual/ja/about/ctrlseq.html#OSC

	only recognize change color palette:
		Ps: 4
		Pt: c ; spec
			c: color index (from 0 to 255)
			spec:
				rgb:r/g/b
				rgb:rr/gg/bb
				rgb:rrr/ggg/bbb
				rgb:rrrr/gggg/bbbb
				#rgb
				#rrggbb
				#rrrgggbbb
				#rrrrggggbbbb
					this rgb format is "RGB Device String Specification"
					see http://xjman.dsl.gr.jp/X11R6/X11/CH06.html
		Pt: c ; ?
			response rgb color
				OSC 4 ; c ; rgb:rr/gg/bb ST

	TODO: this function only works in 32bpp mode
	*/
	struct parm_t *pt = (struct parm_t *) arg;
	int i, argc = pt->argc, index;
	int32_t color;
	uint8_t rgb[3];
	char **argv = pt->argv;
	char buf[BUFSIZE];

	if (argc != 3)
		return;

	index = dec2num(argv[1]);
	if (index < 0 || index >= COLORS)
		return;

	if (strncmp(argv[2], "rgb:", 4) == 0) {
		if ((color = parse_color1(argv[2] + 4)) != -1) /* skip "rgb:" */
			term->color_palette[index] = (uint32_t) color;
	}
	else if (strncmp(argv[2], "#", 1) == 0) {
		if ((color = parse_color2(argv[2] + 1)) != -1) /* skip "#" */
			term->color_palette[index] = (uint32_t) color;
	}
	else if (strncmp(argv[2], "?", 1) == 0) {
		for (i = 0; i < 3; i++)
			rgb[i] = bit_mask[8] & (term->color_palette[index] >> (8 * (2 - i)));

		snprintf(buf, BUFSIZE, "\033]4;%d;rgb:%.2X/%.2X/%.2X\033\\",
			index, rgb[0], rgb[1], rgb[2]);
		ewrite(term->fd, buf, strlen(buf));
	}
}

void reset_palette(struct terminal *term, void *arg)
{
	/*
	reset color c
		OSC 104 ; c ST
			c: index of color
			ST: BEL or ESC \
	reset all color
		OSC 104 ST
			ST: BEL or ESC \

	terminfo: oc=\E]104\E\\
	*/
	struct parm_t *pt = (struct parm_t *) arg;
	int i, argc = pt->argc, c;
	char **argv = pt->argv;

	if (argc < 2) { /* reset all color palette */
		for (i = 0; i < COLORS; i++)
			term->color_palette[i] = color_list[i];
	}
	else if (argc == 2) { /* reset color_palette[c] */
		c = dec2num(argv[1]);
		if (0 <= c && c < COLORS)
			term->color_palette[c] = color_list[c];
	}
}

int isdigit_or_questionmark(int c)
{
	if (isdigit(c) || c == '?')
		return 1;
	else
		return 0;
}

void glyph_width_report(struct terminal *term, void *arg)
{
	/*
	glyph width report
		* request *
		OSC 8900 ; Ps ; Pw ; ? : Pf : Pt ST
			Ps: reserved
			Pw: width (0 or 1 or 2)
			Pfrom: beginning of unicode code point
			Pto: end of unicode code point
			ST: BEL(0x07) or ESC(0x1B) BACKSLASH(0x5C)
		* answer *
		OSC 8900 ; Ps ; Pv ; Pw ; Pf : Pt ; Pf : Pt ; ... ST
			Ps: responce code
				0: ok (default)
				1: recognized but not supported
				2: not recognized
			Pv: reserved (maybe East Asian Width Version)
			Pw: width (0 or 1 or 2)
			Pfrom: beginning of unicode code point
			Pto: end of unicode code point
			ST: BEL(0x07) or ESC(0x1B) BACKSLASH(0x5C)
	ref
		http://uobikiemukot.github.io/yaft/glyph_width_report.html
		https://gist.github.com/saitoha/8767268
	*/
	struct parm_t *pt = (struct parm_t *) arg, sub_parm;
	int i, argc = pt->argc, width, from, to, left, right, w, wcw; //reserved
	char **argv = pt->argv, buf[BUFSIZE];

	if (argc < 4)
		return;

	reset_parm(&sub_parm);
	parse_arg(argv[3], &sub_parm, ':', isdigit_or_questionmark);

	if (sub_parm.argc != 3 || *sub_parm.argv[0] != '?')
		return;

	//reserved = dec2num(argv[1]);
	width = dec2num(argv[2]);
	from = dec2num(sub_parm.argv[1]);
	to = dec2num(sub_parm.argv[2]);

	if ((from < 0 || to >= UCS2_CHARS) /* TODO: change here when implement DRCS */
		|| (width < 0 || width > 2))
		return;

	snprintf(buf, BUFSIZE, "\033]8900;0;0;%d;", width); /* OSC 8900 ; Ps; Pv ; Pw ; */
	ewrite(term->fd, buf, strlen(buf));

	left = right = -1;
	for (i = from; i <= to; i++) {
		wcw = my_wcwidth(i);
		if (wcw <= 0) /* zero width */
			w = 0;
		else if (term->glyph_map[i] == NULL) /* missing glyph */
			w = wcw;
		else
			w = term->glyph_map[i]->width;

		if (w != width) {
			if (right != -1) {
				snprintf(buf, BUFSIZE, "%d:%d;", left, right);
				ewrite(term->fd, buf, strlen(buf));
			}
			else if (left != -1) {
				snprintf(buf, BUFSIZE, "%d:%d;", left, left);
				ewrite(term->fd, buf, strlen(buf));
			}

			left = right = -1;
			continue;
		}

		if (left == -1)
			left = i;
		else
			right = i;
	}

	if (right != -1) {
		snprintf(buf, BUFSIZE, "%d:%d;", left, right);
		ewrite(term->fd, buf, strlen(buf));
	}
	else if (left != -1) {
		snprintf(buf, BUFSIZE, "%d:%d;", left, left);
		ewrite(term->fd, buf, strlen(buf));
	}

	ewrite(term->fd, "\033\\", 2); /* ST (ESC BACKSLASH) */
}


void csi_sequence(struct terminal *term, uint8_t ch)
{
	struct parm_t parm;

	*(term->esc.bp - 1) = '\0'; /* omit final character */

	if (DEBUG)
		fprintf(stderr, "csi: CSI %s\n", term->esc.buf + 1);

	reset_parm(&parm);
	parse_arg(term->esc.buf + 1, &parm, ';', isdigit); /* skip '[' */

	if (csi_func[ch])
		csi_func[ch](term, &parm);

	reset_esc(term);
}

int is_osc_parm(int c)
{
	if (isdigit(c) || isalpha(c) ||
		c == '?' || c == ':' || c == '/' || c == '#')
		return true;
	else
		return false;
}

void omit_string_terminator(char *bp, uint8_t ch)
{
	if (ch == BACKSLASH) /* ST: ESC BACKSLASH */
		*(bp - 2) = '\0';
	else                 /* ST: BEL */
		*(bp - 1) = '\0';
}

void osc_sequence(struct terminal *term, uint8_t ch)
{
	int osc_mode;
	struct parm_t parm;

	omit_string_terminator(term->esc.bp, ch);

	if (DEBUG)
		fprintf(stderr, "osc: OSC %s\n", term->esc.buf);

	reset_parm(&parm);
	parse_arg(term->esc.buf + 1, &parm, ';', is_osc_parm); /* skip ']' */

	if (parm.argc > 0) {
		osc_mode = dec2num(parm.argv[0]);
		if (DEBUG)
			fprintf(stderr, "osc_mode:%d\n", osc_mode);

		/*
		if (osc_mode == 4)
			set_palette(term, &parm);
		else if (osc_mode == 104)
			reset_palette(term, &parm);
		*/
		if (osc_mode == 8900)
			glyph_width_report(term, &parm);
	}
	reset_esc(term);
}


enum {
	RGBMAX = 255,
	HUEMAX = 360,
	LSMAX  = 100,
};

static inline int sixel_bitmap(struct terminal *term, struct sixel_canvas_t *sc, uint8_t bitmap)
{
	int i, offset;

	if (DEBUG)
		fprintf(stderr, "sixel_bitmap()\nbitmap:%.2X point(%d, %d)\n",
			bitmap, sc->point.x, sc->point.y);

	if (sc->point.x >= term->width || sc->point.y >= term->height)
		return 1;

	offset = sc->point.x * BYTES_PER_PIXEL + sc->point.y * sc->line_length;

	for (i = 0; i < BITS_PER_SIXEL; i++) {
		if (offset >= BYTES_PER_PIXEL * term->width * term->height)
			break;

		if (bitmap & (0x01 << i))
			memcpy(sc->bitmap + offset, &sc->color_table[sc->color_index], BYTES_PER_PIXEL);

		offset += sc->line_length;
	}
	sc->point.x++;

	if (sc->point.x > sc->width)
		sc->width = sc->point.x;

	return 1;
}

static inline int sixel_repeat(struct terminal *term, struct sixel_canvas_t *sc, char *buf)
{
	int i, count;
	size_t length;
	char *cp, tmp[BUFSIZE];
	uint8_t bitmap;

	cp = buf + 1; /* skip '!' itself */
	while (isdigit(*cp)) /* skip non sixel bitmap character */
		cp++;

	length = (cp - buf);
	strncpy(tmp, buf + 1, length - 1);
	*(tmp + length - 1) = '\0';

	count = dec2num(tmp);

	if (DEBUG)
		fprintf(stderr, "sixel_repeat()\nbuf:%s length:%u\ncount:%d repeat:0x%.2X\n",
			tmp, (unsigned) length, count, *cp);

	if ('?' <= *cp && *cp <= '~') {
		bitmap = bit_mask[BITS_PER_SIXEL] & (*cp - '?');
		for (i = 0; i < count; i++)
			sixel_bitmap(term, sc, bitmap);
	}

	return length + 1;
}

static inline int sixel_attr(struct sixel_canvas_t *sc, char *buf)
{
	char *cp, tmp[BUFSIZE];
	size_t length;
	struct parm_t parm;

	cp = buf + 1;
	while (isdigit(*cp) || *cp == ';') /* skip valid params */
		cp++;

	length = (cp - buf);
	strncpy(tmp, buf + 1, length - 1);
	*(tmp + length - 1) = '\0';

	reset_parm(&parm);
	parse_arg(tmp, &parm, ';', isdigit);

	if (parm.argc >= 4) {
		sc->width  = dec2num(parm.argv[2]);
		sc->height = dec2num(parm.argv[3]);
	}

	if (DEBUG)
		fprintf(stderr, "sixel_attr()\nbuf:%s\nwidth:%d height:%d\n",
			tmp, sc->width, sc->height);

	return length;
}

static inline uint32_t hue2rgb(int n1, int n2, int hue)
{
	if (hue < 0)
		hue += HUEMAX;

	if (hue > HUEMAX)
		hue -= HUEMAX;

	if (hue < (HUEMAX / 6))
		return (n1 + (((n2 - n1) * hue + (HUEMAX / 12)) / (HUEMAX / 6)));
	if (hue < (HUEMAX / 2))
		return n2;
	if (hue < ((HUEMAX * 2) / 3))
		return (n1 + (((n2 - n1) * (((HUEMAX * 2) / 3) - hue) + (HUEMAX / 12)) / (HUEMAX / 6)));
	else
		return n1;
}

static inline uint32_t hls2rgb(int hue, int lum, int sat)
{
	uint32_t r, g, b;
	int magic1, magic2;

	if (sat == 0) {
		r = g = b = (lum * RGBMAX) / LSMAX;
	}
	else {
		if (lum <= (LSMAX / 2) )
			magic2 = (lum * (LSMAX + sat) + (LSMAX / 2)) / LSMAX;
		else
			magic2 = lum + sat - ((lum * sat) + (LSMAX / 2)) / LSMAX;
		magic1 = 2 * lum - magic2;

		r = (hue2rgb(magic1, magic2, hue + (HUEMAX / 3)) * RGBMAX + (LSMAX / 2)) / LSMAX;
		g = (hue2rgb(magic1, magic2, hue) * RGBMAX + (LSMAX / 2)) / LSMAX;
		b = (hue2rgb(magic1, magic2, hue - (HUEMAX / 3)) * RGBMAX + (LSMAX/2)) / LSMAX;
	}
	return (r << 16) + (g << 8) + b;
}

static inline int sixel_color(struct sixel_canvas_t *sc, char *buf)
{
	char *cp, tmp[BUFSIZE];
	int index, type;
	size_t length;
	uint16_t v1, v2, v3, r, g, b;
	uint32_t color;
	struct parm_t parm;

	cp = buf + 1;
	while (isdigit(*cp) || *cp == ';') /* skip valid params */
		cp++;

	length = (cp - buf);
	strncpy(tmp, buf + 1, length - 1); /* skip '#' */
	*(tmp + length - 1) = '\0';

	reset_parm(&parm);
	parse_arg(tmp, &parm, ';', isdigit);

	if (parm.argc < 1)
		return length;

	index = dec2num(parm.argv[0]);
	if (index < 0)
		index = 0;
	else if (index >= COLORS)
		index = COLORS - 1;

	if (DEBUG)
		fprintf(stderr, "sixel_color()\nbuf:%s length:%u\nindex:%d\n",
			tmp, (unsigned) length, index);

	if (parm.argc == 1) { /* select color */
		sc->color_index = index;
		return length;
	}

	if (parm.argc != 5)
		return length;

	type  = dec2num(parm.argv[1]);
	v1    = dec2num(parm.argv[2]);
	v2    = dec2num(parm.argv[3]);
	v3    = dec2num(parm.argv[4]);

	if (type == 1) /* HLS */
		color = hls2rgb(v1, v2, v3);
	else {
		r = bit_mask[8] & (0xFF * v1 / 100);
		g = bit_mask[8] & (0xFF * v2 / 100);
		b = bit_mask[8] & (0xFF * v3 / 100);
		color = (r << 16) | (g << 8) | b;
	}

	if (DEBUG)
		fprintf(stderr, "type:%d v1:%u v2:%u v3:%u color:0x%.8X\n",
			type, v1, v2, v3, color);

	sc->color_table[index] = color;

	return length;
}

static inline int sixel_cr(struct sixel_canvas_t *sc)
{
	if (DEBUG)
		fprintf(stderr, "sixel_cr()\n");

	sc->point.x = 0;

	return 1;
}

static inline int sixel_nl(struct sixel_canvas_t *sc)
{
	if (DEBUG)
		fprintf(stderr, "sixel_nl()\n");

	/* DECGNL moves active position to left margin
		and down one line of sixels:
		http://odl.sysworks.biz/disk$vaxdocdec963/decw$book/d3qsaaa1.p67.decw$book */
	sc->point.y += BITS_PER_SIXEL;
	sc->point.x = 0;

	if (sc->point.y > sc->height)
		sc->height = sc->point.y;

	return 1;
}

void sixel_parse_data(struct terminal *term, struct sixel_canvas_t *sc, char *start_buf)
{
	/*
	DECDLD sixel data
		'$': carriage return
		'-': new line
		'#': color
			# Pc: select color
			# Pc; Pu; Px; Py; Pz
				Pc : color index (0 to 255)
				Pu : color coordinate system
					1: HLS (0 to 360 for Hue, 0 to 100 for others)
					2: RGB (0 to 100 percent) (default)
				Px : Hue        / Red
				Py : Lightness  / Green
				Pz : Saturation / Blue
		'"': attr
			" Pan; Pad; Ph; Pv
				Pan, Pad: defines aspect ratio (Pan / Pad) (ignored)
				Ph, Pv  : defines vertical/horizontal size of the image
		'!': repeat
			! Pn ch
				Pn : repeat count ([0-9]+)
				ch : character to repeat ('?' to '~')
		sixel bitmap:
			range of ? (hex 3F) to ~ (hex 7E)
			? (hex 3F) represents the binary value 00 0000.
			t (hex 74) represents the binary value 11 0101.
			~ (hex 7E) represents the binary value 11 1111.
	*/
	int size = 0;
	char *cp, *end_buf;
	uint8_t bitmap;

	cp = start_buf;
	end_buf = cp + strlen(start_buf);

	while (cp < end_buf) {
		if (*cp == '!')
			size = sixel_repeat(term, sc, cp);
		else if (*cp == '"')
			size = sixel_attr(sc, cp);
		else if (*cp == '#')
			size = sixel_color(sc, cp);
		else if (*cp == '$')
			size = sixel_cr(sc);
		else if (*cp == '-')
			size = sixel_nl(sc);
		else if ('?' <= *cp && *cp <= '~')  {
			bitmap =  bit_mask[BITS_PER_SIXEL] & (*cp - '?');
			size = sixel_bitmap(term, sc, bitmap);
		}
		else if (*cp == '\0') /* end of sixel data */
			break;
		else
			size = 1;
		cp += size;
	}

	if (DEBUG)
		fprintf(stderr, "sixel_parse_data()\nwidth:%d height:%d\n", sc->width, sc->height);
}

void reset_sixel(struct sixel_canvas_t *sc, struct color_pair_t color_pair, int width, int height)
{
	extern const uint32_t color_list[]; /* global */
	int i;

	memset(sc->bitmap, 0, BYTES_PER_PIXEL * width * height);

	sc->width   = 1;
	sc->height  = 6;
	sc->point.x	= 0;
	sc->point.y = 0;
	sc->line_length = BYTES_PER_PIXEL * width;
	sc->color_index = 0;

	/* 0 - 15: use vt340 or ansi color map */
	/* VT340 VT340 Default Color Map
		ref: http://www.vt100.net/docs/vt3xx-gp/chapter2.html#T2-3
	*/
	sc->color_table[0] = 0x000000; sc->color_table[8]  = 0x424242;
	sc->color_table[1] = 0x3333CC; sc->color_table[9]  = 0x545499;
	sc->color_table[2] = 0xCC2121; sc->color_table[10] = 0x994242;
	sc->color_table[3] = 0x33CC33; sc->color_table[11] = 0x549954;
	sc->color_table[4] = 0xCC33CC; sc->color_table[12] = 0x995499;
	sc->color_table[5] = 0x33CCCC; sc->color_table[13] = 0x549999;
	sc->color_table[6] = 0xCCCC33; sc->color_table[14] = 0x999954;
	sc->color_table[7] = 0x878787; sc->color_table[15] = 0xCCCCCC;

	/* ANSI 16color table (but unusual order corresponding vt340 color map)
	sc->color_table[0] = color_list[0]; sc->color_table[8]  = color_list[8];
	sc->color_table[1] = color_list[4]; sc->color_table[9]  = color_list[12];
	sc->color_table[2] = color_list[1]; sc->color_table[10] = color_list[9];
	sc->color_table[3] = color_list[2]; sc->color_table[11] = color_list[10];
	sc->color_table[4] = color_list[5]; sc->color_table[12] = color_list[13];
	sc->color_table[5] = color_list[6]; sc->color_table[13] = color_list[14];
	sc->color_table[6] = color_list[3]; sc->color_table[14] = color_list[11];
	sc->color_table[7] = color_list[7]; sc->color_table[15] = color_list[15];
	*/
	/* change palette 0, because its often the same color as terminal background */
	sc->color_table[0] = color_list[color_pair.fg];

	/* 16 - 255: use xterm 256 color palette */
	/* copy 256 color map */
	for (i = 16; i < COLORS; i++)
		sc->color_table[i] = color_list[i];
}

int my_ceil(int val, int div)
{
	return (val + div - 1) / div;
}

void sixel_copy2cell(struct terminal *term, struct sixel_canvas_t *sc)
{
	int y, x, h, cols, lines;
	int src_offset, dst_offset;
	struct cell_t *cellp;

	if (sc->height > term->height)
		sc->height = term->height;

	cols  = my_ceil(sc->width, CELL_WIDTH);
	lines = my_ceil(sc->height, CELL_HEIGHT);

	if (cols + term->cursor.x > term->cols)
		cols -= (cols + term->cursor.x - term->cols);

	for (y = 0; y < lines; y++) {
		for (x = 0; x < cols; x++) {
			erase_cell(term, term->cursor.y, term->cursor.x + x);
			cellp = &term->cells[term->cursor.y * term->cols + (term->cursor.x + x)];
			cellp->has_bitmap = true;
			for (h = 0; h < CELL_HEIGHT; h++) {
				src_offset = (y * CELL_HEIGHT + h) * sc->line_length + (CELL_WIDTH * x) * BYTES_PER_PIXEL;
				dst_offset = h * CELL_WIDTH * BYTES_PER_PIXEL;
				if (src_offset >= BYTES_PER_PIXEL * term->width * term->height)
					break;
				memcpy(cellp->bitmap + dst_offset, sc->bitmap + src_offset, CELL_WIDTH * BYTES_PER_PIXEL);
			}
		}
		move_cursor(term, 1, 0);
	}
	cr(term);
}

void sixel_parse_header(struct terminal *term, char *start_buf)
{
	/*
	sixel format
		DSC P1; P2; P3; q; s...s; ST
	parameters
		DCS: ESC(0x1B) P (0x50) (8bit C1 character not recognized)
		P1 : pixel aspect ratio (force 0, 2:1) (ignored)
		P2 : background mode (ignored)
			0 or 2: 0 stdands for current background color (default)
			1     : 0 stands for remaining current color
		P3 : horizontal grid parameter (ignored)
		q  : final character of sixel sequence
		s  : see parse_sixel_data()
		ST : ESC (0x1B) '\' (0x5C) or BEL (0x07)
	*/
	char *cp;
	struct parm_t parm;

	/* replace final char of sixel header by NUL '\0' */
	cp = strchr(start_buf, 'q');
	*cp = '\0';

	if (DEBUG)
		fprintf(stderr, "sixel_parse_header()\nbuf:%s\n", start_buf);

	/* split header by semicolon ';' */
	reset_parm(&parm);
	parse_arg(start_buf, &parm, ';', isdigit);

	/* set canvas parameters */
	reset_sixel(&term->sixel, term->color_pair, term->width, term->height);
	sixel_parse_data(term, &term->sixel, cp + 1); /* skip 'q' */
	sixel_copy2cell(term, &term->sixel);
}

static inline void decdld_bitmap(struct glyph_t *glyph, uint8_t bitmap, uint8_t row, uint8_t column)
{
	/*
			  MSB        LSB (glyph_t bitmap order, padding at LSB side)
				  -> column
	sixel bit0 ->........
	sixel bit1 ->........
	sixel bit2 ->....@@..
	sixel bit3 ->...@..@.
	sixel bit4 ->...@....
	sixel bit5 ->...@....
				 .@@@@@..
				 ...@....
				|...@....
			row |...@....
				v...@....
				 ...@....
				 ...@....
				 ...@....
				 ........
				 ........
	*/
	int i, height_shift, width_shift;

	if (DEBUG)
		fprintf(stderr, "bit pattern:0x%.2X\n", bitmap);

	width_shift = CELL_WIDTH - 1 - column;
	if (width_shift < 0)
		return;

	for (i = 0; i < BITS_PER_SIXEL; i++) {
		if((bitmap >> i) & 0x01) {
			height_shift = row * BITS_PER_SIXEL + i;

			if (height_shift < CELL_HEIGHT) {
				if (DEBUG)
					fprintf(stderr, "height_shift:%d width_shift:%d\n", height_shift, width_shift);
				glyph->bitmap[height_shift] |= bit_mask[CELL_WIDTH] & (0x01 << width_shift);
			}
		}
	}
}

static inline void init_glyph(struct glyph_t *glyph)
{
	int i;

	glyph->width = 1; /* drcs glyph must be HALF */
	glyph->code = 0;  /* this value not used: drcs call by DRCSMMv1 */

	for (i = 0; i < CELL_HEIGHT; i++)
		glyph->bitmap[i] = 0;
}

void decdld_parse_data(char *start_buf, int start_char, struct glyph_t *chars)
{
	/*
	DECDLD sixel data
		';': glyph separator
		'/': line feed
		sixel bitmap:
			range of ? (hex 3F) to ~ (hex 7E)
			? (hex 3F) represents the binary value 00 0000.
			t (hex 74) represents the binary value 11 0101.
			~ (hex 7E) represents the binary value 11 1111.
	*/
	char *cp, *end_buf;
	uint8_t char_num = start_char; /* start_char == 0 means SPACE(0x20) */
	uint8_t bitmap, row = 0, column = 0;

	init_glyph(&chars[char_num]);
	cp      = start_buf;
	end_buf = cp + strlen(cp);

	while (cp < end_buf) {
		if ('?' <= *cp && *cp <= '~') { /* sixel bitmap */
			if (DEBUG)
				fprintf(stderr, "char_num(ten):0x%.2X\n", char_num);
			/* remove offset '?' and use only 6bit */
			bitmap = bit_mask[BITS_PER_SIXEL] & (*cp - '?');
			decdld_bitmap(&chars[char_num], bitmap, row, column);
			column++;
		}
		else if (*cp == ';') { /* next char */
			row = column = 0;
			char_num++;
			init_glyph(&chars[char_num]);
		}
		else if (*cp == '/') { /* sixel nl+cr */
			row++;
			column = 0;
		}
		else if (*cp == '\0')  /* end of DECDLD sequence */
			break;
		cp++;
	}
}

void decdld_parse_header(struct terminal *term, char *start_buf)
{
	/*
	DECDLD format
		DCS Pfn; Pcn; Pe; Pcmw; Pss; Pt; Pcmh; Pcss; f Dscs Sxbp1 ; Sxbp2 ; .. .; Sxbpn ST
	parameters
		DCS : ESC (0x1B) 'P' (0x50) (DCS(8bit C1 code) is not supported)
		Pfn : fontset (ignored)
		Pcn : start char (0 means SPACE 0x20)
		Pe  : erase mode
				0: clear selectet charset
				1: clear only redefined glyph
				2: clear all drcs charset
		Pcmw: max cellwidth (force CELL_WEDTH defined in glyph.h)
		Pss : screen size (ignored)
		Pt  : defines the glyph as text or full cell or sixel (force full cell mode)
		      (TODO: implement sixel/text mode)
		Pcmh: max cellheight (force CELL_HEIGHT defined in glyph.h)
		Pcss: character set size (force: 96)
				0: 94 gylphs charset
				1: 96 gylphs charset
		f   : '{' (0x7B)
		Dscs: define character set
				Intermediate char: SPACE (0x20) to '/' (0x2F)
				final char       : '0' (0x30) to '~' (0x7E)
									but allow chars between '@' (0x40) and '~' (0x7E) for DRCSMMv1
									(ref: https://github.com/saitoha/drcsterm/blob/master/README.rst)
		Sxbp: see parse_decdld_sixel()
		ST  : ESC (0x1B) '\' (0x5C) or BEL (0x07)
	*/
	char *cp;
	int i, start_char, erase_mode, charset;
	struct parm_t parm;

	/* replace final char of DECDLD header by NUL '\0' */
	cp = strchr(start_buf, '{');
	*cp = '\0';

	if (DEBUG)
		fprintf(stderr, "decdld_parse_header()\nbuf:%s\n", start_buf);

	/* split header by semicolon ';' */
	reset_parm(&parm);
	parse_arg(start_buf, &parm, ';', isdigit);

	if (parm.argc != 8) /* DECDLD header must have 8 params */
		return;

	/* set params */
	start_char = dec2num(parm.argv[1]);
	erase_mode = dec2num(parm.argv[2]);

	/* parse Dscs */
	cp++; /* skip final char (NUL) of DECDLD header */
	while (SPACE <= *cp && *cp <= '/') /* skip intermediate char */
		cp++;

	if (0x40 <= *cp && *cp <= 0x7E) /* final char of Dscs must be between 0x40 to 0x7E (DRCSMMv1) */
		charset = *cp - 0x40;
	else
		charset = 0;

	if (DEBUG)
		fprintf(stderr, "charset(ku):0x%.2X start_char:%d erase_mode:%d\n",
			charset, start_char, erase_mode);

	/* reset previous glyph data */
	if (erase_mode < 0 || erase_mode > 2)
		erase_mode = 0;

	if (erase_mode == 2) {      /* reset all drcs charset */
		for (i = 0; i < DRCS_CHARSETS; i++) {
			if (term->drcs[i] != NULL) {
				free(term->drcs[i]);
				term->drcs[i] = NULL;
			}
		}
	}
	else if (erase_mode == 0) { /* reset selected drcs charset */
		if (term->drcs[charset] != NULL) {
			free(term->drcs[charset]);
			term->drcs[charset] = NULL;
		}
	}

	if (term->drcs[charset] == NULL) /* always allcate 96 chars buffer */
		term->drcs[charset] = ecalloc(GLYPH_PER_CHARSET, sizeof(struct glyph_t));

	decdld_parse_data(cp + 1, start_char, term->drcs[charset]); /* skil final char */
}



void dcs_sequence(struct terminal *term, uint8_t ch)
{
	char *cp;

	omit_string_terminator(term->esc.bp, ch);

	if (DEBUG)
		fprintf(stderr, "dcs: DCS %s\n", term->esc.buf);

	/* check DCS header */
	cp = term->esc.buf + 1; /* skip P */
	while (cp < term->esc.bp) {
		if (*cp == '{' || *cp == 'q')      /* DECDLD or sixel */
			break;
		else if (*cp == ';'                /* valid DCS header */
			|| ('0' <= *cp && *cp <= '9'))
			;
		else                               /* invalid sequence */
			cp = term->esc.bp;
		cp++;
	}

	if (cp != term->esc.bp) { /* header only or cannot find final char */
		/* parse DCS header */
		if (*cp == 'q')
			sixel_parse_header(term, term->esc.buf + 1);
		else if (*cp == '{')
			decdld_parse_header(term, term->esc.buf + 1);
	}

	reset_esc(term);
}

int set_cell(struct terminal *term, int y, int x, const struct glyph_t *glyphp)
{
	struct cell_t cell, *cellp;
	uint8_t color_tmp;

	cell.glyphp = glyphp;

	cell.color_pair.fg = (term->attribute & attr_mask[ATTR_BOLD] && term->color_pair.fg <= 7) ?
		term->color_pair.fg + BRIGHT_INC: term->color_pair.fg;
	cell.color_pair.bg = (term->attribute & attr_mask[ATTR_BLINK] && term->color_pair.bg <= 7) ?
		term->color_pair.bg + BRIGHT_INC: term->color_pair.bg;

	if (term->attribute & attr_mask[ATTR_REVERSE]) {
		color_tmp          = cell.color_pair.fg;
		cell.color_pair.fg = cell.color_pair.bg;
		cell.color_pair.bg = color_tmp;
	}

	cell.attribute  = term->attribute;
	cell.width      = glyphp->width;
	cell.has_bitmap = false;

	cellp    = &term->cells[x + y * term->cols];
	*cellp   = cell;
	term->line_dirty[y] = true;

	if (cell.width == WIDE && x + 1 < term->cols) {
		cellp        = &term->cells[x + 1 + y * term->cols];
		*cellp       = cell;
		cellp->width = NEXT_TO_WIDE;
		return WIDE;
	}
	return HALF;
}

void addch(struct terminal *term, uint32_t code)
{
	int width;
	const struct glyph_t *glyphp;

	if (DEBUG)
		fprintf(stderr, "addch: U+%.4X\n", code);

	width = my_wcwidth(code);

	if (width <= 0)                                /* zero width: not support comibining character */
		return;
	else if (0x100000 <= code && code <= 0x10FFFD) /* unicode private area: plane 16 (DRCSMMv1) */
		glyphp = drcsch(term, code);
	else if (code >= UCS2_CHARS                    /* yaft support only UCS2 */
		|| term->glyph_map[code] == NULL           /* missing glyph */
		|| term->glyph_map[code]->width != width)  /* width unmatch */
		glyphp = (width == 1) ? term->glyph_map[SUBSTITUTE_HALF]: term->glyph_map[SUBSTITUTE_WIDE];
	else
		glyphp = term->glyph_map[code];

	if ((term->wrap_occured && term->cursor.x == term->cols - 1) /* folding */
		|| (glyphp->width == WIDE && term->cursor.x == term->cols - 1)) {
		set_cursor(term, term->cursor.y, 0);
		move_cursor(term, 1, 0);
	}
	term->wrap_occured = false;

	move_cursor(term, 0, set_cell(term, term->cursor.y, term->cursor.x, glyphp));
}

void utf8_charset(struct terminal *term, uint8_t ch)
{
	if (0x80 <= ch && ch <= 0xBF) {
		/* check illegal UTF-8 sequence
			* ? byte sequence: first byte must be between 0xC2 ~ 0xFD
			* 2 byte sequence: first byte must be between 0xC2 ~ 0xDF
			* 3 byte sequence: second byte following 0xE0 must be between 0xA0 ~ 0xBF
			* 4 byte sequence: second byte following 0xF0 must be between 0x90 ~ 0xBF
			* 5 byte sequence: second byte following 0xF8 must be between 0x88 ~ 0xBF
			* 6 byte sequence: second byte following 0xFC must be between 0x84 ~ 0xBF
		*/
		if ((term->charset.following_byte == 0)
			|| (term->charset.following_byte == 1 && term->charset.count == 0 && term->charset.code <= 1)
			|| (term->charset.following_byte == 2 && term->charset.count == 0 && term->charset.code == 0 && ch < 0xA0)
			|| (term->charset.following_byte == 3 && term->charset.count == 0 && term->charset.code == 0 && ch < 0x90)
			|| (term->charset.following_byte == 4 && term->charset.count == 0 && term->charset.code == 0 && ch < 0x88)
			|| (term->charset.following_byte == 5 && term->charset.count == 0 && term->charset.code == 0 && ch < 0x84))
			term->charset.is_valid = false;

		term->charset.code <<= 6;
		term->charset.code += ch & 0x3F;
		term->charset.count++;
	}
	else if (0xC0 <= ch && ch <= 0xDF) {
		term->charset.code = ch & 0x1F;
		term->charset.following_byte = 1;
		term->charset.count = 0;
		return;
	}
	else if (0xE0 <= ch && ch <= 0xEF) {
		term->charset.code = ch & 0x0F;
		term->charset.following_byte = 2;
		term->charset.count = 0;
		return;
	}
	else if (0xF0 <= ch && ch <= 0xF7) {
		term->charset.code = ch & 0x07;
		term->charset.following_byte = 3;
		term->charset.count = 0;
		return;
	}
	else if (0xF8 <= ch && ch <= 0xFB) {
		term->charset.code = ch & 0x03;
		term->charset.following_byte = 4;
		term->charset.count = 0;
		return;
	}
	else if (0xFC <= ch && ch <= 0xFD) {
		term->charset.code = ch & 0x01;
		term->charset.following_byte = 5;
		term->charset.count = 0;
		return;
	}
	else { /* 0xFE - 0xFF: not used in UTF-8 */
		addch(term, REPLACEMENT_CHAR);
		reset_charset(term);
		return;
	}

	if (term->charset.count >= term->charset.following_byte) {
		/*	illegal code point (ref: http://www.unicode.org/reports/tr27/tr27-4.html)
			0xD800   ~ 0xDFFF : surrogate pair
			0xFDD0   ~ 0xFDEF : noncharacter
			0xnFFFE  ~ 0xnFFFF: noncharacter (n: 0x00 ~ 0x10)
			0x110000 ~        : invalid (unicode U+0000 ~ U+10FFFF)
		*/
		if (!term->charset.is_valid
			|| (0xD800 <= term->charset.code && term->charset.code <= 0xDFFF)
			|| (0xFDD0 <= term->charset.code && term->charset.code <= 0xFDEF)
			|| ((term->charset.code & 0xFFFF) == 0xFFFE || (term->charset.code & 0xFFFF) == 0xFFFF)
			|| (term->charset.code > 0x10FFFF))
			addch(term, REPLACEMENT_CHAR);
		else
			addch(term, term->charset.code);

		reset_charset(term);
	}
}

bool push_esc(struct terminal *term, uint8_t ch)
{
	long offset;

	if ((term->esc.bp - term->esc.buf) >= term->esc.size) { /* buffer limit */
		if (DEBUG)
			fprintf(stderr, "escape sequence length >= %d, term.esc.buf reallocated\n", term->esc.size);
		offset = term->esc.bp - term->esc.buf;
		term->esc.buf  = erealloc(term->esc.buf, term->esc.size * 2);
		term->esc.size *= 2;
		term->esc.bp   = term->esc.buf + offset;
	}

	/* ref: http://www.vt100.net/docs/vt102-ug/appendixd.html */
	*term->esc.bp++ = ch;
	if (term->esc.state == STATE_ESC) {
		/* format:
			ESC  I.......I F
				 ' '  '/'  '0'  '~'
			0x1B 0x20-0x2F 0x30-0x7E
		*/
		if ('0' <= ch && ch <= '~')        /* final char */
			return true;
		else if (SPACE <= ch && ch <= '/') /* intermediate char */
			return false;
	}
	else if (term->esc.state == STATE_CSI) {
		/* format:
			CSI       P.......P I.......I F
			ESC  '['  '0'  '?'  ' '  '/'  '@'  '~'
			0x1B 0x5B 0x30-0x3F 0x20-0x2F 0x40-0x7E
		*/
		if ('@' <= ch && ch <= '~')
			return true;
		else if (SPACE <= ch && ch <= '?')
			return false;
	}
	else {
		/* format:
			OSC       I.....I F
			ESC  ']'          BEL  or ESC  '\'
			0x1B 0x5D unknown 0x07 or 0x1B 0x5C
			DCS       I....I  F
			ESC  'P'          BEL  or ESC  '\'
			0x1B 0x50 unknown 0x07 or 0x1B 0x5C
		*/
		if (ch == BEL || (ch == BACKSLASH
			&& (term->esc.bp - term->esc.buf) >= 2 && *(term->esc.bp - 2) == ESCT))
			return true;
		else if ((ch == ESCT || ch == CR || ch == LF || ch == BS || ch == HT)
			|| (SPACE <= ch && ch <= '~'))
			return false;
	}

	/* invalid sequence */
	reset_esc(term);
	return false;
}

void parse(struct terminal *term, uint8_t *buf, int size)
{
	/*
		CTRL CHARS      : 0x00 ~ 0x1F
		ASCII(printable): 0x20 ~ 0x7E
		CTRL CHARS(DEL) : 0x7F
		UTF-8           : 0x80 ~ 0xFF
	*/
	uint8_t ch;
	int i;

	for (i = 0; i < size; i++) {
		ch = buf[i];
		if (term->esc.state == STATE_RESET) {
			/* interrupted by illegal byte */
			if (term->charset.following_byte > 0 && (ch < 0x80 || ch > 0xBF)) {
				addch(term, REPLACEMENT_CHAR);
				reset_charset(term);
			}

			if (ch <= 0x1F)
				control_character(term, ch);
			else if (ch <= 0x7F)
				addch(term, ch);
			else
				utf8_charset(term, ch);
		}
		else if (term->esc.state == STATE_ESC) {
			if (push_esc(term, ch))
				esc_sequence(term, ch);
		}
		else if (term->esc.state == STATE_CSI) {
			if (push_esc(term, ch))
				csi_sequence(term, ch);
		}
		else if (term->esc.state == STATE_OSC) {
			if (push_esc(term, ch))
				osc_sequence(term, ch);
		}
		else if (term->esc.state == STATE_DCS) {
			if (push_esc(term, ch))
				dcs_sequence(term, ch);
		}
	}
}


void set_colormap(int colormap[COLORS * BYTES_PER_PIXEL + 1])
{
	int i, ci, r, g, b;
	uint8_t index;

	/* colormap: terminal 256color
	for (i = 0; i < COLORS; i++) {
		ci = i * BYTES_PER_PIXEL;

		r = (color_list[i] >> 16) & bit_mask[8];
		g = (color_list[i] >> 8)  & bit_mask[8];
		b = (color_list[i] >> 0)  & bit_mask[8];

		colormap[ci + 0] = r;
		colormap[ci + 1] = g;
		colormap[ci + 2] = b;
	}
	*/

	/* colormap: red/green: 3bit blue: 2bit
	*/
	for (i = 0; i < COLORS; i++) {
		index = (uint8_t) i;
		ci = i * BYTES_PER_PIXEL;

		r = (index >> RED_SHIFT)   & bit_mask[RED_MASK];
		g = (index >> GREEN_SHIFT) & bit_mask[GREEN_MASK];
		b = (index >> BLUE_SHIFT)  & bit_mask[BLUE_MASK];

		colormap[ci + 0] = r * bit_mask[BITS_PER_BYTE] / bit_mask[RED_MASK];
		colormap[ci + 1] = g * bit_mask[BITS_PER_BYTE] / bit_mask[GREEN_MASK];
		colormap[ci + 2] = b * bit_mask[BITS_PER_BYTE] / bit_mask[BLUE_MASK];
	}
	colormap[COLORS * BYTES_PER_PIXEL] = -1;
}

uint32_t pixel2index(uint32_t pixel)
{
	/* pixel is always 24bpp */
	uint32_t r, g, b;

	/* split r, g, b bits */
	r = (pixel >> 16) & bit_mask[8];
	g = (pixel >> 8)  & bit_mask[8];
	b = (pixel >> 0)  & bit_mask[8];

	/* colormap: terminal 256color
	if (r == g && r == b) { // 24 gray scale
		r = 24 * r / COLORS;
		return 232 + r;
	}					   // 6x6x6 color cube

	r = 6 * r / COLORS;
	g = 6 * g / COLORS;
	b = 6 * b / COLORS;

	return 16 + (r * 36) + (g * 6) + b;
	*/

	/* colormap: red/green: 3bit blue: 2bit
	*/
	// get MSB ..._MASK bits
	r = (r >> (8 - RED_MASK))   & bit_mask[RED_MASK];
	g = (g >> (8 - GREEN_MASK)) & bit_mask[GREEN_MASK];
	b = (b >> (8 - BLUE_MASK))  & bit_mask[BLUE_MASK];

	return (r << RED_SHIFT) | (g << GREEN_SHIFT) | (b << BLUE_SHIFT);
}

void apply_colormap(struct pseudobuffer *pb, unsigned char *capture)
{
	int w, h;
	uint32_t pixel = 0;

	for (h = 0; h < pb->height; h++) {
		for (w = 0; w < pb->width; w++) {
			memcpy(&pixel, pb->buf + h * pb->line_length
				+ w * pb->bytes_per_pixel, pb->bytes_per_pixel);
			*(capture + h * pb->width + w) = pixel2index(pixel) & bit_mask[BITS_PER_BYTE];
		}
	}
}

void gif_init(struct gif_t *gif, int width, int height)
{
	set_colormap(gif->colormap);

	if (!(gif->data = newgif((void **) &gif->image, width, height, gif->colormap, 0)))
		exit(EXIT_FAILURE);

	animategif(gif->data, /* repetitions */ GIF_REPEAT, /* delay */ GIF_DELAY,
		/* transparent background */ GIF_TRANSPARENT, /* disposal */ GIF_DISPOSAL);
}


void redraw(struct terminal *term)
{
	int i;

	for (i = 0; i < term->lines; i++)
		term->line_dirty[i] = true;
}


void term_init(struct terminal *term, int width, int height, bool ambiguous_is_wide)
{
	int i;
	uint32_t code, gi, ambiguous_glyph_num;
	const struct glyph_t *ambiguous_glyphs;

	term->width  = width;
	term->height = height;

	term->cols  = term->width / CELL_WIDTH;
	term->lines = term->height / CELL_HEIGHT;

	if (DEBUG)
		fprintf(stderr, "width:%d height:%d cols:%d lines:%d\n",
			width, height, term->cols, term->lines);

	term->line_dirty = (bool *) ecalloc(term->lines, sizeof(bool));
	term->tabstop    = (bool *) ecalloc(term->cols, sizeof(bool));
	term->cells      = (struct cell_t *) ecalloc(term->cols * term->lines, sizeof(struct cell_t));

	term->esc.buf  = (char *) ecalloc(1, ESCSEQ_SIZE);
	term->esc.size = ESCSEQ_SIZE;

	/* initialize glyph map */
	for (code = 0; code < UCS2_CHARS; code++)
		term->glyph_map[code] = NULL;

	for (gi = 0; gi < sizeof(glyphs) / sizeof(struct glyph_t); gi++)
		term->glyph_map[glyphs[gi].code] = &glyphs[gi];

	if (ambiguous_is_wide) {
		ambiguous_glyphs = ambiguous_wide_glyphs;
		ambiguous_glyph_num = sizeof(ambiguous_wide_glyphs) / sizeof(struct glyph_t);
	}
	else {
		ambiguous_glyphs = ambiguous_half_glyphs;
		ambiguous_glyph_num = sizeof(ambiguous_half_glyphs) / sizeof(struct glyph_t);
	}

	for (gi = 0; gi < ambiguous_glyph_num; gi++)
		term->glyph_map[ambiguous_glyphs[gi].code] = &ambiguous_glyphs[gi];

	if (term->glyph_map[DEFAULT_CHAR] == NULL
		|| term->glyph_map[SUBSTITUTE_HALF] == NULL
		|| term->glyph_map[SUBSTITUTE_WIDE] == NULL)
		fatal("cannot find DEFAULT_CHAR or SUBSTITUTE_HALF or SUBSTITUTE_HALF\n");

	/* initialize drcs */
	for (i = 0; i < DRCS_CHARSETS; i++)
		term->drcs[i] = NULL;

	/* allocate sixel buffer */
	term->sixel.bitmap = (uint8_t *) ecalloc(width * height, BYTES_PER_PIXEL);

	reset(term);
}

void term_die(struct terminal *term)
{
	int i;

	free(term->line_dirty);
	free(term->tabstop);
	free(term->cells);
	free(term->esc.buf);

	for (i = 0; i < DRCS_CHARSETS; i++)
		if (term->drcs[i] != NULL)
			free(term->drcs[i]);

	free(term->sixel.bitmap);
}


void pb_init(struct pseudobuffer *pb, int width, int height)
{
	pb->width  = width;
	pb->height = height;
	pb->bytes_per_pixel = BYTES_PER_PIXEL;
	pb->line_length = pb->width * pb->bytes_per_pixel;
	pb->buf = ecalloc(pb->width * pb->height, pb->bytes_per_pixel);
}


void pb_die(struct pseudobuffer *pb)
{
	free(pb->buf);
}


static inline void draw_sixel(struct pseudobuffer *pb, int line, int col, uint8_t *bitmap)
{
	int h, w, src_offset, dst_offset;
	uint32_t pixel, color = 0;

	for (h = 0; h < CELL_HEIGHT; h++) {
		for (w = 0; w < CELL_WIDTH; w++) {
			src_offset = BYTES_PER_PIXEL * (h * CELL_WIDTH + w);
			memcpy(&color, bitmap + src_offset, BYTES_PER_PIXEL);

			dst_offset = (line * CELL_HEIGHT + h) * pb->line_length + (col * CELL_WIDTH + w) * pb->bytes_per_pixel;
			//////TODO???? pixel = color2pixel(&pb->vinfo, color);
			pixel = color;
			memcpy(pb->buf + dst_offset, &pixel, pb->bytes_per_pixel);
		}
	}
}

static inline void draw_line(struct pseudobuffer *pb, struct terminal *term, int line)
{
	int pos, bdf_padding, glyph_width, margin_right;
	int col, w, h;
	uint32_t pixel;
	struct color_pair_t color_pair;
	struct cell_t *cellp;

	for (col = term->cols - 1; col >= 0; col--) {
		margin_right = (term->cols - 1 - col) * CELL_WIDTH;

		/* target cell */
		cellp = &term->cells[col + line * term->cols];

		/* draw sixel bitmap */
		if (cellp->has_bitmap) {
			draw_sixel(pb, line, col, cellp->bitmap);
			continue;
		}

		/* copy current color_pair (maybe changed) */
		color_pair = cellp->color_pair;

		/* check wide character or not */
		glyph_width = (cellp->width == HALF) ? CELL_WIDTH: CELL_WIDTH * 2;
		bdf_padding = my_ceil(glyph_width, BITS_PER_BYTE) * BITS_PER_BYTE - glyph_width;
		if (cellp->width == WIDE)
			bdf_padding += CELL_WIDTH;

		/* check cursor positon */
		if ((term->mode & MODE_CURSOR && line == term->cursor.y)
			&& (col == term->cursor.x
			|| (cellp->width == WIDE && (col + 1) == term->cursor.x)
			|| (cellp->width == NEXT_TO_WIDE && (col - 1) == term->cursor.x))) {
			color_pair.fg = DEFAULT_BG;
      //NOTE: draws different cursor based on window focus or not
			//color_pair.bg = (!tty.visible && BACKGROUND_DRAW) ? PASSIVE_CURSOR_COLOR: ACTIVE_CURSOR_COLOR;
			color_pair.bg = ACTIVE_CURSOR_COLOR;
		}

		for (h = 0; h < CELL_HEIGHT; h++) {
			/* if UNDERLINE attribute on, swap bg/fg */
			if ((h == (CELL_HEIGHT - 1)) && (cellp->attribute & attr_mask[ATTR_UNDERLINE]))
				color_pair.bg = color_pair.fg;

			for (w = 0; w < CELL_WIDTH; w++) {
				pos = (term->width - 1 - margin_right - w) * pb->bytes_per_pixel
					+ (line * CELL_HEIGHT + h) * pb->line_length;

				/* set color palette */
				if (cellp->glyphp->bitmap[h] & (0x01 << (bdf_padding + w)))
					pixel = color_list[color_pair.fg];
				else
					pixel = color_list[color_pair.bg];

				/* update copy buffer only */
				memcpy(pb->buf + pos, &pixel, pb->bytes_per_pixel);
			}
		}
	}
	term->line_dirty[line] = ((term->mode & MODE_CURSOR) && term->cursor.y == line) ? true: false;
}

void refresh(struct pseudobuffer *pb, struct terminal *term)
{
	int line;

	if (term->mode & MODE_CURSOR)
		term->line_dirty[term->cursor.y] = true;

	for (line = 0; line < term->lines; line++) {
		if (term->line_dirty[line])
			draw_line(pb, term, line);
	}
}

static struct pseudobuffer *pb_g;
static struct terminal *term_g;
static Texture2D thisTerm;

Texture2D terminalTexture()
{
  return thisTerm;
}

void terminalRender (ssize_t size, uint8_t* buf)
{
  struct gif_t gif;
  uint8_t *capture;

  gif_init(&gif, pb_g->width, pb_g->height);
  capture = (uint8_t *) ecalloc(pb_g->width * pb_g->height, 1);

  parse(term_g, buf, size);
  refresh(pb_g, term_g);
  
  apply_colormap(pb_g, capture);
  putgif(gif.data, capture);
  int sizeXX = endgif(gif.data);

  Image r = LoadImageFromMemory(".gif", gif.image, sizeXX);      // Load image from memory buffer
  UpdateTexture(thisTerm, r.data);

  free(capture);
  free(gif.image);

  UnloadImage(r);

  //TODO: free gif.image !!!! valgrind tests !!!
}

/*
 * This is an implementation of wcwidth() and wcswidth() (defined in
 * IEEE Std 1002.1-2001) for Unicode.
 *
 * http://www.opengroup.org/onlinepubs/007904975/functions/wcwidth.html
 * http://www.opengroup.org/onlinepubs/007904975/functions/wcswidth.html
 *
 * In fixed-width output devices, Latin characters all occupy a single
 * "cell" position of equal width, whereas ideographic CJK characters
 * occupy two such cells. Interoperability between terminal-line
 * applications and (teletype-style) character terminals using the
 * UTF-8 encoding requires agreement on which character should advance
 * the cursor by how many cell positions. No established formal
 * standards exist at present on which Unicode character shall occupy
 * how many cell positions on character terminals. These routines are
 * a first attempt of defining such behavior based on simple rules
 * applied to data provided by the Unicode Consortium.
 *
 * For some graphical characters, the Unicode standard explicitly
 * defines a character-cell width via the definition of the East Asian
 * FullWidth (F), Wide (W), Half-width (H), and Narrow (Na) classes.
 * In all these cases, there is no ambiguity about which width a
 * terminal shall use. For characters in the East Asian Ambiguous (A)
 * class, the width choice depends purely on a preference of backward
 * compatibility with either historic CJK or Western practice.
 * Choosing single-width for these characters is easy to justify as
 * the appropriate long-term solution, as the CJK practice of
 * displaying these characters as double-width comes from historic
 * implementation simplicity (8-bit encoded characters were displayed
 * single-width and 16-bit ones double-width, even for Greek,
 * Cyrillic, etc.) and not any typographic considerations.
 *
 * Much less clear is the choice of width for the Not East Asian
 * (Neutral) class. Existing practice does not dictate a width for any
 * of these characters. It would nevertheless make sense
 * typographically to allocate two character cells to characters such
 * as for instance EM SPACE or VOLUME INTEGRAL, which cannot be
 * represented adequately with a single-width glyph. The following
 * routines at present merely assign a single-cell width to all
 * neutral characters, in the interest of simplicity. This is not
 * entirely satisfactory and should be reconsidered before
 * establishing a formal standard in this area. At the moment, the
 * decision which Not East Asian (Neutral) characters should be
 * represented by double-width glyphs cannot yet be answered by
 * applying a simple rule from the Unicode database content. Setting
 * up a proper standard for the behavior of UTF-8 character terminals
 * will require a careful analysis not only of each Unicode character,
 * but also of each presentation form, something the author of these
 * routines has avoided to do so far.
 *
 * http://www.unicode.org/unicode/reports/tr11/
 *
 * Markus Kuhn -- 2007-05-26 (Unicode 5.0)
 *
 * Permission to use, copy, modify, and distribute this software
 * for any purpose and without fee is hereby granted. The author
 * disclaims all warranties with regard to this software.
 *
 * Latest version: http://www.cl.cam.ac.uk/~mgk25/ucs/wcwidth.c
 */

//#include <wchar.h>

struct interval {
  int first;
  int last;
};

/* auxiliary function for binary search in interval table */
static int bisearch(uint32_t ucs, const struct interval *table, int max) {
  int min = 0;
  int mid;

  if ((int) ucs < table[0].first || (int) ucs > table[max].last)
    return 0;
  while (max >= min) {
    mid = (min + max) / 2;
    if ((int) ucs > table[mid].last)
      min = mid + 1;
    else if ((int) ucs < table[mid].first)
      max = mid - 1;
    else
      return 1;
  }

  return 0;
}


/* The following two functions define the column width of an ISO 10646
 * character as follows:
 *
 *    - The null character (U+0000) has a column width of 0.
 *
 *    - Other C0/C1 control characters and DEL will lead to a return
 *      value of -1.
 *
 *    - Non-spacing and enclosing combining characters (general
 *      category code Mn or Me in the Unicode database) have a
 *      column width of 0.
 *
 *    - SOFT HYPHEN (U+00AD) has a column width of 1.
 *
 *    - Other format characters (general category code Cf in the Unicode
 *      database) and ZERO WIDTH SPACE (U+200B) have a column width of 0.
 *
 *    - Hangul Jamo medial vowels and final consonants (U+1160-U+11FF)
 *      have a column width of 0.
 *
 *    - Spacing characters in the East Asian Wide (W) or East Asian
 *      Full-width (F) category as defined in Unicode Technical
 *      Report #11 have a column width of 2.
 *
 *    - All remaining characters (including all printable
 *      ISO 8859-1 and WGL4 characters, Unicode control characters,
 *      etc.) have a column width of 1.
 *
 * This implementation assumes that uint32_t characters are encoded
 * in ISO 10646.
 */

int mk_wcwidth(uint32_t ucs)
{
  /* sorted list of non-overlapping intervals of non-spacing characters */
  /* generated by "uniset +cat=Me +cat=Mn +cat=Cf -00AD +1160-11FF +200B c" */
  static const struct interval combining[] = {
    { 0x0300, 0x036F }, { 0x0483, 0x0486 }, { 0x0488, 0x0489 },
    { 0x0591, 0x05BD }, { 0x05BF, 0x05BF }, { 0x05C1, 0x05C2 },
    { 0x05C4, 0x05C5 }, { 0x05C7, 0x05C7 }, { 0x0600, 0x0603 },
    { 0x0610, 0x0615 }, { 0x064B, 0x065E }, { 0x0670, 0x0670 },
    { 0x06D6, 0x06E4 }, { 0x06E7, 0x06E8 }, { 0x06EA, 0x06ED },
    { 0x070F, 0x070F }, { 0x0711, 0x0711 }, { 0x0730, 0x074A },
    { 0x07A6, 0x07B0 }, { 0x07EB, 0x07F3 }, { 0x0901, 0x0902 },
    { 0x093C, 0x093C }, { 0x0941, 0x0948 }, { 0x094D, 0x094D },
    { 0x0951, 0x0954 }, { 0x0962, 0x0963 }, { 0x0981, 0x0981 },
    { 0x09BC, 0x09BC }, { 0x09C1, 0x09C4 }, { 0x09CD, 0x09CD },
    { 0x09E2, 0x09E3 }, { 0x0A01, 0x0A02 }, { 0x0A3C, 0x0A3C },
    { 0x0A41, 0x0A42 }, { 0x0A47, 0x0A48 }, { 0x0A4B, 0x0A4D },
    { 0x0A70, 0x0A71 }, { 0x0A81, 0x0A82 }, { 0x0ABC, 0x0ABC },
    { 0x0AC1, 0x0AC5 }, { 0x0AC7, 0x0AC8 }, { 0x0ACD, 0x0ACD },
    { 0x0AE2, 0x0AE3 }, { 0x0B01, 0x0B01 }, { 0x0B3C, 0x0B3C },
    { 0x0B3F, 0x0B3F }, { 0x0B41, 0x0B43 }, { 0x0B4D, 0x0B4D },
    { 0x0B56, 0x0B56 }, { 0x0B82, 0x0B82 }, { 0x0BC0, 0x0BC0 },
    { 0x0BCD, 0x0BCD }, { 0x0C3E, 0x0C40 }, { 0x0C46, 0x0C48 },
    { 0x0C4A, 0x0C4D }, { 0x0C55, 0x0C56 }, { 0x0CBC, 0x0CBC },
    { 0x0CBF, 0x0CBF }, { 0x0CC6, 0x0CC6 }, { 0x0CCC, 0x0CCD },
    { 0x0CE2, 0x0CE3 }, { 0x0D41, 0x0D43 }, { 0x0D4D, 0x0D4D },
    { 0x0DCA, 0x0DCA }, { 0x0DD2, 0x0DD4 }, { 0x0DD6, 0x0DD6 },
    { 0x0E31, 0x0E31 }, { 0x0E34, 0x0E3A }, { 0x0E47, 0x0E4E },
    { 0x0EB1, 0x0EB1 }, { 0x0EB4, 0x0EB9 }, { 0x0EBB, 0x0EBC },
    { 0x0EC8, 0x0ECD }, { 0x0F18, 0x0F19 }, { 0x0F35, 0x0F35 },
    { 0x0F37, 0x0F37 }, { 0x0F39, 0x0F39 }, { 0x0F71, 0x0F7E },
    { 0x0F80, 0x0F84 }, { 0x0F86, 0x0F87 }, { 0x0F90, 0x0F97 },
    { 0x0F99, 0x0FBC }, { 0x0FC6, 0x0FC6 }, { 0x102D, 0x1030 },
    { 0x1032, 0x1032 }, { 0x1036, 0x1037 }, { 0x1039, 0x1039 },
    { 0x1058, 0x1059 }, { 0x1160, 0x11FF }, { 0x135F, 0x135F },
    { 0x1712, 0x1714 }, { 0x1732, 0x1734 }, { 0x1752, 0x1753 },
    { 0x1772, 0x1773 }, { 0x17B4, 0x17B5 }, { 0x17B7, 0x17BD },
    { 0x17C6, 0x17C6 }, { 0x17C9, 0x17D3 }, { 0x17DD, 0x17DD },
    { 0x180B, 0x180D }, { 0x18A9, 0x18A9 }, { 0x1920, 0x1922 },
    { 0x1927, 0x1928 }, { 0x1932, 0x1932 }, { 0x1939, 0x193B },
    { 0x1A17, 0x1A18 }, { 0x1B00, 0x1B03 }, { 0x1B34, 0x1B34 },
    { 0x1B36, 0x1B3A }, { 0x1B3C, 0x1B3C }, { 0x1B42, 0x1B42 },
    { 0x1B6B, 0x1B73 }, { 0x1DC0, 0x1DCA }, { 0x1DFE, 0x1DFF },
    { 0x200B, 0x200F }, { 0x202A, 0x202E }, { 0x2060, 0x2063 },
    { 0x206A, 0x206F }, { 0x20D0, 0x20EF }, { 0x302A, 0x302F },
    { 0x3099, 0x309A }, { 0xA806, 0xA806 }, { 0xA80B, 0xA80B },
    { 0xA825, 0xA826 }, { 0xFB1E, 0xFB1E }, { 0xFE00, 0xFE0F },
    { 0xFE20, 0xFE23 }, { 0xFEFF, 0xFEFF }, { 0xFFF9, 0xFFFB },
    { 0x10A01, 0x10A03 }, { 0x10A05, 0x10A06 }, { 0x10A0C, 0x10A0F },
    { 0x10A38, 0x10A3A }, { 0x10A3F, 0x10A3F }, { 0x1D167, 0x1D169 },
    { 0x1D173, 0x1D182 }, { 0x1D185, 0x1D18B }, { 0x1D1AA, 0x1D1AD },
    { 0x1D242, 0x1D244 }, { 0xE0001, 0xE0001 }, { 0xE0020, 0xE007F },
    { 0xE0100, 0xE01EF }
  };

  /* test for 8-bit control characters */
  if (ucs == 0)
    return 0;
  if (ucs < 32 || (ucs >= 0x7f && ucs < 0xa0))
    return -1;

  /* binary search in table of non-spacing characters */
  if (bisearch(ucs, combining,
	       sizeof(combining) / sizeof(struct interval) - 1))
    return 0;

  /* if we arrive here, ucs is not a combining or C0/C1 control character */

  return 1 + 
    (ucs >= 0x1100 &&
     (ucs <= 0x115f ||                    /* Hangul Jamo init. consonants */
      ucs == 0x2329 || ucs == 0x232a ||
      (ucs >= 0x2e80 && ucs <= 0xa4cf &&
       ucs != 0x303f) ||                  /* CJK ... Yi */
      (ucs >= 0xac00 && ucs <= 0xd7a3) || /* Hangul Syllables */
      (ucs >= 0xf900 && ucs <= 0xfaff) || /* CJK Compatibility Ideographs */
      (ucs >= 0xfe10 && ucs <= 0xfe19) || /* Vertical forms */
      (ucs >= 0xfe30 && ucs <= 0xfe6f) || /* CJK Compatibility Forms */
      (ucs >= 0xff00 && ucs <= 0xff60) || /* Fullwidth Forms */
      (ucs >= 0xffe0 && ucs <= 0xffe6) ||
      (ucs >= 0x20000 && ucs <= 0x2fffd) ||
      (ucs >= 0x30000 && ucs <= 0x3fffd)));
}


int mk_wcswidth(const uint32_t *pwcs, size_t n)
{
  int w, width = 0;

  for (;*pwcs && n-- > 0; pwcs++)
    if ((w = mk_wcwidth(*pwcs)) < 0)
      return -1;
    else
      width += w;

  return width;
}


/*
 * The following functions are the same as mk_wcwidth() and
 * mk_wcswidth(), except that spacing characters in the East Asian
 * Ambiguous (A) category as defined in Unicode Technical Report #11
 * have a column width of 2. This variant might be useful for users of
 * CJK legacy encodings who want to migrate to UCS without changing
 * the traditional terminal character-width behaviour. It is not
 * otherwise recommended for general use.
 */
int mk_wcwidth_cjk(uint32_t ucs)
{
  /* sorted list of non-overlapping intervals of East Asian Ambiguous
   * characters, generated by "uniset +WIDTH-A -cat=Me -cat=Mn -cat=Cf c" */
  static const struct interval ambiguous[] = {
    { 0x00A1, 0x00A1 }, { 0x00A4, 0x00A4 }, { 0x00A7, 0x00A8 },
    { 0x00AA, 0x00AA }, { 0x00AE, 0x00AE }, { 0x00B0, 0x00B4 },
    { 0x00B6, 0x00BA }, { 0x00BC, 0x00BF }, { 0x00C6, 0x00C6 },
    { 0x00D0, 0x00D0 }, { 0x00D7, 0x00D8 }, { 0x00DE, 0x00E1 },
    { 0x00E6, 0x00E6 }, { 0x00E8, 0x00EA }, { 0x00EC, 0x00ED },
    { 0x00F0, 0x00F0 }, { 0x00F2, 0x00F3 }, { 0x00F7, 0x00FA },
    { 0x00FC, 0x00FC }, { 0x00FE, 0x00FE }, { 0x0101, 0x0101 },
    { 0x0111, 0x0111 }, { 0x0113, 0x0113 }, { 0x011B, 0x011B },
    { 0x0126, 0x0127 }, { 0x012B, 0x012B }, { 0x0131, 0x0133 },
    { 0x0138, 0x0138 }, { 0x013F, 0x0142 }, { 0x0144, 0x0144 },
    { 0x0148, 0x014B }, { 0x014D, 0x014D }, { 0x0152, 0x0153 },
    { 0x0166, 0x0167 }, { 0x016B, 0x016B }, { 0x01CE, 0x01CE },
    { 0x01D0, 0x01D0 }, { 0x01D2, 0x01D2 }, { 0x01D4, 0x01D4 },
    { 0x01D6, 0x01D6 }, { 0x01D8, 0x01D8 }, { 0x01DA, 0x01DA },
    { 0x01DC, 0x01DC }, { 0x0251, 0x0251 }, { 0x0261, 0x0261 },
    { 0x02C4, 0x02C4 }, { 0x02C7, 0x02C7 }, { 0x02C9, 0x02CB },
    { 0x02CD, 0x02CD }, { 0x02D0, 0x02D0 }, { 0x02D8, 0x02DB },
    { 0x02DD, 0x02DD }, { 0x02DF, 0x02DF }, { 0x0391, 0x03A1 },
    { 0x03A3, 0x03A9 }, { 0x03B1, 0x03C1 }, { 0x03C3, 0x03C9 },
    { 0x0401, 0x0401 }, { 0x0410, 0x044F }, { 0x0451, 0x0451 },
    { 0x2010, 0x2010 }, { 0x2013, 0x2016 }, { 0x2018, 0x2019 },
    { 0x201C, 0x201D }, { 0x2020, 0x2022 }, { 0x2024, 0x2027 },
    { 0x2030, 0x2030 }, { 0x2032, 0x2033 }, { 0x2035, 0x2035 },
    { 0x203B, 0x203B }, { 0x203E, 0x203E }, { 0x2074, 0x2074 },
    { 0x207F, 0x207F }, { 0x2081, 0x2084 }, { 0x20AC, 0x20AC },
    { 0x2103, 0x2103 }, { 0x2105, 0x2105 }, { 0x2109, 0x2109 },
    { 0x2113, 0x2113 }, { 0x2116, 0x2116 }, { 0x2121, 0x2122 },
    { 0x2126, 0x2126 }, { 0x212B, 0x212B }, { 0x2153, 0x2154 },
    { 0x215B, 0x215E }, { 0x2160, 0x216B }, { 0x2170, 0x2179 },
    { 0x2190, 0x2199 }, { 0x21B8, 0x21B9 }, { 0x21D2, 0x21D2 },
    { 0x21D4, 0x21D4 }, { 0x21E7, 0x21E7 }, { 0x2200, 0x2200 },
    { 0x2202, 0x2203 }, { 0x2207, 0x2208 }, { 0x220B, 0x220B },
    { 0x220F, 0x220F }, { 0x2211, 0x2211 }, { 0x2215, 0x2215 },
    { 0x221A, 0x221A }, { 0x221D, 0x2220 }, { 0x2223, 0x2223 },
    { 0x2225, 0x2225 }, { 0x2227, 0x222C }, { 0x222E, 0x222E },
    { 0x2234, 0x2237 }, { 0x223C, 0x223D }, { 0x2248, 0x2248 },
    { 0x224C, 0x224C }, { 0x2252, 0x2252 }, { 0x2260, 0x2261 },
    { 0x2264, 0x2267 }, { 0x226A, 0x226B }, { 0x226E, 0x226F },
    { 0x2282, 0x2283 }, { 0x2286, 0x2287 }, { 0x2295, 0x2295 },
    { 0x2299, 0x2299 }, { 0x22A5, 0x22A5 }, { 0x22BF, 0x22BF },
    { 0x2312, 0x2312 }, { 0x2460, 0x24E9 }, { 0x24EB, 0x254B },
    { 0x2550, 0x2573 }, { 0x2580, 0x258F }, { 0x2592, 0x2595 },
    { 0x25A0, 0x25A1 }, { 0x25A3, 0x25A9 }, { 0x25B2, 0x25B3 },
    { 0x25B6, 0x25B7 }, { 0x25BC, 0x25BD }, { 0x25C0, 0x25C1 },
    { 0x25C6, 0x25C8 }, { 0x25CB, 0x25CB }, { 0x25CE, 0x25D1 },
    { 0x25E2, 0x25E5 }, { 0x25EF, 0x25EF }, { 0x2605, 0x2606 },
    { 0x2609, 0x2609 }, { 0x260E, 0x260F }, { 0x2614, 0x2615 },
    { 0x261C, 0x261C }, { 0x261E, 0x261E }, { 0x2640, 0x2640 },
    { 0x2642, 0x2642 }, { 0x2660, 0x2661 }, { 0x2663, 0x2665 },
    { 0x2667, 0x266A }, { 0x266C, 0x266D }, { 0x266F, 0x266F },
    { 0x273D, 0x273D }, { 0x2776, 0x277F }, { 0xE000, 0xF8FF },
    { 0xFFFD, 0xFFFD }, { 0xF0000, 0xFFFFD }, { 0x100000, 0x10FFFD }
  };

  /* binary search in table of non-spacing characters */
  if (bisearch(ucs, ambiguous,
	       sizeof(ambiguous) / sizeof(struct interval) - 1))
    return 2;

  return mk_wcwidth(ucs);
}


int mk_wcswidth_cjk(const uint32_t *pwcs, size_t n)
{
  int w, width = 0;

  for (;*pwcs && n-- > 0; pwcs++)
    if ((w = mk_wcwidth_cjk(*pwcs)) < 0)
      return -1;
    else
      width += w;

  return width;
}



void setupTerminal()
{

  uint16_t rows = TERM_ROWS, cols = TERM_COLS;

  updateWindowSize(rows, cols);

  bool ambiguous_is_wide = false;
  my_wcwidth = (ambiguous_is_wide) ? mk_wcwidth_cjk: mk_wcwidth;

  pb_g =  malloc(sizeof(struct pseudobuffer));
  term_g = malloc(sizeof(struct terminal));

  // init 
  pb_init(pb_g, CELL_WIDTH * cols, CELL_HEIGHT * rows);
  term_init(term_g, pb_g->width, pb_g->height, ambiguous_is_wide);

  struct gif_t gif;

  gif_init(&gif, pb_g->width, pb_g->height);
  uint8_t *capture;
  capture = (uint8_t *) ecalloc(pb_g->width * pb_g->height, 1);
  refresh(pb_g, term_g);
  apply_colormap(pb_g, capture);
  putgif(gif.data, capture);
  int sizeXX = endgif(gif.data);

  Image r = LoadImageFromMemory(".gif", gif.image, sizeXX);      // Load image from memory buffer
  thisTerm = LoadTextureFromImage(r);

  free(capture);
  free(gif.image);
  UnloadImage(r);

  //TODO: !!!!
  //term_die(&term);
  //pb_die(&pb);
}


int main(int argc, char** argv) {
  mrb_state *mrb;
  mrb_state *mrb_client;
  int i;

  //SetTraceLogLevel(LOG_TRACE); //raylib TRACELOG
  SetTraceLogLevel(LOG_FATAL); //raylib TRACELOG

  // initialize mruby serverside
  if (!(mrb = mrb_open())) {
    fprintf(stderr, "%s: could not initialize mruby\n",argv[0]);
    return -1;
  }

  // initialize mruby clientside
  if (!(mrb_client = mrb_open())) {
    fprintf(stderr, "%s: could not initialize mruby client\n",argv[0]);
    return -1;
  }

  mrb_value args = mrb_ary_new(mrb_client);
  mrb_value args_server = mrb_ary_new(mrb);

  // convert argv into mruby strings
  for (i=1; i<argc; i++) {
    mrb_ary_push(mrb_client, args, mrb_str_new_cstr(mrb_client, argv[i]));
    mrb_ary_push(mrb, args_server, mrb_str_new_cstr(mrb, argv[i]));
    fprintf(stderr, "argv %s\n", argv[i]);
  }

  mrb_define_global_const(mrb, "ARGV", args_server);
  mrb_define_global_const(mrb_client, "ARGV", args);

  eval_static_libs(mrb, globals, NULL);

  eval_static_libs(mrb_client, globals, NULL);


  //TODO: vt100 tty support for inline IDE
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

  eval_static_libs(mrb, markaby, NULL);

  eval_static_libs(mrb, stack_blocker, NULL);
  eval_static_libs(mrb, game_loop, NULL);

  eval_static_libs(mrb_client, stack_blocker, NULL);
  eval_static_libs(mrb_client, game_loop, NULL);
  eval_static_libs(mrb_client, camera, NULL);
  eval_static_libs(mrb_client, aabb, NULL);
  eval_static_libs(mrb_client, polygon, NULL);

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

  //TODO: inline vt100 tty
  //mrb_define_method(mrb_client, socket_stream_class_client, "write_tty", socket_stream_unpack_inbound_tty, MRB_ARGS_REQ(1));

  eval_static_libs(mrb_client, socket_stream, NULL);

  struct RClass *client_side_top_most_thor = mrb_define_class(mrb_client, "ClientSide", thor_class_client);

  mrb_mruby_model_gem_init(mrb);
  mrb_mruby_model_gem_init(mrb_client);

#ifdef TARGET_HEAVY

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

  mrb_define_class_method(mrb, thor_class, "log!", wkndr_log, MRB_ARGS_REQ(1));
  mrb_define_class_method(mrb_client, thor_class_client, "log!", wkndr_log, MRB_ARGS_REQ(1));

  mrb_value retret_stack_server = eval_static_libs(mrb, server_side, NULL);

  mrb_funcall(mrb, mrb_obj_value(server_side_top_most_thor), "startup_serverside", 1, args_server);
  if (mrb->exc) {
    fprintf(stderr, "Exception in SERVERSTARTUP\n");
    mrb_print_error_XXX(mrb);
    mrb_print_backtrace(mrb);
  }

#endif

  mrb_value retret_stack = eval_static_libs(mrb_client, client_side, NULL);

  mrb_funcall(mrb_client, mrb_obj_value(client_side_top_most_thor), "startup_clientside", 1, args);
  if (mrb_client->exc) {
    fprintf(stderr, "Exception in CLIENTSTARTUP\n");
    mrb_print_error_XXX(mrb_client);
    mrb_print_backtrace(mrb_client);
  }

#ifdef TARGET_HEAVY

  mrb_funcall(mrb, mrb_obj_value(server_side_top_most_thor), "block!", 0, 0);
  if (mrb->exc) {
    //THIS IS EXCEPTION ON SERVER SIDE!!!
    fprintf(stderr, "Exception in SERVERBLOCKINIT\n");
    mrb_print_error_XXX(mrb);
  }

#endif

#ifdef PLATFORM_WEB

  mrb_funcall(mrb_client, mrb_obj_value(client_side_top_most_thor), "wizbang!", 0, 0);
  if (mrb_client->exc) {
    fprintf(stderr, "Exception in CLIENTBLOCK\n");
    mrb_print_error_XXX(mrb_client);
    mrb_print_backtrace(mrb_client);
  }

#endif

  mrb_close(mrb);
  mrb_close(mrb_client);

  //TODO: inline vt100 support
  ////NOTE: when libuv binds to fd=0 it sets modes that cause /usr/bin/read to break
  //fcntl(0, F_SETFL, fcntl(0, F_GETFL) & ~O_NONBLOCK);

  fprintf(stderr, "exiting ... \n");

  return 33;
}
