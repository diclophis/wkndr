//

#include <stdlib.h>
#include <math.h>
#include <string.h>

#include <mruby.h>
#include <raylib.h>
#include <raymath.h>
#include <rlgl.h>

#include <mruby/data.h>
#include <mruby/string.h>
#include <mruby/variable.h>

#include <mrb_game_loop.h>

extern struct mrb_data_type play_data_type;

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
  //TODO Light light;
} model_data_s;

typedef struct {
  Matrix *transforms;
  model_data_s* meshless_proxies;
  int count;
} batch_data_s;

//static void model_data_destructor(mrb_state *mrb, void *p_);

//static void crisscross_data_destructor(mrb_state *mrb, void *p_) {
//}
static void batch_data_destructor(mrb_state *mrb, void *p_) {
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

const struct mrb_data_type model_data_type = {"model_data", model_data_destructor};
const struct mrb_data_type batch_data_type = {"batch_data", batch_data_destructor};


static mrb_value model_initialize(mrb_state* mrb, mrb_value self)
{
  mrb_value model_game_loop = mrb_nil_value();
  mrb_value model_obj = mrb_nil_value();
  mrb_value model_png = mrb_nil_value();
  mrb_float scalef;

  mrb_get_args(mrb, "ooof", &model_game_loop, &model_obj, &model_png, &scalef);

  const char *c_model_obj = mrb_string_value_cstr(mrb, &model_obj);
  const char *c_model_png = mrb_string_value_cstr(mrb, &model_png);

  model_data_s *p_data;

  p_data = malloc(sizeof(model_data_s));
  memset(p_data, 0, sizeof(model_data_s));
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not allocate Model");
  }

  p_data->model = LoadModel(c_model_obj); // Load OBJ model

  for (int meshi=0; meshi<p_data->model.meshCount; meshi++) {
    MeshTangents(&p_data->model.meshes[meshi]);
  }
  
  p_data->position.x = 0.0f;
  p_data->position.y = 0.0f;
  p_data->position.z = 0.0f;

  p_data->rotation.x = 0.0f;
  p_data->rotation.y = 1.0f;
  p_data->rotation.z = 0.0f; // Set model position

  p_data->angle = 0.0;

  play_data_s *pp_data = NULL;
  mrb_value data_value = mrb_iv_get(mrb, model_game_loop, mrb_intern_lit(mrb, "@pointer"));
  Data_Get_Struct(mrb, data_value, &play_data_type, pp_data);
  if (!pp_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }
  Shader standardShader = pp_data->globalDebugShader;
  Texture standardTexture = pp_data->globalDebugTexture;
  for (int mi=0; mi<p_data->model.materialCount; mi++) {
    //p_data->model.materials[mi].maps[MAP_DIFFUSE].texture = standardTexture;
    p_data->model.materials[mi].shader = standardShader;
  }

  p_data->scale.x = scalef;
  p_data->scale.y = scalef;
  p_data->scale.z = scalef;

  //p_data->color.r = 255;
  //p_data->color.g = 0;
  //p_data->color.b = 128;
  //p_data->color.a = 255;

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

  return mrb_nil_value();
}


