// stdlib stuff
#define _XOPEN_SOURCE 600

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <pty.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include <unistd.h>
#include <fcntl.h>
#include <utmp.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <pwd.h>



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
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
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
#include <mruby/string.h>
#include <mruby/hash.h>
#include <string.h>


// raylib stuff
#define RAYGUI_IMPLEMENTATION
#include <raylib.h>
#include <raymath.h>
#include <raygui.h>


// kit1zx stuff
#include "box.h"
#include "globals.h"
#include "platform_bits.h"
#include "game_loop.h"
#include "main_menu.h"
#include "socket_stream.h"
#include "window.h"
#include "thor.h"
#include "stack_blocker.h"
#include "start.h"
#include "client.h"
#include "wkndr.h"


//server stuff
#ifdef PLATFORM_DESKTOP

#include <openssl/sha.h>
#include <mruby/string.h>
#include <b64/cencode.h>
#include "base.h"
#include "kube.h"
#include "connection.h"
#include "server.h"
#include "uv_io.h"
#include "wslay_socket_stream.h"

#endif


// emscripten/wasm stuff
#ifdef PLATFORM_WEB
  #include <emscripten/emscripten.h>
  #include <emscripten/html5.h>
#endif


// other stuff
#define FLT_MAX 3.40282347E+38F


typedef struct {
  Camera3D camera;
  Camera2D cameraTwo;
  RenderTexture2D buffer_target;
  Vector2 mousePosition;
} play_data_s;


typedef struct {
  float angle;
  Vector3 position;
  Vector3 rotation;
  Vector3 scale;
  Texture2D texture;
  Color color;
  Color label_color;
  Mesh mesh;
  Model model;
} model_data_s;

typedef struct {
 mrb_state* mrb_pointer;
 struct RObject* self_pointer;
} loop_data_s;


static void play_data_destructor(mrb_state *mrb, void *p_);
static void model_data_destructor(mrb_state *mrb, void *p_);

const struct mrb_data_type play_data_type = {"play_data", play_data_destructor};
const struct mrb_data_type model_data_type = {"model_data", model_data_destructor};

static int counter = 0;
static mrb_value mousexyz;
static mrb_value pressedkeys;


#ifdef PLATFORM_WEB

EMSCRIPTEN_KEEPALIVE
size_t debug_print(mrb_state* mrb, struct RObject* selfP, const char* buf, size_t n) {
  //mrb_value cstrlikebuf = mrb_str_new(mrb, buf, n);
  mrb_value empty_string = mrb_str_new_lit(mrb, "");
  mrb_value clikestr_as_string = mrb_str_cat(mrb, empty_string, buf, n);
  mrb_funcall(mrb, mrb_obj_value(selfP), "process", 1, clikestr_as_string);
  return 0;
}

EMSCRIPTEN_KEEPALIVE
size_t pack_outbound_tty(mrb_state* mrb, struct RObject* selfP, const char* buf, size_t n) {
  mrb_value empty_string = mrb_str_new_lit(mrb, "");
  mrb_value clikestr_as_string = mrb_str_cat(mrb, empty_string, buf, n);

  /*
  mrb_value outbound_tty_msg = mrb_ary_new(mrb);
  mrb_ary_push(mrb, outbound_tty_msg, mrb_fixnum_value(0));
  mrb_ary_push(mrb, outbound_tty_msg, clikestr_as_string);
  mrb_ary_push(mrb, outbound_tty_msg, empty_string);
  */

  mrb_value outbound_tty_msg = mrb_hash_new(mrb);
  mrb_hash_set(mrb, outbound_tty_msg, mrb_fixnum_value(0), clikestr_as_string);
  
  mrb_funcall(mrb, mrb_obj_value(selfP), "write_typed", 1, outbound_tty_msg);

  //mrb_free(mrb, mrb_obj_ptr(outbound_tty_msg));

  return 0;
}


EMSCRIPTEN_KEEPALIVE
size_t resize_tty(mrb_state* mrb, struct RObject* selfP, int cols, int rows, int w, int h) {

  mrb_value outbound_resize_msg = mrb_ary_new(mrb);
  mrb_ary_push(mrb, outbound_resize_msg, mrb_fixnum_value(cols));
  mrb_ary_push(mrb, outbound_resize_msg, mrb_fixnum_value(rows));
  mrb_ary_push(mrb, outbound_resize_msg, mrb_fixnum_value(w));
  mrb_ary_push(mrb, outbound_resize_msg, mrb_fixnum_value(h));

  mrb_value outbound_msg = mrb_hash_new(mrb);
  mrb_hash_set(mrb, outbound_msg, mrb_fixnum_value(3), outbound_resize_msg);
  
  mrb_funcall(mrb, mrb_obj_value(selfP), "write_typed", 1, outbound_msg);

  if (IsWindowReady()) {
    SetWindowSize(w, h);
  }

  //TODO: set window size here
  //mrb_iv_set(
  //    mrb, , mrb_intern_lit(mrb, "@pointer"), // set @data
  //    mrb_obj_value(                           // with value hold in struct
  //        Data_Wrap_Struct(mrb, mrb->object_class, &play_data_type, p_data)));

  return 0;
}


