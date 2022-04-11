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
#include <raylib.h>
#include <raymath.h>
#include <rlgl.h>
//
#define RLIGHTS_IMPLEMENTATION
#include <rlights.h>
//#include <rcamera.h>

#if defined(PLATFORM_DESKTOP)
    #define GLSL_VERSION            330
#else   // PLATFORM_RPI, PLATFORM_ANDROID, PLATFORM_WEB
    #define GLSL_VERSION            100
#endif

#include "mrb_editor.h"
#include "mrb_terminal.h"

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

//#define RLIGHTS_IMPLEMENTATION
//#include "rlights.h"

// local stuff
#include "mrb_game_loop.h"

static Font the_font;

typedef struct {
  float debounce_time;
  float debounce_timer;

  int ctrl_key_pressed;
  int tab_key_pressed;
  int arrow_right_key_pressed;
  int arrow_up_key_pressed;
  int arrow_down_key_pressed;
  int arrow_left_key_pressed;
  int backspace_key_pressed;
  int enter_key_pressed;
  int del_key_pressed;
  int shift_key_pressed;
} keyset;

static keyset foop;

//#if defined(PLATFORM_DESKTOP)
//    #define GLSL_VERSION            330
//#else   // PLATFORM_RPI, PLATFORM_ANDROID, PLATFORM_WEB
//    #define GLSL_VERSION            100
//#endif


void play_data_destructor(mrb_state *mrb, void *p_);
//void texture_data_destructor(mrb_state *mrb, void *p_);
const struct mrb_data_type play_data_type = {"play_data", play_data_destructor};


//const struct mrb_data_type texture_data_type_alt = {"texture_data", texture_data_destructor};
//const struct mrb_data_type texture_data_type = {"texture_data", texture_data_destructor};
extern struct mrb_data_type texture_data_type;

static mrb_value mousexyz;
static mrb_value pressedkeys;

// Using 4 point lights, white, red, green and blue
////static Light lights[MAX_LIGHTS] = { 0 };


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

  if (screenWidth < 0 && screenHeight < 0) {
    return self;
  }

  //SetConfigFlags(FLAG_WINDOW_RESIZABLE);
  SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_INTERLACED_HINT); // | FLAG_WINDOW_TRANSPARENT | FLAG_WINDOW_UNDECORATED);
  //SetConfigFlags(FLAG_MSAA_4X_HINT | FLAG_VSYNC_HINT);

//fprintf(stderr, "WTFOPENPLATFORMBITS!???\n");
//mrb_raise(mrb, E_ARGUMENT_ERROR, "uninitialized rational");
//return mrb_nil_value();

//          mrb_print_backtrace(mrb);

  InitWindow(screenWidth, screenHeight, c_game_name);
  //InitWindow(GetScreenWidth(), GetScreenHeight(), c_game_name);

  //HideCursor();

  play_data_s *p_data = NULL;
  mrb_value data_value;     // this IV holds the data
  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &play_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

int *fontChars = malloc(sizeof(int) * 95);
for (int i=0; i<95; i++) {
  fontChars[i] = i+32;
}


//the_font = LoadFont("resources/unifont-14.0.02.ttf");
//the_font = LoadFontEx("resources/unifont-14.0.02.ttf", 32, fontChars, 95);
the_font = LoadFontEx("resources/freemono.ttf", 32, fontChars, 95);


    //Shader shader = LoadShader(TextFormat("resources/shaders/glsl%i/base_lighting_instanced.vs", GLSL_VERSION),
    //                         TextFormat("resources/shaders/glsl%i/lighting.fs", GLSL_VERSION));

    ////Shader shader;
    //////rlLoadShaderDefault();
    ////shader.id = rlGetShaderIdDefault();

    //p_data->globalDebugShader = shader;

    ////// Get some shader loactions
    //shader.locs[SHADER_LOC_MATRIX_MVP] = GetShaderLocation(shader, "mvp");
    //shader.locs[SHADER_LOC_VECTOR_VIEW] = GetShaderLocation(shader, "viewPos");
    //shader.locs[SHADER_LOC_MATRIX_MODEL] = GetShaderLocationAttrib(shader, "instanceTransform");

    //////shader.locs[RL_SHADER_LOC_VERTEX_COLOR] = GetShaderLocationAttrib(shader, "vertexColor");
    //////shader.locs[SHADER_LOC_VERTEX_COLOR] = GetShaderLocationAttrib(shader, "vertexColor");


    ////// Ambient light level
    //int ambientLoc = GetShaderLocation(shader, "ambient");
    //SetShaderValue(shader, ambientLoc, (float[4]){ 0.2f, 0.2f, 0.2f, 1.0f }, SHADER_UNIFORM_VEC4);

    ////Light foo = CreateLight(LIGHT_DIRECTIONAL, (Vector3){ 75.0f, 75.0f, 0.0f }, Vector3Zero(), WHITE, shader);

    ////foo.enabled = true;

    //// NOTE: We are assigning the intancing shader to material.shader
    //// to be used on mesh drawing with DrawMeshInstanced()
    //Material material = LoadMaterialDefault();
    //material.shader = shader;
    //material.maps[MATERIAL_MAP_DIFFUSE].color = RED;

