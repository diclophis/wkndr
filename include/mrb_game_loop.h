//

struct RClass *mrb_define_game_loop(mrb_state *);

typedef struct {
  Camera3D camera;
  Camera2D cameraTwo;
  //RenderTexture2D buffer_target;
  Vector2 mousePosition;
} play_data_s;