EMSCRIPTEN_KEEPALIVE
size_t socket_connected(mrb_state* mrb, struct RObject* selfP, const char* buf, size_t n) {
  mrb_value empty_string = mrb_str_new_lit(mrb, "");
  mrb_value clikestr_as_string = mrb_str_cat(mrb, empty_string, buf, n);

  /*
  mrb_value outbound_tty_msg = mrb_ary_new(mrb);
  mrb_ary_push(mrb, outbound_tty_msg, mrb_fixnum_value(0));
  mrb_ary_push(mrb, outbound_tty_msg, clikestr_as_string);
  mrb_ary_push(mrb, outbound_tty_msg, empty_string);
  */

  mrb_funcall(mrb, mrb_obj_value(selfP), "did_connect", 1, clikestr_as_string);

  //mrb_free(mrb, mrb_obj_ptr(outbound_tty_msg));

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

mrb_value socket_stream_unpack_inbound_tty(mrb_state* mrb, mrb_value self) {
  mrb_value tty_output;
  mrb_value data_value;

  mrb_get_args(mrb, "o", &tty_output);

  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@client"));

#ifdef PLATFORM_WEB
  mrb_int fp = mrb_int(mrb, data_value);
  void (*write_packed_pointer)(int, const void*, int) = (void (*)(int, const void*, int))fp;
  const char *foo = mrb_string_value_ptr(mrb, tty_output);
  //const char *foo = mrb_string_value_cstr(mrb, &tty_output);
  int len = mrb_string_value_len(mrb, tty_output);

  //mrb_p(mrb, tty_output);

  write_packed_pointer(0, foo, len);

  mrb_free(mrb, mrb_obj_ptr(tty_output));

#endif

//#ifdef PLATFORM_WEB
//  EM_ASM_({
//    window.unpack_inbound_tty(Pointer_stringify($0, $1)); //Pointer_stringify($0, $1)); // Convert message to JS string
//  }, foo, len);
//#endif

  return mrb_nil_value();
}

mrb_value socket_stream_connect(mrb_state* mrb, mrb_value self) {
  long int write_packed_pointer = 0;

#ifdef PLATFORM_WEB
  write_packed_pointer = EM_ASM_INT({
    return window.startConnection($0, $1);
  }, mrb, mrb_obj_ptr(self));
#endif

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


static mrb_value platform_bits_update(mrb_state* mrb, mrb_value self) {
#ifdef PLATFORM_DESKTOP
  //fprintf(stderr, "shouldclose???\n");
  //if (WindowShouldClose()) {
  //  fprintf(stderr, "halt!!!!!!???\n");
  //  mrb_funcall(mrb, self, "halt!", 0, NULL);
  //  return mrb_nil_value();
  //}
#endif

  double time;
  float dt;

  time = GetTime();
  dt = GetFrameTime();

  //self is instance of StackBlocker.new !!!!!!!!!!
  mrb_funcall(mrb, self, "update", 2, mrb_float_value(mrb, time), mrb_float_value(mrb, dt));

  return mrb_nil_value();
}


void platform_bits_update_void(void* arg) {
  loop_data_s* loop_data = arg;

  mrb_state* mrb = loop_data->mrb_pointer;
  struct RObject* self = loop_data->self_pointer;
  mrb_value selfV = mrb_obj_value(self);

  platform_bits_update(mrb, selfV);
}


mrb_value global_show(mrb_state* mrb, mrb_value self) {
  //TODO: FOOO lols
  //SetCameraMode(global_p_data->camera, CAMERA_FIRST_PERSON);

#ifdef PLATFORM_WEB
  mrb_value window_self;

  mrb_get_args(mrb, "o", &window_self);

  loop_data_s* loop_data = (loop_data_s*)malloc(sizeof(loop_data_s));
  loop_data->mrb_pointer = mrb;
  loop_data->self_pointer = mrb_obj_ptr(window_self);

  emscripten_sample_gamepad_data();

  emscripten_set_main_loop_arg(platform_bits_update_void, loop_data, 0, 1);
#endif

  return self;
}


mrb_value global_parse(mrb_state* mrb, mrb_value self) {
  mrb_value mruby_code;

  mrb_get_args(mrb, "o", &mruby_code);

  const char *foo = mrb_string_value_cstr(mrb, &mruby_code);
  int len = mrb_string_value_len(mrb, mruby_code);

  fprintf(stderr, "gonna parse this %d\n", len);

  //mrbc_context *detective_file = mrbc_context_new(mrb);
  //mrbc_filename(mrb, detective_file, "Wkndrfile");
  mrb_value ret;
  //ret = mrb_load_nstring_cxt(mrb, foo, len, detective_file);
  //ret = mrb_load_string(mrb, foo);
  ret = mrb_load_string(mrb, "");
  //ret = mrb_load_string_cxt(mrb, "", detective_file);
  fprintf(stderr, "DONNNNNE %d\n", len);

  if (mrb->exc) {
    fprintf(stderr, "Exception in XXX");
    mrb_print_error(mrb);
  }
  //mrbc_context_free(mrb, detective_file);

  fprintf(stderr, "BIIIIP %d\n", len);

  return mrb_fixnum_value(len);
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


// Garbage collector handler, for play_data struct
// if play_data contains other dynamic data, free it too!
// Check it with GC.start
static void play_data_destructor(mrb_state *mrb, void *p_) {
  play_data_s *pd = (play_data_s *)p_;

  //TODO: memory leak!!!!
  //UnloadRenderTexture(pd->buffer_target);     // Unload texture

  mrb_free(mrb, pd);
};


static mrb_value game_loop_mousep(mrb_state* mrb, mrb_value self)
{
  mrb_value block;
  mrb_get_args(mrb, "&", &block);

  play_data_s *p_data = NULL;
  mrb_value data_value; // this IV holds the data

  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &play_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  RayHitInfo nearestHit;
  char *hitObjectName = "None";
  nearestHit.distance = FLT_MAX;
  nearestHit.hit = false;
  Color cursorColor = WHITE;

  Ray ray; // Picking ray

  ray = GetMouseRay(p_data->mousePosition, p_data->camera);

  // Check ray collision aginst ground plane
  RayHitInfo groundHitInfo = GetCollisionRayGround(ray, 0.0f);

  if ((groundHitInfo.hit) && (groundHitInfo.distance < nearestHit.distance))
  {
    nearestHit = groundHitInfo;

    mrb_ary_set(mrb, mousexyz, 0, mrb_float_value(mrb, nearestHit.position.x));
    mrb_ary_set(mrb, mousexyz, 1, mrb_float_value(mrb, nearestHit.position.y));
    mrb_ary_set(mrb, mousexyz, 2, mrb_float_value(mrb, nearestHit.position.z));

    return mrb_yield_argv(mrb, block, 3, &mousexyz);
  } else {
    return mrb_nil_value();
  }
}


static mrb_value game_loop_keyspressed(mrb_state* mrb, mrb_value self)
{
  //mrb_ary_set(mrb, pressedkeys, 0, mrb_nil_value());
  //mrb_ary_set(mrb, pressedkeys, 1, mrb_nil_value());

  mrb_int argc;
  mrb_value *checkkeys;
  mrb_get_args(mrb, "*", &checkkeys, &argc);

  play_data_s *p_data = NULL;
  mrb_value data_value; // this IV holds the data

  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &play_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  int rc = 0;

  mrb_ary_clear(mrb, pressedkeys);

  for (int i=0; i<argc; i++) {
    mrb_value key_to_check = checkkeys[i];

    if (IsKeyDown(mrb_int(mrb, key_to_check))) {
      mrb_ary_set(mrb, pressedkeys, rc, key_to_check);
      rc++;
    }
  }

  return pressedkeys;
}


static mrb_value game_loop_initialize(mrb_state* mrb, mrb_value self)
{
  play_data_s *p_data;

  p_data = malloc(sizeof(play_data_s));
  memset(p_data, 0, sizeof(play_data_s));
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not allocate @data");
  }

  //p_data->buffer_target = LoadRenderTexture(screenWidth, screenHeight);

  mrb_iv_set(
      mrb, self, mrb_intern_lit(mrb, "@pointer"), // set @data
      mrb_obj_value(                           // with value hold in struct
          Data_Wrap_Struct(mrb, mrb->object_class, &play_data_type, p_data)));

  return self;
}


static mrb_value platform_bits_open(mrb_state* mrb, mrb_value self)
{
  // Initialization
  mrb_value game_name = mrb_nil_value();
  mrb_int screenWidth,screenHeight,screenFps;

  mrb_get_args(mrb, "oiii", &game_name, &screenWidth, &screenHeight, &screenFps);

  const char *c_game_name = mrb_string_value_cstr(mrb, &game_name);

  SetConfigFlags(FLAG_WINDOW_RESIZABLE);

  InitWindow(screenWidth, screenHeight, c_game_name);

  fprintf(stderr, "InitWindow %d %d\n", screenWidth, screenHeight);

  SetExitKey(0);

//#ifdef PLATFORM_DESKTOP
  //SetWindowPosition((GetMonitorWidth() - GetScreenWidth())/2, ((GetMonitorHeight() - GetScreenHeight())/2)+1);
  //SetWindowMonitor(0);
  SetTargetFPS(screenFps);
//#endif

  return self;
}


static mrb_value model_deltap(mrb_state* mrb, mrb_value self)
{
  mrb_float x,y,z;

  mrb_get_args(mrb, "fff", &x, &y, &z);

  model_data_s *p_data = NULL;
  mrb_value data_value; // this IV holds the data

  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &model_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  p_data->position.x = x;
  p_data->position.y = y;
  p_data->position.z = z;

  return mrb_nil_value();
}


static mrb_value model_deltas(mrb_state* mrb, mrb_value self)
{
  mrb_float x,y,z;

  mrb_get_args(mrb, "fff", &x, &y, &z);

  model_data_s *p_data = NULL;
  mrb_value data_value; // this IV holds the data

  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &model_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  p_data->scale.x = x;
  p_data->scale.y = y;
  p_data->scale.z = z;

  return mrb_nil_value();
}


static mrb_value model_deltar(mrb_state* mrb, mrb_value self)
{
  mrb_float x,y,z,r;

  mrb_get_args(mrb, "ffff", &x, &y, &z, &r);

  model_data_s *p_data = NULL;
  mrb_value data_value; // this IV holds the data

  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &model_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  p_data->rotation.x = x;
  p_data->rotation.y = y;
  p_data->rotation.z = z;
  p_data->angle = r;

  return mrb_nil_value();
}


static mrb_value model_yawpitchroll(mrb_state* mrb, mrb_value self)
{
  mrb_float yaw,pitch,roll;
  mrb_float ox,oy,oz;

  mrb_get_args(mrb, "ffffff", &yaw, &pitch, &roll, &ox, &oy, &oz);

  model_data_s *p_data = NULL;
  mrb_value data_value; // this IV holds the data

  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &model_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  Matrix transform = MatrixIdentity();

  transform = MatrixMultiply(transform, MatrixTranslate(ox, oy, oz));
  transform = MatrixMultiply(transform, MatrixRotateZ(DEG2RAD*roll));
  transform = MatrixMultiply(transform, MatrixRotateX(DEG2RAD*pitch));
  transform = MatrixMultiply(transform, MatrixRotateY(DEG2RAD*yaw));
  transform = MatrixMultiply(transform, MatrixTranslate(-ox, -oy, -oz));

  p_data->model.transform = transform;

  return mrb_nil_value();
}


static mrb_value game_loop_draw_grid(mrb_state* mrb, mrb_value self)
{
  mrb_int a;
  mrb_float b;

  mrb_get_args(mrb, "if", &a, &b);

  DrawGrid(a, b);

  return mrb_nil_value();
}


static mrb_value game_loop_draw_plane(mrb_state* mrb, mrb_value self)
{
  mrb_float x,y,z,a,b;

  mrb_get_args(mrb, "fffff", &x, &y, &z, &a, &b);

  DrawPlane((Vector3){x, y, z}, (Vector2){a, b}, DARKBROWN); // Draw a plane XZ

  return mrb_nil_value();
}


static mrb_value game_loop_draw_fps(mrb_state* mrb, mrb_value self)
{
  mrb_int a,b;

  mrb_get_args(mrb, "ii", &a, &b);

  DrawFPS(a, b);

  return mrb_nil_value();
}


static mrb_value platform_bits_shutdown(mrb_state* mrb, mrb_value self) {
  //TODO: implenent on_shutdown
  //mrb_funcall(mrb, self, "play", 2, mrb_float_value(mrb, time), mrb_float_value(mrb, dt));

  fprintf(stderr, "CloseWindow\n");

  //TODO: move this to window class somehow
  CloseWindow(); // Close window and OpenGL context

  return mrb_true_value();
}


static mrb_value game_loop_lookat(mrb_state* mrb, mrb_value self)
{
  mrb_int type;
  mrb_float px,py,pz,tx,ty,tz,fovy;

  mrb_get_args(mrb, "ifffffff", &type, &px, &py, &pz, &tx, &ty, &tz, &fovy);

  play_data_s *p_data = NULL;
  mrb_value data_value;     // this IV holds the data
  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &play_data_type, p_data);

  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  // Camera mode type
  switch(type) {
    case 0:
      p_data->camera.type = CAMERA_ORTHOGRAPHIC;
      //SetCameraMode(p_data->camera, CAMERA_ORBITAL);
      //SetCameraMode(p_data->camera, CAMERA_THIRD_PERSON);
      break;
    case 1:
      p_data->camera.type = CAMERA_PERSPECTIVE;
      //SetCameraMode(p_data->camera, CAMERA_ORBITAL);
      break;
  }

  // Define the camera to look into our 3d world
  p_data->camera.position = (Vector3){ px, py, pz };    // Camera position
  p_data->camera.target = (Vector3){ tx, ty, tz };      // Camera looking at point

  p_data->camera.up = (Vector3){ 0.0f, 1.0f, 0.0f };    // Camera up vector (rotation towards target)
  p_data->camera.fovy = fovy;                           // Camera field-of-view Y

  p_data->cameraTwo.target = (Vector2){ 0, 0 };
  p_data->cameraTwo.offset = (Vector2){ 0, 0 };
  p_data->cameraTwo.rotation = 0.0f;
  p_data->cameraTwo.zoom = 1.0f;

  return mrb_nil_value();
}


static mrb_value game_loop_first_person(mrb_state* mrb, mrb_value self)
{
  play_data_s *p_data = NULL;
  mrb_value data_value;     // this IV holds the data
  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &play_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  SetCameraMode(p_data->camera, CAMERA_FIRST_PERSON);

  return mrb_nil_value();
}

static mrb_value game_loop_threed(mrb_state* mrb, mrb_value self)
{
  mrb_value block;
  mrb_get_args(mrb, "&", &block);

  play_data_s *p_data = NULL;
  mrb_value data_value;     // this IV holds the data
  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &play_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  UpdateCamera(&p_data->camera);

  BeginMode3D(p_data->camera);

  mrb_yield_argv(mrb, block, 0, NULL);

  EndMode3D();

  //fprintf(stderr, "endmode3\n");

  return mrb_nil_value();
}


static mrb_value game_loop_interim(mrb_state* mrb, mrb_value self)
{
  mrb_value block;
  mrb_get_args(mrb, "&", &block);

  play_data_s *p_data = NULL;
  mrb_value data_value;     // this IV holds the data
  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &play_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  mrb_yield_argv(mrb, block, 0, NULL);

  return mrb_nil_value();
}


static mrb_value game_loop_drawmode(mrb_state* mrb, mrb_value self)
{
  mrb_value block;
  mrb_get_args(mrb, "&", &block);

  play_data_s *p_data = NULL;
  mrb_value data_value;     // this IV holds the data
  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &play_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  BeginDrawing();

  ClearBackground(BLACK);

  mrb_yield_argv(mrb, block, 0, NULL);

  EndDrawing();

  //fprintf(stderr, "end_draw\n");

  return mrb_nil_value();
}


static mrb_value game_loop_twod(mrb_state* mrb, mrb_value self)
{
  mrb_value block;
  mrb_get_args(mrb, "&", &block);

  play_data_s *p_data = NULL;
  mrb_value data_value;     // this IV holds the data
  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &play_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  BeginMode2D(p_data->cameraTwo);

  mrb_yield_argv(mrb, block, 0, NULL);
  
  EndMode2D();

  return mrb_nil_value();
}


static mrb_value game_loop_button(mrb_state* mrb, mrb_value self)
{
  mrb_float a,b,c,d;
  mrb_value label;
  mrb_value block;

  mrb_get_args(mrb, "ffffo&!", &a, &b, &c, &d, &label, &block);

  const char *label_cstr = mrb_string_value_cstr(mrb, &label);

  if (GuiButton((Rectangle){a, b, c, d}, label_cstr)) {
    return mrb_yield_argv(mrb, block, 0, NULL);
  }

  return mrb_nil_value();
}


static mrb_value model_initialize(mrb_state* mrb, mrb_value self)
{
  mrb_value model_obj = mrb_nil_value();
  mrb_value model_png = mrb_nil_value();
  mrb_float scalef;
  mrb_get_args(mrb, "oof", &model_obj, &model_png, &scalef);

  const char *c_model_obj = mrb_string_value_cstr(mrb, &model_obj);
  const char *c_model_png = mrb_string_value_cstr(mrb, &model_png);

  model_data_s *p_data;

  p_data = malloc(sizeof(model_data_s));
  memset(p_data, 0, sizeof(model_data_s));
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not allocate Model");
  }

  p_data->model = LoadModel(c_model_obj); // Load OBJ model

  p_data->position.x = 0.0f;
  p_data->position.y = 0.0f;
  p_data->position.z = 0.0f;

  p_data->rotation.x = 0.0f;
  p_data->rotation.y = 1.0f;
  p_data->rotation.z = 0.0f; // Set model position

  p_data->angle = 0.0;
  
  p_data->texture = LoadTexture(c_model_png); // Load model texture
  p_data->model.material.maps[MAP_DIFFUSE].texture = p_data->texture; // Set map diffuse texture

  //TODO?
  //p_data->model.material.shader = shader;

  p_data->scale.x = scalef;
  p_data->scale.y = scalef;
  p_data->scale.z = scalef;

  p_data->color.r = 255;
  p_data->color.g = 255;
  p_data->color.b = 255;
  p_data->color.a = 255;

  p_data->label_color.r = 255;
  p_data->label_color.g = 255;
  p_data->label_color.b = 255;
  p_data->label_color.a = 255;

  mrb_iv_set(
      mrb, self, mrb_intern_lit(mrb, "@pointer"),
      mrb_obj_value(
          Data_Wrap_Struct(mrb, mrb->object_class, &model_data_type, p_data)));

  return self;
}