//LoadShaderCode
//LoadFileText

/*
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

    p_data->globalDebugShader = LoadShaderCodeX(vsSources, fsSources);

    Shader shader = p_data->globalDebugShader;

    //SetShaderDefaultLocations(&shader);
    
    // Get some shader loactions
    //shader.locs[LOC_MATRIX_MODEL] = GetShaderLocation(shader, "matModel");
    shader.locs[LOC_MATRIX_MVP] = GetShaderLocation(shader, "mvp");
    shader.locs[LOC_MATRIX_MODEL] = GetShaderLocationAttrib(shader, "matModel");
    shader.locs[LOC_VECTOR_VIEW] = GetShaderLocation(shader, "viewPos");

    shader.locs[LOC_VERTEX_POSITION] = GetShaderLocationAttrib(shader, "vertexPosition");
    shader.locs[LOC_VERTEX_TEXCOORD01] = GetShaderLocationAttrib(shader, "vertexTexCoord");
    shader.locs[LOC_VERTEX_COLOR] = GetShaderLocationAttrib(shader, "vertexColor");


    // ambient light level
    int ambientLoc = GetShaderLocation(shader, "ambient");
    SetShaderValue(shader, ambientLoc, (float[4]){ 0.1f, 0.1f, 0.1f, 0.5f }, UNIFORM_VEC4);

    //p_data->globalDebugTexture = LoadTexture("resources/texel_checker.png");

    //lights[0] = CreateLight(LIGHT_DIRECTIONAL, (Vector3){ 5, 7, 9 }, Vector3Zero(), WHITE, shader);
    //lights[1] = CreateLight(LIGHT_POINT, (Vector3){ -30, 60, 10 }, Vector3Zero(), WHITE, shader);
    //lights[2] = CreateLight(LIGHT_SPOT, (Vector3){ 0.0, 10000.0, 0.0 }, (Vector3){ 0.0, 0.0, 0.0 }, BLUE, shader);
    //lights[3] = CreateLight(LIGHT_POINT, (Vector3){ -70, 60, -90 }, Vector3Zero(), GREEN, shader);

    lights[0] = CreateLight(LIGHT_DIRECTIONAL, (Vector3){ -5, 70, -9 }, Vector3Zero(), WHITE, shader);
    lights[1] = CreateLight(LIGHT_DIRECTIONAL, (Vector3){  -5, 70, 43 }, Vector3Zero(), RED, shader);
    lights[2] = CreateLight(LIGHT_DIRECTIONAL, (Vector3){ 11, 70, -9 }, Vector3Zero(), GREEN, shader);
    lights[3] = CreateLight(LIGHT_DIRECTIONAL, (Vector3){ 15, 70, 23 }, Vector3Zero(), BLUE, shader);

    //lights[0] = CreateLight(LIGHT_SPOT, (Vector3){  10, 100, 0 }, (Vector3){ -10, 0, 1 }, WHITE, shader);
    //lights[1] = CreateLight(LIGHT_SPOT, (Vector3){ -10, 100, 0 }, (Vector3){ 10, 0, -1 }, RED, shader);
    //lights[2] = CreateLight(LIGHT_SPOT, (Vector3){  0, 100, -10 }, (Vector3){ -1, 0, 10 }, GREEN, shader);
    //lights[3] = CreateLight(LIGHT_SPOT, (Vector3){  0, 100, 10 }, (Vector3){  1, 0,  -10 }, BLUE, shader);

    //lights[0] = CreateLight(LIGHT_POINT, (Vector3){ 300, 300, 300 }, Vector3Zero(), WHITE, shader);
    //lights[1] = CreateLight(LIGHT_POINT, (Vector3){ -30, 5, 30 }, Vector3Zero(), RED, shader);
    //lights[2] = CreateLight(LIGHT_POINT, (Vector3){ 30, 5, -30 }, Vector3Zero(), BLUE, shader);
    //lights[3] = CreateLight(LIGHT_POINT, (Vector3){ -30, 5, -30 }, Vector3Zero(), GREEN, shader);

lights[0].enabled = true;
lights[1].enabled = false;
lights[2].enabled = false;
lights[3].enabled = false;

lights[0].intensity = 0.5;
lights[1].intensity = 0.125;
lights[2].intensity = 0.125;
lights[3].intensity = 0.125;

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


////  lights[0].enabled = 0;
////  UpdateLightValues(standardShader, lights[0]);
///
////  lights[1].enabled = 1;
////  UpdateLightValues(standardShader, lights[1]);
////
////  lights[2].enabled = 1;
////  lights[2].coneAngle = 33.00;
////  UpdateLightValues(standardShader, lights[2]);
////
////  lights[3].enabled = 0;
////  UpdateLightValues(standardShader, lights[3]);
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
//#ifdef TARGET_HEAVY
//  //SetWindowPosition((GetMonitorWidth() - GetScreenWidth())/2, ((GetMonitorHeight() - GetScreenHeight())/2)+1);
//  //SetWindowMonitor(0);
//  SetTargetFPS(screenFps);
//#endif
*/

  
  initEditor();
  
  setupTerminal();

    struct abuf *ab2 = malloc(sizeof(struct abuf));
    ab2->b = NULL;
    ab2->len = 0;

    editorRefreshScreen(ab2);
    terminalRender(ab2->len, ab2->b);

    free(ab2);

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

  foop.debounce_timer = 0;
  foop.debounce_time = 0.25;

  foop.ctrl_key_pressed = 0;
  foop.tab_key_pressed = 0;
  foop.shift_key_pressed = 0;
  foop.arrow_right_key_pressed = 0;
  foop.arrow_left_key_pressed = 0;
  foop.arrow_up_key_pressed = 0;
  foop.arrow_down_key_pressed = 0;
  foop.backspace_key_pressed = 0;
  foop.enter_key_pressed = 0;
  foop.del_key_pressed = 0;

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
  foop.debounce_timer -= 1.0 / 24.0;

  int keyCount = 0;

  int key = 99;
  char chey = 0;

  //// Check if more characters have been pressed on the same frame
  while (key = GetKeyPressed()) {
    keyCount += 1;

    chey = key;
    //fprintf(stderr, "Key: %d\n", key);

    //76  ctrl-l
    if (key == 89) { // ctrl-y
      if (foop.ctrl_key_pressed) {
        fprintf(stderr, "Exec Code!!!!!!\n");

        // run Wkndrfile
        mrb_value empty_string = mrb_str_new_lit(mrb, "");

        int codelen;
        char *codebuf = editorRowsToString(&codelen);

        mrb_value clikestr_as_string = mrb_str_cat(mrb, empty_string, codebuf, codelen);
        mrb_value editr_eval = mrb_funcall(mrb, mrb_obj_value(mrb_class_get(mrb, "Wkndr")), "wkndr_client_eval", 1, clikestr_as_string);

        if (mrb->exc) {
          //mrb_print_error(mrb_client);
          //mrb_print_backtrace(mrb_client);
          //mrb_value mesg = mrb_exc_inspect(mrb, mrb_obj_value(mrb->exc));
          //mrb_value mesg = mrb_funcall(mrb, mrb_obj_value(mrb->exc), "inspect", 0);
          //editorSetStatusMessage(RSTRING_PTR(mesg));
          //"XXX %.*s\n", (int)RSTRING_LEN(mesg), RSTRING_PTR(mesg));
        } else {
          if (!mrb_nil_p(editr_eval)) {
            mrb_value rezstr = mrb_funcall(mrb, editr_eval, "to_s", 0);

            const char *foo = mrb_string_value_ptr(mrb, rezstr);
            int len = mrb_string_value_len(mrb, rezstr);
            editorSetStatusMessage(foo, len);
          }
        }
      }
    } else if (key == 258) {
      foop.tab_key_pressed = 1;
    } else if (key == 344) {
      foop.shift_key_pressed = 1;
    } else if (key == 341) {
      foop.ctrl_key_pressed = 1;
    } else if (key == 261) {
      foop.del_key_pressed = 1;
    } else if (key == 257) {
      foop.enter_key_pressed = 1;
    } else if (key == 259) {
      foop.backspace_key_pressed = 1;
    } else if (key == 263) {
      foop.arrow_left_key_pressed = 1;
    } else if (key == 264) {
      foop.arrow_down_key_pressed = 1;
    } else if (key == 265) {
      foop.arrow_up_key_pressed = 1;
    } else if (key == 262) {
      foop.arrow_right_key_pressed = 1;
    } else {
      //if (foop.shift_key_pressed) {
      //  editorProcessKeypress(key);
      //} else {
      //  editorProcessKeypress(key + 32);
      //}
    }

    foop.debounce_timer = 0.0;
  }

  if (foop.debounce_timer <= 0.0) {
    foop.debounce_timer = foop.debounce_time;

    if (foop.del_key_pressed) {
      keyCount += 1;
      editorProcessKeypress(ARROW_RIGHT);
      editorProcessKeypress(BACKSPACE);
    }

    if (foop.tab_key_pressed) {
      keyCount += 1;
      editorProcessKeypress(TAB);
      //fprintf(stderr, "sentTab\n");
    }

    if (foop.enter_key_pressed) {
      keyCount += 1;
      editorProcessKeypress(ENTER);
    }

    if (foop.backspace_key_pressed) {
      keyCount += 1;
      editorProcessKeypress(BACKSPACE);
    }

    if (foop.arrow_right_key_pressed) {
      keyCount += 1;
      editorProcessKeypress(ARROW_RIGHT);
    }

    if (foop.arrow_left_key_pressed) {
      keyCount += 1;
      editorProcessKeypress(ARROW_LEFT);
    }

    if (foop.arrow_up_key_pressed) {
      keyCount += 1;
      editorProcessKeypress(ARROW_UP);
    }

    if (foop.arrow_down_key_pressed) {
      keyCount += 1;
      editorProcessKeypress(ARROW_DOWN);
    }
  }

  if (IsKeyReleased(261)) {
    foop.debounce_timer = 0.0;
    foop.del_key_pressed = 0;
    //fprintf(stderr, "del enter\n");
  }

  if (IsKeyReleased(257)) {
    foop.debounce_timer = 0.0;
    foop.enter_key_pressed = 0;
    //fprintf(stderr, "done enter\n");
  }

  if (IsKeyReleased(258)) {
    foop.debounce_timer = 0.0;
    foop.tab_key_pressed = 0;
    //fprintf(stderr, "done tab\n");
  }

  if (IsKeyReleased(344)) {
    foop.debounce_timer = 0.0;
    foop.shift_key_pressed = 0;
    //fprintf(stderr, "done shift\n");
  }

