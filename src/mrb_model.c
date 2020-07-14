
#include <stdlib.h>
#include <math.h>
#include <string.h>

#include <mruby.h>
#include <raylib.h>
#include <raymath.h>

#include <mruby/data.h>
//#include <mruby/proc.h>
//#include <mruby/data.h>
#include <mruby/string.h>
//#include <mruby/array.h>
//#include <mruby/hash.h>
//#include <mruby/class.h>
#include <mruby/variable.h>

static int counter = 0;

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
  //Light light;
} model_data_s;

//static void model_data_destructor(mrb_state *mrb, void *p_);

//static void crisscross_data_destructor(mrb_state *mrb, void *p_) {
//}

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

const struct mrb_data_type model_data_type = {"model_data", model_data_destructor};


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

    //p_data->model.materials[mi].shader = standardShader;
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

  DrawModelEx(p_data->model, p_data->position, p_data->rotation, p_data->angle, p_data->scale, p_data->color);

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

  //play_data_s *gl_p_data = NULL;
  //Data_Get_Struct(mrb, pointer_value, &play_data_type, gl_p_data);
  //if (!gl_p_data) {
  //  mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  //}

  float textSize = 5.0;

  //TODO: pass above gl_p_data better
  //Vector3 cubePosition = p_data->position;
  //Vector2 cubeScreenPosition;
  //cubeScreenPosition = GetWorldToScreen((Vector3){cubePosition.x, cubePosition.y, cubePosition.z}, gl_p_data->camera);
  //DrawText(c_label_txt, cubeScreenPosition.x - (float)MeasureText(c_label_txt, textSize) / 2.0, cubeScreenPosition.y, textSize, p_data->label_color);

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

    //p_data->model.materials[mi].shader = standardShader;
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
  int g = (sin(freq * 1.0) * (127.0) + 128.0);
  int b = 128; //(sin(freq * abs(counter) + 3.0) * (127.0) + 128.0);

  //counter++;

  //if (counter == colors) {
  //  counter *= -1;
  //}

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


void mrb_mruby_model_gem_init(mrb_state *mrb) {
  // class Model
  struct RClass *model_class = mrb_define_class(mrb, "Model", mrb->object_class);
  mrb_define_method(mrb, model_class, "initialize", model_initialize, MRB_ARGS_REQ(3));
  mrb_define_method(mrb, model_class, "draw", model_draw, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, model_class, "deltap", model_deltap, MRB_ARGS_REQ(3));
  mrb_define_method(mrb, model_class, "deltar", model_deltar, MRB_ARGS_REQ(4));
  mrb_define_method(mrb, model_class, "deltas", model_deltas, MRB_ARGS_REQ(3));
  mrb_define_method(mrb, model_class, "yawpitchroll", model_yawpitchroll, MRB_ARGS_REQ(6));
  mrb_define_method(mrb, model_class, "label", model_label, MRB_ARGS_REQ(1));

  // class Cube
  struct RClass *cube_class = mrb_define_class(mrb, "Cube", model_class);
  mrb_define_method(mrb, cube_class, "initialize", cube_initialize, MRB_ARGS_REQ(4));
}
