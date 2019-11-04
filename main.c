// stdlib stuff
#define _XOPEN_SOURCE 600

//#if defined(PLATFORM_DESKTOP)
//    #define GLSL_VERSION            330
//#else   // PLATFORM_RPI, PLATFORM_ANDROID, PLATFORM_WEB
//    #define GLSL_VERSION            100
//#endif

// raylib stuff
#define RAYGUI_IMPLEMENTATION 1

//#define RLGL_IMPLEMENTATION 1
//#define GRAPHICS_API_OPENGL_33 1
//
#if defined(GRAPHICS_API_OPENGL_33)
//    #if defined(__APPLE__)
//        #include <OpenGL/gl3.h>         // OpenGL 3 library for OSX
//        #include <OpenGL/gl3ext.h>      // OpenGL 3 extensions library for OSX
//    #else
//        #if defined(RLGL_STANDALONE)
//            #include "glad.h"           // GLAD extensions loading library, includes OpenGL headers
//        #else
            #include "external/glad.h"  // GLAD extensions loading library, includes OpenGL headers
//        #endif
//    #endif
#endif

#if defined(GRAPHICS_API_OPENGL_ES2)
    #include <EGL/egl.h>                // EGL library
    #include <GLES2/gl2.h>              // OpenGL ES 2.0 library
    #include <GLES2/gl2ext.h>           // OpenGL ES 2.0 extensions library
#endif

#if defined(GRAPHICS_API_OPENGL_ES3)
    #include <EGL/egl.h>                // EGL library
    #include <GLES3/gl3.h>              // OpenGL ES 2.0 library
    #include <GLES3/gl2ext.h>           // OpenGL ES 2.0 extensions library
#endif

#include <raylib.h>
#include <raymath.h>
#include <raygui.h>


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

#if defined(__MACH__) || defined(__APPLE__)
#include <util.h>
#else
#include <pty.h>
#endif

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


// kit1zx stuff
#include "box.h"
#include "markaby.h"
#include "globals.h"
#include "game_loop.h"
#include "main_menu.h"
#include "socket_stream.h"
#include "window.h"
//#include "thor.h"
#include "stack_blocker.h"
#include "client_side.h"
#include "wkndr.h"
#include "theseus.h"


//server stuff
#ifdef TARGET_DESKTOP

#include <openssl/sha.h>
#include <mruby/string.h>
#include <b64/cencode.h>
#include "kube.h"
#include "connection.h"
#include "server.h"
#include "server_side.h"
#include "uv_io.h"
#include "wslay_socket_stream.h"
#include "embed_static.h"
#include "protocol.h"

#endif


// emscripten/wasm stuff
#ifdef PLATFORM_WEB
  #include <emscripten/emscripten.h>
  #include <emscripten/html5.h>
#endif


// other stuff
#define FLT_MAX 3.40282347E+38F


#if defined(__MACH__) || defined(__APPLE__)
int ptsname_r(int fd, char* buf, size_t buflen) {
  char *name = ptsname(fd);
  if (name == NULL) {
    errno = EINVAL;
    return -1;
  }
  if (strlen(name) + 1 > buflen) {
    errno = ERANGE;
    return -1;
  }
  strncpy(buf, name, buflen);
  return 0;
}
#endif


//#define MAX_LIGHTS 1 // Max lights supported by standard shader

//// Light type
//typedef struct LightData {
//    unsigned int id;        // Light unique id
//    bool enabled;           // Light enabled
//    int type;               // Light type: LIGHT_POINT, LIGHT_DIRECTIONAL, LIGHT_SPOT
//
//    Vector3 position;       // Light position
//    Vector3 target;         // Light direction: LIGHT_DIRECTIONAL and LIGHT_SPOT (cone direction target)
//    float radius;           // Light attenuation radius light intensity reduced with distance (world distance)
//
//    Color diffuse;          // Light diffuse color
//    float intensity;        // Light intensity level
//
//    float coneAngle;        // Light cone max angle: LIGHT_SPOT
//} LightData, *Light;
//
//// Light types
//typedef enum { LIGHT_POINT, LIGHT_DIRECTIONAL, LIGHT_SPOT } LightType;
//
////----------------------------------------------------------------------------------
//// Global Variables Definition
////----------------------------------------------------------------------------------
//static Light lights[MAX_LIGHTS];            // Lights pool
//static int lightsCount = 0;                 // Enabled lights counter
//static int lightsLocs[MAX_LIGHTS][8];       // Lights location points in shader: 8 possible points per light: 
//                                            // enabled, type, position, target, radius, diffuse, intensity, coneAngle

//
////----------------------------------------------------------------------------------
//// Module Functions Declaration
////----------------------------------------------------------------------------------
//static Light CreateLight(int type, Vector3 position, Color diffuse); // Create a new light, initialize it and add to pool
//static void DestroyLight(Light light);     // Destroy a light and take it out of the list
//
//static void GetShaderLightsLocations(Shader shader);    // Get shader locations for lights (up to MAX_LIGHTS)
//static void SetShaderLightsValues(Shader shader);       // Set shader uniform values for lights



//----------------------------------------------------------------------------------
// Defines and Macros
//----------------------------------------------------------------------------------
#define         MAX_LIGHTS            4         // Max dynamic lights supported by shader

//----------------------------------------------------------------------------------
// Types and Structures Definition
//----------------------------------------------------------------------------------
// Light data
typedef struct {   
    int type;
    Vector3 position;
    Vector3 target;
    Color color;
    bool enabled;
    float radius;           // Light attenuation radius light intensity reduced with distance (world distance)
    float intensity;        // Light intensity level
    float coneAngle;        // Light cone max angle: LIGHT_SPOT
    
    // Shader locations
    int enabledLoc;
    int typeLoc;
    int posLoc;
    int targetLoc;
    int colorLoc;
    int intensityLoc;
    int coneAngleLoc;
    int radiusLoc;
} Light;

// Light type
typedef enum {
    LIGHT_DIRECTIONAL,
    LIGHT_POINT,
    LIGHT_SPOT
} LightType;


//----------------------------------------------------------------------------------
// Global Variables Definition
//----------------------------------------------------------------------------------
int lightsCount = 0;    // Current amount of created lights
static Shader standardShader;
static Light firstLight;
Light lights[MAX_LIGHTS] = { 0 };

//----------------------------------------------------------------------------------
// Module Functions Declaration
//----------------------------------------------------------------------------------
Light CreateLight(int type, Vector3 position, Vector3 target, Color color, Shader shader);   // Create a light and get shader locations
void UpdateLightValues(Shader shader, Light light);         // Send light properties to shader
static void DrawLight(Light light);        // Draw light in 3D world
//void InitLightLocations(Shader shader, Light *light);     // Init light shader locations