//Key: 265 U
//Key: 262 R
//Key: 264 D
//Key: 263 L

  if (IsKeyReleased(265)) {
    foop.debounce_timer = 0.0;
    foop.arrow_up_key_pressed = 0;
    //fprintf(stderr, "done up arrow\n");
  }

  if (IsKeyReleased(262)) {
    foop.debounce_timer = 0.0;
    foop.arrow_right_key_pressed = 0;
    //fprintf(stderr, "done right arrow\n");
  }

  if (IsKeyReleased(263)) {
    foop.debounce_timer = 0.0;
    foop.arrow_left_key_pressed = 0;
    //fprintf(stderr, "done left arrow\n");
  }

  if (IsKeyReleased(264)) {
    foop.debounce_timer = 0.0;
    foop.arrow_down_key_pressed = 0;
    //fprintf(stderr, "done down arrow\n");
  }

  if (IsKeyReleased(341)) {
    foop.debounce_timer = 0.0;
    foop.ctrl_key_pressed = 0;
    //fprintf(stderr, "done ctrl\n");
  }

  if (IsKeyReleased(259)) {
    foop.debounce_timer = 0.0;
    foop.backspace_key_pressed = 0;
    //fprintf(stderr, "done backspace\n");
  }

  while (key = GetCharPressed()) {
    //fprintf(stderr, "Char: %d\n", key);
    if ((key >= 32) && (key <= 125)) // NOTE: Only allow keys in range [32..125]
    {
        keyCount += 1;
        editorProcessKeypress((char)key);
    }
    foop.debounce_timer = 0.0;
  }

  if (keyCount > 0) {
    struct abuf *ab2 = malloc(sizeof(struct abuf));
    ab2->b = NULL;
    ab2->len = 0;

    editorRefreshScreen(ab2);
    terminalRender(ab2->len, ab2->b);

    free(ab2->b);
    free(ab2);
  }

  mrb_value block;
  mrb_get_args(mrb, "&", &block);



        // Check if screen is resized
        if (IsWindowResized())
        {
            int screenWidth = GetScreenWidth();
            int screenHeight = GetScreenHeight();
            //float resolution[2] = { (float)screenWidth, (float)screenHeight };
            //SetShaderValue(shader, resolutionLoc, resolution, SHADER_UNIFORM_VEC2);
        }

  {
    BeginDrawing();
    ClearBackground((Color){0.0, 0.0, 0.0, 0.0});

    {
      mrb_yield_argv(mrb, block, 0, NULL);
    }

    //DrawTexture(terminalTexture(), 0, 0, (Color){255.0, 255.0, 255.0, 255.0} );

    EndDrawing();

    //SwapScreenBuffer();                  // Copy back buffer to front buffer (screen)

    //// Frame time control system
    //CORE.Time.current = GetTime();
    //CORE.Time.draw = CORE.Time.current - CORE.Time.previous;
    //CORE.Time.previous = CORE.Time.current;

    //CORE.Time.frame = CORE.Time.update + CORE.Time.draw;

    //PollInputEvents();      // Poll user events (before next frame update)
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
  //DrawText("dsdsd", 32.0, 32.0, textSize, RED);

  //////Vector3 cubePosition = p_data->position;
  //////Vector2 cubeScreenPosition;
  //////cubeScreenPosition = GetWorldToScreen((Vector3){cubePosition.x, cubePosition.y, cubePosition.z}, gl_p_data->camera);
  ////Vector2 ballPosition = { (float)512/2, (float)512/2 };
  ////DrawCircleV(ballPosition, 50, MAROON);
  //////fprintf(stderr, "wtf\n");
  
  EndMode2D();

  return mrb_nil_value();
}