static void model_data_destructor(mrb_state *mrb, void *p_) {
  fprintf(stderr, "!!!!!!!!!!! deconstruct!!!\n");

  //TODO
  //mrb_value data_value;
  //data_value = mrb_iv_get(mrb, (mrb_value)p_, mrb_intern_lit(mrb, "@pointer"));

  model_data_s *p_data = p_;

  //Data_Get_Struct(mrb, data_value, &model_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }
  //model_data_s *pd = (model_data_s *)p_;

  //// De-Initialization
  UnloadTexture(p_data->texture);     // Unload texture
  //TODO:
  //UnloadModel(pd->model);         // Unload model

  mrb_free(mrb, p_);
};


static mrb_value model_draw(mrb_state* mrb, mrb_value self)
{
  mrb_bool draw_wires;

  mrb_get_args(mrb, "b", &draw_wires);

  model_data_s *p_data = NULL;
  mrb_value data_value; // this IV holds the data

  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &model_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  if (draw_wires) {
    DrawModelWiresEx(p_data->model, p_data->position, p_data->rotation, p_data->angle, p_data->scale, BLUE);   // Draw 3d model with texture
  } 

  //TODO, mode switch
  //else {
    // Draw 3d model with texture
    DrawModelEx(p_data->model, p_data->position, p_data->rotation, p_data->angle, p_data->scale, p_data->color);
  //}

  return mrb_nil_value();
}


