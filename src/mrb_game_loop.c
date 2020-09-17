//

// stdlib
#include <stdio.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <string.h>
#include <assert.h>

// mruby stuff
#include <mruby.h>
#include <mruby/data.h>
#include <mruby/string.h>
#include <mruby/variable.h>
#include <mruby/array.h>
#include <mruby/numeric.h>

// raylib stuff
//#include <raylib.h>
#include <raymath.h>

#include <rlgl.h>

//#include <GL/gl.h>
//#include <GL/glext.h>
//#include "external/glad.h"

//#if defined(GRAPHICS_API_OPENGL_33)
//    #if defined(__APPLE__)
//        #include <OpenGL/gl3.h>         // OpenGL 3 library for OSX
//        #include <OpenGL/gl3ext.h>      // OpenGL 3 extensions library for OSX
//    #else
//        #define GLAD_REALLOC RL_REALLOC
//        #define GLAD_FREE RL_FREE
//
//        #define GLAD_IMPLEMENTATION
//        #if defined(RLGL_STANDALONE)
//            #include "glad.h"           // GLAD extensions loading library, includes OpenGL headers
//        #else
//            #include "external/glad.h"  // GLAD extensions loading library, includes OpenGL headers
//        #endif
//    #endif
//#endif
//#if defined(GRAPHICS_API_OPENGL_ES2)
//    #define GL_GLEXT_PROTOTYPES
//    #include <EGL/egl.h>                // EGL library
//    #include <GLES2/gl2.h>              // OpenGL ES 2.0 library
//    #include <GLES2/gl2ext.h>           // OpenGL ES 2.0 extensions library
//#endif
#define RLIGHTS_IMPLEMENTATION
#include "rlights.h"

// local stuff
#include "mrb_game_loop.h"


//#if defined(PLATFORM_DESKTOP)
//    #define GLSL_VERSION            330
//#else   // PLATFORM_RPI, PLATFORM_ANDROID, PLATFORM_WEB
//    #define GLSL_VERSION            100
//#endif


void play_data_destructor(mrb_state *mrb, void *p_);
const struct mrb_data_type play_data_type = {"play_data", play_data_destructor};

static mrb_value mousexyz;
static mrb_value pressedkeys;

// Using 4 point lights, white, red, green and blue
static Light lights[MAX_LIGHTS] = { 0 };


// Garbage collector handler, for play_data struct
// if play_data contains other dynamic data, free it too!
// Check it with GC.start
void play_data_destructor(mrb_state *mrb, void *p_) {
  play_data_s *pd = (play_data_s *)p_;

  //TODO: memory leak!!!!
  //UnloadRenderTexture(pd->buffer_target);     // Unload texture

  mrb_free(mrb, pd);
};


