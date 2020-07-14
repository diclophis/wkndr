//

//mrb_value platform_bits_update(mrb_state* mrb, mrb_value self);
//struct RClass *install_model_class = mrb_define_class(mrb_client, "Model", mrb->object_class);
struct RClass *mrb_define_game_loop(mrb_state *);

typedef struct {
  Camera3D camera;
  Camera2D cameraTwo;
  //RenderTexture2D buffer_target;
  Vector2 mousePosition;
} play_data_s;