static mrb_value cube_initialize(mrb_state* mrb, mrb_value self)
{
  mrb_float w,h,l,scalef;
  mrb_value model_game_loop;
  mrb_get_args(mrb, "offff", &model_game_loop, &w, &h, &l, &scalef);

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

  play_data_s *pp_data = NULL;
  mrb_value data_value = mrb_iv_get(mrb, model_game_loop, mrb_intern_lit(mrb, "@pointer"));
  Data_Get_Struct(mrb, data_value, &play_data_type, pp_data);
  if (!pp_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }
  Shader standardShader = pp_data->globalDebugShader;
  Texture standardTexture = pp_data->globalDebugTexture;
  
  //for (int mi=0; mi<p_data->model.materialCount; mi++) {
  //  //p_data->model.materials[mi].maps[MAP_DIFFUSE].texture = standardTexture;
  //  p_data->model.materials[mi].shader = standardShader;
  //}

  Material material = LoadMaterialDefault();
  material.shader = standardShader;
  material.maps[MAP_DIFFUSE].color = RED;

  p_data->model.materials[0] = material;

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

  //p_data->color.r = 255;
  //p_data->color.g = g;
  //p_data->color.b = b;
  //p_data->color.a = 255;

  p_data->color.r = 255;
  p_data->color.g = 255;
  p_data->color.b = 255;
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


//    //static mrb_value mesh_proxy_initialize(mrb_state* mrb, mrb_value self)
static mrb_value batcher_at(mrb_state* mrb, mrb_value self)
{
  mrb_int ind;
  mrb_get_args(mrb, "i", &ind);

  batch_data_s *b_data = NULL;
  mrb_value data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));
  Data_Get_Struct(mrb, data_value, &batch_data_type, b_data);
  if (!b_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  model_data_s *p_data_pointer = &b_data->meshless_proxies[ind];

  mrb_value obj = mrb_obj_value(
                    Data_Wrap_Struct(mrb, mrb->object_class, &model_data_type, p_data_pointer)
                  );

  mrb_int argc = 1;
  mrb_value argv[1];

  argv[0] = obj;

  mrb_value resulting_proxy = mrb_obj_new(mrb, mrb_class_get(mrb, "MeshProxy"), argc, argv);

  //struct RClass* _class_uv;
  //struct RClass* _class_uv_ip4addr;
  //mrb_get_args(mrb, "*", &argv, &argc);
  //_class_uv = mrb_module_get(mrb, "UV");
  //_class_uv_ip4addr = mrb_class_get_under(mrb, _class_uv, "Ip4Addr");
  //return mrb_obj_new(mrb, _class_uv_ip4addr, argc, argv);



//      //   //mrb_float w,h,l,scalef;
//      //   //mrb_value model_game_loop;
//      //   //mrb_get_args(mrb, "offff", &model_game_loop, &w, &h, &l, &scalef);
//    
//      //   //GIVEN POINTER!!!???!!!!!!!!!!!!
//      //   mrb_value some_batch_reference;
//      //   mrb_get_args(mrb, "o", &some_batch_reference);
//    
//      //   //batch_data_bb *bb_data;
//      //   //bb_data = malloc(sizeof(batch_data_bb));
//      //   //memset(bb_data, 0, sizeof(batch_data_bb));
//      //   //if (!bb_data) {
//      //   //  mrb_raise(mrb, E_RUNTIME_ERROR, "Could not allocate CubicXXX");
//      //   //}
//      //   ////Data_Get_Struct(mrb, data_value, &play_data_type, pp_data);
//      //   ////if (!pp_data) {
//      //   ////  mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
//      //   ////}
//      //   
//      //   //this p_data shoul dreference passed pointers bits-fu
//    
//      //   ////TODO: pointer to pointer p_data->mesh = GenMeshCube(w, h, l);
//      //   ////p_data->model = LoadModelFromMesh(p_data->mesh);
//    
//      //   //////model_game_loop reference "o" get_args
//      //   ////play_data_s *pp_data = NULL;
//      //   ////mrb_value data_value = mrb_iv_get(mrb, model_game_loop, mrb_intern_lit(mrb, "@pointer"));
//      //   ////Data_Get_Struct(mrb, data_value, &play_data_type, pp_data);
//      //   ////if (!pp_data) {
//      //   ////  mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
//      //   ////}
//    
//      //   //p_data->position.x = 0.0f;
//      //   //p_data->position.y = 0.0f;
//      //   //p_data->position.z = 0.0f;
//    
//      //   //p_data->rotation.x = 0.0f;
//      //   //p_data->rotation.y = 1.0f;
//      //   //p_data->rotation.z = 0.0f; // Set model position
//      //   //p_data->angle = 0.0;
//      //   //
//      //   //p_data->scale.x = scalef;
//      //   //p_data->scale.y = scalef;
//      //   //p_data->scale.z = scalef;
//    
//      //   //float colors = 32.0;
//      //   //float freq = 64.0 / colors;
//    
//      //   //int r = 128; //(sin(freq * abs(counter) + 0.0) * (127.0) + 128.0);
//      //   //int g = (sin(freq * 1.0) * (127.0) + 128.0);
//      //   //int b = 128; //(sin(freq * abs(counter) + 3.0) * (127.0) + 128.0);
//    
//      //   //p_data->color.r = 255;
//      //   //p_data->color.g = 255;
//      //   //p_data->color.b = 255;
//      //   //p_data->color.a = 255;
//    
//      //   //r = (sin(freq * abs(counter) + 0.0) * (127.0) + 128.0);
//      //   //g = (sin(freq * abs(counter) + 1.0) * (127.0) + 128.0);
//      //   //b = (sin(freq * abs(counter) + 3.0) * (127.0) + 128.0);
//    
//      //   //counter++;
//    
//      //   //if (counter == colors) {
//      //   //  counter *= -1;
//      //   //}
//    
//      //   //p_data->label_color.r = r;
//      //   //p_data->label_color.g = g;
//      //   //p_data->label_color.b = b;
//      //   //p_data->label_color.a = 255;
//    
//      //   //mrb_iv_set(
//      //   //    mrb, self, mrb_intern_lit(mrb, "@pointer"),
//      //   //    mrb_obj_value(
//      //   //        Data_Wrap_Struct(mrb, mrb->object_class, &model_data_type, p_data)));
//    
//    //RETURN @POINTER
//    
//      //return self;
//    }
//    
//    //proxy_deltap
//    //proxy_deltar
//    //proxy_deltal
//    //batch_data_type
//    //b_data = batch_data_s
//    //
//    //for (int i = 0; i < count; i++) {
//    //  b_data->rotations[i]
//    //  b_data->translations[i]
//    //  b_data->transforms[i] = MatrixMultiply(rotations[i], translations[i]);
//    //}
//    
//    
//    //* transforms Matrix
//    //* meshless_models ModelDataP
//    
//    
//    static mrb_value batcher_hydrate(mrb_state* mrb, mrb_value self)
//    {
//      // class ........ material!!, transforms = 
//      //                                Matrix* transforms = RL_MALLOC(count * sizeof(Matrix));
//      //  Pre-multiplied transformations passed to rlgl
//      //
//    
//      ///!!!!batcher_fill_in_transform_here!!!
//      //transforms[i] = MatrixMultiply(rotations[i], translations[i]);
//      //!!!!!!!!!!!
//    
//      //   ////play_data_s *pp_data = NULL;
//      //   ////mrb_value data_value = mrb_iv_get(mrb, model_game_loop, mrb_intern_lit(mrb, "@pointer"));
//      //   ////Data_Get_Struct(mrb, data_value, &play_data_type, pp_data);
//      //   ////if (!pp_data) {
//      //   ////  mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @meshes");
//      //   ////}
//    
//    
//      Model model = { 0 };
//      model.transform = MatrixIdentity();
//    
//      mrb_value meshes_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@meshes"));
//      mrb_value count = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@count"));
//    }
//    
//    
//    
  return resulting_proxy;
}


