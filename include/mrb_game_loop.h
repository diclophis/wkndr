//

struct RClass *mrb_define_game_loop(mrb_state *);

typedef struct {
  Camera3D camera;
  Camera2D cameraTwo;
  //RenderTexture2D buffer_target;
  Vector2 mousePosition;
  Texture globalDebugTexture;
  Shader globalDebugShader;
} play_data_s;


typedef struct {
  Texture2D texture;
} texture_data_s;


void texture_data_destructor(mrb_state *mrb, void *p_);