//color and alpha is 255 based
static mrb_value game_loop_draw_circle(mrb_state* mrb, mrb_value self)
{
  mrb_float radius,x,y,z,r,g,b,a;

  mrb_get_args(mrb, "ffffffff", &radius, &x, &y, &z, &r, &g, &b, &a);

  //fprintf(stderr, "%f %f %f %f %f %f %f %f\n", radius, x, y, z, r, g, b, a);

  //DrawCircle(x, y, radius, (Color){ r, g, b, a });
  DrawCircleV((Vector2){ x, y }, radius, (Color){ r, g, b, a });
  //64.000000 75.000000 75.000000 0.000000 1.000000 1.000000 1.000000 1.000000
  //DrawCircleV((Vector2){ x, y }, radius, MAROON);

  return mrb_nil_value();
}


static mrb_value game_loop_draw_texture(mrb_state* mrb, mrb_value self)
{
  mrb_value texture_data;
  mrb_float x,y,z,r,g,b,a;

  mrb_get_args(mrb, "offfffff", &texture_data, &x, &y, &z, &r, &g, &b, &a);

  ////DrawCircle(x, y, radius, (Color){ r, g, b, a });
  //DrawCircleV((Vector2){ x, y }, radius, (Color){ r, g, b, a });

  texture_data_s *t_data = NULL;
  mrb_value data_value = mrb_iv_get(mrb, texture_data, mrb_intern_lit(mrb, "@pointer"));
  Data_Get_Struct(mrb, data_value, &texture_data_type, t_data);
  if (!t_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  DrawTexture(t_data->texture, x, y, (Color){ r, g, b, a });

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

  RayCollision nearestHit;
  char *hitObjectName = "None";
  nearestHit.distance = FLT_MAX;
  nearestHit.hit = false;
  Color cursorColor = RAYWHITE;

  Vector2 mousePosition = { -0.0f, -0.0f };

  mousePosition = GetMousePosition();

  mrb_ary_set(mrb, mousexyz, 0, mrb_float_value(mrb, mousePosition.x));
  mrb_ary_set(mrb, mousexyz, 1, mrb_float_value(mrb, mousePosition.y));
  mrb_ary_set(mrb, mousexyz, 2, mrb_int_value(mrb, IsMouseButtonDown(MOUSE_LEFT_BUTTON)));

  //TODO: debug window close
  //if (IsMouseButtonDown(MOUSE_LEFT_BUTTON)) {
  //  CloseWindow();
  //}

  return mrb_yield_argv(mrb, block, 3, &mousexyz);
}

static mrb_value model_label(mrb_state* mrb, mrb_value self)
{
  mrb_value label_txt = mrb_nil_value();
  mrb_value pointer_value;
  mrb_float x,y;
  mrb_get_args(mrb, "ffo", &x, &y, &label_txt);

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

  float textSize = 16.0;

  //Vector3 cubePosition = p_data->position;

  //Vector2 cubeScreenPosition;
  //cubeScreenPosition = GetWorldToScreen((Vector3){cubePosition.x, cubePosition.y, cubePosition.z}, gl_p_data->camera);
  //cubeScreenPosition = GetWorldToScreen((Vector3){0, 0, 0}, p_data->cameraTwo);
  //cubeScreenPosition = GetWorldToScreen2D((Vector2){512, 32}, p_data->cameraTwo);

  //DrawRectangle(cubeScreenPosition.x - (float)MeasureText(c_label_txt, textSize) / 2.0, cubeScreenPosition.y, 100, 64, RAYWHITE);
  //DrawText(c_label_txt, cubeScreenPosition.x - ((float)MeasureText(c_label_txt, textSize) / 2.0) + 32, cubeScreenPosition.y + 32, textSize, SKYBLUE);
  //fprintf(stdout, c_label_txt);
  //fprintf(stdout, "\n");
  DrawTextEx(the_font, c_label_txt, (Vector2){x + 8.0, y-(textSize/2.0)}, textSize, 1.0, SKYBLUE);  // Draw text using font and additional parameters

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
      //p_data->camera.type = CAMERA_ORTHOGRAPHIC;
      //SetCameraMode(p_data->camera, CAMERA_ORBITAL);
      SetCameraMode(p_data->camera, CAMERA_ORTHOGRAPHIC);
      break;
    case 1:
      //p_data->camera.type = CAMERA_PERSPECTIVE;
      //SetCameraMode(p_data->camera, CAMERA_ORBITAL);
      SetCameraMode(p_data->camera, CAMERA_PERSPECTIVE);
      break;
  }

  // Define the camera to look into our 3d world
  p_data->camera.position = (Vector3){ px, py, pz };    // Camera position
  p_data->camera.target = (Vector3){ tx, ty, tz };      // Camera looking at point

  //NOTE: Y IS UP
  p_data->camera.up = (Vector3){ 0.0f, 1.0f, 0.0f };    // Camera up vector (rotation towards target)
  p_data->camera.fovy = fovy;                           // Camera field-of-view Y

  p_data->cameraTwo.target = (Vector2){ 0, 0 };
  p_data->cameraTwo.offset = (Vector2){ 0, 0 };
  p_data->cameraTwo.rotation = 0.0f;
  p_data->cameraTwo.zoom = 1.0f;

  UpdateCamera(&p_data->camera);

  //TODO
  ////SetShaderValue(standardShader, standardShader.locs[LOC_VECTOR_VIEW], cameraPos, UNIFORM_VEC3);
  //// Update the light shader with the camera view position
  //float cameraPos[3] = { camera.position.x, camera.position.y, camera.position.z };

  //float cameraPos[3] = { p_data->camera.position.x, p_data->camera.position.y, p_data->camera.position.z };

  ////SetShaderValue(RLGL.State.defaultShaderId, p_data->globalDebugShader.locs[SHADER_LOC_VECTOR_VIEW], cameraPos, SHADER_UNIFORM_VEC3);

  //        //float cameraPos[3] = { camera.position.x, camera.position.y, camera.position.z };
  //                
  //                SetShaderValue(p_data->globalDebugShader, p_data->globalDebugShader.locs[SHADER_LOC_VECTOR_VIEW], cameraPos, SHADER_UNIFORM_VEC3);

  //                UpdateCamera(&p_data->camera);


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


static mrb_value game_loop_screenat(mrb_state* mrb, mrb_value self)
{
  mrb_int type;
  mrb_float wx,wy,wz;

  mrb_get_args(mrb, "fff", &wx, &wy, &wz);

  play_data_s *p_data = NULL;
  mrb_value data_value;     // this IV holds the data
  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &play_data_type, p_data);

  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  Vector2 foo = GetWorldToScreen((Vector3){wx, wy, wz}, p_data->camera); 

  mrb_value screenxy = mrb_ary_new(mrb);
  mrb_ary_set(mrb, screenxy, 0, mrb_float_value(mrb, foo.x));
  mrb_ary_set(mrb, screenxy, 1, mrb_float_value(mrb, foo.y));

  return screenxy;
}