static mrb_value batcher_draw(mrb_state* mrb, mrb_value self)
{
//      //mrb_value label_txt = mrb_nil_value();
//      //mrb_value pointer_value;
//      //mrb_get_args(mrb, "oo", &pointer_value, &label_txt);
//    
//      //const char *c_label_txt = mrb_string_value_cstr(mrb, &label_txt);
//    
//    

  mrb_int count = mrb_int(mrb, mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@count")));

  batch_data_s *b_data = NULL;
  mrb_value data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));
  Data_Get_Struct(mrb, data_value, &batch_data_type, b_data);
  if (!b_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  for (int i = 0; i < count; i++) {
    model_data_s p_data = b_data->meshless_proxies[0];

    //Matrix matScale = MatrixScale(p_data.scale.x, p_data.scale.y, p_data.scale.z);
    Matrix matRotation = MatrixRotate(p_data.rotation, p_data.angle*DEG2RAD);
    Matrix matTranslation = MatrixTranslate(p_data.position.x, p_data.position.y, p_data.position.z);
    //Matrix matTransform = MatrixMultiply(MatrixMultiply(matScale, matRotation), matTranslation);

    Matrix matTransform = MatrixIdentity();

    //b_data->transforms[i] = matTransform;

    b_data->transforms[i] = MatrixMultiply(MatrixMultiply(matTransform, matRotation), matTranslation);

    //  MatrixMultiply(
    //    MatrixIdentity(),
    //    MatrixRotate(p_data.rotation, p_data.angle*DEG2RAD)
    //  ),
    //  MatrixTranslate(p_data.position.x, p_data.position.y, p_data.position.z)
    //);
  }

  model_data_s *og_data = NULL;
  mrb_value og_value; // this IV holds the data
  mrb_value og_og_value; // this IV holds the data
  og_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@model"));
  og_og_value = mrb_iv_get(mrb, og_value, mrb_intern_lit(mrb, "@pointer"));
  Data_Get_Struct(mrb, og_og_value, &model_data_type, og_data);
  if (!og_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  rlDrawMeshInstanced(og_data->mesh, og_data->model.materials[0], b_data->transforms, count);
}


//NEW FROM POINTER!!!!!
static mrb_value mesh_proxy_initialize(mrb_state* mrb, mrb_value self)
{
  mrb_value model_pointer = mrb_nil_value();

  mrb_get_args(mrb, "o", &model_pointer);

  model_data_s *p_data = NULL;
  //mrb_value data_value; // this IV holds the data
  //data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, model_pointer, &model_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  mrb_iv_set(
      mrb, self, mrb_intern_lit(mrb, "@pointer"),
      mrb_obj_value(
          Data_Wrap_Struct(mrb, mrb->object_class, &model_data_type, p_data)));

//     model_data_s *p_data;
//   
//     p_data = malloc(sizeof(model_data_s));
//     memset(p_data, 0, sizeof(model_data_s));
//     if (!p_data) {
//       mrb_raise(mrb, E_RUNTIME_ERROR, "Could not allocate Cube");
//     }
//   
//     //p_data->mesh = GenMeshCube(w, h, l);
//     //p_data->model = LoadModelFromMesh(p_data->mesh);
//     
//     //play_data_s *pp_data = NULL;
//     //mrb_value data_value = mrb_iv_get(mrb, model_game_loop, mrb_intern_lit(mrb, "@pointer"));
//     //Data_Get_Struct(mrb, data_value, &play_data_type, pp_data);
//     //if (!pp_data) {
//     //  mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
//     //}
//     //Shader standardShader = pp_data->globalDebugShader;
//     //Texture standardTexture = pp_data->globalDebugTexture;
//     //for (int mi=0; mi<p_data->model.materialCount; mi++) {
//     //  //p_data->model.materials[mi].maps[MAP_DIFFUSE].texture = standardTexture;
//     //  p_data->model.materials[mi].shader = standardShader;
//     //}
//   
//     ///!!!!batcher_fill_in_transform_here!!!
//     //transforms[i] = MatrixMultiply(rotations[i], translations[i]);
//     //!!!!!!!!!!!
//   
//     //p_data->position.x = 0.0f;
//     //p_data->position.y = 0.0f;
//     //p_data->position.z = 0.0f;
//   
//     //p_data->rotation.x = 0.0f;
//     //p_data->rotation.y = 1.0f;
//     //p_data->rotation.z = 0.0f; // Set model position
//     //p_data->angle = 0.0;
//     //
//     //p_data->scale.x = scalef;
//     //p_data->scale.y = scalef;
//     //p_data->scale.z = scalef;
//   
//     //float colors = 32.0;
//     //float freq = 64.0 / colors;
//   
//     //int r = 128; //(sin(freq * abs(counter) + 0.0) * (127.0) + 128.0);
//     //int g = (sin(freq * 1.0) * (127.0) + 128.0);
//     //int b = 128; //(sin(freq * abs(counter) + 3.0) * (127.0) + 128.0);
//   
//     ////counter++;
//     ////if (counter == colors) {
//     ////  counter *= -1;
//     ////}
//   
//     ////p_data->color.r = 255;
//     ////p_data->color.g = g;
//     ////p_data->color.b = b;
//     ////p_data->color.a = 255;
//   
//     //p_data->color.r = 255;
//     //p_data->color.g = 255;
//     //p_data->color.b = 255;
//     //p_data->color.a = 255;
//   
//     //r = (sin(freq * abs(counter) + 0.0) * (127.0) + 128.0);
//     //g = (sin(freq * abs(counter) + 1.0) * (127.0) + 128.0);
//     //b = (sin(freq * abs(counter) + 3.0) * (127.0) + 128.0);
//   
//     //counter++;
//   
//     //if (counter == colors) {
//     //  counter *= -1;
//     //}
//   
//     //p_data->label_color.r = r;
//     //p_data->label_color.g = g;
//     //p_data->label_color.b = b;
//     //p_data->label_color.a = 255;
//   
//     mrb_iv_set(
//         mrb, self, mrb_intern_lit(mrb, "@pointer"),
//         mrb_obj_value(
//             Data_Wrap_Struct(mrb, mrb->object_class, &model_data_type, p_data)));
//   
  return self;
}