//----------------------------------------------------------------------------------
// Defines and Macros
//----------------------------------------------------------------------------------
// ...

//----------------------------------------------------------------------------------
// Types and Structures Definition
//----------------------------------------------------------------------------------
// ...

//----------------------------------------------------------------------------------
// Global Variables Definition
//----------------------------------------------------------------------------------
// ...

//----------------------------------------------------------------------------------
// Module specific Functions Declaration
//----------------------------------------------------------------------------------
// ...

//----------------------------------------------------------------------------------
// Module Functions Definition
//----------------------------------------------------------------------------------

// Create a light and get shader locations
Light CreateLight(int type, Vector3 position, Vector3 target, Color color, Shader shader)
{
    Light light = { 0 };

    if (lightsCount < MAX_LIGHTS)
    {
        light.enabled = true;
        light.type = type;
        light.position = position;
        light.target = target;
        light.color = color;
        light.radius = 2.0;
        light.intensity = 1.0;
        light.coneAngle = 7.0;


//                case LIGHT_DIRECTIONAL:
//                {
//                    Vector3 direction = VectorSubtract(lights[i]->target, lights[i]->position);
//                    VectorNormalize(&direction);
//                    
//                    tempFloat[0] = direction.x;
//                    tempFloat[1] = direction.y;
//                    tempFloat[2] = direction.z;
//                    SetShaderValue(shader, lightsLocs[i][3], tempFloat, UNIFORM_VEC3);
//                    
//                    //glUniform3f(lightsLocs[i][3], direction.x, direction.y, direction.z);
//                } break;
//                case LIGHT_SPOT:
//                {
//                    tempFloat[0] = lights[i]->position.x;
//                    tempFloat[1] = lights[i]->position.y;
//                    tempFloat[2] = lights[i]->position.z;
//                    SetShaderValue(shader, lightsLocs[i][2], tempFloat, UNIFORM_VEC3);
//                    
//                    //glUniform3f(lightsLocs[i][2], lights[i]->position.x, lights[i]->position.y, lights[i]->position.z);
//                    
//                    Vector3 direction = VectorSubtract(lights[i]->target, lights[i]->position);
//                    VectorNormalize(&direction);
//                    
//                    tempFloat[0] = direction.x;
//                    tempFloat[1] = direction.y;
//                    tempFloat[2] = direction.z;
//                    SetShaderValue(shader, lightsLocs[i][3], tempFloat, UNIFORM_VEC3);
//                    //glUniform3f(lightsLocs[i][3], direction.x, direction.y, direction.z);
//                    
//                    tempFloat[0] = lights[i]->coneAngle;
//                    SetShaderValue(shader, lightsLocs[i][7], tempFloat, UNIFORM_FLOAT);
//                    //glUniform1f(lightsLocs[i][7], lights[i]->coneAngle);
//                } break;

        // TODO: Below code doesn't look good to me, 
        // it assumes a specific shader naming and structure
        // Probably this implementation could be improved
        char enabledName[32] = "lights[x].enabled\0";
        char typeName[32] = "lights[x].type\0";
        char posName[32] = "lights[x].position\0";
        char targetName[32] = "lights[x].target\0";
        char colorName[32] = "lights[x].color\0";
        char intensityName[32] = "lights[x].intensity\0";
        char coneAngleName[32] = "lights[x].coneAngle\0";
        char radiusName[32] = "lights[x].radius\0";

        enabledName[7] = '0' + lightsCount;
        typeName[7] = '0' + lightsCount;
        posName[7] = '0' + lightsCount;
        targetName[7] = '0' + lightsCount;
        colorName[7] = '0' + lightsCount;
        intensityName[7] = '0' + lightsCount;
        coneAngleName[7] = '0' + lightsCount;
        radiusName[7] = '0' + lightsCount;

        light.enabledLoc = GetShaderLocation(shader, enabledName);
        light.typeLoc = GetShaderLocation(shader, typeName);
        light.posLoc = GetShaderLocation(shader, posName);
        light.targetLoc = GetShaderLocation(shader, targetName);
        light.colorLoc = GetShaderLocation(shader, colorName);
        light.intensityLoc = GetShaderLocation(shader, intensityName);
        light.coneAngleLoc = GetShaderLocation(shader, coneAngleName);
        light.radiusLoc = GetShaderLocation(shader, radiusName);

//        locNameUpdated[0] = '\0';
//        strcpy(locNameUpdated, locName);
//        strcat(locNameUpdated, "intensity\0");
//        lightsLocs[i][6] = GetShaderLocation(shader, locNameUpdated);
//        
//        locNameUpdated[0] = '\0';
//        strcpy(locNameUpdated, locName);
//        strcat(locNameUpdated, "coneAngle\0");
//        lightsLocs[i][7] = GetShaderLocation(shader, locNameUpdated);

        UpdateLightValues(shader, light);
        
        lightsCount++;
    }

    return light;
}

// Send light properties to shader
// NOTE: Light shader locations should be available 
void UpdateLightValues(Shader shader, Light light)
{
    // Send to shader light enabled state and type
    SetShaderValue(shader, light.enabledLoc, &light.enabled, UNIFORM_INT);
    SetShaderValue(shader, light.typeLoc, &light.type, UNIFORM_INT);
    SetShaderValue(shader, light.intensityLoc, &light.intensity, UNIFORM_FLOAT);
    SetShaderValue(shader, light.coneAngleLoc, &light.coneAngle, UNIFORM_FLOAT);
    SetShaderValue(shader, light.radiusLoc, &light.radius, UNIFORM_FLOAT);

    // Send to shader light position values
    float position[3] = { light.position.x, light.position.y, light.position.z };
    SetShaderValue(shader, light.posLoc, position, UNIFORM_VEC3);

    // Send to shader light target position values
    float target[3] = { light.target.x, light.target.y, light.target.z };
    SetShaderValue(shader, light.targetLoc, target, UNIFORM_VEC3);

    // Send to shader light color values
    float color[4] = { (float)light.color.r/(float)255, (float)light.color.g/(float)255, 
                       (float)light.color.b/(float)255, (float)light.color.a/(float)255 };
    SetShaderValue(shader, light.colorLoc, color, UNIFORM_VEC4);
}


// Vector3 math functions
static float VectorLength(const Vector3 v);             // Calculate vector length
static void VectorNormalize(Vector3 *v);                // Normalize provided vector
static Vector3 VectorSubtract(Vector3 v1, Vector3 v2); // Substract two vectors


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
  Light light;
} model_data_s;

typedef struct {
 mrb_state* mrb_pointer;
 struct RObject* self_pointer;
} loop_data_s;


static void play_data_destructor(mrb_state *mrb, void *p_);
static void model_data_destructor(mrb_state *mrb, void *p_);
static void crisscross_data_destructor(mrb_state *mrb, void *p_);