static mrb_value platform_bits_open(mrb_state* mrb, mrb_value self)
{
  // Initialization
  mrb_value game_name = mrb_nil_value();
  mrb_int screenWidth,screenHeight,screenFps;

  mrb_get_args(mrb, "oiii", &game_name, &screenWidth, &screenHeight, &screenFps);

  const char *c_game_name = mrb_string_value_cstr(mrb, &game_name);

  SetConfigFlags(FLAG_WINDOW_RESIZABLE);
  //SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_VSYNC_HINT);
  //SetConfigFlags(FLAG_MSAA_4X_HINT | FLAG_VSYNC_HINT);

  InitWindow(screenWidth, screenHeight, c_game_name);

  play_data_s *p_data = NULL;
  mrb_value data_value;     // this IV holds the data
  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &play_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

//LoadShaderCode
//LoadFileText


  char *newerVer = "#version 300 es\n#define NEWER_GL\n";
  //char *olderVer = "#version 100\n#define highp\n#define mediump\n#define lowp\n";
  char *olderVer = "#version 100\n";
  char *setVer = NULL;

  char *vsSource = LoadFileText("resources/shaders/standard.vs");
  char *fsSource = LoadFileText("resources/shaders/standard.fs");

  if (rlglIsNewer()) {
      setVer = newerVer;
  } else {
      setVer = olderVer;
  }

  //switch(GLSL_VERSION) {
  //  case 330:
  //    setVer = newerVer;
  //    break;

  //  case 100:
  //    setVer = olderVer;
  //    break;
  //}

  const char *vsSources[2] = { setVer, vsSource };
  const char *fsSources[2] = { setVer, fsSource };

    //fprintf(stderr, fsSources);
    //p_data->globalDebugShader = LoadShader(FormatText("resources/shaders/glsl%i/base_lighting.vs", GLSL_VERSION), 
    //                                       FormatText("resources/shaders/glsl%i/lighting.fs", GLSL_VERSION));
    //LoadShader("resources/shaders/standard.vs",
    //                                       "resources/shaders/standard.fs");

    p_data->globalDebugShader = LoadShaderCodeX(vsSources, fsSources);

    Shader shader = p_data->globalDebugShader;
    
    // Get some shader loactions
    shader.locs[LOC_MATRIX_MODEL] = GetShaderLocation(shader, "matModel");
    shader.locs[LOC_VECTOR_VIEW] = GetShaderLocation(shader, "viewPos");

    // ambient light level
    int ambientLoc = GetShaderLocation(shader, "ambient");
    SetShaderValue(shader, ambientLoc, (float[4]){ 0.01f, 0.01f, 0.01f, 1.0f }, UNIFORM_VEC4);

    p_data->globalDebugTexture = LoadTexture("resources/texel_checker.png");

    //lights[0] = CreateLight(LIGHT_DIRECTIONAL, (Vector3){ 3, 2, 3 }, Vector3Zero(), BLUE, shader);
    lights[0] = CreateLight(LIGHT_POINT, (Vector3){ -30, 30, -30 }, Vector3Zero(), WHITE, shader);
    lights[1] = CreateLight(LIGHT_POINT, (Vector3){ -30, 30, 30 }, Vector3Zero(), RED, shader);
    lights[2] = CreateLight(LIGHT_POINT, (Vector3){ 30, 30, -30 }, Vector3Zero(), BLUE, shader);
    lights[3] = CreateLight(LIGHT_POINT, (Vector3){ 60, 60, 60 }, Vector3Zero(), GREEN, shader);

//  //startLighting
//  standardShader = LoadShader("resources/standard.vs",  "resources/standard.fs");
//
//  //TODO
//  //// ambient light level
//  int ambientLoc = GetShaderLocation(standardShader, "ambient");
//  SetShaderValue(standardShader, ambientLoc, (float[4]){ 0.0125f, 0.0125f, 0.0125f, 1.0f }, UNIFORM_VEC4);
//
//  // Get some shader loactions
//  standardShader.locs[LOC_MATRIX_MODEL] = GetShaderLocation(standardShader, "matModel");
//  standardShader.locs[LOC_VECTOR_VIEW] = GetShaderLocation(standardShader, "viewPos");
//  standardShader.locs[LOC_COLOR_DIFFUSE] = GetShaderLocation(standardShader, "colDiffuse");
//  standardShader.locs[LOC_COLOR_SPECULAR] = GetShaderLocation(standardShader, "colSpecular");
//  
//  //glBindAttribLocation(standardShader.id, 3, "vertexColor");
//
//  lights[0] = CreateLight(LIGHT_POINT, (Vector3){ 0, 30, 0 }, Vector3Zero(), WHITE, standardShader);
//  lights[1] = CreateLight(LIGHT_DIRECTIONAL, (Vector3){ -33, 55, -77 }, Vector3Zero(), WHITE, standardShader);
//  lights[2] = CreateLight(LIGHT_SPOT, (Vector3){ 0, 100, 0 }, Vector3Zero(), WHITE, standardShader);
//  lights[3] = CreateLight(LIGHT_POINT, (Vector3){ 20, 20, 20 }, Vector3Zero(), WHITE, standardShader);
//
//  lights[0].intensity = 0.1;
//  lights[0].enabled = 0;
//  UpdateLightValues(standardShader, lights[0]);
//
//  lights[1].intensity = 0.00001;
//  lights[1].enabled = 1;
//  UpdateLightValues(standardShader, lights[1]);
//
//  lights[2].intensity = 0.00001;
//  lights[2].enabled = 1;
//  lights[2].coneAngle = 33.00;
//  UpdateLightValues(standardShader, lights[2]);
//
//  lights[3].intensity = 0.001;
//  lights[3].enabled = 0;
//  UpdateLightValues(standardShader, lights[3]);
//
//  //lights[0] = CreateLight(LIGHT_SPOT, Vector3Zero(), Vector3Zero(), BLUE, standardShader);
//  //lights[0].intensity = 10.0;
//
//  //lights[0] = CreateLight(LIGHT_POINT, (Vector3){ 0, 3, 0 }, Vector3Zero(), WHITE, standardShader);
//  //lights[0].intensity = 10.0;
//
//  //lights[0] = CreateLight(LIGHT_DIRECTIONAL, (Vector3){ 3, 5, 7 }, Vector3Zero(), WHITE, standardShader);
//  //lights[0].intensity = 10.0;
//
//  //lights[0] = CreateLight(LIGHT_POINT, (Vector3){ 2, 2, 2 }, Vector3Zero(), WHITE, standardShader);
//
//  SetExitKey(0);
//
//#ifdef TARGET_DESKTOP
//  //SetWindowPosition((GetMonitorWidth() - GetScreenWidth())/2, ((GetMonitorHeight() - GetScreenHeight())/2)+1);
//  //SetWindowMonitor(0);
//  SetTargetFPS(screenFps);
//#endif

  return self;
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

  //p_data->camera.type = CAMERA_PERSPECTIVE;
  //// Define the camera to look into our 3d world
  //p_data->camera.position = (Vector3){ px, py, pz };    // Camera position
  //p_data->camera.target = (Vector3){ tx, ty, tz };      // Camera looking at point
  //p_data->camera.up = (Vector3){ 0.0f, 1.0f, 0.0f };    // Camera up vector (rotation towards target)
  //p_data->camera.fovy = fovy;                           // Camera field-of-view Y

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


static mrb_value game_loop_drawmode(mrb_state* mrb, mrb_value self)
{
  mrb_value block;
  mrb_get_args(mrb, "&", &block);

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
    fprintf(stderr, "WTFWTF\n");
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  BeginMode2D(p_data->cameraTwo);

    mrb_yield_argv(mrb, block, 0, NULL);

  //float textSize = 20.0;
  ////Vector3 cubePosition = p_data->position;
  ////Vector2 cubeScreenPosition;
  ////cubeScreenPosition = GetWorldToScreen((Vector3){cubePosition.x, cubePosition.y, cubePosition.z}, gl_p_data->camera);
  //DrawText("dsdsd", 50, 50, textSize, RED);
  //Vector2 ballPosition = { (float)512/2, (float)512/2 };
  //DrawCircleV(ballPosition, 50, MAROON);
  ////fprintf(stderr, "wtf\n");
  
  EndMode2D();

  return mrb_nil_value();
}


static mrb_value game_loop_draw_circle(mrb_state* mrb, mrb_value self)
{
  mrb_float radius,x,y,z,r,g,b,a;

  mrb_get_args(mrb, "ffffffff", &radius, &x, &y, &z, &r, &g, &b, &a);

  //DrawCircle(x, y, radius, (Color){ r, g, b, a });
  DrawCircleV((Vector2){ x, y }, radius, (Color){ r, g, b, a });

  return mrb_nil_value();
}


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

  Vector2 mousePosition = { -0.0f, -0.0f };

  mousePosition = GetMousePosition();

  mrb_ary_set(mrb, mousexyz, 0, mrb_float_value(mrb, mousePosition.x));
  mrb_ary_set(mrb, mousexyz, 1, mrb_float_value(mrb, mousePosition.y));
  mrb_ary_set(mrb, mousexyz, 2, mrb_int_value(mrb, IsMouseButtonDown(MOUSE_LEFT_BUTTON)));

  return mrb_yield_argv(mrb, block, 3, &mousexyz);
}