/////////////////////////////////////////////////////////////////////////////



static mrb_value batcher_initialize(mrb_state* mrb, mrb_value self)
{
  //mrb_value model_game_loop = mrb_nil_value();
  //mrb_value model_obj = mrb_nil_value();
  //mrb_value model_png = mrb_nil_value();
  //mrb_float scalef;
  //mrb_get_args(mrb, "ooof", &model_game_loop, &model_obj, &model_png, &scalef);

  mrb_value storage = mrb_nil_value();
  mrb_value model = mrb_nil_value();
  mrb_int count;

  mrb_get_args(mrb, "ooi", &storage, &model, &count);

  mrb_iv_set(
      mrb, self, mrb_intern_lit(mrb, "@storage"),
      storage
  );

  mrb_iv_set(
      mrb, self, mrb_intern_lit(mrb, "@model"),
      model
  );

  mrb_iv_set(
      mrb, self, mrb_intern_lit(mrb, "@count"),
      mrb_fixnum_value(count)
  );


  batch_data_s *b_data;

  b_data = malloc(sizeof(batch_data_s));
  memset(b_data, 0, sizeof(batch_data_s));

  b_data->transforms = RL_MALLOC(count * sizeof(Matrix));
  b_data->meshless_proxies = malloc(sizeof(model_data_s) * count);

  for (int i = 0; i < count; i++) {
    model_data_s p_data = b_data->meshless_proxies[0];

    p_data.position.x = 0.0f;
    p_data.position.y = 0.0f;
    p_data.position.z = 0.0f;

    p_data.rotation.x = 0.0f;
    p_data.rotation.y = 1.0f;
    p_data.rotation.z = 0.0f; // Set model position
  }


//    
//    
//    //* transforms Matrix
//    //* meshless_models ModelDataP
//    
//    
//    static mrb_value batcher_hydrate(mrb_state* mrb, mrb_value self)
//    {
//      // class ........ material!!, transforms = 
//      //                                Matrix* transforms = RL_MALLOC(count * sizeof(Matrix));
//      //  Pre-multiplied transformations passed to rlgl
//      //

  //const char *c_model_obj = mrb_string_value_cstr(mrb, &model_obj);
  //const char *c_model_png = mrb_string_value_cstr(mrb, &model_png);

  //model_data_s *p_data;

  //p_data = malloc(sizeof(model_data_s));
  //memset(p_data, 0, sizeof(model_data_s));
  //if (!p_data) {
  //  mrb_raise(mrb, E_RUNTIME_ERROR, "Could not allocate Model");
  //}

  //p_data->model = LoadModel(c_model_obj); // Load OBJ model

  //for (int meshi=0; meshi<p_data->model.meshCount; meshi++) {
  //  MeshTangents(&p_data->model.meshes[meshi]);
  //}
  //
  //p_data->position.x = 0.0f;
  //p_data->position.y = 0.0f;
  //p_data->position.z = 0.0f;

  //p_data->rotation.x = 0.0f;
  //p_data->rotation.y = 1.0f;
  //p_data->rotation.z = 0.0f; // Set model position

  //p_data->angle = 0.0;

  //play_data_s *pp_data = NULL;
  //mrb_value data_value = mrb_iv_get(mrb, model_game_loop, mrb_intern_lit(mrb, "@pointer"));
  //Data_Get_Struct(mrb, data_value, &play_data_type, pp_data);
  //if (!pp_data) {
  //  mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  //}
  //Shader standardShader = pp_data->globalDebugShader;
  //Texture standardTexture = pp_data->globalDebugTexture;
  //for (int mi=0; mi<p_data->model.materialCount; mi++) {
  //  //p_data->model.materials[mi].maps[MAP_DIFFUSE].texture = standardTexture;
  //  p_data->model.materials[mi].shader = standardShader;
  //}

  //p_data->scale.x = scalef;
  //p_data->scale.y = scalef;
  //p_data->scale.z = scalef;

  ////p_data->color.r = 255;
  ////p_data->color.g = 0;
  ////p_data->color.b = 128;
  ////p_data->color.a = 255;

  //p_data->color.r = 255;
  //p_data->color.g = 255;
  //p_data->color.b = 255;
  //p_data->color.a = 255;

  //p_data->label_color.r = 255;
  //p_data->label_color.g = 255;
  //p_data->label_color.b = 255;
  //p_data->label_color.a = 255;

  mrb_iv_set(
      mrb, self, mrb_intern_lit(mrb, "@pointer"),
      mrb_obj_value(
          Data_Wrap_Struct(mrb, mrb->object_class, &batch_data_type, b_data)));

  return self;
}