static mrb_value model_label(mrb_state* mrb, mrb_value self)
{
  mrb_value label_txt = mrb_nil_value();
  mrb_value pointer_value;
  mrb_get_args(mrb, "oo", &pointer_value, &label_txt);

  const char *c_label_txt = mrb_string_value_cstr(mrb, &label_txt);

  model_data_s *p_data = NULL;
  mrb_value data_value; // this IV holds the data

  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &model_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  play_data_s *gl_p_data = NULL;

  Data_Get_Struct(mrb, pointer_value, &play_data_type, gl_p_data);
  if (!gl_p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  float textSize = 5.0;

  Vector3 cubePosition = p_data->position;

  Vector2 cubeScreenPosition;
  cubeScreenPosition = GetWorldToScreen((Vector3){cubePosition.x, cubePosition.y, cubePosition.z}, gl_p_data->camera);

  DrawText(c_label_txt, cubeScreenPosition.x - (float)MeasureText(c_label_txt, textSize) / 2.0, cubeScreenPosition.y, textSize, p_data->label_color);

  return mrb_nil_value();
}


static mrb_value cube_initialize(mrb_state* mrb, mrb_value self)
{
  mrb_float w,h,l,scalef;
  mrb_get_args(mrb, "ffff", &w, &h, &l, &scalef);

  model_data_s *p_data;

  p_data = malloc(sizeof(model_data_s));
  memset(p_data, 0, sizeof(model_data_s));
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not allocate Cube");
  }

  p_data->mesh = GenMeshCube(w, h, l);
  p_data->model = LoadModelFromMesh(p_data->mesh);

  p_data->position.x = 0.0f;
  p_data->position.y = 0.0f;
  p_data->position.z = 0.0f;

  p_data->rotation.x = 0.0f;
  p_data->rotation.y = 1.0f;
  p_data->rotation.z = 0.0f; // Set model position
  p_data->angle = 0.0;
  
  p_data->scale.x = scalef;
  p_data->scale.y = scalef;
  p_data->scale.z = scalef;

  float colors = 128.0;
  float freq = 64.0 / colors;

  int r = (sin(freq * abs(counter) + 0.0) * (127.0) + 128.0);
  int g = (sin(freq * abs(counter) + 1.0) * (127.0) + 128.0);
  int b = (sin(freq * abs(counter) + 3.0) * (127.0) + 128.0);

  counter++;

  if (counter == colors) {
    counter *= -1;
  }

  p_data->color.r = r;
  p_data->color.g = g;
  p_data->color.b = b;
  p_data->color.a = 255;

  r = (sin(freq * abs(counter) + 0.0) * (127.0) + 128.0);
  g = (sin(freq * abs(counter) + 1.0) * (127.0) + 128.0);
  b = (sin(freq * abs(counter) + 3.0) * (127.0) + 128.0);

  counter++;

  if (counter == colors) {
    counter *= -1;
  }

  p_data->label_color.r = r;
  p_data->label_color.g = g;
  p_data->label_color.b = b;
  p_data->label_color.a = 255;

  mrb_iv_set(
      mrb, self, mrb_intern_lit(mrb, "@pointer"),
      mrb_obj_value(
          Data_Wrap_Struct(mrb, mrb->object_class, &model_data_type, p_data)));

  return self;
}