static mrb_value model_label(mrb_state* mrb, mrb_value self)
{
  mrb_value label_txt = mrb_nil_value();
  mrb_value pointer_value;
  mrb_get_args(mrb, "o", &label_txt);

  const char *c_label_txt = mrb_string_value_cstr(mrb, &label_txt);

  play_data_s *p_data = NULL;
  mrb_value data_value; // this IV holds the data

  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &play_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  //play_data_s *gl_p_data = NULL;

  ////play_data_s *p_data = NULL;
  ////mrb_value data_value;     // this IV holds the data
  ////data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));
  ////Data_Get_Struct(mrb, data_value, &play_data_type, p_data);
  ////if (!p_data) {
  ////  fprintf(stderr, "WTFWTF\n");
  ////  mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  ////}
  ////BeginMode2D(p_data->cameraTwo);

  //Data_Get_Struct(mrb, pointer_value, &play_data_type, gl_p_data);
  //if (!gl_p_data) {
  //  mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  //}

  float textSize = 30.0;

  //Vector3 cubePosition = p_data->position;

  Vector2 cubeScreenPosition;
  //cubeScreenPosition = GetWorldToScreen((Vector3){cubePosition.x, cubePosition.y, cubePosition.z}, gl_p_data->camera);
  //cubeScreenPosition = GetWorldToScreen((Vector3){0, 0, 0}, p_data->cameraTwo);
  cubeScreenPosition = GetWorldToScreen2D((Vector2){250, 75}, p_data->cameraTwo);

  DrawText(c_label_txt, cubeScreenPosition.x - (float)MeasureText(c_label_txt, textSize) / 2.0, cubeScreenPosition.y, textSize, BLUE);

  return mrb_nil_value();
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

  UpdateCamera(&p_data->camera);

  //TODO
  //float cameraPos[3] = { p_data->camera.position.x, p_data->camera.position.y, p_data->camera.position.z };
  ////SetShaderValue(standardShader, standardShader.locs[LOC_VECTOR_VIEW], cameraPos, UNIFORM_VEC3);
  //// Update the light shader with the camera view position
  ////float cameraPos[3] = { camera.position.x, camera.position.y, camera.position.z };
  //SetShaderValue(p_data->globalDebugShader, p_data->globalDebugShader.locs[LOC_VECTOR_VIEW], cameraPos, UNIFORM_VEC3);
  //float cameraPos[3] = { p_data->camera.position.x, p_data->camera.position.y, p_data->camera.position.z };
  //SetShaderValue(standardShader, standardShader.locs[LOC_VECTOR_VIEW], cameraPos, UNIFORM_VEC3);
  //////updateLighting
  //////white closeup point
  ////lights[0].position.x = tx + 0;
  ////lights[0].position.y = ty + 0.5;
  ////lights[0].position.z = tz + 0;
  ////lights[0].target.x = tx + 0;
  ////lights[0].target.y = ty + 0;
  ////lights[0].target.z = tz + 0;
  ////lights[0].intensity = 0.075;
  ////lights[0].radius = 0.333;
  ////lights[0].enabled = false;
  //////white directional
  ////lights[1].intensity = 0.25;
  ////lights[1].enabled = true;
  //////blue spotlight
  ////lights[2].position.x = tx;
  ////lights[2].position.y = ty + 3;
  ////lights[2].position.z = tz;
  ////lights[2].target.x = tx;
  ////lights[2].target.y = ty;
  ////lights[2].target.z = tz;
  ////lights[2].intensity = 0.000001;
  ////lights[2].coneAngle = 20.00;
  ////lights[2].enabled = true;
  ////lights[3].intensity = 0.15;
  ////lights[3].radius = 3.0;
  ////lights[3].enabled = false;
  //UpdateLightValues(standardShader, lights[0]);
  //UpdateLightValues(standardShader, lights[1]);
  //UpdateLightValues(standardShader, lights[2]);
  //UpdateLightValues(standardShader, lights[3]);

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

  UpdateLightValues(p_data->globalDebugShader, lights[0]);
  UpdateLightValues(p_data->globalDebugShader, lights[1]);
  UpdateLightValues(p_data->globalDebugShader, lights[2]);
  UpdateLightValues(p_data->globalDebugShader, lights[3]);

  BeginMode3D(p_data->camera);

    mrb_yield_argv(mrb, block, 0, NULL);

    ////drawLighting
    //for (int i=0; i<MAX_LIGHTS; i++) {
    //  DrawLight(lights[i]);
    //}

    //// Draw markers to show where the lights are
    //if (lights[0].enabled) { DrawSphereEx(lights[0].position, 0.5f, 8, 8, BLUE); }
    //if (lights[1].enabled) { DrawSphereEx(lights[1].position, 2.0f, 8, 8, RED); }
    //if (lights[2].enabled) { DrawSphereEx(lights[2].position, 2.0f, 8, 8, GREEN); }
    //if (lights[3].enabled) { DrawSphereEx(lights[3].position, 2.0f, 8, 8, BLUE); }
    //DrawGrid(10, 1.0f);

  EndMode3D();

  return mrb_nil_value();
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


struct RClass *mrb_define_game_loop(mrb_state *mrb) {
  mousexyz = mrb_ary_new(mrb);
  pressedkeys = mrb_ary_new(mrb);

  struct RClass *game_class = mrb_define_class(mrb, "GameLoop", mrb->object_class);
  mrb_define_method(mrb, game_class, "initialize", game_loop_initialize, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, game_class, "open", platform_bits_open, MRB_ARGS_REQ(4));
  mrb_define_method(mrb, game_class, "lookat", game_loop_lookat, MRB_ARGS_REQ(8));
  mrb_define_method(mrb, game_class, "drawmode", game_loop_drawmode, MRB_ARGS_BLOCK());
  mrb_define_method(mrb, game_class, "twod", game_loop_twod, MRB_ARGS_BLOCK());
  mrb_define_method(mrb, game_class, "threed", game_loop_threed, MRB_ARGS_BLOCK());
  mrb_define_method(mrb, game_class, "draw_circle", game_loop_draw_circle, MRB_ARGS_REQ(8));
  mrb_define_method(mrb, game_class, "mousep", game_loop_mousep, MRB_ARGS_BLOCK());
  mrb_define_method(mrb, game_class, "label", model_label, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, game_class, "keyspressed", game_loop_keyspressed, MRB_ARGS_ANY());

  return game_class;
}