const struct mrb_data_type play_data_type = {"play_data", play_data_destructor};
const struct mrb_data_type model_data_type = {"model_data", model_data_destructor};
const struct mrb_data_type crisscross_data_type = {"crisscross_data", crisscross_data_destructor};

static int counter = 0;
static mrb_value mousexyz;
static mrb_value pressedkeys;


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

mrb_value socket_stream_unpack_inbound_tty(mrb_state* mrb, mrb_value self) {
  mrb_value tty_output;
  mrb_value data_value;

  mrb_get_args(mrb, "o", &tty_output);

  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@client"));

#ifdef PLATFORM_WEB
  mrb_int fp = mrb_int(mrb, data_value);
  void (*write_packed_pointer)(int, const void*, int) = (void (*)(int, const void*, int))fp;
  const char *foo = mrb_string_value_ptr(mrb, tty_output);
  int len = mrb_string_value_len(mrb, tty_output);

  write_packed_pointer(0, foo, len);

  mrb_free(mrb, mrb_obj_ptr(tty_output));

#endif

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


//TODO
static mrb_value platform_bits_update(mrb_state* mrb, mrb_value self) {
#ifdef TARGET_DESKTOP
  //TODO: this should have logic on ruby side based on if is window or not
  //if (WindowShouldClose()) {
    //return mrb_true_value();
    //return mrb_nil_value();
  //}
#endif

  double time;
  float dt;


  time = GetTime();
  dt = GetFrameTime();

  //double itime;
  //float idt;

  //int cnt = 3;
  //for (int i=0; i<cnt; i++) {
  //  idt = dt / (float)cnt;
  //  itime = time - ((float)i*(idt));

    //self is instance of StackBlocker.new !!!!!!!!!!
    //mrb_funcall(mrb, self, "update", 2, mrb_float_value(mrb, itime), mrb_float_value(mrb, idt));
    mrb_funcall(mrb, self, "update", 2, mrb_float_value(mrb, time), mrb_float_value(mrb, dt));

    if (mrb->exc) {
      fprintf(stderr, "Exception in SERVER_UPDATE_BITS");
      mrb_print_error(mrb);
      mrb_print_backtrace(mrb);
      return mrb_nil_value();
    }

  //}

  return mrb_true_value();
}


//TODO
void platform_bits_update_void(void* arg) {
  loop_data_s* loop_data = arg;

  mrb_state* mrb = loop_data->mrb_pointer;
  struct RObject* self = loop_data->self_pointer;
  mrb_value selfV = mrb_obj_value(self);

  platform_bits_update(mrb, selfV);
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

  //void emscripten_set_main_loop_arg(em_arg_callback_func func, void *arg, int fps, int simulate_infinite_loop)
  emscripten_set_main_loop_arg(platform_bits_update_void, loop_data, 0, 1);
#endif

#ifdef PLATFORM_DESKTOP
  
#endif

  fprintf(stderr, "wtf show!\n");

  return self;
}


mrb_value cheese_cross(mrb_state* mrb, mrb_value self) {
  loop_data_s *loop_data = NULL;
  mrb_value data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@flip_pointer"));

  Data_Get_Struct(mrb, data_value, &crisscross_data_type, loop_data);
  if (!loop_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  //TODO
  mrb_value wiz_return_halt = mrb_funcall(loop_data->mrb_pointer, mrb_obj_value(loop_data->self_pointer), "common_cheese_process!", 0, 0);

  if (loop_data->mrb_pointer->exc) {
    fprintf(stderr, "Exception in SERVER_CHEESE_CROSS");
    mrb_print_error(loop_data->mrb_pointer);
    mrb_print_backtrace(loop_data->mrb_pointer);
    return mrb_false_value();
  }

  if (mrb_test(wiz_return_halt)) {
    return mrb_true_value();
  } else {
    return mrb_false_value();
  }
}


static void if_exception_error_and_exit(mrb_state* mrb, char *context) {
  // check for exception, only one can exist at any point in time
  if (mrb->exc) {
    fprintf(stderr, "Exception in %s", context);
    mrb_print_error(mrb);
    exit(2);
  }
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

  float px,py,pz,tx,ty,tz,fovy = 0;
  px = 5;
  py = 4;
  pz = 3;
  
  fovy = 5.0;

  p_data->camera.type = CAMERA_PERSPECTIVE;
  // Define the camera to look into our 3d world
  p_data->camera.position = (Vector3){ px, py, pz };    // Camera position
  p_data->camera.target = (Vector3){ tx, ty, tz };      // Camera looking at point

  p_data->camera.up = (Vector3){ 0.0f, 1.0f, 0.0f };    // Camera up vector (rotation towards target)
  p_data->camera.fovy = fovy;                           // Camera field-of-view Y

  p_data->cameraTwo.target = (Vector2){ 0, 0 };
  p_data->cameraTwo.offset = (Vector2){ 0, 0 };
  p_data->cameraTwo.rotation = 0.0f;
  p_data->cameraTwo.zoom = 1.0f;

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
  //SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_VSYNC_HINT);

  InitWindow(screenWidth, screenHeight, c_game_name);

  //startLighting
  standardShader = LoadShader("resources/standard.vs",  "resources/standard.fs");

  // ambient light level
  int ambientLoc = GetShaderLocation(standardShader, "ambient");
  SetShaderValue(standardShader, ambientLoc, (float[4]){ 0.125f, 0.125f, 0.125f, 1.0f }, UNIFORM_VEC4);

  // Get some shader loactions
  standardShader.locs[LOC_MATRIX_MODEL] = GetShaderLocation(standardShader, "matModel");
  standardShader.locs[LOC_VECTOR_VIEW] = GetShaderLocation(standardShader, "viewPos");
  standardShader.locs[LOC_COLOR_DIFFUSE] = GetShaderLocation(standardShader, "colDiffuse");
  
  glBindAttribLocation(standardShader.id, 3, "vertexColor");

  lights[0] = CreateLight(LIGHT_POINT, (Vector3){ 0, 3, 0 }, Vector3Zero(), WHITE, standardShader);
  lights[1] = CreateLight(LIGHT_DIRECTIONAL, (Vector3){ 3, 5, 7 }, Vector3Zero(), WHITE, standardShader);
  lights[2] = CreateLight(LIGHT_SPOT, Vector3Zero(), Vector3Zero(), BLUE, standardShader);
  lights[3] = CreateLight(LIGHT_POINT, (Vector3){ 2, 2, 2 }, Vector3Zero(), WHITE, standardShader);

  SetExitKey(0);

//#ifdef TARGET_DESKTOP
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
  DrawPlane((Vector3){0.0, 0.0, 0.0}, (Vector2){a*b, a*b}, BLUE);                                       // Draw a plane XZ

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


//TODO: implenent on_shutdown
static mrb_value platform_bits_shutdown(mrb_state* mrb, mrb_value self) {
//  //mrb_funcall(mrb, self, "play", 2, mrb_float_value(mrb, time), mrb_float_value(mrb, dt));
//  fprintf(stderr, "CloseWindow\n");
//  //TODO: move this to window class somehow
//  CloseWindow(); // Close window and OpenGL context

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

  float cameraPos[3] = { p_data->camera.position.x, p_data->camera.position.y, p_data->camera.position.z };
  SetShaderValue(standardShader, standardShader.locs[LOC_VECTOR_VIEW], cameraPos, UNIFORM_VEC3);

  //updateLighting
  //white closeup point
  lights[0].position.x = tx + 0;
  lights[0].position.y = ty + 0.5;
  lights[0].position.z = tz + 0;
  lights[0].target.x = tx + 0;
  lights[0].target.y = ty + 0;
  lights[0].target.z = tz + 0;
  lights[0].intensity = 0.075;
  lights[0].radius = 0.333;
  lights[0].enabled = false;

  //white directional
  lights[1].intensity = 0.25;
  lights[1].enabled = true;

  //blue spotlight
  lights[2].position.x = tx + 2;
  lights[2].position.y = ty + 3;
  lights[2].position.z = tz - 2;
  lights[2].target.x = tx;
  lights[2].target.y = ty;
  lights[2].target.z = tz;
  lights[2].intensity = 0.000001;
  lights[2].coneAngle = 20.00;
  lights[2].enabled = true;

  lights[3].intensity = 0.15;
  lights[3].radius = 3.0;
  lights[3].enabled = false;

  UpdateLightValues(standardShader, lights[0]);
  UpdateLightValues(standardShader, lights[1]);
  UpdateLightValues(standardShader, lights[2]);
  UpdateLightValues(standardShader, lights[3]);

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

  float cameraPos[3] = { p_data->camera.position.x, p_data->camera.position.y, p_data->camera.position.z };
  SetShaderValue(standardShader, standardShader.locs[LOC_VECTOR_VIEW], cameraPos, UNIFORM_VEC3);

  BeginMode3D(p_data->camera);

  mrb_yield_argv(mrb, block, 0, NULL);

  //drawLighting
  //for (int i=0; i<MAX_LIGHTS; i++) {
  //  DrawLight(lights[i]);
  //}

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

  //TODO....
  //play_data_s *p_data = NULL;
  //mrb_value data_value;     // this IV holds the data
  //data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  //Data_Get_Struct(mrb, data_value, &play_data_type, p_data);
  //if (!p_data) {
  //  mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  //}

  {
    BeginDrawing();
    ClearBackground(BLANK);
    {
      mrb_yield_argv(mrb, block, 0, NULL);
    }
    EndDrawing();
  }

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

  //mrb_value png_ending = mrb_str_new_cstr(mrb, ".png");
  //mrb_value mtl_ending = mrb_str_new_cstr(mrb, ".mtl");

  //mrb_value foop = mrb_funcall(mrb, model_png, "end_with?", 1, png_ending);
  //if (mrb->exc) {
  //  fprintf(stderr, "Exception in SERVER");
  //  mrb_print_error(mrb);
  //  mrb_print_backtrace(mrb);
  //}

  //mrb_value foop_mtl = mrb_funcall(mrb, model_png, "end_with?", 1, mtl_ending);
  //if (mrb->exc) {
  //  fprintf(stderr, "Exception in SERVER");
  //  mrb_print_error(mrb);
  //  mrb_print_backtrace(mrb);
  //}

  ////if (mrb_equal(mrb, foop, mrb_true_value())) {
  ////  p_data->texture = LoadTexture(c_model_png); // Load model texture
  ////  p_data->model.material.maps[MAP_DIFFUSE].texture = p_data->texture; // Set map diffuse texture
  ////}

  //if (true || mrb_equal(mrb, foop_mtl, mrb_true_value())) {
  //  fprintf(stderr, "detected mtl\n");

  //  //int foo = 0;
  //  //Material mmm = LoadMaterials(c_model_png, &foo); // Load model texture
  for (int mi=0; mi<p_data->model.materialCount; mi++) {
    //Material material = { 0 };
    //material.shader = standardShader;
    //p_data->model.materials[mi] = material;

  //  ////material.maps[MAP_DIFFUSE].texture = LoadTexture("../models/resources/pbr/trooper_albedo.png");   // Load model diffuse texture
  //  ////material.maps[MAP_NORMAL].texture = LoadTexture("../models/resources/pbr/trooper_normals.png");     // Load model normal texture
  //  ////material.maps[MAP_SPECULAR].texture = LoadTexture("../models/resources/pbr/trooper_roughness.png"); // Load model specular texture

  //  material.maps[MAP_DIFFUSE].color = WHITE;
  //  material.maps[MAP_SPECULAR].color = WHITE;
    //p_data->model.materials[mi].maps[MAP_DIFFUSE].color = WHITE;
    //p_data->model.materials[mi].maps[MAP_NORMAL].color = WHITE;
    //p_data->model.materials[mi].maps[MAP_SPECULAR].color = WHITE;

    p_data->model.materials[mi].shader = standardShader;
  }

  //p_data->model.materials[1].shader = standardShader;
  //p_data->model.materials[2].shader = standardShader;
  //p_data->model.materials[3].shader = standardShader;

  //  ////mmm.maps[MAP_DIFFUSE].color = WHITE;
  //  ////mmm.maps[MAP_SPECULAR].color = WHITE;

  //  ////Light spotLight = CreateLight(LIGHT_SPOT, (Vector3){50.0f, 50.0f, 100.0f}, (Color){255, 255, 255, 255});
  //  ////spotLight->target = (Vector3){0.0f, 0.0f, 0.0f};
  //  ////spotLight->intensity = 1.0f;
  //  ////spotLight->diffuse = (Color){255, 100, 100, 255};
  //  ////spotLight->coneAngle = 10.0f;
  //  ////p_data->light = spotLight;

  //p_data->light = firstLight;

  //  //mmm.shader = GetDefaultShader();
  //  //p_data->model.material = mmm;

  //  //// Set shader lights values for enabled lights
  //  //// NOTE: If values are not changed in real time, they can be set at initialization!!!
  //  //SetShaderLightsValues(standardShader);

  //  //p_data->model.material.maps[MAP_DIFFUSE].texture = p_data->texture; // Set map diffuse texture
  //}

  ////TODO?
  ////p_data->model.material.shader = shader;

  p_data->scale.x = scalef;
  p_data->scale.y = scalef;
  p_data->scale.z = scalef;

  p_data->color.r = 255;
  p_data->color.g = 0;
  p_data->color.b = 128;
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

static void crisscross_data_destructor(mrb_state *mrb, void *p_) {
}

static void model_data_destructor(mrb_state *mrb, void *p_) {
  // //TODO
  // //mrb_value data_value;
  // //data_value = mrb_iv_get(mrb, (mrb_value)p_, mrb_intern_lit(mrb, "@pointer"));

  // model_data_s *p_data = p_;

  // //Data_Get_Struct(mrb, data_value, &model_data_type, p_data);
  // if (!p_data) {
  //   mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  // }
  // //model_data_s *pd = (model_data_s *)p_;

  // //// De-Initialization
  // UnloadTexture(p_data->texture);     // Unload texture
  // //TODO:
  // //UnloadModel(pd->model);         // Unload model

  // mrb_free(mrb, p_);
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

  //if (draw_wires) {
    //DrawModelWiresEx(p_data->model, p_data->position, p_data->rotation, p_data->angle, p_data->scale, BLUE);   // Draw 3d model with texture
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
  
  //for (int meshi=0; meshi<p_data->model.meshCount; meshi++) {
  //  MeshTangents(&p_data->model.meshes[meshi]);
  //}

  //Material material = { 0 };

  ////material.shader = GetShaderDefault();
  //material.shader = standardShader;

  for (int mi=0; mi<p_data->model.materialCount; mi++) {
  ////  Material material = { 0 };

  ////  ////material.shader = GetShaderDefault();
  ////  material.shader = standardShader;

  ////  ////material.maps[MAP_DIFFUSE].texture = LoadTexture("../models/resources/pbr/trooper_albedo.png");   // Load model diffuse texture
  ////  ////material.maps[MAP_NORMAL].texture = LoadTexture("../models/resources/pbr/trooper_normals.png");     // Load model normal texture
  ////  ////material.maps[MAP_SPECULAR].texture = LoadTexture("../models/resources/pbr/trooper_roughness.png"); // Load model specular texture

    //p_data->model.materials[mi].maps[MAP_DIFFUSE].color = WHITE;
    //p_data->model.materials[mi].maps[MAP_NORMAL].color = WHITE;
    //p_data->model.materials[mi].maps[MAP_SPECULAR].color = WHITE;

    p_data->model.materials[mi].shader = standardShader;
  }

  ////material.maps[MAP_DIFFUSE].texture = LoadTexture("../models/resources/pbr/trooper_albedo.png");   // Load model diffuse texture
  ////material.maps[MAP_NORMAL].texture = LoadTexture("../models/resources/pbr/trooper_normals.png");     // Load model normal texture
  ////material.maps[MAP_SPECULAR].texture = LoadTexture("../models/resources/pbr/trooper_roughness.png"); // Load model specular texture

  //material.maps[MAP_DIFFUSE].color = WHITE;
  //material.maps[MAP_SPECULAR].color = WHITE;

  ////Light spotLight = CreateLight(LIGHT_SPOT, (Vector3){50.0f, 50.0f, 100.0f}, (Color){255, 255, 255, 255});
  ////spotLight->target = (Vector3){0.0f, 0.0f, 0.0f};
  ////spotLight->intensity = 1.0f;
  ////spotLight->diffuse = (Color){255, 100, 100, 255};
  ////spotLight->coneAngle = 10.0f;
  ////p_data->light = spotLight;

  //p_data->model.materials[0] = material;
  //p_data->light = firstLight;

  //// Set shader lights values for enabled lights
  //// NOTE: If values are not changed in real time, they can be set at initialization!!!
  //SetShaderLightsValues(standardShader);

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

  float colors = 32.0;
  float freq = 64.0 / colors;

  int r = 128; //(sin(freq * abs(counter) + 0.0) * (127.0) + 128.0);
  int g = (sin(freq * abs(counter) + 1.0) * (127.0) + 128.0);
  int b = 128; //(sin(freq * abs(counter) + 3.0) * (127.0) + 128.0);

  counter++;

  if (counter == colors) {
    counter *= -1;
  }

  p_data->color.r = 255;
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
  //for (int meshi=0; meshi<p_data->model.meshCount; meshi++) {
  //  MeshTangents(&p_data->model.meshes[meshi]);
  //}

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

#ifdef TARGET_DESKTOP
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
//TODO: fix when on back on linux box
#ifdef TARGET_DESKTOP

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

  close(a);
  close(b);

  return mrb_nil_value();
}


static mrb_value fast_tty_resize(mrb_state* mrb, mrb_value self)
{
  mrb_int a,cols,rows;
  mrb_get_args(mrb, "iii", &a, &cols, &rows);

  struct winsize w = {rows, cols, 0, 0};

  ioctl(a, TIOCSWINSZ, &w);

  return mrb_true_value();
}


static mrb_value fast_tty_fd(mrb_state* mrb, mrb_value self)
{
#ifdef TARGET_DESKTOP
  struct winsize w = {1, 1, 0, 0};

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
  
  //ptsname_r(fdm, ptyname, foo);
  ttyname_r(fdm, ptyname, foo);

  //TODO
  //strncpy(ptyname, ptsname(fdm, ), FILENAME_MAX-1);
  //ptsname

  //// Open the slave PTY
  fds = open(ptyname, O_RDWR | O_NOCTTY);
  //fds = open(ptyname, O_RDWR);

  //TODO: clean this up once sure its not broken or missing parts
  //pid_t result = setsid();
  //if (result < 0)
  //{
  //  //fprintf(stderr, "%s\n", explain_setsid());
  //  fprintf(stderr, "Error %d on setsid()\n", errno);
  //  fprintf(stderr, "Error %s on setsid()\n", strerror(errno));
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

//TODO: minimal scripting env
// MRB_API mrb_state*
// mrb_empty_open_allocf(mrb_allocf f, void *ud)
// {
//   mrb_state *mrb = mrb_open_core(f, ud);
//
//   if (mrb == NULL) {
//     return NULL;
//   }
//
// //#ifndef DISABLE_GEMS
// //  mrb_init_mrbgems(mrb);
// //  mrb_gc_arena_restore(mrb, 0);
// //#endif
//   return mrb;
// }
//
//
// MRB_API mrb_state*
// mrb_empty_open(void)
// {
//   mrb_state *mrb = mrb_empty_open_allocf(mrb_default_allocf, NULL);
//
//   return mrb;
// }

//--------------------------------------------------------------------------------------------
// Module Functions Definitions
//--------------------------------------------------------------------------------------------

//// Create a new light, initialize it and add to pool
//Light CreateLight(int type, Vector3 position, Color diffuse)
//{
//    Light light = NULL;
//    
//    if (lightsCount < MAX_LIGHTS)
//    {
//        // Allocate dynamic memory
//        light = (Light)malloc(sizeof(LightData));
//        
//        // Initialize light values with generic values
//        light->id = lightsCount;
//        light->type = type;
//        light->enabled = true;
//        
//        light->position = position;
//        light->target = (Vector3){ 0.0f, 0.0f, 0.0f };
//        light->intensity = 1.0f;
//        light->diffuse = diffuse;
//        
//        // Add new light to the array
//        lights[lightsCount] = light;
//        
//        // Increase enabled lights count
//        lightsCount++;
//    }
//    else
//    {
//        // NOTE: Returning latest created light to avoid crashes
//        light = lights[lightsCount];
//    }
//
//    return light;
//}

//// Destroy a light and take it out of the list
//void DestroyLight(Light light)
//{
//    if (light != NULL)
//    {
//        int lightId = light->id;
//
//        // Free dynamic memory allocation
//        free(lights[lightId]);
//
//        // Remove *obj from the pointers array
//        for (int i = lightId; i < lightsCount; i++)
//        {
//            // Resort all the following pointers of the array
//            if ((i + 1) < lightsCount)
//            {
//                lights[i] = lights[i + 1];
//                lights[i]->id = lights[i + 1]->id;
//            }
//        }
//        
//        // Decrease enabled physic objects count
//        lightsCount--;
//    }
//}

//// Draw light in 3D world
void DrawLight(Light light)
{
    switch (light.type)
    {
        case LIGHT_POINT:
        {
            DrawSphereWires(light.position, 0.3f*light.intensity, 8, 8, (light.enabled ? light.color : GRAY));
            
            DrawCircle3D(light.position, light.radius, (Vector3){ 0, 0, 0 }, 0.0f, (light.enabled ? light.color : GRAY));
            DrawCircle3D(light.position, light.radius, (Vector3){ 1, 0, 0 }, 90.0f, (light.enabled ? light.color : GRAY));
            DrawCircle3D(light.position, light.radius, (Vector3){ 0, 1, 0 },90.0f, (light.enabled ? light.color : GRAY));
        } break;
        case LIGHT_DIRECTIONAL:
        {
            DrawLine3D(light.position, light.target, (light.enabled ? light.color : GRAY));
            
            DrawSphereWires(light.position, 0.3f*light.intensity, 8, 8, (light.enabled ? light.color : GRAY));
            DrawCubeWires(light.target, 0.3f, 0.3f, 0.3f, (light.enabled ? light.color : GRAY));
        } break;
        case LIGHT_SPOT:
        {
            DrawLine3D(light.position, light.target, (light.enabled ? light.color : GRAY));
            
            Vector3 dir = VectorSubtract(light.target, light.position);
            VectorNormalize(&dir);
            
            DrawCircle3D(light.position, 0.5f, dir, 0.0f, (light.enabled ? light.color : GRAY));
            
            //DrawCylinderWires(light.position, 0.0f, 0.3f*light.coneAngle/50, 0.6f, 5, (light.enabled ? light.color : GRAY));
            DrawCubeWires(light.target, 0.3f, 0.3f, 0.3f, (light.enabled ? light.color : GRAY));
        } break;
        default: break;
    }
}

//// Get shader locations for lights (up to MAX_LIGHTS)
//static void GetShaderLightsLocations(Shader shader)
//{
//    char locName[32] = "lights[X].\0";
//    char locNameUpdated[64];
//    
//    for (int i = 0; i < MAX_LIGHTS; i++)
//    {
//        locName[7] = '0' + i;
//        
//        strcpy(locNameUpdated, locName);
//        strcat(locNameUpdated, "enabled\0");
//        lightsLocs[i][0] = GetShaderLocation(shader, locNameUpdated);
//        
//        locNameUpdated[0] = '\0';
//        strcpy(locNameUpdated, locName);
//        strcat(locNameUpdated, "type\0");
//        lightsLocs[i][1] = GetShaderLocation(shader, locNameUpdated);
//
//        locNameUpdated[0] = '\0';
//        strcpy(locNameUpdated, locName);
//        strcat(locNameUpdated, "position\0");
//        lightsLocs[i][2] = GetShaderLocation(shader, locNameUpdated);
//        
//        locNameUpdated[0] = '\0';
//        strcpy(locNameUpdated, locName);
//        strcat(locNameUpdated, "direction\0");
//        lightsLocs[i][3] = GetShaderLocation(shader, locNameUpdated);
//        
//        locNameUpdated[0] = '\0';
//        strcpy(locNameUpdated, locName);
//        strcat(locNameUpdated, "radius\0");
//        lightsLocs[i][4] = GetShaderLocation(shader, locNameUpdated);
//        
//        locNameUpdated[0] = '\0';
//        strcpy(locNameUpdated, locName);
//        strcat(locNameUpdated, "diffuse\0");
//        lightsLocs[i][5] = GetShaderLocation(shader, locNameUpdated);
//        
//        locNameUpdated[0] = '\0';
//        strcpy(locNameUpdated, locName);
//        strcat(locNameUpdated, "intensity\0");
//        lightsLocs[i][6] = GetShaderLocation(shader, locNameUpdated);
//        
//        locNameUpdated[0] = '\0';
//        strcpy(locNameUpdated, locName);
//        strcat(locNameUpdated, "coneAngle\0");
//        lightsLocs[i][7] = GetShaderLocation(shader, locNameUpdated);
//    }
//}
//
//// Set shader uniform values for lights
//// NOTE: It would be far easier with shader UBOs but are not supported on OpenGL ES 2.0
//static void SetShaderLightsValues(Shader shader)
//{
//    int tempInt[8] = { 0 };
//    float tempFloat[8] = { 0.0f };
//   
//   fprintf(stderr, "FOOOOOP %d\n", lightsCount);
//
//    for (int i = 0; i < MAX_LIGHTS; i++)
//    {
//        if (i < lightsCount)
//        {
//            tempInt[0] = lights[i]->enabled;
//            SetShaderValue(shader, lightsLocs[i][0], tempInt, UNIFORM_INT); //glUniform1i(lightsLocs[i][0], lights[i]->enabled);
//            
//            tempInt[0] = lights[i]->type;
//            SetShaderValue(shader, lightsLocs[i][1], tempInt, UNIFORM_INT); //glUniform1i(lightsLocs[i][1], lights[i]->type);
//            
//            tempFloat[0] = (float)lights[i]->diffuse.r/255.0f;
//            tempFloat[1] = (float)lights[i]->diffuse.g/255.0f;
//            tempFloat[2] = (float)lights[i]->diffuse.b/255.0f;
//            tempFloat[3] = (float)lights[i]->diffuse.a/255.0f;
//            SetShaderValue(shader, lightsLocs[i][5], tempFloat, UNIFORM_VEC4);
//            //glUniform4f(lightsLocs[i][5], (float)lights[i]->diffuse.r/255, (float)lights[i]->diffuse.g/255, (float)lights[i]->diffuse.b/255, (float)lights[i]->diffuse.a/255);
//            
//            tempFloat[0] = lights[i]->intensity;
//            SetShaderValue(shader, lightsLocs[i][6], tempFloat, UNIFORM_FLOAT);
//            
//            switch (lights[i]->type)
//            {
//                case LIGHT_POINT:
//                {
//                    tempFloat[0] = lights[i]->position.x;
//                    tempFloat[1] = lights[i]->position.y;
//                    tempFloat[2] = lights[i]->position.z;
//                    SetShaderValue(shader, lightsLocs[i][2], tempFloat, UNIFORM_VEC3);
//
//                    tempFloat[0] = lights[i]->radius;
//                    SetShaderValue(shader, lightsLocs[i][4], tempFloat, UNIFORM_FLOAT);
//            
//                    //glUniform3f(lightsLocs[i][2], lights[i]->position.x, lights[i]->position.y, lights[i]->position.z);
//                    //glUniform1f(lightsLocs[i][4], lights[i]->radius);
//                } break;
//                case LIGHT_DIRECTIONAL:
//                {
//                    Vector3 direction = VectorSubtract(lights[i]->target, lights[i]->position);
//                    VectorNormalize(&direction);
//                    
//                    tempFloat[0] = direction.x;
//                    tempFloat[1] = direction.y;
//                    tempFloat[2] = direction.z;
//                    SetShaderValue(shader, lightsLocs[i][3], tempFloat, UNIFORM_VEC3);
//                    
//                    //glUniform3f(lightsLocs[i][3], direction.x, direction.y, direction.z);
//                } break;
//                case LIGHT_SPOT:
//                {
//                    tempFloat[0] = lights[i]->position.x;
//                    tempFloat[1] = lights[i]->position.y;
//                    tempFloat[2] = lights[i]->position.z;
//                    SetShaderValue(shader, lightsLocs[i][2], tempFloat, UNIFORM_VEC3);
//                    
//                    //glUniform3f(lightsLocs[i][2], lights[i]->position.x, lights[i]->position.y, lights[i]->position.z);
//                    
//                    Vector3 direction = VectorSubtract(lights[i]->target, lights[i]->position);
//                    VectorNormalize(&direction);
//                    
//                    tempFloat[0] = direction.x;
//                    tempFloat[1] = direction.y;
//                    tempFloat[2] = direction.z;
//                    SetShaderValue(shader, lightsLocs[i][3], tempFloat, UNIFORM_VEC3);
//                    //glUniform3f(lightsLocs[i][3], direction.x, direction.y, direction.z);
//                    
//                    tempFloat[0] = lights[i]->coneAngle;
//                    SetShaderValue(shader, lightsLocs[i][7], tempFloat, UNIFORM_FLOAT);
//                    //glUniform1f(lightsLocs[i][7], lights[i]->coneAngle);
//                } break;
//                default: break;
//            }
//        }
//        else
//        {
//            tempInt[0] = 0;
//            SetShaderValue(shader, lightsLocs[i][0], tempInt, UNIFORM_INT); //glUniform1i(lightsLocs[i][0], 0);   // Light disabled
//        }
//    }
//}

// Calculate vector length
float VectorLength(const Vector3 v)
{
    float length;

    length = sqrtf(v.x*v.x + v.y*v.y + v.z*v.z);

    return length;
}

// Normalize provided vector
void VectorNormalize(Vector3 *v)
{
    float length, ilength;

    length = VectorLength(*v);

    if (length == 0.0f) length = 1.0f;

    ilength = 1.0f/length;

    v->x *= ilength;
    v->y *= ilength;
    v->z *= ilength;
}

// Substract two vectors
Vector3 VectorSubtract(Vector3 v1, Vector3 v2)
{
    Vector3 result;

    result.x = v1.x - v2.x;
    result.y = v1.y - v2.y;
    result.z = v1.z - v2.z;

    return result;
}

int main(int argc, char** argv) {
  mrb_state *mrb;

  mrb_state *mrb_client;

  // initialize mruby
  if (!(mrb = mrb_open())) {
    fprintf(stderr,"%s: could not initialize mruby\n",argv[0]);
    return -1;
  }

  // initialize mruby
  if (!(mrb_client = mrb_open())) {
    fprintf(stderr,"%s: could not initialize mruby client\n",argv[0]);
    return -1;
  }

  mousexyz = mrb_ary_new(mrb_client);
  pressedkeys = mrb_ary_new(mrb_client);

  mrb_value args = mrb_ary_new(mrb_client);
  mrb_value args_server = mrb_ary_new(mrb);
  int i;

  // convert argv into mruby strings
  for (i=1; i<argc; i++) {
    mrb_ary_push(mrb_client, args, mrb_str_new_cstr(mrb_client, argv[i]));
    mrb_ary_push(mrb, args_server, mrb_str_new_cstr(mrb, argv[i]));
  }

  mrb_define_global_const(mrb, "ARGV", args_server);
  mrb_define_global_const(mrb_client, "ARGV", args);

  eval_static_libs(mrb, globals, NULL);
  eval_static_libs(mrb_client, globals, NULL);

  struct RClass *fast_utmp = mrb_define_class(mrb, "FastUTMP", mrb->object_class);
  mrb_define_class_method(mrb, fast_utmp, "utmps", fast_utmp_utmps, MRB_ARGS_NONE());

  struct RClass *fast_tty = mrb_define_class(mrb, "FastTTY", mrb->object_class);
  mrb_define_class_method(mrb, fast_tty, "fd", fast_tty_fd, MRB_ARGS_NONE());
  mrb_define_class_method(mrb, fast_tty, "close", fast_tty_close, MRB_ARGS_REQ(2));
  mrb_define_class_method(mrb, fast_tty, "resize", fast_tty_resize, MRB_ARGS_REQ(3));

  struct RClass *websocket_mod = mrb_define_module(mrb, "WebSocket");
  mrb_define_class_under(mrb, websocket_mod, "Error", E_RUNTIME_ERROR);
  mrb_define_module_function(mrb, websocket_mod, "create_accept", mrb_websocket_create_accept, MRB_ARGS_REQ(1));

  //TODO /////// class PlatformBits
  struct RClass *stack_blocker_class = mrb_define_class(mrb, "StackBlocker", mrb->object_class);
  mrb_define_method(mrb, stack_blocker_class, "signal", platform_bits_update, MRB_ARGS_NONE());

  struct RClass *stack_blocker_class_client = mrb_define_class(mrb_client, "StackBlocker", mrb_client->object_class);
  mrb_define_method(mrb_client, stack_blocker_class_client, "signal", platform_bits_update, MRB_ARGS_NONE());

  // class GameLoop
  struct RClass *game_class = mrb_define_class(mrb_client, "GameLoop", mrb->object_class);
  mrb_define_method(mrb_client, game_class, "initialize", game_loop_initialize, MRB_ARGS_REQ(1));
  mrb_define_method(mrb_client, game_class, "lookat", game_loop_lookat, MRB_ARGS_REQ(8));
  mrb_define_method(mrb_client, game_class, "first_person!", game_loop_first_person, MRB_ARGS_NONE());
  mrb_define_method(mrb_client, game_class, "draw_grid", game_loop_draw_grid, MRB_ARGS_REQ(2));
  mrb_define_method(mrb_client, game_class, "draw_plane", game_loop_draw_plane, MRB_ARGS_REQ(5));
  mrb_define_method(mrb_client, game_class, "draw_fps", game_loop_draw_fps, MRB_ARGS_REQ(2));
  mrb_define_method(mrb_client, game_class, "mousep", game_loop_mousep, MRB_ARGS_BLOCK());
  mrb_define_method(mrb_client, game_class, "keyspressed", game_loop_keyspressed, MRB_ARGS_ANY());
  mrb_define_method(mrb_client, game_class, "threed", game_loop_threed, MRB_ARGS_BLOCK());
  mrb_define_method(mrb_client, game_class, "interim", game_loop_interim, MRB_ARGS_BLOCK());
  mrb_define_method(mrb_client, game_class, "drawmode", game_loop_drawmode, MRB_ARGS_BLOCK());
  mrb_define_method(mrb_client, game_class, "twod", game_loop_twod, MRB_ARGS_BLOCK());
  mrb_define_method(mrb_client, game_class, "button", game_loop_button, MRB_ARGS_REQ(5));
  mrb_define_method(mrb_client, game_class, "open", platform_bits_open, MRB_ARGS_REQ(4));
  mrb_define_method(mrb_client, game_class, "shutdown", platform_bits_shutdown, MRB_ARGS_NONE());

  // class Model
  struct RClass *model_class = mrb_define_class(mrb_client, "Model", mrb->object_class);
  mrb_define_method(mrb_client, model_class, "initialize", model_initialize, MRB_ARGS_REQ(3));
  mrb_define_method(mrb_client, model_class, "draw", model_draw, MRB_ARGS_NONE());
  mrb_define_method(mrb_client, model_class, "deltap", model_deltap, MRB_ARGS_REQ(3));
  mrb_define_method(mrb_client, model_class, "deltar", model_deltar, MRB_ARGS_REQ(4));
  mrb_define_method(mrb_client, model_class, "deltas", model_deltas, MRB_ARGS_REQ(3));
  mrb_define_method(mrb_client, model_class, "yawpitchroll", model_yawpitchroll, MRB_ARGS_REQ(6));
  mrb_define_method(mrb_client, model_class, "label", model_label, MRB_ARGS_REQ(1));

  // class Cube
  struct RClass *cube_class = mrb_define_class(mrb_client, "Cube", model_class);
  mrb_define_method(mrb_client, cube_class, "initialize", cube_initialize, MRB_ARGS_REQ(4));

  // class Sphere
  struct RClass *sphere_class = mrb_define_class(mrb_client, "Sphere", model_class);
  mrb_define_method(mrb_client, sphere_class, "initialize", sphere_initialize, MRB_ARGS_REQ(4));

  //TODO: x-platofmr these???
  eval_static_libs(mrb, markaby, NULL);
  eval_static_libs(mrb_client, window, NULL);
  eval_static_libs(mrb_client, box, NULL);

  eval_static_libs(mrb, stack_blocker, NULL);
  eval_static_libs(mrb_client, stack_blocker, NULL);

  eval_static_libs(mrb, theseus, NULL);
  eval_static_libs(mrb_client, theseus, NULL);

  eval_static_libs(mrb, game_loop, NULL);
  eval_static_libs(mrb_client, game_loop, NULL);

  //TODO: full thor???
  //eval_static_libs(mrb, thor, NULL);
  //eval_static_libs(mrb_client, thor, NULL);

  //eval_static_libs(mrb, thess, NULL);
  //eval_static_libs(mrb_client, thess, NULL);

  //struct RClass *thor_b_class = mrb_define_class(mrb, "Thor", mrb->object_class);
  struct RClass *thor_class = mrb_define_class(mrb, "Wkndr", mrb->object_class);

  //struct RClass *thor_b_class_client = mrb_define_class(mrb_client, "Thor", mrb_client->object_class);
  struct RClass *thor_class_client = mrb_define_class(mrb_client, "Wkndr", mrb_client->object_class);

  eval_static_libs(mrb, wkndr, NULL);
  eval_static_libs(mrb_client, wkndr, NULL);

  //TODO: this is related to Window
  mrb_define_class_method(mrb_client, thor_class_client, "show!", global_show, MRB_ARGS_REQ(1));

  struct RClass *socket_stream_class = mrb_define_class(mrb, "SocketStream", mrb->object_class);
  struct RClass *socket_stream_class_client = mrb_define_class(mrb_client, "SocketStream", mrb_client->object_class);
  mrb_define_method(mrb_client, socket_stream_class_client, "connect!", socket_stream_connect, MRB_ARGS_REQ(0));
  mrb_define_method(mrb_client, socket_stream_class_client, "write_packed", socket_stream_write_packed, MRB_ARGS_REQ(1));
  mrb_define_method(mrb_client, socket_stream_class_client, "write_tty", socket_stream_unpack_inbound_tty, MRB_ARGS_REQ(1));

  eval_static_libs(mrb_client, socket_stream, NULL);

  //mrb_value the_stack;
  //mrb_value the_stack_client;

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

  mrb_define_class_method(mrb, thor_class, "cheese_cross!", cheese_cross, MRB_ARGS_REQ(0));

  mrb_value retret_stack_server = eval_static_libs(mrb, server_side, NULL);

  //TODO: re-bootstrap centalized shell3
  mrb_funcall(mrb, mrb_obj_value(server_side_top_most_thor), "startup_serverside", 1, args_server);
  if (mrb->exc) {
    fprintf(stderr, "Exception in SERVERSTARTUP\n");
    mrb_print_error(mrb);
    mrb_print_backtrace(mrb);
  }
#endif

  mrb_value retret_stack = eval_static_libs(mrb_client, client_side, NULL);

  //TODO: re-bootstrap centalized shell3
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

  //NOTE: when libuv binds to fd=0 it sets modes that cause /usr/bin/read to break
  fcntl(0, F_SETFL, fcntl(0, F_GETFL) & ~O_NONBLOCK);

  fprintf(stderr, "exiting ... \n");

  return 33;
}