static mrb_value sphere_initialize(mrb_state* mrb, mrb_value self)
{
  mrb_float ra,scalef;
  mrb_int ri,sl;
  mrb_get_args(mrb, "fiif", &ra, &ri, &sl, &scalef);

  model_data_s *p_data;

  p_data = malloc(sizeof(model_data_s));
  memset(p_data, 0, sizeof(model_data_s));
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not allocate Sphere");
  }

  p_data->model = LoadModelFromMesh(GenMeshSphere(ra, ri, sl));

  p_data->position.x = 0.0f;
  p_data->position.y = 0.0f;
  p_data->position.z = 0.0f;

  p_data->rotation.x = 0.0f;
  p_data->rotation.y = 1.0f;
  p_data->rotation.z = 0.0f; // Set model position
  p_data->angle = 0.0;
  
  p_data->scale.x = scalef;
  p_data->scale.y = scalef;
  p_data->scale.z = scalef;

  mrb_iv_set(
      mrb, self, mrb_intern_lit(mrb, "@pointer"),
      mrb_obj_value(
          Data_Wrap_Struct(mrb, mrb->object_class, &model_data_type, p_data)));

  return self;
}


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

  mrb_value accept_key = mrb_str_new(mrb, NULL, 28);
  char *c = RSTRING_PTR(accept_key);