void mrb_mruby_model_gem_init(mrb_state *mrb) {
  // class Model
  struct RClass *model_class = mrb_define_class(mrb, "Model", mrb->object_class);
  mrb_define_method(mrb, model_class, "initialize", model_initialize, MRB_ARGS_REQ(5));
  mrb_define_method(mrb, model_class, "draw", model_draw, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, model_class, "deltap", model_deltap, MRB_ARGS_REQ(3));
  mrb_define_method(mrb, model_class, "deltar", model_deltar, MRB_ARGS_REQ(4));
  mrb_define_method(mrb, model_class, "deltas", model_deltas, MRB_ARGS_REQ(3));
  mrb_define_method(mrb, model_class, "yawpitchroll", model_yawpitchroll, MRB_ARGS_REQ(6));
  mrb_define_method(mrb, model_class, "label", model_label, MRB_ARGS_REQ(1));

  // class Cube
  struct RClass *cube_class = mrb_define_class(mrb, "Cube", model_class);
  mrb_define_method(mrb, cube_class, "initialize", cube_initialize, MRB_ARGS_REQ(5));

  //// class MeshProxy
  struct RClass *mesh_proxy_class = mrb_define_class(mrb, "MeshProxy", model_class);
  mrb_define_method(mrb, mesh_proxy_class, "initialize", mesh_proxy_initialize, MRB_ARGS_REQ(1));

  // class Batcher
  struct RClass *batcher_class = mrb_define_class(mrb, "CubicBatchingSystem", mrb->object_class);
  mrb_define_method(mrb, batcher_class, "initialize", batcher_initialize, MRB_ARGS_REQ(3));

  //mrb_define_method(mrb, batcher_class, "hydrate", batcher_hydrate, MRB_ARGS_REQ(0));
  mrb_define_method(mrb, batcher_class, "at", batcher_at, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, batcher_class, "draw", batcher_draw, MRB_ARGS_REQ(0));
}
