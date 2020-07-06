//

// stdlib
#include <stdio.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <assert.h>

// mruby stuff
#include <mruby.h>
#include <mruby/data.h>
#include <mruby/string.h>
#include <mruby/variable.h>

// local stuff
#include "mrb_game_loop.h"


static void play_data_destructor(mrb_state *mrb, void *p_);
const struct mrb_data_type play_data_type = {"play_data", play_data_destructor};


// Garbage collector handler, for play_data struct
// if play_data contains other dynamic data, free it too!
// Check it with GC.start
static void play_data_destructor(mrb_state *mrb, void *p_) {
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

//  SetConfigFlags(FLAG_WINDOW_RESIZABLE);
//  //SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_VSYNC_HINT);
//
//  InitWindow(screenWidth, screenHeight, c_game_name);
//
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
  //
  //p_data->camera.up = (Vector3){ 0.0f, 1.0f, 0.0f };    // Camera up vector (rotation towards target)
  //p_data->camera.fovy = fovy;                           // Camera field-of-view Y
  //
  //p_data->cameraTwo.target = (Vector2){ 0, 0 };
  //p_data->cameraTwo.offset = (Vector2){ 0, 0 };
  //p_data->cameraTwo.rotation = 0.0f;
  //p_data->cameraTwo.zoom = 1.0f;

  mrb_iv_set(
      mrb, self, mrb_intern_lit(mrb, "@pointer"), // set @data
      mrb_obj_value(                           // with value hold in struct
          Data_Wrap_Struct(mrb, mrb->object_class, &play_data_type, p_data)));

  return self;
}


struct RClass *mrb_define_game_loop(mrb_state *mrb) {
  //// class GameLoop
  //mousexyz = mrb_ary_new(mrb);
  //pressedkeys = mrb_ary_new(mrb);
  struct RClass *game_class = mrb_define_class(mrb, "GameLoop", mrb->object_class);
  mrb_define_method(mrb, game_class, "initialize", game_loop_initialize, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, game_class, "open", platform_bits_open, MRB_ARGS_REQ(4));
  //mrb_define_method(mrb, game_class, "lookat", game_loop_lookat, MRB_ARGS_REQ(8));
  //mrb_define_method(mrb, game_class, "first_person!", game_loop_first_person, MRB_ARGS_NONE());
  //mrb_define_method(mrb, game_class, "draw_grid", game_loop_draw_grid, MRB_ARGS_REQ(2));
  //mrb_define_method(mrb, game_class, "draw_plane", game_loop_draw_plane, MRB_ARGS_REQ(5));
  //mrb_define_method(mrb, game_class, "draw_fps", game_loop_draw_fps, MRB_ARGS_REQ(2));
  //mrb_define_method(mrb, game_class, "mousep", game_loop_mousep, MRB_ARGS_BLOCK());
  //mrb_define_method(mrb, game_class, "keyspressed", game_loop_keyspressed, MRB_ARGS_ANY());
  //mrb_define_method(mrb, game_class, "threed", game_loop_threed, MRB_ARGS_BLOCK());
  //mrb_define_method(mrb, game_class, "interim", game_loop_interim, MRB_ARGS_BLOCK());
  //mrb_define_method(mrb, game_class, "drawmode", game_loop_drawmode, MRB_ARGS_BLOCK());
  //mrb_define_method(mrb, game_class, "twod", game_loop_twod, MRB_ARGS_BLOCK());
  //mrb_define_method(mrb, game_class, "button", game_loop_button, MRB_ARGS_REQ(5));
  //mrb_define_method(mrb, game_class, "shutdown", platform_bits_shutdown, MRB_ARGS_NONE());
  //mrb_define_method(mrb, game_class, "draw_circle", game_loop_draw_circle, MRB_ARGS_REQ(8));

  return game_class;
}