#ifdef PLATFORM_DESKTOP
  uint8_t sha1buf[20];
  if (!SHA1((const unsigned char *) key_src, 60, sha1buf)) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "SHA1 failed");
  }

  base64_encodestate s;
  base64_init_encodestate(&s);
  c += base64_encode_block((const char *) sha1buf, 20, c, &s);
  base64_encode_blockend(c, &s);
#endif

  return accept_key;
}


static mrb_value fast_utmp_utmps(mrb_state* mrb, mrb_value self)
{
#ifdef PLATFORM_DESKTOP

  //mrb_value rets = mrb_ary_new(mrb);
  mrb_value outbound_utmp = mrb_hash_new(mrb);

  struct utmp *utmp_buf;
  size_t entries = 0;
  time_t boot_time;

  utmpname(UTMP_FILE);

  setutent();

  while ((utmp_buf = getutent()) != NULL) {
    if (utmp_buf->ut_name[0] && utmp_buf->ut_line[0] && utmp_buf->ut_type == USER_PROCESS) {
      ++entries;

			//mrb_value mrb_login_pid = mrb_fixnum_value(utmp_buf->ut_pid);

      mrb_value empty_string = mrb_str_new_lit(mrb, "");
      mrb_value clikestr_as_string = mrb_str_cat(mrb, empty_string, utmp_buf->ut_line, UT_LINESIZE);
      mrb_funcall(mrb, clikestr_as_string, "strip!", 0);

      mrb_value nempty_string = mrb_str_new_lit(mrb, "");
      mrb_value nclikestr_as_string = mrb_str_cat(mrb, nempty_string, utmp_buf->ut_name, UT_NAMESIZE);
      mrb_funcall(mrb, nclikestr_as_string, "strip!", 0);

      mrb_hash_set(mrb, outbound_utmp, clikestr_as_string, nclikestr_as_string);

      //mrb_ary_push(mrb, rets, outbound_utmp);
    }

    if (utmp_buf->ut_type == BOOT_TIME) {
      boot_time = utmp_buf->ut_time;
    }
  }

  endutent();

  return outbound_utmp;

#else
  return mrb_nil_value();
#endif
}