//void DrawLight(Light light)
//{
//    switch (light.type)
//    {
//        case LIGHT_POINT:
//        {
//            DrawSphereWires(light.position, 0.3f*light.intensity, 8, 8, (light.enabled ? light.color : GRAY));
//            
//            DrawCircle3D(light.position, light.radius, (Vector3){ 0, 0, 0 }, 0.0f, (light.enabled ? light.color : GRAY));
//            DrawCircle3D(light.position, light.radius, (Vector3){ 1, 0, 0 }, 90.0f, (light.enabled ? light.color : GRAY));
//            DrawCircle3D(light.position, light.radius, (Vector3){ 0, 1, 0 },90.0f, (light.enabled ? light.color : GRAY));
//        } break;
//        case LIGHT_DIRECTIONAL:
//        {
//            DrawLine3D(light.position, light.target, (light.enabled ? light.color : GRAY));
//            
//            DrawSphereWires(light.position, 0.3f*light.intensity, 8, 8, (light.enabled ? light.color : GRAY));
//            DrawCubeWires(light.target, 0.3f, 0.3f, 0.3f, (light.enabled ? light.color : GRAY));
//        } break;
//        case LIGHT_SPOT:
//        {
//            DrawLine3D(light.position, light.target, (light.enabled ? light.color : GRAY));
//            
//            Vector3 dir = Vector3Subtract(light.target, light.position);
//            dir = Vector3Normalize(dir);
//            
//            DrawCircle3D(light.position, 0.5f, dir, 0.0f, (light.enabled ? light.color : GRAY));
//            
//            //DrawCylinderWires(light.position, 0.0f, 0.3f*light.coneAngle/50, 0.6f, 5, (light.enabled ? light.color : GRAY));
//            DrawCubeWires(light.target, 0.3f, 0.3f, 0.3f, (light.enabled ? light.color : GRAY));
//        } break;
//        default: break;
//    }
//}


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

  //UpdateLightValues(p_data->globalDebugShader, lights[0]);
  //UpdateLightValues(p_data->globalDebugShader, lights[1]);
  //UpdateLightValues(p_data->globalDebugShader, lights[2]);
  //UpdateLightValues(p_data->globalDebugShader, lights[3]);

  BeginMode3D(p_data->camera);


    mrb_yield_argv(mrb, block, 0, NULL);

    ////////////drawLighting
    //for (int i=0; i<MAX_LIGHTS; i++) {
    //  DrawLight(lights[i]);
    //}

    //// Draw markers to show where the lights are
    //if (lights[0].enabled) { DrawSphereEx(lights[0].position, 0.5f, 8, 8, BLUE); }
    //if (lights[1].enabled) { DrawSphereEx(lights[1].position, 2.0f, 8, 8, RED); }
    //if (lights[2].enabled) { DrawSphereEx(lights[2].position, 2.0f, 8, 8, GREEN); }
    //if (lights[3].enabled) { DrawSphereEx(lights[3].position, 2.0f, 8, 8, BLUE); }
    //DrawGrid(10, 1.0f);
    DrawGrid(100, 1.0); 

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
  mrb_define_method(mrb, game_class, "screenat", game_loop_screenat, MRB_ARGS_REQ(3));
  mrb_define_method(mrb, game_class, "drawmode", game_loop_drawmode, MRB_ARGS_BLOCK());
  mrb_define_method(mrb, game_class, "twod", game_loop_twod, MRB_ARGS_BLOCK());
  mrb_define_method(mrb, game_class, "threed", game_loop_threed, MRB_ARGS_BLOCK());
  mrb_define_method(mrb, game_class, "draw_circle", game_loop_draw_circle, MRB_ARGS_REQ(8));
  mrb_define_method(mrb, game_class, "mousep", game_loop_mousep, MRB_ARGS_BLOCK());
  mrb_define_method(mrb, game_class, "label", model_label, MRB_ARGS_REQ(3));
  mrb_define_method(mrb, game_class, "keyspressed", game_loop_keyspressed, MRB_ARGS_ANY());
  mrb_define_method(mrb, game_class, "draw_texture", game_loop_draw_texture, MRB_ARGS_REQ(8));

  return game_class;
}
