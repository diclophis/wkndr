//

// mruby stuff
#include <mruby.h>


struct RClass *mrb_define_game_loop(mrb_state *mrb) {
  //// class GameLoop
  //mousexyz = mrb_ary_new(mrb);
  //pressedkeys = mrb_ary_new(mrb);
  struct RClass *game_class = mrb_define_class(mrb, "GameLoop", mrb->object_class);
  //mrb_define_method(mrb, game_class, "initialize", game_loop_initialize, MRB_ARGS_REQ(1));
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
  //mrb_define_method(mrb, game_class, "open", platform_bits_open, MRB_ARGS_REQ(4));
  //mrb_define_method(mrb, game_class, "shutdown", platform_bits_shutdown, MRB_ARGS_NONE());
  //mrb_define_method(mrb, game_class, "draw_circle", game_loop_draw_circle, MRB_ARGS_REQ(8));

  return game_class;
}