static mrb_value fast_tty_close(mrb_state* mrb, mrb_value self)
{
  mrb_int a,b;
  mrb_get_args(mrb, "ii", &a, &b);

  //fprintf(stderr, "wtf %d, %d\n", a, b);

  close(a);
  close(b);

  return mrb_nil_value();
}


static mrb_value fast_tty_resize(mrb_state* mrb, mrb_value self)
{
  mrb_int a,cols,rows;
  mrb_get_args(mrb, "iii", &a, &cols, &rows);

  fprintf(stderr, "resize %d %d %d\n", a, cols, rows);
  
  struct winsize w = {rows, cols, 0, 0};

  ioctl(a, TIOCSWINSZ, &w);

  return mrb_true_value();
}


static mrb_value fast_tty_fd(mrb_state* mrb, mrb_value self)
{
#ifdef PLATFORM_DESKTOP
  struct winsize w = {21, 82, 0, 0};

	int fdm, fds, rc;
  static char ptyname[FILENAME_MAX];

	fdm = posix_openpt(O_RDWR);
	//fdm = open("/dev/pts/ptmx", O_RDWR);
	if (fdm < 0)
	{
		fprintf(stderr, "Error %d on posix_openpt()\n", errno);
		return mrb_nil_value();
	}

  ioctl(fdm, TIOCSWINSZ, &w);

	rc = grantpt(fdm);
	if (rc != 0)
	{
		fprintf(stderr, "Error %d on grantpt()\n", errno);
		return mrb_nil_value();
	}

	rc = unlockpt(fdm);
	if (rc != 0)
	{
		fprintf(stderr, "Error %d on unlockpt()\n", errno);
		return mrb_nil_value();
	}

  int foo = FILENAME_MAX;
  ptyname[FILENAME_MAX-1] = '\0';
  
  ptsname_r(fdm, ptyname, foo);

  //strncpy(ptyname, ptsname(fdm, ), FILENAME_MAX-1);
  //ptsname

	//// Open the slave PTY
	fds = open(ptyname, O_RDWR | O_NOCTTY);
	//fds = open(ptyname, O_RDWR);

	//pid_t result = setsid();
	//if (result < 0)
	//{
	//  //fprintf(stderr, "%s\n", explain_setsid());
	//	fprintf(stderr, "Error %d on setsid()\n", errno);
	//	fprintf(stderr, "Error %s on setsid()\n", strerror(errno));
  //}

  //ptsname(fdm), O_RDWR);

  mrb_value rets = mrb_ary_new(mrb);

  mrb_value mrb_mr = mrb_fixnum_value(fdm);
  mrb_value mrb_sl = mrb_fixnum_value(fds);
  mrb_value empty_string = mrb_str_new_cstr(mrb, ptyname);

  mrb_ary_push(mrb, rets, mrb_mr);
  mrb_ary_push(mrb, rets, mrb_sl);
  mrb_ary_push(mrb, rets, empty_string);

  return rets;
#else
  return mrb_nil_value();
#endif
}


