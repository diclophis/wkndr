// simple mruby/raylib game

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <pty.h>

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

#include <string.h>
#include <openssl/sha.h>
#include <mruby/string.h>
#include <b64/cencode.h>

#include "server.h"

// The Sec-WebSocket-Accept part is interesting.
// The server must derive it from the Sec-WebSocket-Key that the client sent.
// To get it, concatenate the client's Sec-WebSocket-Key and "258EAFA5-E914-47DA-95CA-C5AB0DC85B11" together
// (it's a "magic string"), take the SHA-1 hash of the result, and return the base64 encoding of the hash.
#define WS_GUID "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
#define E_WEBSOCKET_ERROR mrb_class_get_under(mrb, mrb_module_get(mrb, "WebSocket"), "Error")
static mrb_value mrb_websocket_create_accept(mrb_state *mrb, mrb_value self) {
  char *client_key;
  mrb_int client_key_len;

  mrb_get_args(mrb, "s", &client_key, &client_key_len);

  if (client_key_len != 24) {
    mrb_raise(mrb, E_WEBSOCKET_ERROR, "wrong client key len");
  }

  uint8_t key_src[60];
  memcpy(key_src, client_key, 24);
  memcpy(key_src+24, WS_GUID, 36);

  uint8_t sha1buf[20];
  if (!SHA1((const unsigned char *) key_src, 60, sha1buf)) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "SHA1 failed");
  }

  mrb_value accept_key = mrb_str_new(mrb, NULL, 28);
  char *c = RSTRING_PTR(accept_key);
  base64_encodestate s;
  base64_init_encodestate(&s);
  c += base64_encode_block((const char *) sha1buf, 20, c, &s);
  base64_encode_blockend(c, &s);

  return accept_key;
}

static void if_exception_error_and_exit(mrb_state* mrb, char *context) {
  // check for exception, only one can exist at any point in time
  if (mrb->exc) {
    fprintf(stderr, "Exception in %s", context);
    mrb_print_error(mrb);
    exit(2);
  }
}


static void eval_static_libs(mrb_state* mrb, ...) {
  va_list argp;
  va_start(argp, mrb);

  int end_of_static_libs = 0;
  uint8_t const *p;

  while(!end_of_static_libs) {
    p = va_arg(argp, uint8_t const*);
    if (NULL == p) {
      end_of_static_libs = 1;
    } else {
      mrb_load_irep(mrb, p);
      if_exception_error_and_exit(mrb, "bundled ruby static lib\n");
    }
  }

  va_end(argp);
}



static mrb_value pty_getpty(mrb_state* mrb, mrb_value self)
{
    //mrb_value res;
    //struct pty_info info;
    //struct pty_info thinfo;

  struct winsize w = {21, 82, 0, 0};

  int master;
  int slave;

  if (openpty(&master, &slave, NULL, NULL, &w) < 0) {
    exit(1);
  }

  //master = posix_openpt(O_RDWR);

  setsid();

  //if (ioctl(slave, TIOCSCTTY, NULL) < 0) {
  //  exit(1);
  //}




  // Temporarily redirect stdout to the slave, so that the command executed in
  // the subprocess will write to the slave.
  //int _stdout = dup(STDOUT_FILENO);
  //dup2(slave, STDOUT_FILENO);


/*
    rb_io_t *wfptr,*rfptr;
    VALUE rport = rb_obj_alloc(rb_cFile);
    VALUE wport = rb_obj_alloc(rb_cFile);
    char SlaveName[DEVICELEN];
    MakeOpenFile(rport, rfptr);
    MakeOpenFile(wport, wfptr);
    establishShell(argc, argv, &info, SlaveName);
    rfptr->mode = rb_io_mode_flags("r");
    rfptr->f = fdopen(info.fd, "r");
    rfptr->path = strdup(SlaveName);
    wfptr->mode = rb_io_mode_flags("w") | FMODE_SYNC;
    wfptr->f = fdopen(dup(info.fd), "w");
    wfptr->path = strdup(SlaveName);
    res = rb_ary_new2(3);
    rb_ary_store(res,0,(VALUE)rport);
    rb_ary_store(res,1,(VALUE)wport);
    rb_ary_store(res,2,INT2FIX(info.child_pid));
    thinfo.thread = rb_thread_create(pty_syswait, (void*)&info);
    thinfo.child_pid = info.child_pid;
    rb_thread_schedule();
    if (rb_block_given_p()) {
	rb_ensure(rb_yield, res, pty_finalize_syswait, (VALUE)&thinfo);
	return Qnil;
    }
    return res;
*/

  return mrb_fixnum_value(master);
}


int main(int argc, char** argv) {
  mrb_state *mrb;
  struct mrb_parser_state *ret;

  // initialize mruby
  if (!(mrb = mrb_open())) {
    fprintf(stderr,"%s: could not initialize mruby\n",argv[0]);
    return -1;
  }

  mrb_value args = mrb_ary_new(mrb);
  int i;

  // convert argv into mruby strings
  for (i=1; i<argc; i++) {
     mrb_ary_push(mrb, args, mrb_str_new_cstr(mrb,argv[i]));
  }

  struct RClass *websocket_mod = mrb_define_module(mrb, "WebSocket");
  mrb_define_class_under(mrb, websocket_mod, "Error", E_RUNTIME_ERROR);
  mrb_define_module_function(mrb, websocket_mod, "create_accept", mrb_websocket_create_accept, MRB_ARGS_REQ(1));


  struct RClass *cPTY = mrb_define_module(mrb, "PTY");
  mrb_define_module_function(mrb, cPTY, "getpty", pty_getpty, MRB_ARGS_NONE());

  mrb_define_global_const(mrb, "ARGV", args);

  eval_static_libs(mrb, server, NULL);

  mrb_close(mrb);

  fprintf(stderr, "exiting ... \n");

  return 0;
}