int main(int argc, char** argv) {
  mrb_state *mrb;

  // initialize mruby
  if (!(mrb = mrb_open())) {
    fprintf(stderr,"%s: could not initialize mruby\n",argv[0]);
    return -1;
  }

  mousexyz = mrb_ary_new(mrb);
  pressedkeys = mrb_ary_new(mrb);

  mrb_value args = mrb_ary_new(mrb);
  int i;

  // convert argv into mruby strings
  for (i=1; i<argc; i++) {
    fprintf(stderr, "wtf: %s\n", argv[i]);
    mrb_ary_push(mrb, args, mrb_str_new_cstr(mrb, argv[i]));
  }

  mrb_define_global_const(mrb, "ARGV", args);

  struct RClass *fast_utmp = mrb_define_class(mrb, "FastUTMP", mrb->object_class);
  mrb_define_class_method(mrb, fast_utmp, "utmps", fast_utmp_utmps, MRB_ARGS_NONE());

  struct RClass *fast_tty = mrb_define_class(mrb, "FastTTY", mrb->object_class);
  mrb_define_class_method(mrb, fast_tty, "fd", fast_tty_fd, MRB_ARGS_NONE());
  mrb_define_class_method(mrb, fast_tty, "close", fast_tty_close, MRB_ARGS_REQ(2));
  mrb_define_class_method(mrb, fast_tty, "resize", fast_tty_resize, MRB_ARGS_REQ(3));


  struct RClass *websocket_mod = mrb_define_module(mrb, "WebSocket");
  mrb_define_class_under(mrb, websocket_mod, "Error", E_RUNTIME_ERROR);
  mrb_define_module_function(mrb, websocket_mod, "create_accept", mrb_websocket_create_accept, MRB_ARGS_REQ(1));

  // class PlatformBits
  //struct RClass *platform_bits_class = mrb_define_class(mrb, "Window", mrb->object_class);

  struct RClass *stack_blocker_class = mrb_define_class(mrb, "StackBlocker", mrb->object_class);
  mrb_define_method(mrb, stack_blocker_class, "signal", platform_bits_update, MRB_ARGS_NONE());

  // class GameLoop
  struct RClass *game_class = mrb_define_class(mrb, "GameLoop", mrb->object_class);
  mrb_define_method(mrb, game_class, "initialize", game_loop_initialize, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, game_class, "lookat", game_loop_lookat, MRB_ARGS_REQ(8));
  mrb_define_method(mrb, game_class, "first_person!", game_loop_first_person, MRB_ARGS_NONE());
  mrb_define_method(mrb, game_class, "draw_grid", game_loop_draw_grid, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, game_class, "draw_plane", game_loop_draw_plane, MRB_ARGS_REQ(5));
  mrb_define_method(mrb, game_class, "draw_fps", game_loop_draw_fps, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, game_class, "mousep", game_loop_mousep, MRB_ARGS_BLOCK());
  mrb_define_method(mrb, game_class, "keyspressed", game_loop_keyspressed, MRB_ARGS_ANY());
  mrb_define_method(mrb, game_class, "threed", game_loop_threed, MRB_ARGS_BLOCK());
  mrb_define_method(mrb, game_class, "interim", game_loop_interim, MRB_ARGS_BLOCK());
  mrb_define_method(mrb, game_class, "drawmode", game_loop_drawmode, MRB_ARGS_BLOCK());
  mrb_define_method(mrb, game_class, "twod", game_loop_twod, MRB_ARGS_BLOCK());
  mrb_define_method(mrb, game_class, "button", game_loop_button, MRB_ARGS_REQ(5));
  mrb_define_method(mrb, game_class, "open", platform_bits_open, MRB_ARGS_REQ(4));
  mrb_define_method(mrb, game_class, "shutdown", platform_bits_shutdown, MRB_ARGS_NONE());

  // class Model
  struct RClass *model_class = mrb_define_class(mrb, "Model", mrb->object_class);
  mrb_define_method(mrb, model_class, "initialize", model_initialize, MRB_ARGS_REQ(3));
  mrb_define_method(mrb, model_class, "draw", model_draw, MRB_ARGS_NONE());
  mrb_define_method(mrb, model_class, "deltap", model_deltap, MRB_ARGS_REQ(3));
  mrb_define_method(mrb, model_class, "deltar", model_deltar, MRB_ARGS_REQ(4));
  mrb_define_method(mrb, model_class, "deltas", model_deltas, MRB_ARGS_REQ(3));
  mrb_define_method(mrb, model_class, "yawpitchroll", model_yawpitchroll, MRB_ARGS_REQ(6));
  mrb_define_method(mrb, model_class, "label", model_label, MRB_ARGS_REQ(1));

  // class Cube
  struct RClass *cube_class = mrb_define_class(mrb, "Cube", model_class);
  mrb_define_method(mrb, cube_class, "initialize", cube_initialize, MRB_ARGS_REQ(4));

  // class Sphere
  struct RClass *sphere_class = mrb_define_class(mrb, "Sphere", model_class);
  mrb_define_method(mrb, sphere_class, "initialize", sphere_initialize, MRB_ARGS_REQ(4));

  eval_static_libs(mrb, window, NULL);

  eval_static_libs(mrb, thor, NULL);

  eval_static_libs(mrb, wkndr, NULL);

  struct RClass *thor_b_class = mrb_define_class(mrb, "Thor", mrb->object_class);

  struct RClass *thor_class = mrb_define_class(mrb, "Wkndr", thor_b_class);
  mrb_define_class_method(mrb, thor_class, "show!", global_show, MRB_ARGS_REQ(1));
  mrb_define_class_method(mrb, thor_class, "parse!", global_parse, MRB_ARGS_REQ(1));

  struct RClass *socket_stream_class = mrb_define_class(mrb, "SocketStream", mrb->object_class);
  mrb_define_method(mrb, socket_stream_class, "connect!", socket_stream_connect, MRB_ARGS_REQ(0));
  mrb_define_method(mrb, socket_stream_class, "write_packed", socket_stream_write_packed, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, socket_stream_class, "write_tty", socket_stream_unpack_inbound_tty, MRB_ARGS_REQ(1));

  eval_static_libs(mrb, globals, NULL);

  eval_static_libs(mrb, socket_stream, NULL);

  eval_static_libs(mrb, platform_bits, NULL);

  eval_static_libs(mrb, game_loop, NULL);

  eval_static_libs(mrb, main_menu, NULL);

  eval_static_libs(mrb, box, NULL);

  eval_static_libs(mrb, stack_blocker, NULL);


#ifdef PLATFORM_DESKTOP
  eval_static_libs(mrb, base, NULL);
  eval_static_libs(mrb, wslay_socket_stream, uv_io, NULL);
  eval_static_libs(mrb, connection, NULL);
  eval_static_libs(mrb, server, NULL);

#endif

//  if (i == 1) {
//    eval_static_libs(mrb, client, NULL);
//  } else {
//#ifdef PLATFORM_DESKTOP
//    mrb_funcall(mrb, mrb_obj_value(thor_class), "backend", 1, args);
//#endif    
//  }

  if (i == 1) {
    mrb_funcall(mrb, mrb_obj_value(thor_class), "start", 0);
  } else {
    mrb_funcall(mrb, mrb_obj_value(thor_class), "start", 1, args);
  }

  mrb_close(mrb);

  //NOTE: when libuv binds to fd=0 it sets modes that cause /usr/bin/read to break
  fcntl(0, F_SETFL, fcntl(0, F_GETFL) & ~O_NONBLOCK);

  fprintf(stderr, "exiting ... \n");

  return 0;
}
