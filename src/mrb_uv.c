//

#include "mrb_uv.h"

#include <fcntl.h>













static void mrb_uv_stat_free(mrb_state *mrb, void *p) {
  mrb_free(mrb, p);
}


static struct mrb_data_type const mrb_uv_stat_type = {
  "uv_stat", mrb_uv_stat_free
};


mrb_value mrb_uv_create_stat(mrb_state *mrb, uv_stat_t const *src_st) {
  uv_stat_t *st;
  struct RClass *cls;

  cls = mrb_class_get_under(mrb, mrb_module_get(mrb, "UV"), "Stat");
  st = (uv_stat_t*)mrb_malloc(mrb, sizeof(uv_stat_t));
  *st = *src_st; /* copy */
  return mrb_obj_value(mrb_data_object_alloc(mrb, cls, st, &mrb_uv_stat_type));
}

#define stat_field(n)                                                   \
  static mrb_value                                                      \
  mrb_uv_stat_ ## n(mrb_state *mrb, mrb_value self)                     \
  {                                                                     \
    uv_stat_t *st = (uv_stat_t*)mrb_uv_get_ptr(mrb, self, &mrb_uv_stat_type); \
    return mrb_uv_from_uint64(mrb, st->st_ ## n);                       \
  }                                                                     \

stat_field(dev)
stat_field(mode)
stat_field(nlink)
stat_field(uid)
stat_field(gid)
stat_field(rdev)
stat_field(ino)
stat_field(size)
stat_field(blksize)
stat_field(blocks)
stat_field(flags)
stat_field(gen)

#undef stat_field

#define stat_time_field(n)                                              \
  static mrb_value                                                      \
  mrb_uv_stat_ ## n(mrb_state *mrb, mrb_value self)                     \
  {                                                                     \
    uv_stat_t *st = (uv_stat_t*)mrb_uv_get_ptr(mrb, self, &mrb_uv_stat_type); \
    return mrb_funcall(mrb, mrb_obj_value(mrb_class_get(mrb, "Time")), "at", 2, \
                       mrb_uv_from_uint64(mrb, st->st_ ## n.tv_sec),    \
                       mrb_uv_from_uint64(mrb, st->st_ ## n.tv_nsec / 1000)); \
  }                                                                     \

stat_time_field(atim)
stat_time_field(mtim)
stat_time_field(ctim)
stat_time_field(birthtim)

#undef stat_time_field

/*********************************************************
 * UV::FS
 *********************************************************/
typedef struct {
  mrb_state* mrb;
  mrb_value instance;
  uv_file fd;
} mrb_uv_file;

static void
mrb_uv_fs_free(mrb_state *mrb, void *p)
{
  mrb_uv_file *ctx = (mrb_uv_file*)p;
  if (ctx) {
    uv_fs_t req;
    req.data = ctx;
    uv_fs_close(uv_default_loop(), &req, ctx->fd, NULL);
    mrb_free(mrb, ctx);
  }
}

static const struct mrb_data_type mrb_uv_file_type = {
  "uv_file", mrb_uv_fs_free
};

uv_file
mrb_uv_to_fd(mrb_state *mrb, mrb_value v)
{
  if (mrb_fixnum_p(v)) {
    return mrb_fixnum(v);
  }

  return ((mrb_uv_file*)mrb_uv_get_ptr(mrb, v, &mrb_uv_file_type))->fd;
}

static mrb_value
dirtype_to_sym(mrb_state *mrb, uv_dirent_type_t t)
{
  mrb_sym ret;
  switch(t) {
  case UV_DIRENT_FILE: ret = mrb_intern_lit(mrb, "file"); break;
  case UV_DIRENT_DIR: ret = mrb_intern_lit(mrb, "dir"); break;
  case UV_DIRENT_LINK: ret = mrb_intern_lit(mrb, "link"); break;
  case UV_DIRENT_FIFO: ret = mrb_intern_lit(mrb, "fifo"); break;
  case UV_DIRENT_SOCKET: ret = mrb_intern_lit(mrb, "socket"); break;
  case UV_DIRENT_CHAR: ret = mrb_intern_lit(mrb, "char"); break;
  case UV_DIRENT_BLOCK: ret = mrb_intern_lit(mrb, "block"); break;

  default:
  case UV_DIRENT_UNKNOWN: ret = mrb_intern_lit(mrb, "unknown"); break;
  }
  return mrb_symbol_value(ret);
}

static mrb_value
dir_to_array(mrb_state *mrb, uv_fs_t *req)
{
  mrb_value ret = mrb_ary_new_capa(mrb, req->result);
  int ai = mrb_gc_arena_save(mrb);
  uv_dirent_t ent;

  while (uv_fs_scandir_next(req, &ent) != UV_EOF) {
    mrb_ary_push(mrb, ret, mrb_assoc_new(mrb, mrb_str_new_cstr(mrb, ent.name), dirtype_to_sym(mrb, ent.type)));
    mrb_gc_arena_restore(mrb, ai);
  }

  return ret;
}

static void
_uv_fs_cb(uv_fs_t* uv_req)
{
  mrb_uv_req_t* req = (mrb_uv_req_t*) uv_req->data;
  mrb_state* mrb = req->mrb;

  mrb_assert(!mrb_nil_p(req->block));

  if (uv_req->result < 0) {
    mrb_value const err = mrb_uv_create_error(mrb, uv_req->result);
    mrb_uv_req_yield(req, 1, &err);
    return;
  }

  switch (uv_req->fs_type) {
  case UV_FS_MKDTEMP: {
    mrb_value const str = mrb_str_new_cstr(mrb, uv_req->path);
    mrb_uv_req_yield(req, 1, &str);
  } break;

  case UV_FS_ACCESS: {
    mrb_value const arg = mrb_uv_create_status(mrb, uv_req->result);
    mrb_uv_req_yield(req, 1, &arg);
  } break;

#if MRB_UV_CHECK_VERSION(1, 14, 0)
  case UV_FS_COPYFILE: {
    mrb_uv_req_yield(req, 0, NULL);
  } break;
#endif

  case UV_FS_SCANDIR: {
    mrb_value const ary = dir_to_array(mrb, uv_req);
    mrb_uv_req_yield(req, 1, &ary);
  } break;

#if MRB_UV_CHECK_VERSION(1, 8, 0)
  case UV_FS_REALPATH:
#endif
  case UV_FS_READLINK: {
    mrb_value const res = mrb_str_new_cstr(mrb, uv_req->ptr);
    mrb_uv_req_yield(req, 1, &res);
  } break;

  case UV_FS_STAT:
  case UV_FS_FSTAT:
  case UV_FS_LSTAT: {
    mrb_value const res = mrb_uv_create_stat(mrb, &uv_req->statbuf);
    mrb_uv_req_yield(req, 1, &res);
  } break;

  default: {
      mrb_value const res = mrb_fixnum_value(uv_req->result);
      mrb_uv_req_yield(req, 1, &res);
    } break;
  }
}

static mrb_value
mrb_uv_fs_fd(mrb_state *mrb, mrb_value self)
{
  mrb_uv_file *ctx = (mrb_uv_file*)mrb_uv_get_ptr(mrb, self, &mrb_uv_file_type);
  return mrb_fixnum_value(ctx->fd);
}

static void
_uv_fs_open_cb(uv_fs_t* uv_req)
{
  mrb_uv_req_t *req = (mrb_uv_req_t*)uv_req->data;
  mrb_state* mrb = req->mrb;
  mrb_value args[2];
  mrb_uv_file *file;

  args[0] = mrb_iv_get(mrb, req->instance, mrb_intern_lit(mrb, "fs_open"));
  args[1] = mrb_uv_create_status(mrb, uv_req->result);
  mrb_iv_set(mrb, req->instance, mrb_intern_lit(mrb, "fs_open"), mrb_nil_value());
  file = (mrb_uv_file*)DATA_PTR(args[0]);
  file->fd = uv_req->result;
  mrb_uv_req_yield(req, 2, args);
}

static mrb_value
mrb_uv_fs_open(mrb_state *mrb, mrb_value self)
{
  char const *arg_filename;
  mrb_value c, b, ret;
  mrb_int arg_flags, arg_mode;
  struct RClass* _class_uv_fs;
  mrb_uv_file* context;
  mrb_uv_req_t* req;
  int res;

  mrb_get_args(mrb, "&zii", &b, &arg_filename, &arg_flags, &arg_mode);

  _class_uv_fs = mrb_class_get_under(mrb, mrb_module_get(mrb, "UV"), "FS");
  c = mrb_obj_value(mrb_obj_alloc(mrb, MRB_TT_DATA, _class_uv_fs));
  context = (mrb_uv_file*)mrb_malloc(mrb, sizeof(mrb_uv_file));
  context->mrb = mrb;
  context->instance = c;
  context->fd = -1;
  DATA_PTR(c) = context;
  DATA_TYPE(c) = &mrb_uv_file_type;

  req = mrb_uv_req_current(mrb, b, &ret);
  res = uv_fs_open(mrb_uv_current_loop(mrb), &req->req.fs,
                   arg_filename, arg_flags, arg_mode, mrb_nil_p(req->block)? NULL : _uv_fs_open_cb);
  mrb_uv_req_check_error(mrb, req, res);
  if (mrb_nil_p(req->block)) {
    context->fd = res;
    return c;
  }
  mrb_iv_set(mrb, req->instance, mrb_intern_lit(mrb, "fs_open"), c);
  return ret;
}

static mrb_value
mrb_uv_fs_close(mrb_state *mrb, mrb_value self)
{
  mrb_uv_file* context = (mrb_uv_file*)mrb_uv_get_ptr(mrb, self, &mrb_uv_file_type);
  mrb_value b, ret;
  mrb_uv_req_t *req;

  mrb_get_args(mrb, "&", &b);

  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_check_error(mrb, req, uv_fs_close(
      mrb_uv_current_loop(mrb), &req->req.fs, context->fd, mrb_nil_p(req->block)? NULL : _uv_fs_cb));
  if (mrb_nil_p(req->block)) {
    context->fd = -1;
  }
  return ret;
}

static mrb_value
mrb_uv_fs_write(mrb_state *mrb, mrb_value self)
{
  mrb_value arg_data = mrb_nil_value();
  mrb_int arg_length = -1;
  mrb_int arg_offset = 0;
  mrb_uv_file* context = (mrb_uv_file*)mrb_uv_get_ptr(mrb, self, &mrb_uv_file_type);
  mrb_value b, ret;
  mrb_uv_req_t *req;
  uv_buf_t buf;
  int r;

  mrb_get_args(mrb, "&S|ii", &b, &arg_data, &arg_offset, &arg_length);

  if (arg_length == -1)
    arg_length = RSTRING_LEN(arg_data);
  if (arg_offset < 0)
    arg_offset = 0;
  mrb_str_resize(mrb, arg_data, arg_length);

  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_set_buf(req, &buf, arg_data);
  mrb_uv_req_check_error(mrb, req, r = uv_fs_write(
      mrb_uv_current_loop(mrb), &req->req.fs,
      context->fd, &buf, 1, arg_offset, mrb_nil_p(req->block)? NULL : _uv_fs_cb));
  return mrb_nil_p(req->block)? mrb_fixnum_value(r) : ret;
}

static mrb_value
mrb_uv_fs_read(mrb_state *mrb, mrb_value self)
{
  mrb_int arg_length = BUFSIZ, arg_offset = 0;
  mrb_uv_file* context = (mrb_uv_file*)mrb_uv_get_ptr(mrb, self, &mrb_uv_file_type);
  mrb_value b, buf_str, ret;
  uv_buf_t buf;
  mrb_uv_req_t* req;
  int res;

  mrb_get_args(mrb, "&|ii", &b, &arg_length, &arg_offset);

  buf_str = mrb_str_resize(mrb, mrb_str_buf_new(mrb, arg_length), arg_length);
  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_set_buf(req, &buf, buf_str);
  res = uv_fs_read(mrb_uv_current_loop(mrb), &req->req.fs, context->fd,
                       &buf, 1, arg_offset, mrb_nil_p(req->block)? NULL : _uv_fs_cb);
  mrb_uv_req_check_error(mrb, req, res);
  if (mrb_nil_p(req->block)) {
    mrb_str_resize(mrb, buf_str, res);
    return buf_str;
  }
  return ret;
}

static mrb_value
mrb_uv_fs_unlink(mrb_state *mrb, mrb_value self)
{
  char const *arg_path;
  mrb_value b, ret;
  mrb_uv_req_t* req;

  mrb_get_args(mrb, "&z", &b, &arg_path);

  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_check_error(mrb, req, uv_fs_unlink(
      mrb_uv_current_loop(mrb), &req->req.fs, arg_path, mrb_nil_p(req->block)? NULL : _uv_fs_cb));

  return ret;
}

static mrb_value
mrb_uv_fs_mkdir(mrb_state *mrb, mrb_value self)
{
  char const *arg_path;
  mrb_int arg_mode = 0755;
  mrb_value b, ret;
  mrb_uv_req_t* req;

  mrb_get_args(mrb, "&z|i", &b, &arg_path, &arg_mode);
  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_check_error(mrb, req, uv_fs_mkdir(
      mrb_uv_current_loop(mrb), &req->req.fs, arg_path, arg_mode,
      mrb_nil_p(req->block)? NULL : _uv_fs_cb));
  return ret;
}

static mrb_value
mrb_uv_fs_rmdir(mrb_state *mrb, mrb_value self)
{
  mrb_value arg_path;
  mrb_value b, ret;
  mrb_uv_req_t* req;

  mrb_get_args(mrb, "&S", &b, &arg_path);

  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_check_error(mrb, req, uv_fs_rmdir(
      mrb_uv_current_loop(mrb), &req->req.fs, mrb_string_value_ptr(mrb, arg_path),
      mrb_nil_p(req->block)? NULL : _uv_fs_cb));
  return ret;
}

static mrb_value
mrb_uv_fs_scandir(mrb_state *mrb, mrb_value self)
{
  char const *arg_path;
  mrb_int arg_flags;
  mrb_value b, ret;
  mrb_uv_req_t* req;
  int res;

  mrb_get_args(mrb, "&zi", &b, &arg_path, &arg_flags);
  req = mrb_uv_req_current(mrb, b, &ret);
  res = uv_fs_scandir(mrb_uv_current_loop(mrb), &req->req.fs, arg_path, arg_flags,
                      mrb_nil_p(req->block)? NULL : _uv_fs_cb);

  if (mrb_nil_p(req->block) && res >= 0) {
    mrb_value ret = dir_to_array(mrb, &req->req.fs);
    mrb_uv_req_clear(req);
    return ret;
  }
  mrb_uv_req_check_error(mrb, req, res);
  return ret;
}

static mrb_value
mrb_uv_fs_stat(mrb_state *mrb, mrb_value self)
{
  char const *arg_path;
  mrb_value b, ret;
  mrb_uv_req_t* req;
  int res;

  mrb_get_args(mrb, "&z", &b, &arg_path);

  req = mrb_uv_req_current(mrb, b, &ret);
  res = uv_fs_stat(mrb_uv_current_loop(mrb), &req->req.fs, arg_path,
                   mrb_nil_p(req->block)? NULL : _uv_fs_cb);

  if (mrb_nil_p(req->block) && res >= 0) {
    mrb_value ret = mrb_uv_create_stat(mrb, &req->req.fs.statbuf);
    mrb_uv_req_clear(req);
    return ret;
  }
  mrb_uv_req_check_error(mrb, req, res);
  return ret;
}

static mrb_value
mrb_uv_fs_fstat(mrb_state *mrb, mrb_value self)
{
  mrb_value b, ret;
  mrb_uv_req_t* req;
  mrb_uv_file *context = (mrb_uv_file*)mrb_uv_get_ptr(mrb, self, &mrb_uv_file_type);
  int res;

  mrb_get_args(mrb, "&", &b);

  req = mrb_uv_req_current(mrb, b, &ret);
  res = uv_fs_fstat(mrb_uv_current_loop(mrb), &req->req.fs, context->fd,
                    mrb_nil_p(req->block)? NULL : _uv_fs_cb);

  if (mrb_nil_p(req->block) && res >= 0) {
    mrb_value ret = mrb_uv_create_stat(mrb, &req->req.fs.statbuf);
    mrb_uv_req_clear(req);
    return ret;
  }
  mrb_uv_req_check_error(mrb, req, res);
  return ret;
}

static mrb_value
mrb_uv_fs_lstat(mrb_state *mrb, mrb_value self)
{
  char const *arg_path;
  mrb_value b, ret;
  mrb_uv_req_t* req;
  int res;

  mrb_get_args(mrb, "&z", &b, &arg_path);

  req = mrb_uv_req_current(mrb, b, &ret);
  res = uv_fs_lstat(mrb_uv_current_loop(mrb), &req->req.fs, arg_path,
                    mrb_nil_p(req->block)? NULL : _uv_fs_cb);
  if (mrb_nil_p(req->block) && res >= 0) {
    mrb_value ret = mrb_uv_create_stat(mrb, &req->req.fs.statbuf);
    mrb_uv_req_clear(req);
    return ret;
  }
  mrb_uv_req_check_error(mrb, req, res);
  return ret;
}

static mrb_value
mrb_uv_fs_rename(mrb_state *mrb, mrb_value self)
{
  char const *arg_path, *arg_new_path;
  mrb_value b, ret;
  mrb_uv_req_t* req;

  mrb_get_args(mrb, "&zz", &b, &arg_path, &arg_new_path);

  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_check_error(mrb, req, uv_fs_rename(
      mrb_uv_current_loop(mrb), &req->req.fs, arg_path, arg_new_path, mrb_nil_p(req->block)? NULL : _uv_fs_cb));
  return ret;
}

static mrb_value
mrb_uv_fs_fsync(mrb_state *mrb, mrb_value self)
{
  mrb_value b, ret;
  mrb_uv_file *context = (mrb_uv_file*)mrb_uv_get_ptr(mrb, self, &mrb_uv_file_type);
  mrb_uv_req_t* req;

  mrb_get_args(mrb, "&", &b);

  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_check_error(mrb, req, uv_fs_fsync(
      mrb_uv_current_loop(mrb), &req->req.fs, context->fd, mrb_nil_p(req->block)? NULL : _uv_fs_cb));
  return ret;
}

static mrb_value
mrb_uv_fs_fdatasync(mrb_state *mrb, mrb_value self)
{
  mrb_value b, ret;
  mrb_uv_file *context = (mrb_uv_file*)mrb_uv_get_ptr(mrb, self, &mrb_uv_file_type);
  mrb_uv_req_t* req;

  mrb_get_args(mrb, "&", &b);

  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_check_error(mrb, req, uv_fs_fdatasync(
      mrb_uv_current_loop(mrb), &req->req.fs, context->fd, mrb_nil_p(req->block)? NULL : _uv_fs_cb));
  return ret;
}

static mrb_value
mrb_uv_fs_ftruncate(mrb_state *mrb, mrb_value self)
{
  mrb_int arg_offset;
  mrb_value b, ret;
  mrb_uv_file *context = (mrb_uv_file*)mrb_uv_get_ptr(mrb, self, &mrb_uv_file_type);
  mrb_uv_req_t* req;

  mrb_get_args(mrb, "&i", &b, &arg_offset);

  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_check_error(mrb, req, uv_fs_ftruncate(
      mrb_uv_current_loop(mrb), &req->req.fs, context->fd, arg_offset,
      mrb_nil_p(req->block)? NULL : _uv_fs_cb));
  return ret;
}

static mrb_value
mrb_uv_fs_sendfile(mrb_state *mrb, mrb_value self)
{
  mrb_int arg_outfd, arg_infd, arg_offset, arg_length;
  mrb_value b, outfile, infile, ret;
  mrb_uv_req_t* req;

  mrb_get_args(mrb, "&ooii", &b, &infile, &outfile, &arg_offset, &arg_length);
  arg_infd = mrb_uv_to_fd(mrb, infile);
  arg_outfd = mrb_uv_to_fd(mrb, outfile);

  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_check_error(mrb, req, uv_fs_sendfile(
      mrb_uv_current_loop(mrb), &req->req.fs, arg_infd, arg_outfd, arg_offset, arg_length,
      mrb_nil_p(req->block)? NULL : _uv_fs_cb));
  return ret;
}

static mrb_value
mrb_uv_fs_chmod(mrb_state *mrb, mrb_value self)
{
  char const *arg_path;
  mrb_int arg_mode;
  mrb_value b, ret;
  mrb_uv_req_t* req;

  mrb_get_args(mrb, "&zi", &b, &arg_path, &arg_mode);

  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_check_error(mrb, req, uv_fs_chmod(
      mrb_uv_current_loop(mrb), &req->req.fs, arg_path, arg_mode, mrb_nil_p(req->block)? NULL : _uv_fs_cb));
  return ret;
}

static mrb_value
mrb_uv_fs_link(mrb_state *mrb, mrb_value self)
{
  char const *arg_path, *arg_new_path;
  mrb_value b, ret;
  mrb_uv_req_t* req;

  mrb_get_args(mrb, "&zz", &b, &arg_path, &arg_new_path);

  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_check_error(mrb, req, uv_fs_link(
      mrb_uv_current_loop(mrb), &req->req.fs, arg_path, arg_new_path, mrb_nil_p(req->block)? NULL : _uv_fs_cb));
  return ret;
}

static mrb_value
mrb_uv_fs_utime(mrb_state *mrb, mrb_value self)
{
  char const *path;
  mrb_float atime, mtime;
  mrb_value b, ret;
  mrb_uv_req_t* req;

  mrb_get_args(mrb, "&zff", &b, &path, &atime, &mtime);

  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_check_error(mrb, req, uv_fs_utime(
      mrb_uv_current_loop(mrb), &req->req.fs, path, (double)atime, (double)mtime,
      mrb_nil_p(req->block)? NULL : _uv_fs_cb));
  return ret;
}

static mrb_value
mrb_uv_fs_futime(mrb_state *mrb, mrb_value self)
{
  mrb_float atime, mtime;
  mrb_value b, ret;
  mrb_uv_file *ctx = (mrb_uv_file*)mrb_uv_get_ptr(mrb, self, &mrb_uv_file_type);
  mrb_uv_req_t *req;

  mrb_get_args(mrb, "&ff", &b, &atime, &mtime);

  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_check_error(mrb, req, uv_fs_futime(
      mrb_uv_current_loop(mrb), &req->req.fs, ctx->fd,
      (double)atime, (double)mtime, mrb_nil_p(req->block)? NULL : _uv_fs_cb));
  return ret;
}

static mrb_value
mrb_uv_fs_fchmod(mrb_state *mrb, mrb_value self)
{
  mrb_int mode;
  mrb_value b, ret;
  mrb_uv_file *ctx = (mrb_uv_file*)mrb_uv_get_ptr(mrb, self, &mrb_uv_file_type);
  mrb_uv_req_t *req;

  mrb_get_args(mrb, "&i", &b, &mode);

  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_check_error(mrb, req, uv_fs_fchmod(
      mrb_uv_current_loop(mrb), &req->req.fs, ctx->fd, mode, mrb_nil_p(req->block)? NULL : _uv_fs_cb));
  return ret;
}

static mrb_value
mrb_uv_fs_symlink(mrb_state *mrb, mrb_value self)
{
  char const *path, *new_path;
  mrb_int flags = 0;
  mrb_value b, ret;
  mrb_uv_req_t *req;

  mrb_get_args(mrb, "&zz|i", &b, &path, &new_path, &flags);

  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_check_error(mrb, req, uv_fs_symlink(
      mrb_uv_current_loop(mrb), &req->req.fs, path, new_path, flags, mrb_nil_p(req->block)? NULL : _uv_fs_cb));
  return ret;
}

static mrb_value
mrb_uv_fs_readlink(mrb_state *mrb, mrb_value self)
{
  char const *path;
  mrb_value b, ret;
  mrb_uv_req_t *req;
  int res;

  mrb_get_args(mrb, "&z", &b, &path);

  req = mrb_uv_req_current(mrb, b, &ret);
  res = uv_fs_readlink(
      mrb_uv_current_loop(mrb), &req->req.fs, path, mrb_nil_p(req->block)? NULL : _uv_fs_cb);

  if (mrb_nil_p(req->block) && res >= 0) {
    mrb_value const ret = mrb_str_new_cstr(mrb, req->req.fs.ptr);
    mrb_uv_req_clear(req);
    return ret;
  }
  mrb_uv_req_check_error(mrb, req, res);
  return ret;
}

#if MRB_UV_CHECK_VERSION(1, 8, 0)

static mrb_value
mrb_uv_fs_realpath(mrb_state *mrb, mrb_value self)
{
  char const *path;
  mrb_value b, ret;
  mrb_uv_req_t *req;
  int res;

  mrb_get_args(mrb, "&z", &b, &path);

  req = mrb_uv_req_current(mrb, b, &ret);
  res = uv_fs_realpath(mrb_uv_current_loop(mrb), &req->req.fs, path,
                       mrb_nil_p(req->block)? NULL : _uv_fs_cb);

  if (mrb_nil_p(req->block)) {
    mrb_value const ret = mrb_str_new_cstr(mrb, req->req.fs.ptr);
    mrb_uv_req_clear(req);
    return ret;
  }
  mrb_uv_req_check_error(mrb, req, res);
  return ret;
}

#endif

static mrb_value
mrb_uv_fs_chown(mrb_state *mrb, mrb_value self)
{
  char const *path;
  mrb_int uid, gid;
  mrb_value b, ret;
  mrb_uv_req_t *req;

  mrb_get_args(mrb, "&zii", &b, &path, &uid, &gid);

  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_check_error(mrb, req, uv_fs_chown(
      mrb_uv_current_loop(mrb), &req->req.fs, path,
      (uv_uid_t)uid, (uv_gid_t)gid, mrb_nil_p(req->block)? NULL : _uv_fs_cb));
  return ret;
}

static mrb_value
mrb_uv_fs_fchown(mrb_state *mrb, mrb_value self)
{
  mrb_int uid, gid;
  mrb_value b, ret;
  mrb_uv_file *ctx = (mrb_uv_file*)mrb_uv_get_ptr(mrb, self, &mrb_uv_file_type);
  mrb_uv_req_t *req;

  mrb_get_args(mrb, "&ii", &b, &uid, &gid);

  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_check_error(mrb, req, uv_fs_fchown(
      mrb_uv_current_loop(mrb), &req->req.fs, ctx->fd,
      (uv_uid_t)uid, (uv_gid_t)gid, mrb_nil_p(req->block)? NULL : _uv_fs_cb));
  return ret;
}

static mrb_value
mrb_uv_fs_mkdtemp(mrb_state *mrb, mrb_value self)
{
  char const *tmp;
  mrb_value b, ret;
  mrb_uv_req_t *req;
  int res;

  mrb_get_args(mrb, "&z", &b, &tmp);

  req = mrb_uv_req_current(mrb, b, &ret);
  res = uv_fs_mkdtemp(mrb_uv_current_loop(mrb), &req->req.fs,
                      tmp, mrb_nil_p(req->block)? NULL : _uv_fs_cb);

  if (mrb_nil_p(req->block) && res >= 0) {
    mrb_value const ret = mrb_str_new_cstr(mrb, req->req.fs.path);
    mrb_uv_req_clear(req);
    return ret;
  }
  mrb_uv_req_check_error(mrb, req, res);
  return ret;
}

static mrb_value
mrb_uv_fs_access(mrb_state *mrb, mrb_value self)
{
  const char *path;
  mrb_int flags;
  int res;
  mrb_value b, ret;
  mrb_uv_req_t *req;

  mrb_get_args(mrb, "&zi", &b, &path, &flags);

  req = mrb_uv_req_current(mrb, b, &ret);
  res = uv_fs_access(mrb_uv_current_loop(mrb), &req->req.fs, path, flags,
                     mrb_nil_p(req->block)? NULL : _uv_fs_cb);
  if (mrb_nil_p(req->block)) {
    mrb_uv_req_clear(req);
    return mrb_uv_create_status(mrb, res);
  }
  mrb_uv_req_check_error(mrb, req, res);
  return ret;
}

#if MRB_UV_CHECK_VERSION(1, 14, 0)

static mrb_value
mrb_uv_fs_copyfile(mrb_state *mrb, mrb_value self)
{
  const char *old_path, *new_path;
  mrb_int flags = 0;
  mrb_value proc, ret;
  mrb_uv_req_t *req;
  int res;

  mrb_get_args(mrb, "&zz|i", &proc, &old_path, &new_path, &flags);
  req = mrb_uv_req_current(mrb, proc, &ret);
  res = uv_fs_copyfile(
      mrb_uv_current_loop(mrb), &req->req.fs, old_path, new_path, flags,
      mrb_nil_p(req->block)? NULL : _uv_fs_cb);
  if (mrb_nil_p(req->block)) {
    mrb_uv_req_clear(req);
    return mrb_uv_create_status(mrb, res);
  }
  mrb_uv_req_check_error(mrb, req, res);
  return ret;
}

#endif

void mrb_mruby_uv_gem_init_fs(mrb_state *mrb, struct RClass *UV)
{
  struct RClass *_class_uv_fs;
  struct RClass *_class_uv_stat;

  _class_uv_fs = mrb_define_class_under(mrb, UV, "FS", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_uv_fs, MRB_TT_DATA);
  mrb_define_const(mrb, _class_uv_fs, "SYMLINK_DIR", mrb_fixnum_value(UV_FS_SYMLINK_DIR));
  mrb_define_const(mrb, _class_uv_fs, "SYMLINK_JUNCTION", mrb_fixnum_value(UV_FS_SYMLINK_JUNCTION));
  mrb_define_const(mrb, _class_uv_fs, "O_RDONLY", mrb_fixnum_value(O_RDONLY));
  mrb_define_const(mrb, _class_uv_fs, "O_WRONLY", mrb_fixnum_value(O_WRONLY));
  mrb_define_const(mrb, _class_uv_fs, "O_RDWR", mrb_fixnum_value(O_RDWR));
  mrb_define_const(mrb, _class_uv_fs, "O_CREAT", mrb_fixnum_value(O_CREAT));
  mrb_define_const(mrb, _class_uv_fs, "O_TRUNC", mrb_fixnum_value(O_TRUNC));
  mrb_define_const(mrb, _class_uv_fs, "O_APPEND", mrb_fixnum_value(O_APPEND));
#ifdef O_TEXT
  mrb_define_const(mrb, _class_uv_fs, "O_TEXT", mrb_fixnum_value(O_TEXT));
#endif
#ifdef O_BINARY
  mrb_define_const(mrb, _class_uv_fs, "O_BINARY", mrb_fixnum_value(O_BINARY));
#endif
  mrb_define_const(mrb, _class_uv_fs, "S_IWRITE", mrb_fixnum_value(S_IWUSR));
  mrb_define_const(mrb, _class_uv_fs, "S_IREAD", mrb_fixnum_value(S_IRUSR));
  mrb_define_const(mrb, _class_uv_fs, "S_IEXEC", mrb_fixnum_value(S_IXUSR));
  mrb_define_const(mrb, _class_uv_fs, "F_OK", mrb_fixnum_value(F_OK));
  mrb_define_const(mrb, _class_uv_fs, "R_OK", mrb_fixnum_value(R_OK));
  mrb_define_const(mrb, _class_uv_fs, "W_OK", mrb_fixnum_value(W_OK));
  mrb_define_const(mrb, _class_uv_fs, "X_OK", mrb_fixnum_value(X_OK));
#if MRB_UV_CHECK_VERSION(1, 14, 0)
  mrb_define_const(mrb, _class_uv_fs, "COPYFILE_EXCL", mrb_fixnum_value(UV_FS_COPYFILE_EXCL));
#endif
  mrb_define_method(mrb, _class_uv_fs, "write", mrb_uv_fs_write, MRB_ARGS_REQ(1) | MRB_ARGS_OPT(2));
  mrb_define_method(mrb, _class_uv_fs, "read", mrb_uv_fs_read, MRB_ARGS_REQ(0) | MRB_ARGS_OPT(2));
  mrb_define_method(mrb, _class_uv_fs, "datasync", mrb_uv_fs_fdatasync, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_fs, "truncate", mrb_uv_fs_ftruncate, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_fs, "stat", mrb_uv_fs_fstat, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_fs, "sync", mrb_uv_fs_fsync, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_fs, "chmod", mrb_uv_fs_fchmod, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_fs, "utime", mrb_uv_fs_futime, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, _class_uv_fs, "chown", mrb_uv_fs_fchown, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, _class_uv_fs, "close", mrb_uv_fs_close, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_fs, "fd", mrb_uv_fs_fd, MRB_ARGS_NONE());
  mrb_define_class_method(mrb, _class_uv_fs, "open", mrb_uv_fs_open, MRB_ARGS_REQ(2));
  mrb_define_class_method(mrb, _class_uv_fs, "unlink", mrb_uv_fs_unlink, MRB_ARGS_REQ(1));
  mrb_define_class_method(mrb, _class_uv_fs, "mkdir", mrb_uv_fs_mkdir, MRB_ARGS_REQ(1));
  mrb_define_class_method(mrb, _class_uv_fs, "rmdir", mrb_uv_fs_rmdir, MRB_ARGS_REQ(1));
  mrb_define_class_method(mrb, _class_uv_fs, "scandir", mrb_uv_fs_scandir, MRB_ARGS_REQ(2));
  mrb_define_class_method(mrb, _class_uv_fs, "stat", mrb_uv_fs_stat, MRB_ARGS_REQ(1));
  mrb_define_class_method(mrb, _class_uv_fs, "rename", mrb_uv_fs_rename, MRB_ARGS_REQ(2));
  mrb_define_class_method(mrb, _class_uv_fs, "sendfile", mrb_uv_fs_sendfile, MRB_ARGS_REQ(4));
  mrb_define_class_method(mrb, _class_uv_fs, "chmod", mrb_uv_fs_chmod, MRB_ARGS_REQ(2));
  mrb_define_class_method(mrb, _class_uv_fs, "lstat", mrb_uv_fs_lstat, MRB_ARGS_REQ(1));
  mrb_define_class_method(mrb, _class_uv_fs, "link", mrb_uv_fs_link, MRB_ARGS_REQ(2));
  mrb_define_class_method(mrb, _class_uv_fs, "utime", mrb_uv_fs_utime, MRB_ARGS_REQ(3));
  mrb_define_class_method(mrb, _class_uv_fs, "symlink", mrb_uv_fs_symlink, MRB_ARGS_REQ(3));
  mrb_define_class_method(mrb, _class_uv_fs, "readlink", mrb_uv_fs_readlink, MRB_ARGS_REQ(1));
  mrb_define_class_method(mrb, _class_uv_fs, "chown", mrb_uv_fs_chown, MRB_ARGS_REQ(3));
  mrb_define_class_method(mrb, _class_uv_fs, "mkdtemp", mrb_uv_fs_mkdtemp, MRB_ARGS_REQ(1));
  mrb_define_class_method(mrb, _class_uv_fs, "access", mrb_uv_fs_access, MRB_ARGS_REQ(2));
  mrb_define_class_method(mrb, _class_uv_fs, "scandir", mrb_uv_fs_scandir, MRB_ARGS_REQ(2));
#if MRB_UV_CHECK_VERSION(1, 14, 0)
  mrb_define_class_method(mrb, _class_uv_fs, "copyfile", mrb_uv_fs_copyfile, MRB_ARGS_REQ(2) | MRB_ARGS_OPT(1));
#endif
#if MRB_UV_CHECK_VERSION(1, 8, 0)
  mrb_define_class_method(mrb, _class_uv_fs, "realpath", mrb_uv_fs_realpath, MRB_ARGS_REQ(1));
#endif

  /* for compatibility */
  mrb_define_class_method(mrb, _class_uv_fs, "readdir", mrb_uv_fs_scandir, MRB_ARGS_REQ(2));

  _class_uv_stat = mrb_define_class_under(mrb, UV, "Stat", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_uv_stat, MRB_TT_DATA);
  mrb_define_method(mrb, _class_uv_stat, "dev", mrb_uv_stat_dev, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_stat, "mode", mrb_uv_stat_mode, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_stat, "nlink", mrb_uv_stat_nlink, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_stat, "uid", mrb_uv_stat_uid, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_stat, "gid", mrb_uv_stat_gid, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_stat, "rdev", mrb_uv_stat_rdev, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_stat, "ino", mrb_uv_stat_ino, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_stat, "size", mrb_uv_stat_size, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_stat, "blksize", mrb_uv_stat_blksize, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_stat, "blocks", mrb_uv_stat_blocks, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_stat, "flags", mrb_uv_stat_flags, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_stat, "gen", mrb_uv_stat_gen, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_stat, "atim", mrb_uv_stat_atim, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_stat, "mtim", mrb_uv_stat_mtim, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_stat, "ctim", mrb_uv_stat_ctim, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_stat, "birthtim", mrb_uv_stat_birthtim, MRB_ARGS_NONE());
  /* cannot create from mruby side */
  mrb_undef_class_method(mrb, _class_uv_stat, "new");
}


/*********************************************************
 * main
 *********************************************************/

mrb_value
mrb_uv_from_uint64(mrb_state *mrb, uint64_t v)
{
  return MRB_INT_MAX < v? mrb_float_value(mrb, (mrb_float)v) : mrb_fixnum_value(v);
}

mrb_value
mrb_uv_gc_table_get(mrb_state *mrb)
{
  return mrb_const_get(mrb, mrb_obj_value(mrb_module_get(mrb, "UV")), mrb_intern_lit(mrb, "$GC"));
}

void
mrb_uv_gc_table_clean(mrb_state *mrb, uv_loop_t *target)
{
  int i, new_i = 0;
  mrb_value t = mrb_uv_gc_table_get(mrb);
  mrb_value const *ary = RARRAY_PTR(t);
  for (i = 0; i < RARRAY_LEN(t); ++i) {
    mrb_value const v = ary[i];
    mrb_uv_handle *h;
    if (!DATA_PTR(v)) { continue; }
    if (DATA_TYPE(v) != &mrb_uv_handle_type) { continue; }

    h = (mrb_uv_handle*)DATA_PTR(v);
    if (target && h->handle.loop != target) { continue; }

    mrb_uv_handle_type.dfree(mrb, h);
  }
  mrb_ary_resize(mrb, t, new_i);
  uv_run(uv_default_loop(), UV_RUN_ONCE);
}

void
mrb_uv_gc_protect(mrb_state *mrb, mrb_value v)
{
  mrb_assert(mrb_type(v) == MRB_TT_DATA);
  mrb_ary_push(mrb, mrb_uv_gc_table_get(mrb), v);
}

static mrb_value
mrb_uv_gc(mrb_state *mrb, mrb_value self)
{
  mrb_uv_gc_table_clean(mrb, NULL);
  mrb_full_gc(mrb);
  return self;
}

static mrb_value
mrb_uv_run(mrb_state *mrb, mrb_value self)
{
  mrb_int arg_mode = UV_RUN_DEFAULT;
  mrb_get_args(mrb, "|i", &arg_mode);
  return mrb_fixnum_value(uv_run(mrb_uv_current_loop(mrb), arg_mode));
}

mrb_value
mrb_uv_data_get(mrb_state *mrb, mrb_value self)
{
  return mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "data"));
}

mrb_value
mrb_uv_data_set(mrb_state *mrb, mrb_value self)
{
  mrb_value arg;
  mrb_get_args(mrb, "o", &arg);
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "data"), arg);
  return self;
}

#if MRB_UV_CHECK_VERSION(1, 9, 0)

// UV::Passwd
static void
mrb_uv_passwd_free(mrb_state *mrb, void *p)
{
  uv_passwd_t *passwd = (uv_passwd_t*)p;
  if (!p) { return; }

  uv_os_free_passwd(passwd);
  mrb_free(mrb, p);
}

static mrb_data_type const passwd_type = { "uv_passwd", mrb_uv_passwd_free };

static mrb_value
mrb_uv_passwd_init(mrb_state *mrb, mrb_value self)
{
  uv_passwd_t passwd, *ptr;

  mrb_get_args(mrb, "");

  mrb_uv_check_error(mrb, uv_os_get_passwd(&passwd));
  ptr = (uv_passwd_t*)mrb_malloc(mrb, sizeof(uv_passwd_t));
  *ptr = passwd;
  DATA_PTR(self) = ptr;
  DATA_TYPE(self) = &passwd_type;

  return self;
}

static mrb_value
mrb_uv_passwd_username(mrb_state *mrb, mrb_value self)
{
  uv_passwd_t *p;
  Data_Get_Struct(mrb, self, &passwd_type, p);
  return mrb_str_new_cstr(mrb, p->username);
}

static mrb_value
mrb_uv_passwd_shell(mrb_state *mrb, mrb_value self)
{
  uv_passwd_t *p;
  Data_Get_Struct(mrb, self, &passwd_type, p);
  return p->shell? mrb_str_new_cstr(mrb, p->shell) : mrb_nil_value();
}

static mrb_value
mrb_uv_passwd_homedir(mrb_state *mrb, mrb_value self)
{
  uv_passwd_t *p;
  Data_Get_Struct(mrb, self, &passwd_type, p);
  return mrb_str_new_cstr(mrb, p->homedir);
}

static mrb_value
mrb_uv_passwd_uid(mrb_state *mrb, mrb_value self)
{
  uv_passwd_t *p;
  Data_Get_Struct(mrb, self, &passwd_type, p);
  return mrb_fixnum_value(p->uid);
}

static mrb_value
mrb_uv_passwd_gid(mrb_state *mrb, mrb_value self)
{
  uv_passwd_t *p;
  Data_Get_Struct(mrb, self, &passwd_type, p);
  return mrb_fixnum_value(p->gid);
}

#endif

/*
 * UV::Req
 */
static void
mrb_uv_req_free(mrb_state *mrb, void *p)
{
  mrb_uv_req_t *req = (mrb_uv_req_t*)p;

  if (!p) { return; }

  if (req->req.req.type == UV_FS) {
    uv_fs_req_cleanup((uv_fs_t*)&req->req);
  }
  mrb_free(mrb, p);
}

static mrb_data_type const req_type = { "uv_req", mrb_uv_req_free };

static mrb_uv_req_t*
mrb_uv_req_alloc(mrb_state *mrb)
{
  mrb_uv_req_t *p;
  struct RClass *cls;
  mrb_value ret;
  int ai;

  ai = mrb_gc_arena_save(mrb);
  cls = mrb_class_get_under(mrb, mrb_module_get(mrb, "UV"), "Req");
  p = (mrb_uv_req_t*)mrb_malloc(mrb, sizeof(mrb_uv_req_t));
  ret = mrb_obj_value(mrb_data_object_alloc(mrb, cls, p, &req_type));
  p->mrb = mrb;
  p->instance = ret;
  p->req.req.data = p;
  p->is_used = FALSE;

  mrb_uv_gc_protect(mrb, ret);
  mrb_gc_arena_restore(mrb, ai);
  return p;
}

mrb_uv_req_t*
mrb_uv_req_current(mrb_state *mrb, mrb_value blk, mrb_value *result)
{
  mrb_value cur_loop = mrb_uv_current_loop_obj(mrb);
  mrb_value cur_yarn = mrb_funcall(mrb, cur_loop, "current_yarn", 0);
  mrb_sym const sym = mrb_intern_lit(mrb, "_req");
  mrb_uv_req_t *ret;

  mrb_assert(!mrb_nil_p(cur_loop));

  if (!mrb_nil_p(blk)) { // block passed
    ret = mrb_uv_req_alloc(mrb);
    *result = ret->instance;
  } else {
    mrb_value req, target;
    target = mrb_nil_p(cur_yarn)? cur_loop : cur_yarn;
    req = mrb_iv_get(mrb, target, sym);

    if (mrb_nil_p(req)) {
      ret = mrb_uv_req_alloc(mrb);
      mrb_iv_set(mrb, target, sym, ret->instance);
    } else {
      ret = (mrb_uv_req_t*)mrb_uv_get_ptr(mrb, req, &req_type);
    }
    req = ret->instance;

    if (mrb_nil_p(cur_yarn)) {
      *result = ret->instance;
    } else {
      *result = mrb_fiber_yield(mrb, 1, &req);
      blk = mrb_funcall(mrb, cur_yarn, "to_proc", 0);
    }
  }

  mrb_assert(!ret->is_used);

  ret->is_used = TRUE;
  mrb_iv_set(mrb, ret->instance, mrb_intern_lit(mrb, "uv_cb"), blk);
  ret->block = blk;

  return ret;
}

void
mrb_uv_req_check_error(mrb_state *mrb, mrb_uv_req_t *req, int err)
{
  if (mrb_nil_p(req->block) || err < 0) {
    mrb_uv_req_clear(req);
  }

  mrb_uv_check_error(mrb, err);
}

void
mrb_uv_req_clear(mrb_uv_req_t *req)
{
  mrb_state *mrb = req->mrb;

  mrb_assert(req->is_used);

  if (req->req.req.type == UV_FS) {
    uv_fs_req_cleanup(&req->req.fs);
    req->req.fs.result = 0;
  }
  req->req.req.type = UV_UNKNOWN_REQ;
  req->is_used = FALSE;
  req->block = mrb_nil_value();
  mrb_iv_set(mrb, req->instance, mrb_intern_lit(mrb, "uv_cb"), mrb_nil_value());
  mrb_iv_set(mrb, req->instance, mrb_intern_lit(mrb, "buf"), mrb_nil_value());
}

void
mrb_uv_req_yield(mrb_uv_req_t *req, mrb_int argc, mrb_value const *argv)
{
  mrb_value const b = req->block;
  mrb_gc_protect(req->mrb, b);
  mrb_uv_req_clear(req);
  mrb_yield_argv(req->mrb, b, argc, argv);
}

void
mrb_uv_req_set_buf(mrb_uv_req_t *req, uv_buf_t *buf, mrb_value str)
{
  mrb_state *mrb = req->mrb;
  mrb_str_modify(mrb, mrb_str_ptr(str));
  *buf = uv_buf_init(RSTRING_PTR(str), RSTRING_LEN(str));
  mrb_iv_set(mrb, req->instance, mrb_intern_lit(mrb, "buf"), str);
}

static mrb_value
mrb_uv_cancel(mrb_state *mrb, mrb_value self)
{
  mrb_uv_check_error(mrb, uv_cancel(&((mrb_uv_req_t*)mrb_uv_get_ptr(mrb, self, &req_type))->req.req));
  return self;
}

static mrb_value
mrb_uv_req_type(mrb_state *mrb, mrb_value self)
{
  mrb_uv_req_t *req;

  req = (mrb_uv_req_t*)mrb_uv_get_ptr(mrb, self, &req_type);
  return mrb_fixnum_value(req->req.req.type);
  switch(req->req.req.type) {
#define XX(u, l) case UV_ ## u: return symbol_value_lit(mrb, #l);
      UV_REQ_TYPE_MAP(XX)
#undef XX

  case UV_UNKNOWN_REQ: return symbol_value_lit(mrb, "unknown");

  default:
    mrb_raisef(mrb, E_TYPE_ERROR, "Invalid uv_req_t type: %S", mrb_fixnum_value(req->req.req.type));
    return self;
  }
}

static mrb_value
mrb_uv_req_type_name(mrb_state *mrb, mrb_value self)
{
  mrb_uv_req_t *req;

  req = (mrb_uv_req_t*)mrb_uv_get_ptr(mrb, self, &req_type);
#if MRB_UV_CHECK_VERSION(1, 19, 0)
  return mrb_symbol_value(mrb_intern_cstr(mrb, uv_req_type_name(uv_req_get_type(&req->req.req))));
#else
  switch(req->req.req.type) {
#define XX(u, l) case UV_ ## u: return symbol_value_lit(mrb, #l);
      UV_REQ_TYPE_MAP(XX)
#undef XX

    case UV_UNKNOWN_REQ: return symbol_value_lit(mrb, "unknown");

    default:
      mrb_raisef(mrb, E_TYPE_ERROR, "Invalid uv_req_t type: %S", mrb_fixnum_value(req->req.req.type));
      return self;
  }
#endif
}

#if MRB_UV_CHECK_VERSION(1, 19, 0)

static mrb_value
mrb_uv_fs_req_result(mrb_state *mrb, mrb_value self)
{
  mrb_uv_req_t *req = (mrb_uv_req_t*)mrb_uv_get_ptr(mrb, self, &req_type);
  if (req->req.req.type != UV_FS) { mrb_raise(mrb, E_TYPE_ERROR, "not fs request"); }
  return mrb_fixnum_value(uv_fs_get_result(&req->req.fs));
}

static mrb_value
mrb_uv_fs_req_statbuf(mrb_state *mrb, mrb_value self)
{
  mrb_uv_req_t *req = (mrb_uv_req_t*)mrb_uv_get_ptr(mrb, self, &req_type);
  if (req->req.req.type != UV_FS) { mrb_raise(mrb, E_TYPE_ERROR, "not fs request"); }
  return mrb_uv_create_stat(mrb, uv_fs_get_statbuf(&req->req.fs));
}

static mrb_value
mrb_uv_fs_req_path(mrb_state *mrb, mrb_value self)
{
  mrb_uv_req_t *req = (mrb_uv_req_t*)mrb_uv_get_ptr(mrb, self, &req_type);
  if (req->req.req.type != UV_FS) { mrb_raise(mrb, E_TYPE_ERROR, "not fs request"); }
  return mrb_str_new_cstr(mrb, uv_fs_get_path(&req->req.fs));
}

static mrb_value
mrb_uv_fs_req_type(mrb_state *mrb, mrb_value self)
{
  mrb_uv_req_t *req = (mrb_uv_req_t*)mrb_uv_get_ptr(mrb, self, &req_type);
  if (req->req.req.type != UV_FS) { mrb_raise(mrb, E_TYPE_ERROR, "not fs request"); }
  return mrb_fixnum_value(uv_fs_get_type(&req->req.fs));
}

#endif

/*********************************************************
 * UV::Loop
 *********************************************************/
static void
mrb_uv_loop_free(mrb_state *mrb, void *p)
{
  uv_loop_t *l = (uv_loop_t*)p;

  if (!l || l == uv_default_loop()) { return; }

  // mrb_uv_gc_table_clean(mrb, l);
  uv_walk(l, mrb_uv_close_handle_belongs_to_vm, mrb);
  uv_run(l, UV_RUN_ONCE);
  mrb_uv_check_error(mrb, uv_loop_close(l));
  mrb_free(mrb, p);
}

const struct mrb_data_type mrb_uv_loop_type = {
  "uv_loop", mrb_uv_loop_free
};

static mrb_value
mrb_uv_default_loop(mrb_state *mrb, mrb_value self)
{
  return mrb_iv_get(
      mrb, mrb_const_get(
          mrb, mrb_obj_value(mrb->object_class), mrb_intern_lit(mrb, "UV")),
      mrb_intern_lit(mrb, "default_loop"));
}

static mrb_value
mrb_uv_current_loop_meth(mrb_state *mrb, mrb_value self)
{
  return mrb_uv_current_loop_obj(mrb);
}

static mrb_value
mrb_uv_loop_init(mrb_state *mrb, mrb_value self)
{
  uv_loop_t *l = (uv_loop_t*)mrb_malloc(mrb, sizeof(uv_loop_t));
  mrb_uv_check_error(mrb, uv_loop_init(l));
  DATA_PTR(self) = l;
  DATA_TYPE(self) = &mrb_uv_loop_type;
  return self;
}

static mrb_value
mrb_uv_loop_run(mrb_state *mrb, mrb_value self)
{
  uv_loop_t* loop = (uv_loop_t*)mrb_uv_get_ptr(mrb, self, &mrb_uv_loop_type);
  mrb_int arg_mode = UV_RUN_DEFAULT;

  mrb_get_args(mrb, "|i", &arg_mode);
  mrb_uv_check_error(mrb, uv_run(loop, arg_mode));
  return self;
}

static mrb_value
mrb_uv_loop_close(mrb_state *mrb, mrb_value self)
{
  uv_loop_t* loop = (uv_loop_t*)mrb_uv_get_ptr(mrb, self, &mrb_uv_loop_type);

  if (loop == uv_default_loop()) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "cannot close default uv loop");
  }

  mrb_uv_gc_table_clean(mrb, loop);
  uv_walk(loop, mrb_uv_close_handle_belongs_to_vm, mrb);
  uv_run(loop, UV_RUN_ONCE);
  mrb_uv_check_error(mrb, uv_loop_close(loop));
  DATA_PTR(self) = NULL;
  DATA_TYPE(self) = NULL;
  mrb_free(mrb, loop);

  return self;
}

static mrb_value
mrb_uv_loop_alive(mrb_state *mrb, mrb_value self)
{
  uv_loop_t* loop = (uv_loop_t*)mrb_uv_get_ptr(mrb, self, &mrb_uv_loop_type);
  return mrb_bool_value(uv_loop_alive(loop));
}

static mrb_value
mrb_uv_stop(mrb_state *mrb, mrb_value self)
{
  uv_loop_t *loop = (uv_loop_t*)mrb_uv_get_ptr(mrb, self, &mrb_uv_loop_type);
  return uv_stop(loop), self;
}

static mrb_value
mrb_uv_update_time(mrb_state *mrb, mrb_value self)
{
  uv_loop_t *loop = (uv_loop_t*)mrb_uv_get_ptr(mrb, self, &mrb_uv_loop_type);
  return uv_update_time(loop), self;
}

static mrb_value
mrb_uv_backend_fd(mrb_state *mrb, mrb_value self)
{
  uv_loop_t *loop = (uv_loop_t*)mrb_uv_get_ptr(mrb, self, &mrb_uv_loop_type);
  return mrb_fixnum_value(uv_backend_fd(loop));
}

static mrb_value
mrb_uv_backend_timeout(mrb_state *mrb, mrb_value self)
{
  uv_loop_t *loop = (uv_loop_t*)mrb_uv_get_ptr(mrb, self, &mrb_uv_loop_type);
  return mrb_fixnum_value(uv_backend_timeout(loop));
}

static mrb_value
mrb_uv_now(mrb_state *mrb, mrb_value self)
{
  uv_loop_t *loop;

  loop = (uv_loop_t*)mrb_uv_get_ptr(mrb, self, &mrb_uv_loop_type);
  return mrb_uv_from_uint64(mrb, uv_now(loop));
}

static mrb_value
mrb_uv_loadavg(mrb_state *mrb, mrb_value self)
{
  mrb_value ret = mrb_ary_new_capa(mrb, 3);
  double avg[3];
  uv_loadavg(avg);
  mrb_ary_push(mrb, ret, mrb_float_value(mrb, avg[0]));
  mrb_ary_push(mrb, ret, mrb_float_value(mrb, avg[1]));
  mrb_ary_push(mrb, ret, mrb_float_value(mrb, avg[2]));
  return ret;
}

#if MRB_UV_CHECK_VERSION(1, 0, 2)

static mrb_value
mrb_uv_loop_configure(mrb_state *mrb, mrb_value self) {
  mrb_value h, block_signal;
  uv_loop_t *loop = (uv_loop_t*)mrb_uv_get_ptr(mrb, self, &mrb_uv_loop_type);

  mrb_get_args(mrb, "H", &h);

  if (!mrb_nil_p(block_signal = mrb_hash_get(mrb, h, mrb_symbol_value(mrb_intern_lit(mrb, "block_signal"))))) {
    mrb_uv_check_error(mrb, uv_loop_configure(loop, UV_LOOP_BLOCK_SIGNAL, mrb_fixnum(block_signal)));
  }

  return self;
}

#endif

#if MRB_UV_CHECK_VERSION(1, 12, 0)

static mrb_value
mrb_uv_loop_fork(mrb_state *mrb, mrb_value self)
{
  uv_loop_t *loop = (uv_loop_t*)mrb_uv_get_ptr(mrb, self, &mrb_uv_loop_type);
  mrb_uv_check_error(mrb, uv_loop_fork(loop));
  return self;
}

#endif

static mrb_value
mrb_uv_loop_eq(mrb_state *mrb, mrb_value self)
{
  uv_loop_t *loop = (uv_loop_t*)mrb_uv_get_ptr(mrb, self, &mrb_uv_loop_type);
  uv_loop_t *other;

  mrb_get_args(mrb, "d", &other, &mrb_uv_loop_type);

  return mrb_bool_value(loop == other);
}

static mrb_value
mrb_uv_loop_make_current(mrb_state *mrb, mrb_value self)
{
  mrb_iv_set(
      mrb, mrb_const_get(
          mrb, mrb_obj_value(mrb->object_class), mrb_intern_lit(mrb, "UV")),
      mrb_intern_lit(mrb, "current_loop"), self);
  return self;
}

/*********************************************************
 * UV::Ip4Addr
 *********************************************************/
static void
uv_ip4addr_free(mrb_state *mrb, void *p)
{
  mrb_free(mrb, p);
}

const struct mrb_data_type mrb_uv_ip4addr_type = {
  "uv_ip4addr", uv_ip4addr_free,
};

/* NOTE: this type is internally used for instances where a
 * sockaddr is owned by libuv (such as during callbacks),
 * therefore we don't want mruby to free the pointer during
 * garbage collection */
const struct mrb_data_type mrb_uv_ip4addr_nofree_type = {
  "uv_ip4addr_nofree", NULL,
};

static mrb_value
mrb_uv_ip4_addr(mrb_state *mrb, mrb_value self)
{
  mrb_uv_args_int argc;
  mrb_value *argv;
  struct RClass* _class_uv;
  struct RClass* _class_uv_ip4addr;
  mrb_get_args(mrb, "*", &argv, &argc);
  _class_uv = mrb_module_get(mrb, "UV");
  _class_uv_ip4addr = mrb_class_get_under(mrb, _class_uv, "Ip4Addr");
  return mrb_obj_new(mrb, _class_uv_ip4addr, argc, argv);
}

static mrb_value
mrb_uv_ip4addr_init(mrb_state *mrb, mrb_value self)
{
  mrb_value arg_host = mrb_nil_value(),  arg_port = mrb_nil_value();
  struct sockaddr_in vaddr;
  struct sockaddr_in *addr = NULL, *paddr = NULL;

  mrb_get_args(mrb, "o|o", &arg_host, &arg_port);
  if (mrb_type(arg_host) == MRB_TT_STRING && !mrb_nil_p(arg_port) && mrb_fixnum_p(arg_port)) {
    mrb_uv_check_error(mrb, uv_ip4_addr(mrb_str_to_cstr(mrb, arg_host), mrb_fixnum(arg_port), &vaddr));
    addr = (struct sockaddr_in*) mrb_malloc(mrb, sizeof(struct sockaddr_in));
    memcpy(addr, &vaddr, sizeof(struct sockaddr_in));
  } else if (mrb_type(arg_host) == MRB_TT_DATA) {
    if (DATA_TYPE(arg_host) == &mrb_uv_ip4addr_nofree_type) {
      paddr = (struct sockaddr_in *) DATA_PTR(arg_host);
    }
    else {
      Data_Get_Struct(mrb, arg_host, &mrb_uv_ip4addr_type, paddr);
    }
    addr = (struct sockaddr_in*) mrb_malloc(mrb, sizeof(struct sockaddr_in));
    memcpy(addr, paddr, sizeof(struct sockaddr_in));
  } else {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "invalid argument");
  }
  DATA_PTR(self) = addr;
  DATA_TYPE(self) = &mrb_uv_ip4addr_type;
  return self;
}

static mrb_value
mrb_uv_ip4addr_to_s(mrb_state *mrb, mrb_value self)
{
  mrb_value str = mrb_funcall(mrb, self, "sin_addr", 0);
  mrb_str_cat2(mrb, str, ":");
  mrb_str_concat(mrb, str, mrb_funcall(mrb, self, "sin_port", 0));
  return str;
}

static mrb_value
mrb_uv_ip4addr_sin_addr(mrb_state *mrb, mrb_value self)
{
  struct sockaddr_in* addr = NULL;
  char name[256];

  Data_Get_Struct(mrb, self, &mrb_uv_ip4addr_type, addr);
  if (!addr) {
    return mrb_nil_value();
  }
  mrb_uv_check_error(mrb, uv_ip4_name(addr, name, sizeof(name)));
  return mrb_str_new(mrb, name, strlen(name));
}

static mrb_value
mrb_uv_ip4addr_sin_port(mrb_state *mrb, mrb_value self)
{
  struct sockaddr_in* addr = NULL;
  Data_Get_Struct(mrb, self, &mrb_uv_ip4addr_type, addr);
  return mrb_fixnum_value(htons(addr->sin_port));
}

/*********************************************************
 * UV::Ip6Addr
 *********************************************************/
static void
uv_ip6addr_free(mrb_state *mrb, void *p)
{
  mrb_free(mrb, p);
}

const struct mrb_data_type mrb_uv_ip6addr_type = {
  "uv_ip6addr", uv_ip6addr_free,
};

/* NOTE: this type is internally used for instances where a
 * sockaddr is owned by libuv (such as during callbacks),
 * therefore we don't want mruby to free the pointer during
 * garbage collection */
const struct mrb_data_type mrb_uv_ip6addr_nofree_type = {
  "uv_ip6addr_nofree", NULL,
};

static mrb_value
mrb_uv_ip6_addr(mrb_state *mrb, mrb_value self)
{
  mrb_uv_args_int argc;
  mrb_value *argv;
  struct RClass* _class_uv;
  struct RClass* _class_uv_ip6addr;
  mrb_get_args(mrb, "*", &argv, &argc);
  _class_uv = mrb_module_get(mrb, "UV");
  _class_uv_ip6addr = mrb_class_get_under(mrb, _class_uv, "Ip6Addr");
  return mrb_obj_new(mrb, _class_uv_ip6addr, argc, argv);
}

static mrb_value
mrb_uv_ip6addr_init(mrb_state *mrb, mrb_value self)
{
  mrb_value arg_host = mrb_nil_value(), arg_port = mrb_nil_value();
  struct sockaddr_in6 vaddr;
  struct sockaddr_in6 *addr = NULL, *paddr = NULL;

  mrb_get_args(mrb, "o|o", &arg_host, &arg_port);
  if (mrb_type(arg_host) == MRB_TT_STRING && !mrb_nil_p(arg_port) && mrb_fixnum_p(arg_port)) {
    mrb_uv_check_error(mrb, uv_ip6_addr(mrb_str_to_cstr(mrb, arg_host), mrb_fixnum(arg_port), &vaddr));
    addr = (struct sockaddr_in6*) mrb_malloc(mrb, sizeof(struct sockaddr_in6));
    memcpy(addr, &vaddr, sizeof(struct sockaddr_in6));
  } else if (mrb_type(arg_host) == MRB_TT_DATA) {
    if (DATA_TYPE(arg_host) == &mrb_uv_ip6addr_nofree_type) {
      paddr = (struct sockaddr_in6 *) DATA_PTR(arg_host);
    }
    else {
      Data_Get_Struct(mrb, arg_host, &mrb_uv_ip6addr_type, paddr);
    }
    addr = (struct sockaddr_in6*) mrb_malloc(mrb, sizeof(struct sockaddr_in6));
    memcpy(addr, paddr, sizeof(struct sockaddr_in6));
  } else {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "invalid argument");
  }
  DATA_PTR(self) = addr;
  DATA_TYPE(self) = &mrb_uv_ip6addr_type;
  return self;
}

static mrb_value
mrb_uv_ip6addr_to_s(mrb_state *mrb, mrb_value self)
{
  mrb_value str = mrb_funcall(mrb, self, "sin_addr", 0);
  mrb_str_cat2(mrb, str, ":");
  mrb_str_concat(mrb, str, mrb_funcall(mrb, self, "sin_port", 0));
  return str;
}

static mrb_value
mrb_uv_ip6addr_sin_addr(mrb_state *mrb, mrb_value self)
{
  struct sockaddr_in6* addr = NULL;
  char name[256];

  Data_Get_Struct(mrb, self, &mrb_uv_ip6addr_type, addr);
  if (!addr) {
    return mrb_nil_value();
  }
  mrb_uv_check_error(mrb, uv_ip6_name(addr, name, sizeof(name)));
  return mrb_str_new(mrb, name, strlen(name));
}

static mrb_value
mrb_uv_ip6addr_sin_port(mrb_state *mrb, mrb_value self)
{
  struct sockaddr_in6* addr = NULL;
  Data_Get_Struct(mrb, self, &mrb_uv_ip6addr_type, addr);
  return mrb_fixnum_value(htons(addr->sin6_port));
}

static mrb_value
mrb_uv_ip6addr_sin6_scope_id(mrb_state *mrb, mrb_value self)
{
  struct sockaddr_in6* addr = NULL;
  Data_Get_Struct(mrb, self, &mrb_uv_ip6addr_type, addr);
  return mrb_fixnum_value(addr->sin6_scope_id);
}

#if MRB_UV_CHECK_VERSION(1, 16, 0)

static mrb_value
mrb_uv_ip6addr_if_indextoiid(mrb_state *mrb, mrb_value self)
{
  struct sockaddr_in6* addr = NULL;
  char ifname[UV_IF_NAMESIZE];
  size_t ifname_size = sizeof(ifname);
  Data_Get_Struct(mrb, self, &mrb_uv_ip6addr_type, addr);
  mrb_uv_check_error(mrb, uv_if_indextoiid(addr->sin6_scope_id, ifname, &ifname_size));
  return mrb_str_new(mrb, ifname, ifname_size);
}

static mrb_value
mrb_uv_ip6addr_if_indextoname(mrb_state *mrb, mrb_value self)
{
  struct sockaddr_in6* addr = NULL;
  char ifname[UV_IF_NAMESIZE];
  size_t ifname_size = sizeof(ifname);
  Data_Get_Struct(mrb, self, &mrb_uv_ip6addr_type, addr);
  mrb_uv_check_error(mrb, uv_if_indextoname(addr->sin6_scope_id, ifname, &ifname_size));
  return mrb_str_new(mrb, ifname, ifname_size);
}

static mrb_value
mrb_uv_if_indextoiid(mrb_state *mrb, mrb_value self)
{
  char ifname[UV_IF_NAMESIZE];
  size_t ifname_size = sizeof(ifname);
  mrb_int idx;
  mrb_get_args(mrb, "i", &idx);
  mrb_uv_check_error(mrb, uv_if_indextoiid(idx, ifname, &ifname_size));
  return mrb_str_new(mrb, ifname, ifname_size);
}

static mrb_value
mrb_uv_if_indextoname(mrb_state *mrb, mrb_value self)
{
  char ifname[UV_IF_NAMESIZE];
  size_t ifname_size = sizeof(ifname);
  mrb_int idx;
  mrb_get_args(mrb, "i", &idx);
  mrb_uv_check_error(mrb, uv_if_indextoname(idx, ifname, &ifname_size));
  return mrb_str_new(mrb, ifname, ifname_size);
}

#endif

/*
 * UV.getnameinfo
 */
static void
mrb_uv_getnameinfo_cb(uv_getnameinfo_t *uv_req, int status, char const *host, char const* service)
{
  mrb_uv_req_t *req = (mrb_uv_req_t*)uv_req->data;
  mrb_state *mrb = req->mrb;
  mrb_value args[] = {
    mrb_str_new_cstr(mrb, host),
    mrb_str_new_cstr(mrb, service),
    mrb_uv_create_status(mrb, status),
  };
  mrb_uv_req_yield(req, 3, args);
}

static mrb_value
mrb_uv_getnameinfo(mrb_state *mrb, mrb_value self)
{
  mrb_value block, sock, ret;
  mrb_int flags = 0;
  struct sockaddr* addr;
  mrb_uv_req_t *req;

  mrb_get_args(mrb, "&o|i", &block, &sock, &flags);

  addr = (struct sockaddr*)mrb_data_check_get_ptr(mrb, sock, &mrb_uv_ip4addr_type);
  if (!addr) {
    addr = (struct sockaddr*)mrb_data_check_get_ptr(mrb, sock, &mrb_uv_ip6addr_type);
  }

  req = mrb_uv_req_current(mrb, block, &ret);
  if (mrb_nil_p(req->block)) {
    mrb_uv_req_clear(req);
    mrb_raise(mrb, E_ARGUMENT_ERROR, "Expected callback in uv_getaddrinfo.");
  }
  mrb_uv_req_check_error(mrb, req, uv_getnameinfo(
      mrb_uv_current_loop(mrb), &req->req.getnameinfo,
      mrb_uv_getnameinfo_cb, addr, flags));
  return ret;
}

/*********************************************************
 * UV::Addrinfo
 *********************************************************/
static void
uv_addrinfo_free(mrb_state *mrb, void *p)
{
  uv_freeaddrinfo((struct addrinfo*)p);
}

static void
uv_addrinfo_nofree(mrb_state *mrb, void *p) {}

static const struct mrb_data_type uv_addrinfo_type = {
  "uv_addrinfo", uv_addrinfo_free,
};

static const struct mrb_data_type uv_addrinfo_nofree_type = {
  "uv_addrinfo", uv_addrinfo_nofree,
};

static struct addrinfo const *
addrinfo_ptr(mrb_state *mrb, mrb_value v)
{
  void *ret = mrb_data_check_get_ptr(mrb, v, &uv_addrinfo_type);
  if (ret) { return (struct addrinfo*)ret; }
  return (struct addrinfo*)mrb_data_get_ptr(mrb, v, &uv_addrinfo_nofree_type);
}

static void
_uv_getaddrinfo_cb(uv_getaddrinfo_t* uv_req, int status, struct addrinfo* res)
{
  mrb_value args[2];
  mrb_uv_req_t* req = (mrb_uv_req_t*) uv_req->data;
  mrb_state* mrb = req->mrb;

  mrb_value c = mrb_nil_value();
  if (status == 0) {
    struct RClass* _class_uv = mrb_module_get(mrb, "UV");
    struct RClass* _class_uv_addrinfo = mrb_class_get_under(mrb, _class_uv, "Addrinfo");
    c = mrb_obj_new(mrb, _class_uv_addrinfo, 0, NULL);
    DATA_PTR(c) = res;
    DATA_TYPE(c) = &uv_addrinfo_type;
  }

  args[0] = mrb_uv_create_status(mrb, status);
  args[1] = c;
  mrb_uv_req_yield(req, 2, args);
}

static mrb_value
mrb_uv_getaddrinfo(mrb_state *mrb, mrb_value self)
{
  mrb_value node, service, b = mrb_nil_value(), ret;
  mrb_value mrb_hints = mrb_hash_new(mrb);
  mrb_uv_req_t* req;
  mrb_value value;
  struct addrinfo hints = {0};
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = 0;
  hints.ai_protocol = 0;
  hints.ai_flags = 0;

  mrb_get_args(mrb, "SS|H&", &node, &service, &mrb_hints, &b);

  // parse hints
  value = mrb_hash_get(mrb, mrb_hints, mrb_symbol_value(mrb_intern_lit(mrb, "ai_family")));
  if (mrb_obj_equal(mrb, value, mrb_symbol_value(mrb_intern_lit(mrb, "ipv4")))) {
    hints.ai_family = AF_INET;
  } else if (mrb_obj_equal(mrb, value, mrb_symbol_value(mrb_intern_lit(mrb, "ipv6")))) {
    hints.ai_family = AF_INET6;
  }
  value = mrb_hash_get(mrb, mrb_hints, mrb_symbol_value(mrb_intern_lit(mrb, "datagram")));
  if (mrb_obj_equal(mrb, value, mrb_symbol_value(mrb_intern_lit(mrb, "dgram")))) {
    hints.ai_socktype = SOCK_DGRAM;
  } else if (mrb_obj_equal(mrb, value, mrb_symbol_value(mrb_intern_lit(mrb, "stream")))) {
    hints.ai_socktype = SOCK_STREAM;
  }
  value = mrb_hash_get(mrb, mrb_hints, mrb_symbol_value(mrb_intern_lit(mrb, "protocol")));
  if (mrb_obj_equal(mrb, value, mrb_symbol_value(mrb_intern_lit(mrb, "ip")))) {
    hints.ai_protocol = IPPROTO_IP;
  } else if (mrb_obj_equal(mrb, value, mrb_symbol_value(mrb_intern_lit(mrb, "udp")))) {
    hints.ai_protocol = IPPROTO_UDP;
  } else if (mrb_obj_equal(mrb, value, mrb_symbol_value(mrb_intern_lit(mrb, "tcp")))) {
    hints.ai_protocol = IPPROTO_TCP;
  }
  value = mrb_hash_get(mrb, mrb_hints, mrb_symbol_value(mrb_intern_lit(mrb, "flags")));
  if (mrb_obj_is_kind_of(mrb, value, mrb->fixnum_class)) {
    hints.ai_flags = mrb_int(mrb, value);
  }

  req = mrb_uv_req_current(mrb, b, &ret);
  if (mrb_nil_p(req->block)) {
    mrb_uv_req_clear(req);
    mrb_raise(mrb, E_ARGUMENT_ERROR, "Expected callback in uv_getaddrinfo.");
  }
  mrb_uv_req_check_error(mrb, req, uv_getaddrinfo(
      mrb_uv_current_loop(mrb), &req->req.getaddrinfo, _uv_getaddrinfo_cb,
      RSTRING_PTR(node), RSTRING_PTR(service), &hints));
  return ret;
}

static mrb_value
mrb_uv_addrinfo_flags(mrb_state *mrb, mrb_value self)
{
  return mrb_fixnum_value(addrinfo_ptr(mrb, self)->ai_flags);
}

static mrb_value
mrb_uv_addrinfo_family(mrb_state *mrb, mrb_value self)
{
  return mrb_fixnum_value(addrinfo_ptr(mrb, self)->ai_family);
}

static mrb_value
mrb_uv_addrinfo_socktype(mrb_state *mrb, mrb_value self)
{
  return mrb_fixnum_value(addrinfo_ptr(mrb, self)->ai_socktype);
}

static mrb_value
mrb_uv_addrinfo_protocol(mrb_state *mrb, mrb_value self)
{
  return mrb_fixnum_value(addrinfo_ptr(mrb, self)->ai_protocol);
}

static mrb_value
mrb_uv_addrinfo_addr(mrb_state *mrb, mrb_value self)
{
  struct addrinfo const* addr = addrinfo_ptr(mrb, self);
  struct RClass* _class_uv = mrb_module_get(mrb, "UV");
  mrb_value c = mrb_nil_value();
  mrb_value args[1];

  switch (addr->ai_family) {
  case AF_INET:
    {
      struct RClass* _class_uv_ip4addr = mrb_class_get_under(mrb, _class_uv, "Ip4Addr");
      struct sockaddr_in* saddr = (struct sockaddr_in*)mrb_malloc(mrb, sizeof(struct sockaddr_in));
      *saddr = *(struct sockaddr_in*)addr->ai_addr;
      args[0] = mrb_obj_value(
        Data_Wrap_Struct(mrb, mrb->object_class,
        &mrb_uv_ip4addr_type, (void*) saddr));
      c = mrb_obj_new(mrb, _class_uv_ip4addr, 1, args);
    }
    break;
  case AF_INET6:
    {
      struct RClass* _class_uv_ip6addr = mrb_class_get_under(mrb, _class_uv, "Ip6Addr");
      struct sockaddr_in6* saddr = (struct sockaddr_in6*)mrb_malloc(mrb, sizeof(struct sockaddr_in6));
      *saddr = *(struct sockaddr_in6*)addr->ai_addr;
      args[0] = mrb_obj_value(
        Data_Wrap_Struct(mrb, mrb->object_class,
        &mrb_uv_ip6addr_type, (void*) saddr));
      c = mrb_obj_new(mrb, _class_uv_ip6addr, 1, args);
    }
    break;
  }
  return c;
}

static mrb_value
mrb_uv_addrinfo_canonname(mrb_state *mrb, mrb_value self)
{
  struct addrinfo const* addr = addrinfo_ptr(mrb, self);
  return mrb_str_new_cstr(mrb,
    addr->ai_canonname ? addr->ai_canonname : "");
}

static mrb_value
mrb_uv_addrinfo_next(mrb_state *mrb, mrb_value self)
{
  struct addrinfo const* addr = addrinfo_ptr(mrb, self);
  struct RClass* _class_uv, *_class_uv_addrinfo;
  mrb_value c;

  if (!addr->ai_next) { return mrb_nil_value(); }

  _class_uv = mrb_module_get(mrb, "UV");
  _class_uv_addrinfo = mrb_class_get_under(mrb, _class_uv, "Addrinfo");

  c = mrb_obj_new(mrb, _class_uv_addrinfo, 0, NULL);
  mrb_iv_set(mrb, c, mrb_intern_lit(mrb, "parent_addrinfo"), self);
  DATA_PTR(c) = addr->ai_next;
  DATA_TYPE(c) = &uv_addrinfo_nofree_type;
  return c;
}

static mrb_value
mrb_uv_guess_handle(mrb_state *mrb, mrb_value self)
{
  mrb_int fd;
  uv_handle_type h;
  mrb_get_args(mrb, "i", &fd);

  h = uv_guess_handle(fd);

  switch(h) {
  case UV_FILE: return symbol_value_lit(mrb, "file");

#define XX(t, l) case UV_ ## t: return symbol_value_lit(mrb, #l);
  UV_HANDLE_TYPE_MAP(XX)
#undef XX

  default:
  case UV_UNKNOWN_HANDLE:
    return symbol_value_lit(mrb, "unknown");
  }
}

static mrb_value
mrb_uv_exepath(mrb_state *mrb, mrb_value self)
{
  char buf[PATH_MAX];
  size_t s = sizeof(buf);
  mrb_uv_check_error(mrb, uv_exepath(buf, &s));
  return mrb_str_new(mrb, buf, s);
}

static mrb_value
mrb_uv_cwd(mrb_state *mrb, mrb_value self)
{
  char buf[PATH_MAX];
  size_t s = sizeof(buf);
  mrb_uv_check_error(mrb, uv_cwd(buf, &s));
  return mrb_str_new(mrb, buf, s);
}

static mrb_value
mrb_uv_chdir(mrb_state *mrb, mrb_value self)
{
  char *z;
  mrb_get_args(mrb, "z", &z);
  mrb_uv_check_error(mrb, uv_chdir(z));
  return self;
}

static mrb_value
mrb_uv_kill(mrb_state *mrb, mrb_value self)
{
  mrb_int pid, sig;
  mrb_get_args(mrb, "ii", &pid, &sig);
  mrb_uv_check_error(mrb, uv_kill(pid, sig));
  return self;
}

static mrb_value
mrb_uv_version(mrb_state *mrb, mrb_value self)
{
  return mrb_fixnum_value(uv_version());
}

static mrb_value
mrb_uv_version_string(mrb_state *mrb, mrb_value self)
{
  return mrb_str_new_cstr(mrb, uv_version_string());
}

void*
mrb_uv_get_ptr(mrb_state *mrb, mrb_value v, struct mrb_data_type const *t)
{
  if (mrb_type(v) == MRB_TT_DATA && !DATA_PTR(v)) {
    mrb_raise(mrb, E_UV_ERROR, "uninitialized or already destroyed data");
  }
  return mrb_data_get_ptr(mrb, v, t);
}

mrb_value
mrb_uv_create_error(mrb_state *mrb, int err)
{
  mrb_value argv[] = {
    mrb_str_new_cstr(mrb, uv_strerror(err)),
    mrb_symbol_value(mrb_intern_cstr(mrb, uv_err_name(err))),
  };
  mrb_assert(err < 0);
  return mrb_obj_new(mrb, E_UV_ERROR, 2, argv);
}

mrb_value
mrb_uv_create_status(mrb_state *mrb, int st)
{
  if (st < 0) { return mrb_uv_create_error(mrb, st); }

  mrb_assert(st == 0);
  return mrb_nil_value();
}

void
mrb_uv_check_error(mrb_state *mrb, int err)
{
  if (err >= 0) { return; }

  mrb_exc_raise(mrb, mrb_uv_create_error(mrb, err));
}

static mrb_value
mrb_uv_get_error(mrb_state *mrb, mrb_value self)
{
  mrb_int err;
  mrb_value argv[2];

  mrb_get_args(mrb, "i", &err);

  if (err >= 0) {
    return mrb_nil_value();
  }

  argv[0] = mrb_str_new_cstr(mrb, uv_strerror(err));
  argv[1] = mrb_symbol_value(mrb_intern_cstr(mrb, uv_err_name(err)));
  return mrb_obj_new(mrb, E_UV_ERROR, 2, argv);
}

#if MRB_UV_CHECK_VERSION(1, 10, 0)

static mrb_value
mrb_uv_translate_sys_error(mrb_state *mrb, mrb_value self)
{
  mrb_int err;
  mrb_get_args(mrb, "i", &err);
  return mrb_fixnum_value(uv_translate_sys_error(err));
}

#endif

static mrb_value
mrb_uv_free_memory(mrb_state *mrb, mrb_value self)
{
  return mrb_uv_from_uint64(mrb, uv_get_free_memory());
}

static mrb_value
mrb_uv_total_memory(mrb_state *mrb, mrb_value self)
{
  return mrb_uv_from_uint64(mrb, uv_get_total_memory());
}

static mrb_value
mrb_uv_hrtime(mrb_state *mrb, mrb_value self)
{
  return mrb_uv_from_uint64(mrb, uv_hrtime());
}

static mrb_value
mrb_uv_disable_stdio_inheritance(mrb_state *mrb, mrb_value self)
{
  return uv_disable_stdio_inheritance(), self;
}

static mrb_value
mrb_uv_process_title(mrb_state *mrb, mrb_value self)
{
  char buf[PATH_MAX];

  mrb_uv_check_error(mrb, uv_get_process_title(buf, PATH_MAX));
  return mrb_str_new_cstr(mrb, buf);
}

static mrb_value
mrb_uv_process_title_set(mrb_state *mrb, mrb_value self)
{
  char const *z;
  mrb_get_args(mrb, "z", &z);

  mrb_uv_check_error(mrb, uv_set_process_title(z));
  return mrb_uv_process_title(mrb, self);
}

static mrb_value
mrb_uv_rusage(mrb_state *mrb, mrb_value self)
{
  uv_rusage_t usage;
  mrb_value ret, tv;

  mrb_uv_check_error(mrb, uv_getrusage(&usage));

  ret = mrb_hash_new_capa(mrb, 16);
#define set_val(name) \
  mrb_hash_set(mrb, ret, symbol_value_lit(mrb, #name), mrb_uv_from_uint64(mrb, usage.ru_ ## name))

  set_val(maxrss);
  set_val(ixrss);
  set_val(idrss);
  set_val(isrss);
  set_val(minflt);
  set_val(majflt);
  set_val(nswap);
  set_val(inblock);
  set_val(oublock);
  set_val(msgsnd);
  set_val(msgrcv);
  set_val(nsignals);
  set_val(nvcsw);
  set_val(nivcsw);

#undef set_val

  tv = mrb_ary_new_capa(mrb, 2);
  mrb_ary_push(mrb, tv, mrb_fixnum_value(usage.ru_utime.tv_sec));
  mrb_ary_push(mrb, tv, mrb_fixnum_value(usage.ru_utime.tv_usec));
  mrb_hash_set(mrb, ret, symbol_value_lit(mrb, "utime"), tv);

  tv = mrb_ary_new_capa(mrb, 2);
  mrb_ary_push(mrb, tv, mrb_fixnum_value(usage.ru_stime.tv_sec));
  mrb_ary_push(mrb, tv, mrb_fixnum_value(usage.ru_stime.tv_usec));
  mrb_hash_set(mrb, ret, symbol_value_lit(mrb, "stime"), tv);

  return ret;
}

static mrb_value
mrb_uv_cpu_info(mrb_state *mrb, mrb_value self)
{
  uv_cpu_info_t *info;
  int info_count, err, i, ai;
  mrb_value ret;

  err = uv_cpu_info(&info, &info_count);
  if (err < 0) {
    mrb_uv_check_error(mrb, err);
  }

  ret = mrb_ary_new_capa(mrb, info_count);
  ai = mrb_gc_arena_save(mrb);
  for (i = 0; i < info_count; ++i) {
    mrb_value c = mrb_hash_new_capa(mrb, 3), t = mrb_hash_new_capa(mrb, 5);

    mrb_hash_set(mrb, t, symbol_value_lit(mrb, "user"), mrb_uv_from_uint64(mrb, info[i].cpu_times.user));
    mrb_hash_set(mrb, t, symbol_value_lit(mrb, "nice"), mrb_uv_from_uint64(mrb, info[i].cpu_times.nice));
    mrb_hash_set(mrb, t, symbol_value_lit(mrb, "sys"), mrb_uv_from_uint64(mrb, info[i].cpu_times.sys));
    mrb_hash_set(mrb, t, symbol_value_lit(mrb, "idle"), mrb_uv_from_uint64(mrb, info[i].cpu_times.idle));
    mrb_hash_set(mrb, t, symbol_value_lit(mrb, "irq"), mrb_uv_from_uint64(mrb, info[i].cpu_times.irq));

    mrb_hash_set(mrb, c, symbol_value_lit(mrb, "model"), mrb_str_new_cstr(mrb, info[i].model));
    mrb_hash_set(mrb, c, symbol_value_lit(mrb, "speed"), mrb_fixnum_value(info[i].speed));
    mrb_hash_set(mrb, c, symbol_value_lit(mrb, "cpu_times"), t);

    mrb_ary_push(mrb, ret, c);
    mrb_gc_arena_restore(mrb, ai);
  }

  uv_free_cpu_info(info, info_count);
  return ret;
}

static mrb_value
mrb_uv_interface_addresses(mrb_state *mrb, mrb_value self)
{
  uv_interface_address_t *addr;
  int addr_count, err, i, ai;
  mrb_value ret;
  struct RClass *UV = mrb_module_get(mrb, "UV");

  err = uv_interface_addresses(&addr, &addr_count);
  if (err < 0) {
    mrb_uv_check_error(mrb, err);
  }

  ret = mrb_ary_new_capa(mrb, addr_count);
  ai = mrb_gc_arena_save(mrb);
  for (i = 0; i < addr_count; ++i) {
    int j;
    mrb_value n = mrb_hash_new_capa(mrb, 5), phys = mrb_ary_new_capa(mrb, 6);

    for (j = 0; j < 6; ++j) {
      mrb_ary_push(mrb, phys, mrb_fixnum_value((uint8_t)addr[i].phys_addr[j]));
    }

    mrb_hash_set(mrb, n, symbol_value_lit(mrb, "name"), mrb_str_new_cstr(mrb, addr[i].name));
    mrb_hash_set(mrb, n, symbol_value_lit(mrb, "is_internal"), mrb_bool_value(addr[i].is_internal));
    mrb_hash_set(mrb, n, symbol_value_lit(mrb, "phys_addr"), phys);
    {
      struct RClass *cls;
      void *ptr;
      struct mrb_data_type const *type;

      switch(addr[i].address.address4.sin_family) {
      case AF_INET:
        cls = mrb_class_get_under(mrb, UV, "Ip4Addr");
        ptr = mrb_malloc(mrb, sizeof(struct sockaddr_in));
        *(struct sockaddr_in*)ptr = addr[i].address.address4;
        type = &mrb_uv_ip4addr_type;
        break;
      case AF_INET6:
        cls = mrb_class_get_under(mrb, UV, "Ip6Addr");
        ptr = mrb_malloc(mrb, sizeof(struct sockaddr_in6));
        *(struct sockaddr_in6*)ptr = addr[i].address.address6;
        type = &mrb_uv_ip6addr_type;
        break;
      default: mrb_assert(FALSE);
      }
      mrb_hash_set(mrb, n, symbol_value_lit(mrb, "address"), mrb_obj_value(Data_Wrap_Struct(mrb, cls, type, ptr)));
    }

    {
      struct RClass *cls;
      void *ptr;
      struct mrb_data_type const *type;

      switch(addr[i].netmask.netmask4.sin_family) {
      case AF_INET:
        cls = mrb_class_get_under(mrb, UV, "Ip4Addr");
        ptr = mrb_malloc(mrb, sizeof(struct sockaddr_in));
        *(struct sockaddr_in*)ptr = addr[i].netmask.netmask4;
        type = &mrb_uv_ip4addr_type;
        break;
      case AF_INET6:
        cls = mrb_class_get_under(mrb, UV, "Ip6Addr");
        ptr = mrb_malloc(mrb, sizeof(struct sockaddr_in6));
        *(struct sockaddr_in6*)ptr = addr[i].netmask.netmask6;
        type = &mrb_uv_ip6addr_type;
        break;
      default: mrb_assert(FALSE);
      }
      mrb_hash_set(mrb, n, symbol_value_lit(mrb, "netmask"), mrb_obj_value(Data_Wrap_Struct(mrb, cls, type, ptr)));
    }

    mrb_ary_push(mrb, ret, n);
    mrb_gc_arena_restore(mrb, ai);
  }

  uv_free_interface_addresses(addr, addr_count);
  return ret;
}

static void
mrb_uv_work_cb(uv_work_t *uv_req)
{
  mrb_uv_req_t *req = (mrb_uv_req_t*)uv_req->data;
  mrb_value cfunc = req->block;

  mrb_assert(mrb_type(cfunc) == MRB_TT_PROC);
  mrb_assert(MRB_PROC_CFUNC_P(mrb_proc_ptr(cfunc)));

  mrb_proc_ptr(cfunc)->body.func(NULL, mrb_nil_value());
}

static void
mrb_uv_after_work_cb(uv_work_t *uv_req, int err)
{
  mrb_uv_req_t *req = (mrb_uv_req_t*)uv_req->data;
  mrb_state *mrb = req->mrb;
  mrb_value arg = mrb_fixnum_value(err);

  mrb_iv_set(mrb, req->instance, mrb_intern_lit(mrb, "cfunc_cb"), mrb_nil_value());
  req->block = mrb_iv_get(mrb, req->instance, mrb_intern_lit(mrb, "uv_cb"));
  mrb_uv_req_yield(req, 1, &arg);
}

static mrb_value
mrb_uv_queue_work(mrb_state *mrb, mrb_value self)
{
  mrb_value cfunc, blk, ret;
  mrb_uv_req_t *req;

  mrb_get_args(mrb, "o&", &cfunc, &blk);
  if (mrb_type(cfunc) != MRB_TT_PROC || !MRB_PROC_CFUNC_P(mrb_proc_ptr(cfunc))) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "invalid cfunc callback");
  }
  if (mrb_nil_p(blk)) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "expected block to UV.queue_work");
  }

  req = mrb_uv_req_current(mrb, blk, &ret);
  mrb_iv_set(mrb, req->instance, mrb_intern_lit(mrb, "cfunc_cb"), cfunc);
  req->block = cfunc;
  mrb_uv_req_check_error(mrb, req, uv_queue_work(
      mrb_uv_current_loop(mrb), &req->req.work, mrb_uv_work_cb, mrb_uv_after_work_cb));
  return ret;
}

static mrb_value
mrb_uv_resident_set_memory(mrb_state *mrb, mrb_value self)
{
  size_t rss;
  mrb_uv_check_error(mrb, uv_resident_set_memory(&rss));
  return mrb_uv_from_uint64(mrb, rss);
}

static mrb_value
mrb_uv_uptime(mrb_state *mrb, mrb_value self)
{
  double t;
  mrb_uv_check_error(mrb, uv_uptime(&t));
  return mrb_float_value(mrb, (mrb_float)t);
}

uv_os_sock_t
mrb_uv_to_socket(mrb_state *mrb, mrb_value v)
{
  if (mrb_fixnum_p(v)) { /* treat raw integer as socket */
    return mrb_fixnum(v);
  }

  mrb_raisef(mrb, E_ARGUMENT_ERROR, "Cannot get socket from: %S", v);
  return 0; /* for compiler warning */
}

char**
mrb_uv_setup_args(mrb_state *mrb, int *argc, char **argv, mrb_bool set_global)
{
  int new_argc; char **new_argv;

  new_argv = uv_setup_args(*argc, argv);
  if (new_argv == argv) { // no change
    new_argc = *argc;
  } else {
    char **it = new_argv;
    new_argc = 0;
    while (*it) {
        ++new_argc;
        ++it;
    }
  }

  if (set_global) {
    int i, ai;
    mrb_value argv_val;

    mrb_gv_set(mrb, mrb_intern_lit(mrb, "$0"), mrb_str_new_cstr(mrb, new_argv[0]));

    argv_val = mrb_ary_new_capa(mrb, new_argc - 1);
    ai = mrb_gc_arena_save(mrb);
    for (i = 1; i < new_argc; ++i) {
      mrb_ary_push(mrb, argv_val, mrb_str_new_cstr(mrb, new_argv[i]));
      mrb_gc_arena_restore(mrb, ai);
    }
    mrb_define_global_const(mrb, "ARGV", argv_val);
  }

  *argc = new_argc;
  return new_argv;
}

#if MRB_UV_CHECK_VERSION(1, 12, 0)

// OS
static mrb_value
mrb_uv_get_osfhandle(mrb_state *mrb, mrb_value self)
{
  mrb_int i;
  mrb_get_args(mrb, "i", &i);
  return mrb_cptr_value(mrb, (void*)(uintptr_t)uv_get_osfhandle(i));
}

#endif

#if MRB_UV_CHECK_VERSION(1, 6, 0)

static mrb_value
mrb_uv_os_homedir(mrb_state *mrb, mrb_value self)
{
  enum { BUF_SIZE = 128 };
  mrb_value buf = mrb_str_buf_new(mrb, BUF_SIZE);
  int res;
  size_t s = BUF_SIZE;
  mrb_str_resize(mrb, buf, BUF_SIZE);

  res = uv_os_homedir(RSTRING_PTR(buf), &s);
  if (res == UV_ENOBUFS) {
    mrb_str_resize(mrb, buf, s);
    res = uv_os_homedir(RSTRING_PTR(buf), &s);
  }
  mrb_uv_check_error(mrb, res);

  mrb_str_resize(mrb, buf, s);
  return buf;
}

#endif

#if MRB_UV_CHECK_VERSION(1, 9, 0)

static mrb_value
mrb_uv_os_tmpdir(mrb_state *mrb, mrb_value self)
{
  enum { BUF_SIZE = 128 };
  mrb_value buf = mrb_str_buf_new(mrb, BUF_SIZE);
  int res;
  size_t s = BUF_SIZE;
  mrb_str_resize(mrb, buf, BUF_SIZE);

  res = uv_os_tmpdir(RSTRING_PTR(buf), &s);
  if (res == UV_ENOBUFS) {
    mrb_str_resize(mrb, buf, s);
    res = uv_os_tmpdir(RSTRING_PTR(buf), &s);
  }
  mrb_uv_check_error(mrb, res);

  mrb_str_resize(mrb, buf, s);
  return buf;
}

#endif

#if MRB_UV_CHECK_VERSION(1, 12, 0)

static mrb_value
mrb_uv_os_getenv(mrb_state *mrb, mrb_value self)
{
  enum { BUF_SIZE = 128 };
  mrb_value buf = mrb_str_buf_new(mrb, BUF_SIZE);
  int res;
  size_t s = BUF_SIZE;
  char const *env;
  mrb_get_args(mrb, "z", &env);

  mrb_str_resize(mrb, buf, BUF_SIZE);

  res = uv_os_getenv(env, RSTRING_PTR(buf), &s);
  if (res == UV_ENOBUFS) {
    mrb_str_resize(mrb, buf, s);
    res = uv_os_getenv(env, RSTRING_PTR(buf), &s);
  }

  if (res == UV_ENOENT) { return mrb_nil_value(); }

  mrb_uv_check_error(mrb, res);

  mrb_str_resize(mrb, buf, s);
  return buf;
}

static mrb_value
mrb_uv_os_setenv(mrb_state *mrb, mrb_value self)
{
  char *env, *val;
  mrb_get_args(mrb, "zz", &env, &val);
  mrb_uv_check_error(mrb, uv_os_setenv(env, val));
  return self;
}

static mrb_value
mrb_uv_os_unsetenv(mrb_state *mrb, mrb_value self)
{
  char *env;
  mrb_get_args(mrb, "z", &env);
  mrb_uv_check_error(mrb, uv_os_unsetenv(env));
  return self;
}

static mrb_value
mrb_uv_os_gethostname(mrb_state *mrb, mrb_value self)
{
  enum { BUF_SIZE = 128 };
  mrb_value buf = mrb_str_buf_new(mrb, BUF_SIZE);
  int res;
  size_t s = BUF_SIZE;
  mrb_str_resize(mrb, buf, BUF_SIZE);

  res = uv_os_gethostname(RSTRING_PTR(buf), &s);
  if (res == UV_ENOBUFS) {
    mrb_str_resize(mrb, buf, s);
    res = uv_os_gethostname(RSTRING_PTR(buf), &s);
  }
  mrb_uv_check_error(mrb, res);

  mrb_str_resize(mrb, buf, s);
  return buf;
}

#endif

#if MRB_UV_CHECK_VERSION(1, 18, 0)

static mrb_value
mrb_uv_os_getpid(mrb_state *mrb, mrb_value self)
{
  return mrb_fixnum_value(uv_os_getpid());
}

#endif

#if MRB_UV_CHECK_VERSION(1, 16, 0)

static mrb_value
mrb_uv_os_getppid(mrb_state *mrb, mrb_value self)
{
  return mrb_fixnum_value(uv_os_getppid());
}

#endif

/*********************************************************
 * register
 *********************************************************/

void
mrb_mruby_uv_gem_init(mrb_state* mrb) {
  int ai = mrb_gc_arena_save(mrb);

  struct RClass* _class_uv;
  struct RClass* _class_uv_loop;
  struct RClass* _class_uv_addrinfo;
  struct RClass* _class_uv_ip4addr;
  struct RClass* _class_uv_ip6addr;
  struct RClass* _class_uv_req;
  struct RClass* _class_uv_os;
#if MRB_UV_CHECK_VERSION(1, 9, 0)
  struct RClass* _class_uv_passwd;
#endif
  mrb_value def_loop;

  mrb_define_class(mrb, "UVError", E_NAME_ERROR);

  _class_uv = mrb_define_module(mrb, "UV");
  mrb_define_module_function(mrb, _class_uv, "run", mrb_uv_run, MRB_ARGS_NONE());
  mrb_define_module_function(mrb, _class_uv, "default_loop", mrb_uv_default_loop, MRB_ARGS_NONE());
  mrb_define_module_function(mrb, _class_uv, "current_loop", mrb_uv_current_loop_meth, MRB_ARGS_NONE());
  mrb_define_module_function(mrb, _class_uv, "ip4_addr", mrb_uv_ip4_addr, MRB_ARGS_REQ(2));
  mrb_define_module_function(mrb, _class_uv, "ip6_addr", mrb_uv_ip6_addr, MRB_ARGS_REQ(2));
  mrb_define_module_function(mrb, _class_uv, "getaddrinfo", mrb_uv_getaddrinfo, MRB_ARGS_REQ(3));
  mrb_define_module_function(mrb, _class_uv, "getnameinfo", mrb_uv_getnameinfo, MRB_ARGS_REQ(2));
  mrb_define_module_function(mrb, _class_uv, "gc", mrb_uv_gc, MRB_ARGS_NONE());
  mrb_define_module_function(mrb, _class_uv, "guess_handle", mrb_uv_guess_handle, MRB_ARGS_REQ(1));
  mrb_define_module_function(mrb, _class_uv, "exepath", mrb_uv_exepath, MRB_ARGS_NONE());
  mrb_define_module_function(mrb, _class_uv, "cwd", mrb_uv_cwd, MRB_ARGS_NONE());
  mrb_define_module_function(mrb, _class_uv, "chdir", mrb_uv_chdir, MRB_ARGS_REQ(1));
  mrb_define_module_function(mrb, _class_uv, "loadavg", mrb_uv_loadavg, MRB_ARGS_NONE());
  mrb_define_module_function(mrb, _class_uv, "kill", mrb_uv_kill, MRB_ARGS_REQ(2));
  mrb_define_module_function(mrb, _class_uv, "version", mrb_uv_version, MRB_ARGS_NONE());
  mrb_define_module_function(mrb, _class_uv, "version_string", mrb_uv_version_string, MRB_ARGS_NONE());
  mrb_define_module_function(mrb, _class_uv, "free_memory", mrb_uv_free_memory, MRB_ARGS_NONE());
  mrb_define_module_function(mrb, _class_uv, "total_memory", mrb_uv_total_memory, MRB_ARGS_NONE());
  mrb_define_module_function(mrb, _class_uv, "hrtime", mrb_uv_hrtime, MRB_ARGS_NONE());
  mrb_define_module_function(mrb, _class_uv, "disable_stdio_inheritance", mrb_uv_disable_stdio_inheritance, MRB_ARGS_NONE());
  mrb_define_module_function(mrb, _class_uv, "process_title", mrb_uv_process_title, MRB_ARGS_NONE());
  mrb_define_module_function(mrb, _class_uv, "process_title=", mrb_uv_process_title_set, MRB_ARGS_REQ(1));
  mrb_define_module_function(mrb, _class_uv, "rusage", mrb_uv_rusage, MRB_ARGS_NONE());
  mrb_define_module_function(mrb, _class_uv, "cpu_info", mrb_uv_cpu_info, MRB_ARGS_NONE());
  mrb_define_module_function(mrb, _class_uv, "interface_addresses", mrb_uv_interface_addresses, MRB_ARGS_NONE());
  mrb_define_module_function(mrb, _class_uv, "queue_work", mrb_uv_queue_work, MRB_ARGS_REQ(1) | MRB_ARGS_BLOCK());
  mrb_define_module_function(mrb, _class_uv, "resident_set_memory", mrb_uv_resident_set_memory, MRB_ARGS_NONE());
  mrb_define_module_function(mrb, _class_uv, "uptime", mrb_uv_uptime, MRB_ARGS_NONE());
  mrb_define_module_function(mrb, _class_uv, "get_error", mrb_uv_get_error, MRB_ARGS_REQ(1));
#if MRB_UV_CHECK_VERSION(1, 10, 0)
  mrb_define_module_function(mrb, _class_uv, "translate_sys_error", mrb_uv_translate_sys_error, MRB_ARGS_REQ(1));
#endif
#if MRB_UV_CHECK_VERSION(1, 12, 0)
  mrb_define_module_function(mrb, _class_uv, "osfhandle", mrb_uv_get_osfhandle, MRB_ARGS_REQ(1));
#endif

  mrb_define_const(mrb, _class_uv, "UV_RUN_DEFAULT", mrb_fixnum_value(UV_RUN_DEFAULT));
  mrb_define_const(mrb, _class_uv, "UV_RUN_ONCE", mrb_fixnum_value(UV_RUN_ONCE));
  mrb_define_const(mrb, _class_uv, "UV_RUN_NOWAIT", mrb_fixnum_value(UV_RUN_NOWAIT));
#ifdef _WIN32
  mrb_define_const(mrb, _class_uv, "IS_WINDOWS", mrb_true_value());
#else
  mrb_define_const(mrb, _class_uv, "IS_WINDOWS", mrb_false_value());
#endif
  mrb_define_const(mrb, _class_uv, "SOMAXCONN", mrb_fixnum_value(SOMAXCONN));
  mrb_gc_arena_restore(mrb, ai);

  _class_uv_loop = mrb_define_class_under(mrb, _class_uv, "Loop", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_uv_loop, MRB_TT_DATA);
  mrb_define_method(mrb, _class_uv_loop, "initialize", mrb_uv_loop_init, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_loop, "run", mrb_uv_loop_run, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_loop, "delete", mrb_uv_loop_close, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_loop, "close", mrb_uv_loop_close, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_loop, "data=", mrb_uv_data_set, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_loop, "data", mrb_uv_data_get, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_loop, "alive?", mrb_uv_loop_alive, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_loop, "stop", mrb_uv_stop, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_loop, "update_time", mrb_uv_update_time, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_loop, "backend_fd", mrb_uv_backend_fd, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_loop, "backend_timeout", mrb_uv_backend_timeout, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_loop, "now", mrb_uv_now, MRB_ARGS_NONE());
#if MRB_UV_CHECK_VERSION(1, 12, 0)
  mrb_define_method(mrb, _class_uv_loop, "fork", mrb_uv_loop_fork, MRB_ARGS_NONE());
#endif
#if MRB_UV_CHECK_VERSION(1, 12, 2)
  mrb_define_method(mrb, _class_uv_loop, "configure", mrb_uv_loop_configure, MRB_ARGS_REQ(1));
#endif
  mrb_define_method(mrb, _class_uv_loop, "==", mrb_uv_loop_eq, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_loop, "make_current", mrb_uv_loop_make_current, MRB_ARGS_NONE());
  mrb_gc_arena_restore(mrb, ai);

  def_loop = mrb_obj_value(mrb_data_object_alloc(mrb, _class_uv_loop, uv_default_loop(), &mrb_uv_loop_type));
  mrb_iv_set(mrb, mrb_obj_value(_class_uv), mrb_intern_lit(mrb, "default_loop"), def_loop);
  mrb_iv_set(mrb, mrb_obj_value(_class_uv), mrb_intern_lit(mrb, "current_loop"), def_loop);

  _class_uv_addrinfo = mrb_define_class_under(mrb, _class_uv, "Addrinfo", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_uv_addrinfo, MRB_TT_DATA);
  mrb_define_method(mrb, _class_uv_addrinfo, "flags", mrb_uv_addrinfo_flags, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_addrinfo, "family", mrb_uv_addrinfo_family, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_addrinfo, "socktype", mrb_uv_addrinfo_socktype, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_addrinfo, "protocol", mrb_uv_addrinfo_protocol, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_addrinfo, "addr", mrb_uv_addrinfo_addr, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_addrinfo, "canonname", mrb_uv_addrinfo_canonname, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_addrinfo, "next", mrb_uv_addrinfo_next, MRB_ARGS_NONE());

  mrb_define_const(mrb, _class_uv_addrinfo, "AF_INET", mrb_fixnum_value(AF_INET));
  mrb_define_const(mrb, _class_uv_addrinfo, "AF_INET6", mrb_fixnum_value(AF_INET6));
  mrb_define_const(mrb, _class_uv_addrinfo, "AF_UNSPEC", mrb_fixnum_value(AF_UNSPEC));
#ifdef AF_UNIX
  mrb_define_const(mrb, _class_uv_addrinfo, "AF_UNIX", mrb_fixnum_value(AF_UNIX));
#endif

  mrb_define_const(mrb, _class_uv_addrinfo, "SOCK_STREAM", mrb_fixnum_value(SOCK_STREAM));
  mrb_define_const(mrb, _class_uv_addrinfo, "SOCK_DGRAM", mrb_fixnum_value(SOCK_DGRAM));
  mrb_define_const(mrb, _class_uv_addrinfo, "SOCK_RAW", mrb_fixnum_value(SOCK_RAW));
  mrb_define_const(mrb, _class_uv_addrinfo, "SOCK_SEQPACKET", mrb_fixnum_value(SOCK_SEQPACKET));

  mrb_define_const(mrb, _class_uv_addrinfo, "AI_PASSIVE", mrb_fixnum_value(AI_PASSIVE));
  mrb_define_const(mrb, _class_uv_addrinfo, "AI_CANONNAME", mrb_fixnum_value(AI_CANONNAME));
  mrb_define_const(mrb, _class_uv_addrinfo, "AI_NUMERICHOST", mrb_fixnum_value(AI_NUMERICHOST));
  mrb_define_const(mrb, _class_uv_addrinfo, "AI_NUMERICSERV", mrb_fixnum_value(AI_NUMERICSERV));
  mrb_define_const(mrb, _class_uv_addrinfo, "AI_V4MAPPED", mrb_fixnum_value(AI_V4MAPPED));
  mrb_define_const(mrb, _class_uv_addrinfo, "AI_ALL", mrb_fixnum_value(AI_ALL));
  mrb_define_const(mrb, _class_uv_addrinfo, "AI_ADDRCONFIG", mrb_fixnum_value(AI_ADDRCONFIG));

  mrb_define_const(mrb, _class_uv_addrinfo, "IPPROTO_TCP", mrb_fixnum_value(IPPROTO_TCP));
  mrb_define_const(mrb, _class_uv_addrinfo, "IPPROTO_UDP", mrb_fixnum_value(IPPROTO_UDP));

  mrb_gc_arena_restore(mrb, ai);

  _class_uv_ip4addr = mrb_define_class_under(mrb, _class_uv, "Ip4Addr", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_uv_ip4addr, MRB_TT_DATA);
  mrb_define_method(mrb, _class_uv_ip4addr, "initialize", mrb_uv_ip4addr_init, MRB_ARGS_REQ(1) | MRB_ARGS_OPT(1));
  mrb_define_method(mrb, _class_uv_ip4addr, "to_s", mrb_uv_ip4addr_to_s, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_ip4addr, "sin_addr", mrb_uv_ip4addr_sin_addr, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_ip4addr, "sin_port", mrb_uv_ip4addr_sin_port, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_ip4addr, "addr", mrb_uv_ip4addr_sin_addr, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_ip4addr, "port", mrb_uv_ip4addr_sin_port, MRB_ARGS_NONE());
  mrb_gc_arena_restore(mrb, ai);

  _class_uv_ip6addr = mrb_define_class_under(mrb, _class_uv, "Ip6Addr", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_uv_ip6addr, MRB_TT_DATA);
  mrb_define_method(mrb, _class_uv_ip6addr, "initialize", mrb_uv_ip6addr_init, MRB_ARGS_REQ(1) | MRB_ARGS_OPT(1));
  mrb_define_method(mrb, _class_uv_ip6addr, "to_s", mrb_uv_ip6addr_to_s, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_ip6addr, "addr", mrb_uv_ip6addr_sin_addr, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_ip6addr, "port", mrb_uv_ip6addr_sin_port, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_ip6addr, "sin_addr", mrb_uv_ip6addr_sin_addr, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_ip6addr, "sin_port", mrb_uv_ip6addr_sin_port, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_ip6addr, "scope_id", mrb_uv_ip6addr_sin6_scope_id, MRB_ARGS_NONE());
#if MRB_UV_CHECK_VERSION(1, 16, 0)
  mrb_define_method(mrb, _class_uv_ip6addr, "if_indextoname", mrb_uv_ip6addr_if_indextoname, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_ip6addr, "if_indextoiid", mrb_uv_ip6addr_if_indextoiid, MRB_ARGS_NONE());
#endif
  mrb_gc_arena_restore(mrb, ai);

#if MRB_UV_CHECK_VERSION(1, 16, 0)
  mrb_define_module_function(mrb, _class_uv, "if_indextoname", mrb_uv_if_indextoname, MRB_ARGS_NONE());
  mrb_define_module_function(mrb, _class_uv, "if_indextoiid", mrb_uv_if_indextoiid, MRB_ARGS_NONE());
#endif

  /* TODO
  uv_inet_ntop
  uv_inet_pton
  uv_replace_allocator
  */

  _class_uv_req = mrb_define_class_under(mrb, _class_uv, "Req", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_uv_req, MRB_TT_DATA);
  mrb_define_method(mrb, _class_uv_req, "cancel", mrb_uv_cancel, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_req, "type", mrb_uv_req_type, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_req, "type_name", mrb_uv_req_type_name, MRB_ARGS_NONE());
#if MRB_UV_CHECK_VERSION(1, 19, 0)
  mrb_define_method(mrb, _class_uv_req, "path", mrb_uv_fs_req_path, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_req, "result", mrb_uv_fs_req_result, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_req, "statbuf", mrb_uv_fs_req_statbuf, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_req, "type", mrb_uv_fs_req_type, MRB_ARGS_NONE());
#endif
  mrb_undef_class_method(mrb, _class_uv_req, "new");

  _class_uv_os = mrb_define_module_under(mrb, _class_uv, "OS");
#if MRB_UV_CHECK_VERSION(1, 6, 0)
  mrb_define_module_function(mrb, _class_uv_os, "homedir", mrb_uv_os_homedir, MRB_ARGS_NONE());
#endif
#if MRB_UV_CHECK_VERSION(1, 9, 0)
  mrb_define_module_function(mrb, _class_uv_os, "tmpdir", mrb_uv_os_tmpdir, MRB_ARGS_NONE());
#endif
#if MRB_UV_CHECK_VERSION(1, 12, 0)
  mrb_define_module_function(mrb, _class_uv_os, "getenv", mrb_uv_os_getenv, MRB_ARGS_REQ(1));
  mrb_define_module_function(mrb, _class_uv_os, "setenv", mrb_uv_os_setenv, MRB_ARGS_REQ(2));
  mrb_define_module_function(mrb, _class_uv_os, "unsetenv", mrb_uv_os_unsetenv, MRB_ARGS_REQ(1));
  mrb_define_module_function(mrb, _class_uv_os, "hostname", mrb_uv_os_gethostname, MRB_ARGS_NONE());
#endif
#if MRB_UV_CHECK_VERSION(1, 16, 0)
  mrb_define_module_function(mrb, _class_uv_os, "getppid", mrb_uv_os_getppid, MRB_ARGS_NONE());
#endif
#if MRB_UV_CHECK_VERSION(1, 18, 0)
  mrb_define_module_function(mrb, _class_uv_os, "getpid", mrb_uv_os_getpid, MRB_ARGS_NONE());
#endif

#if MRB_UV_CHECK_VERSION(1, 9, 0)
  _class_uv_passwd = mrb_define_class_under(mrb, _class_uv_os, "Passwd", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_uv_passwd, MRB_TT_DATA);
  mrb_define_method(mrb, _class_uv_passwd, "initialize", mrb_uv_passwd_init, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_passwd, "username", mrb_uv_passwd_username, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_passwd, "shell", mrb_uv_passwd_shell, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_passwd, "homedir", mrb_uv_passwd_homedir, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_passwd, "uid", mrb_uv_passwd_uid, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_passwd, "gid", mrb_uv_passwd_gid, MRB_ARGS_NONE());
#endif

  mrb_mruby_uv_gem_init_fs(mrb, _class_uv);
  mrb_mruby_uv_gem_init_handle(mrb, _class_uv);
  //mrb_mruby_uv_gem_init_thread(mrb, _class_uv);
  //mrb_mruby_uv_gem_init_dl(mrb, _class_uv);

  mrb_define_const(mrb, _class_uv, "$GC", mrb_ary_new(mrb));
}

void
mrb_mruby_uv_gem_final(mrb_state* mrb) {
  // clear gc table
  mrb_uv_gc_table_clean(mrb, NULL);

  // run close callbacks to release objects related to mruby
  uv_walk(uv_default_loop(), mrb_uv_close_handle_belongs_to_vm, mrb);
  uv_run(uv_default_loop(), UV_RUN_ONCE);
}


mrb_value
mrb_uv_current_loop_obj(mrb_state *mrb) {
  return mrb_iv_get(
      mrb, mrb_const_get(
          mrb, mrb_obj_value(mrb->object_class), mrb_intern_lit(mrb, "UV")),
      mrb_intern_lit(mrb, "current_loop"));
}

uv_loop_t*
mrb_uv_current_loop(mrb_state *mrb) {
  return (uv_loop_t*)mrb_uv_get_ptr(mrb, mrb_uv_current_loop_obj(mrb), &mrb_uv_loop_type);
}

static void
set_handle_cb(mrb_uv_handle *h, mrb_value b)
{
  mrb_state *mrb = h->mrb;
  if (mrb_nil_p(b)) {
    mrb_raise(mrb, mrb_class_get(mrb, "RuntimeError"), "block not passed");
  }
  if (!mrb_nil_p(h->block)) {
    mrb_raise(mrb, mrb_class_get(mrb, "RuntimeError"), "uv_handle_t callback already set.");
  }
  h->block = b;
  mrb_iv_set(mrb, h->instance, mrb_intern_lit(mrb, "uv_handle_cb"), b);
}

static void
yield_handle_cb(mrb_uv_handle *h, mrb_int argc, mrb_value const *argv)
{
  mrb_state *mrb = h->mrb;
  mrb_assert(!mrb_nil_p(h->block));
  mrb_yield_argv(mrb, h->block, argc, argv);
}

static uv_loop_t*
get_loop(mrb_state *mrb, mrb_value *v)
{
  if(mrb_nil_p(*v)) {
    *v = mrb_uv_current_loop_obj(mrb);
  }
  mrb_assert(!mrb_nil_p(*v));
  return (uv_loop_t*)mrb_uv_get_ptr(mrb, *v, &mrb_uv_loop_type);
}

static void
no_yield_close_cb(uv_handle_t *h)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)h->data;
  DATA_PTR(ctx->instance) = NULL;
  DATA_TYPE(ctx->instance) = NULL;
  mrb_free(ctx->mrb, ctx);
}

static void
mrb_uv_handle_free(mrb_state *mrb, void *p)
{
  mrb_uv_handle* context = (mrb_uv_handle*) p;
  if (!context) { return; }

  mrb_assert(mrb == context->mrb);
  mrb_assert(context->handle.type != UV_UNKNOWN_HANDLE);
  // mrb_assert(!uv_has_ref(&context->handle));

  if (!uv_is_closing(&context->handle)) {
    uv_close(&context->handle, no_yield_close_cb);
  }
}

void
mrb_uv_close_handle_belongs_to_vm(uv_handle_t *h, void *arg)
{
  mrb_state *mrb = (mrb_state*)arg;
  mrb_uv_handle* handle = (mrb_uv_handle*)h->data;

  if (!handle) { return; }
  if (handle->mrb != mrb) { return; }

  mrb_uv_handle_type.dfree(mrb, handle);
}

const struct mrb_data_type mrb_uv_handle_type = {
  "uv_handle", mrb_uv_handle_free
};

mrb_uv_handle*
mrb_uv_handle_alloc(mrb_state* mrb, uv_handle_type t, mrb_value instance, mrb_value loop)
{
  size_t const size = uv_handle_size(t);
  mrb_uv_handle* context = (mrb_uv_handle*) mrb_malloc(mrb, sizeof(mrb_uv_handle) + (size - sizeof(uv_handle_t)));
  context->mrb = mrb;
  context->instance = instance;
  context->block = mrb_nil_value();
  context->handle.data = context;
  context->handle.type = UV_UNKNOWN_HANDLE;
  mrb_assert(mrb_type(instance) == MRB_TT_DATA);
  DATA_PTR(instance) = context;
  DATA_TYPE(instance) = &mrb_uv_handle_type;
  mrb_assert(DATA_TYPE(loop) == &mrb_uv_loop_type);
  mrb_iv_set(mrb, instance, mrb_intern_lit(mrb, "loop"), loop);
  return context;
}

static void
_uv_done_cb(uv_req_t* uv_req, int status)
{
  mrb_uv_req_t *req = (mrb_uv_req_t*) uv_req->data;
  mrb_value const arg = mrb_uv_create_status(req->mrb, status);
  mrb_uv_req_yield(req, 1, &arg);
}

static void
_uv_alloc_cb(uv_handle_t* handle, size_t suggested_size, uv_buf_t* buf)
{
  buf->base = mrb_malloc(((mrb_uv_handle*)handle->data)->mrb, suggested_size);
  buf->len = suggested_size;
}

static void
_uv_close_cb(uv_handle_t* handle)
{
  mrb_uv_handle* context = (mrb_uv_handle*) handle->data;
  mrb_state* mrb = context->mrb;
  mrb_value proc;
  proc = mrb_iv_get(mrb, context->instance, mrb_intern_lit(mrb, "close_cb"));
  mrb_assert(!mrb_nil_p(proc));
  mrb_yield_argv(mrb, proc, 0, NULL);
  mrb_iv_remove(mrb, context->instance, mrb_intern_lit(mrb, "close_cb"));
  DATA_PTR(context->instance) = NULL;
  mrb_free(mrb, context);
}

static mrb_value
mrb_uv_close(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_value b = mrb_nil_value();

  mrb_get_args(mrb, "&", &b);
  DATA_PTR(self) = NULL;
  if (mrb_nil_p(b)) {
    uv_close(&context->handle, no_yield_close_cb);
  } else {
    mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "close_cb"), b);
    mrb_uv_gc_protect(mrb, self);
    uv_close(&context->handle, _uv_close_cb);
  }
  return self;
}

static mrb_value
mrb_uv_is_closing(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  return mrb_bool_value(uv_is_closing(&ctx->handle));
}

static mrb_value
mrb_uv_is_active(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  return mrb_bool_value(uv_is_active(&ctx->handle));
}

static mrb_value
mrb_uv_ref(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  return uv_ref(&ctx->handle), self;
}

static mrb_value
mrb_uv_unref(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  return uv_unref(&ctx->handle), self;
}

static mrb_value
mrb_uv_has_ref(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  return mrb_bool_value(uv_has_ref(&ctx->handle));
}

static mrb_value
mrb_uv_recv_buffer_size(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  int v = 0;
  mrb_uv_check_error(mrb, uv_recv_buffer_size(&ctx->handle, &v));
  return mrb_fixnum_value(v);
}

static mrb_value
mrb_uv_recv_buffer_size_set(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_int tmp_v;
  int v;
  mrb_get_args(mrb, "i", &tmp_v);
  v = tmp_v;
  mrb_uv_check_error(mrb, uv_recv_buffer_size(&ctx->handle, &v));
  return self;
}

static mrb_value
mrb_uv_send_buffer_size(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  int v = 0;
  mrb_uv_check_error(mrb, uv_send_buffer_size(&ctx->handle, &v));
  return mrb_fixnum_value(v);
}

static mrb_value
mrb_uv_send_buffer_size_set(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_int tmp_v;
  int v;
  mrb_get_args(mrb, "i", &tmp_v);
  v = tmp_v;
  mrb_uv_check_error(mrb, uv_send_buffer_size(&ctx->handle, &v));
  return self;
}

static mrb_value
mrb_uv_fileno(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  uv_os_fd_t fd;
  mrb_uv_check_error(mrb, uv_fileno(&ctx->handle, &fd));
  return mrb_uv_from_uint64(mrb, fd);
}

#if !MRB_UV_CHECK_VERSION(1, 19, 0)
#define uv_handle_get_loop(h) ((h)->loop)
#endif

static mrb_value
mrb_uv_handle_loop(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_value ret = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "loop"));

  mrb_assert(uv_handle_get_loop(&ctx->handle) == ((uv_loop_t*)mrb_uv_get_ptr(mrb, ret, &mrb_uv_loop_type)));

  return ret;
}

#if MRB_UV_CHECK_VERSION(1, 19, 0)

static mrb_value
mrb_uv_handle_get_type(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  return mrb_fixnum_value(uv_handle_get_type(&ctx->handle));
}

#endif

static mrb_value
mrb_uv_handle_type_name(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
#if MRB_UV_CHECK_VERSION(1, 19, 0)
  return mrb_symbol_value(mrb_intern_cstr(mrb, uv_handle_type_name(uv_handle_get_type(&ctx->handle))));
#else
  uv_handle_type const t = ctx->handle.type;
  switch(t) {
#define XX(u, l) case UV_ ## u: return symbol_value_lit(mrb, #l);
      UV_HANDLE_TYPE_MAP(XX)
#undef XX

  default:
    mrb_raisef(mrb, E_TYPE_ERROR, "Invalid uv_handle_t type: %S", mrb_fixnum_value(t));
    return self;
  }
#endif
}

/*********************************************************
 * UV::Pipe
 *********************************************************/
static mrb_value
mrb_uv_pipe_init(mrb_state *mrb, mrb_value self)
{
  mrb_value arg_loop = mrb_nil_value(), arg_ipc = mrb_nil_value();
  mrb_uv_handle* context = NULL;
  uv_loop_t* loop;
  int ipc = 0;

  mrb_get_args(mrb, "|oo", &arg_ipc, &arg_loop);
  loop = get_loop(mrb, &arg_loop);
  if (!mrb_nil_p(arg_ipc)) {
    if (mrb_fixnum_p(arg_ipc))
      ipc = mrb_fixnum(arg_ipc);
    else
      ipc = mrb_bool(arg_ipc);
  }

  context = mrb_uv_handle_alloc(mrb, UV_NAMED_PIPE, self, arg_loop);

  mrb_uv_check_error(mrb, uv_pipe_init(loop, (uv_pipe_t*)&context->handle, ipc));
  return self;
}

static mrb_value
mrb_uv_pipe_open(mrb_state *mrb, mrb_value self)
{
  mrb_int arg_file = 0;
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);

  mrb_get_args(mrb, "i", &arg_file);
  mrb_uv_check_error(mrb, uv_pipe_open((uv_pipe_t*)&context->handle, arg_file));
  return self;
}

static mrb_value
mrb_uv_pipe_connect(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_value b = mrb_nil_value(), ret;
  char* name;
  mrb_uv_req_t* req;

  mrb_get_args(mrb, "&z", &b, &name);
  req = mrb_uv_req_current(mrb, b, &ret);
  uv_pipe_connect(&req->req.connect, (uv_pipe_t*)&context->handle, name, (uv_connect_cb)_uv_done_cb);
  return ret;
}

static mrb_value
mrb_uv_pipe_bind(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  const char* name;

  mrb_get_args(mrb, "z", &name);
  mrb_uv_check_error(mrb, uv_pipe_bind((uv_pipe_t*)&context->handle, name));
  return self;
}

static mrb_value
mrb_uv_pipe_pending_instances(mrb_state *mrb, mrb_value self)
{
  mrb_int arg_count = 0;
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);

  mrb_get_args(mrb, "i", &arg_count);
  uv_pipe_pending_instances((uv_pipe_t*)&context->handle, arg_count);
  return self;
}

static mrb_value
mrb_uv_pipe_getsockname(mrb_state *mrb, mrb_value self)
{
  enum { BUF_SIZE = 128 };
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_value buf = mrb_str_buf_new(mrb, BUF_SIZE);
  int res;
  size_t s = BUF_SIZE;
  mrb_get_args(mrb, "");

  mrb_str_resize(mrb, buf, BUF_SIZE);
  res = uv_pipe_getsockname((uv_pipe_t*)&context->handle, RSTRING_PTR(buf), &s);
  if (res == UV_ENOBUFS) {
    mrb_str_resize(mrb, buf, s);
    res = uv_pipe_getsockname((uv_pipe_t*)&context->handle, RSTRING_PTR(buf), &s);
  }
  mrb_uv_check_error(mrb, res);

  mrb_str_resize(mrb, buf, s);
  return buf;
}

#if MRB_UV_CHECK_VERSION(1, 3, 0)

static mrb_value
mrb_uv_pipe_getpeername(mrb_state *mrb, mrb_value self)
{
  enum { BUF_SIZE = 128 };
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_value buf = mrb_str_buf_new(mrb, BUF_SIZE);
  int res;
  size_t s = BUF_SIZE;
  mrb_get_args(mrb, "");

  mrb_str_resize(mrb, buf, BUF_SIZE);
  res = uv_pipe_getpeername((uv_pipe_t*)&context->handle, RSTRING_PTR(buf), &s);
  if (res == UV_ENOBUFS) {
    mrb_str_resize(mrb, buf, s);
    res = uv_pipe_getpeername((uv_pipe_t*)&context->handle, RSTRING_PTR(buf), &s);
  }
  mrb_uv_check_error(mrb, res);

  mrb_str_resize(mrb, buf, s);
  return buf;
}

#endif

#if MRB_UV_CHECK_VERSION(1, 16, 0)

static mrb_value
mrb_uv_pipe_chmod(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_int mode;
  mrb_get_args(mrb, "i", &mode);

  mrb_uv_check_error(mrb, uv_pipe_chmod((uv_pipe_t*)&context->handle, mode));
  return self;
}

#endif

/*********************************************************
 * UV::TCP
 *********************************************************/
static mrb_value
mrb_uv_tcp_init(mrb_state *mrb, mrb_value self)
{
  mrb_value arg_loop = mrb_nil_value();
  mrb_uv_handle* context = NULL;
  uv_loop_t* loop;
  mrb_int flags;

  mrb_int c = mrb_get_args(mrb, "|oi", &arg_loop, &flags);
  loop = get_loop(mrb, &arg_loop);

  context = mrb_uv_handle_alloc(mrb, UV_TCP, self, arg_loop);

  if (c == 2 && MRB_UV_CHECK_VERSION(1, 7, 0)) {
#if MRB_UV_CHECK_VERSION(1, 7, 0)
    mrb_uv_check_error(mrb, uv_tcp_init_ex(loop, (uv_tcp_t*)&context->handle, flags));
#endif
  } else {
    mrb_uv_check_error(mrb, uv_tcp_init(loop, (uv_tcp_t*)&context->handle));
  }
  return self;
}

static mrb_value
mrb_uv_tcp_open(mrb_state *mrb, mrb_value self)
{
  mrb_value socket;
  mrb_uv_handle *ctx;
  mrb_get_args(mrb, "o", &socket);
  ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);

  mrb_uv_check_error(mrb, uv_tcp_open((uv_tcp_t*)&ctx->handle, mrb_uv_to_socket(mrb, socket)));
  return self;
}

static mrb_value
mrb_uv_tcp_connect(mrb_state *mrb, mrb_value self, int version)
{
  mrb_value arg_addr;
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_value b = mrb_nil_value(), ret;
  struct sockaddr_storage* addr = NULL;
  mrb_uv_req_t* req;

  mrb_get_args(mrb, "&o", &b, &arg_addr);
  if (version != 4 && version != 6) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "(INTERNAL BUG) invalid IP version!");
  }
  if (mrb_nil_p(arg_addr) || strcmp(mrb_obj_classname(mrb, arg_addr), version == 4 ? "UV::Ip4Addr" : "UV::Ip6Addr")) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "invalid argument");
  }

  if (version == 4) {
    Data_Get_Struct(mrb, arg_addr, &mrb_uv_ip4addr_type, addr);
  }
  else {
    Data_Get_Struct(mrb, arg_addr, &mrb_uv_ip6addr_type, addr);
  }

  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_check_error(mrb, req, uv_tcp_connect(
      &req->req.connect, (uv_tcp_t*)&context->handle, ((const struct sockaddr *) addr), (uv_connect_cb)_uv_done_cb));
  return ret;
}

static mrb_value
mrb_uv_tcp_connect4(mrb_state *mrb, mrb_value self)
{
  return mrb_uv_tcp_connect(mrb, self, 4);
}

static mrb_value
mrb_uv_tcp_connect6(mrb_state *mrb, mrb_value self)
{
  return mrb_uv_tcp_connect(mrb, self, 6);
}

static mrb_value
mrb_uv_tcp_bind(mrb_state *mrb, mrb_value self, int version)
{
  mrb_value arg_addr = mrb_nil_value();
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  struct sockaddr_storage* addr = NULL;

  mrb_get_args(mrb, "o", &arg_addr);
  if (version != 4 && version != 6) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "(INTERNAL BUG) invalid IP version!");
  }
  if (mrb_nil_p(arg_addr) || strcmp(mrb_obj_classname(mrb, arg_addr), version == 4 ? "UV::Ip4Addr" : "UV::Ip6Addr")) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "invalid argument");
  }

  if (version == 4) {
    Data_Get_Struct(mrb, arg_addr, &mrb_uv_ip4addr_type, addr);
  }
  else {
    Data_Get_Struct(mrb, arg_addr, &mrb_uv_ip6addr_type, addr);
  }

  mrb_uv_check_error(mrb, uv_tcp_bind((uv_tcp_t*)&context->handle, ((const struct sockaddr *) addr), version == 4? 0 : UV_TCP_IPV6ONLY));
  return self;
}

static mrb_value
mrb_uv_tcp_bind4(mrb_state *mrb, mrb_value self)
{
  return mrb_uv_tcp_bind(mrb, self, 4);
}

static mrb_value
mrb_uv_tcp_bind6(mrb_state *mrb, mrb_value self)
{
  return mrb_uv_tcp_bind(mrb, self, 6);
}

static mrb_value
mrb_uv_tcp_simultaneous_accepts_get(mrb_state *mrb, mrb_value self)
{
  return mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "simultaneous_accepts"));
}

static mrb_value
mrb_uv_tcp_simultaneous_accepts_set(mrb_state *mrb, mrb_value self)
{
  mrb_int arg_simultaneous_accepts;
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);

  mrb_get_args(mrb, "i", &arg_simultaneous_accepts);
  uv_tcp_simultaneous_accepts((uv_tcp_t*)&context->handle, arg_simultaneous_accepts);
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "simultaneous_accepts"), mrb_bool_value(arg_simultaneous_accepts));
  return self;
}

static mrb_value
mrb_uv_tcp_keepalive_delay(mrb_state *mrb, mrb_value self)
{
  return mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "keepalive"));
}

static mrb_value
mrb_uv_tcp_keepalive_p(mrb_state *mrb, mrb_value self)
{
  return mrb_bool_value(mrb_iv_defined(mrb, self, mrb_intern_lit(mrb, "keepalive")));
}

static mrb_value
mrb_uv_tcp_keepalive_set(mrb_state *mrb, mrb_value self)
{
  mrb_int arg_keepalive, arg_delay;
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);

  mrb_get_args(mrb, "ii", &arg_keepalive, &arg_delay);
  uv_tcp_keepalive((uv_tcp_t*)&context->handle, arg_keepalive, arg_delay);
  if (arg_keepalive) {
    mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "keepalive"), mrb_fixnum_value(arg_delay));
  } else {
    mrb_iv_remove(mrb, self, mrb_intern_lit(mrb, "keepalive"));
  }
  return self;
}

static mrb_value
mrb_uv_tcp_nodelay_get(mrb_state *mrb, mrb_value self)
{
  return mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "nodelay"));
}

static mrb_value
mrb_uv_tcp_nodelay_set(mrb_state *mrb, mrb_value self)
{
  mrb_int arg_nodelay;
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);

  mrb_get_args(mrb, "i", &arg_nodelay);
  uv_tcp_nodelay((uv_tcp_t*)&context->handle, arg_nodelay);
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "nodelay"), mrb_bool_value(arg_nodelay));
  return self;
}

static mrb_value
mrb_uv_tcp_getpeername(mrb_state *mrb, mrb_value self)
{
  int len;
  struct sockaddr_storage addr;
  struct RClass* _class_uv;
  struct RClass* _class_uv_ipaddr;
  struct RData *data;
  mrb_value value_data, value_result = mrb_nil_value();
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);

  len = sizeof(addr);
  mrb_uv_check_error(mrb, uv_tcp_getpeername((uv_tcp_t*)&context->handle, (struct sockaddr *)&addr, &len));
  switch (addr.ss_family) {
    case AF_INET:
    case AF_INET6:
      _class_uv = mrb_module_get(mrb, "UV");
      if (addr.ss_family == AF_INET) {
        _class_uv_ipaddr = mrb_class_get_under(mrb, _class_uv, "Ip4Addr");
        data = Data_Wrap_Struct(mrb, mrb->object_class,
            &mrb_uv_ip4addr_nofree_type, (void *) &addr);
      }
      else {
        _class_uv_ipaddr = mrb_class_get_under(mrb, _class_uv, "Ip6Addr");
        data = Data_Wrap_Struct(mrb, mrb->object_class,
            &mrb_uv_ip6addr_nofree_type, (void *) &addr);
      }
      value_data = mrb_obj_value((void *) data);
      value_result = mrb_class_new_instance(mrb, 1, &value_data,
          _class_uv_ipaddr);
      break;
  }
  return value_result;
}

static mrb_value
mrb_uv_getsockname(mrb_state *mrb, mrb_value self, int tcp)
{
  int len;
  struct sockaddr_storage addr;
  struct RClass* _class_uv;
  struct RClass* _class_uv_ipaddr;
  struct RData *data;
  mrb_value value_data, value_result = mrb_nil_value();
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);

  len = sizeof(addr);
  if (tcp) {
    mrb_uv_check_error(mrb, uv_tcp_getsockname((uv_tcp_t*)&context->handle, (struct sockaddr *)&addr, &len));
  }
  else {
    mrb_uv_check_error(mrb, uv_udp_getsockname((uv_udp_t*)&context->handle, (struct sockaddr *)&addr, &len));
  }
  switch (addr.ss_family) {
    case AF_INET:
    case AF_INET6:
      _class_uv = mrb_module_get(mrb, "UV");
      if (addr.ss_family == AF_INET) {
        _class_uv_ipaddr = mrb_class_get_under(mrb, _class_uv, "Ip4Addr");
        data = Data_Wrap_Struct(mrb, mrb->object_class,
            &mrb_uv_ip4addr_nofree_type, (void *) &addr);
      }
      else {
        _class_uv_ipaddr = mrb_class_get_under(mrb, _class_uv, "Ip6Addr");
        data = Data_Wrap_Struct(mrb, mrb->object_class,
            &mrb_uv_ip6addr_nofree_type, (void *) &addr);
      }
      value_data = mrb_obj_value((void *) data);
      value_result = mrb_class_new_instance(mrb, 1, &value_data,
          _class_uv_ipaddr);
      break;
  }
  return value_result;
}

static mrb_value
mrb_uv_tcp_getsockname(mrb_state *mrb, mrb_value self)
{
  return mrb_uv_getsockname(mrb, self, 1);
}

/*********************************************************
 * UV::UDP
 *********************************************************/
static mrb_value
mrb_uv_udp_init(mrb_state *mrb, mrb_value self)
{
  mrb_value arg_loop = mrb_nil_value();
  mrb_uv_handle* context = NULL;
  uv_loop_t* loop;
  mrb_int flags;

  mrb_int c = mrb_get_args(mrb, "|oi", &arg_loop, &flags);
  loop = get_loop(mrb, &arg_loop);

  context = mrb_uv_handle_alloc(mrb, UV_UDP, self, arg_loop);

  if (c == 2 && MRB_UV_CHECK_VERSION(1, 7, 0)) {
#if MRB_UV_CHECK_VERSION(1, 7, 0)
    mrb_uv_check_error(mrb, uv_udp_init_ex(loop, (uv_udp_t*)&context->handle, flags));
#endif
  } else {
    mrb_uv_check_error(mrb, uv_udp_init(loop, (uv_udp_t*)&context->handle));
  }
  return self;
}

static mrb_value
mrb_uv_udp_open(mrb_state *mrb, mrb_value self)
{
  mrb_value socket;
  mrb_uv_handle *ctx;
  mrb_get_args(mrb, "o", &socket);
  ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);

  mrb_uv_check_error(mrb, uv_udp_open((uv_udp_t*)&ctx->handle, mrb_uv_to_socket(mrb, socket)));
  return self;
}

static mrb_value
mrb_uv_udp_bind(mrb_state *mrb, mrb_value self, int version)
{
  mrb_value arg_addr = mrb_nil_value(), arg_flags = mrb_nil_value();
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  struct sockaddr_storage* addr = NULL;
  int flags = 0;

  mrb_get_args(mrb, "o|o", &arg_addr, &arg_flags);
  if (version != 4 && version != 6) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "(INTERNAL BUG) invalid IP version!");
  }
  if (mrb_nil_p(arg_addr) || strcmp(mrb_obj_classname(mrb, arg_addr), version == 4 ? "UV::Ip4Addr" : "UV::Ip6Addr")) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "invalid argument");
  }
  if (!mrb_nil_p(arg_flags)) {
    if (mrb_fixnum_p(arg_flags))
      flags = mrb_fixnum(arg_flags);
    else
      mrb_raise(mrb, E_ARGUMENT_ERROR, "invalid argument");
  }
  if (version == 4) {
    Data_Get_Struct(mrb, arg_addr, &mrb_uv_ip4addr_type, addr);
  }
  else {
    Data_Get_Struct(mrb, arg_addr, &mrb_uv_ip6addr_type, addr);
  }

  mrb_uv_check_error(mrb, uv_udp_bind((uv_udp_t*)&context->handle, ((const struct sockaddr *) addr), flags));
  return self;
}

static mrb_value
mrb_uv_udp_bind4(mrb_state *mrb, mrb_value self)
{
  return mrb_uv_udp_bind(mrb, self, 4);
}

static mrb_value
mrb_uv_udp_bind6(mrb_state *mrb, mrb_value self)
{
  return mrb_uv_udp_bind(mrb, self, 6);
}

static void
_uv_udp_send_cb(uv_udp_send_t* uv_req, int status)
{
  mrb_uv_req_t *req = (mrb_uv_req_t*) uv_req->data;
  mrb_value const arg = mrb_uv_create_status(req->mrb, status);
  mrb_uv_req_yield(req, 1, &arg);
}

static mrb_value
mrb_uv_udp_send(mrb_state *mrb, mrb_value self, int version)
{
  mrb_value arg_data = mrb_nil_value(), arg_addr = mrb_nil_value();
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  struct sockaddr_storage* addr = NULL;
  mrb_value b = mrb_nil_value(), ret;
  uv_buf_t buf;
  mrb_uv_req_t* req;

  mrb_get_args(mrb, "&So", &b, &arg_data, &arg_addr);
  if (version != 4 && version != 6) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "(INTERNAL BUG) invalid IP version!");
  }
  if (mrb_nil_p(arg_addr) || strcmp(mrb_obj_classname(mrb, arg_addr), version == 4 ? "UV::Ip4Addr" : "UV::Ip6Addr")) {
    mrb_raise(mrb, E_ARGUMENT_ERROR, "invalid argument");
  }

  if (version == 4) {
    Data_Get_Struct(mrb, arg_addr, &mrb_uv_ip4addr_type, addr);
  }
  else {
    Data_Get_Struct(mrb, arg_addr, &mrb_uv_ip6addr_type, addr);
  }

  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_set_buf(req, &buf, arg_data);
  mrb_uv_req_check_error(mrb, req, uv_udp_send(
      &req->req.udp_send, (uv_udp_t*)&context->handle, &buf, 1,
      ((const struct sockaddr *) addr), _uv_udp_send_cb));
  return ret;
}

static mrb_value
mrb_uv_udp_send4(mrb_state *mrb, mrb_value self)
{
  return mrb_uv_udp_send(mrb, self, 4);
}

static mrb_value
mrb_uv_udp_send6(mrb_state *mrb, mrb_value self)
{
  return mrb_uv_udp_send(mrb, self, 6);
}

static void
_uv_udp_recv_cb(uv_udp_t* handle, ssize_t nread, const uv_buf_t* buf, const struct sockaddr* addr, unsigned flags)
{
  mrb_uv_handle* context = (mrb_uv_handle*) handle->data;
  mrb_state* mrb = context->mrb;
  mrb_value args[3];
  struct RClass* _class_uv;
  struct RClass* _class_uv_ipaddr = NULL;
  struct RData* data = NULL;
  mrb_value value_data, value_addr = mrb_nil_value();

  mrb_uv_check_error(mrb, nread);

  _class_uv = mrb_module_get(mrb, "UV");
  switch (addr->sa_family) {
  case AF_INET:
    /* IPv4 */
    _class_uv_ipaddr = mrb_class_get_under(mrb, _class_uv, "Ip4Addr");
    data = Data_Wrap_Struct(mrb, mrb->object_class,
                            &mrb_uv_ip4addr_nofree_type, (void *) addr);
    break;
  case AF_INET6:
    /* IPv6 */
    _class_uv_ipaddr = mrb_class_get_under(mrb, _class_uv, "Ip6Addr");
    data = Data_Wrap_Struct(mrb, mrb->object_class,
                            &mrb_uv_ip6addr_nofree_type, (void *) addr);
    break;

  default:
    /* Non-IP */
    mrb_raise(mrb, E_ARGUMENT_ERROR, "invalid argument");
    break;
  }

  value_data = mrb_obj_value((void *) data);
  value_addr = mrb_obj_new(mrb, _class_uv_ipaddr, 1, &value_data);
  args[0] = mrb_str_new(mrb, buf->base, nread);
  args[1] = value_addr;
  args[2] = mrb_fixnum_value(flags);
  mrb_free(mrb, buf->base);
  yield_handle_cb(context, 3, args);
}

static mrb_value
mrb_uv_udp_recv_start(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_value b = mrb_nil_value();
  uv_udp_recv_cb udp_recv_cb = _uv_udp_recv_cb;

  mrb_get_args(mrb, "&", &b);
  set_handle_cb(context, b);
  mrb_uv_check_error(mrb, uv_udp_recv_start((uv_udp_t*)&context->handle, _uv_alloc_cb, udp_recv_cb));
  return self;
}

static mrb_value
mrb_uv_udp_recv_stop(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);

  mrb_uv_check_error(mrb, uv_udp_recv_stop((uv_udp_t*)&context->handle));
  return self;
}

static mrb_value
mrb_uv_udp_getsockname(mrb_state *mrb, mrb_value self)
{
  return mrb_uv_getsockname(mrb, self, 0);
}

static mrb_value
mrb_uv_udp_set_membership(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  char *multicast, *iface;
  mrb_int mem;

  mrb_get_args(mrb, "zzi", &multicast, &iface, &mem);
  mrb_uv_check_error(mrb, uv_udp_set_membership((uv_udp_t*)&ctx->handle, multicast, iface, mem));
  return self;
}

static mrb_value
mrb_uv_udp_multicast_loop_set(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_bool b;

  mrb_get_args(mrb, "b", &b);
  mrb_uv_check_error(mrb, uv_udp_set_multicast_loop((uv_udp_t*)&ctx->handle, b));
  return mrb_bool_value(b);
}

static mrb_value
mrb_uv_udp_multicast_ttl_set(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_bool b;

  mrb_get_args(mrb, "b", &b);
  mrb_uv_check_error(mrb, uv_udp_set_multicast_ttl((uv_udp_t*)&ctx->handle, b));
  return mrb_bool_value(b);
}

static mrb_value
mrb_uv_udp_broadcast_set(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_bool b;

  mrb_get_args(mrb, "b", &b);
  mrb_uv_check_error(mrb, uv_udp_set_broadcast((uv_udp_t*)&ctx->handle, b));
  return mrb_bool_value(b);
}

static mrb_value
mrb_uv_udp_multicast_interface_set(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_value s;

  mrb_get_args(mrb, "S", &s);
  mrb_uv_check_error(mrb, uv_udp_set_multicast_interface((uv_udp_t*)&ctx->handle, mrb_string_value_ptr(mrb, s)));
  return s;
}

static mrb_value
mrb_uv_udp_ttl_set(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_int v;

  mrb_get_args(mrb, "i", &v);
  mrb_uv_check_error(mrb, uv_udp_set_ttl((uv_udp_t*)&ctx->handle, v));
  return mrb_fixnum_value(v);
}

static mrb_value
mrb_uv_udp_try_send(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_value s, a;
  int err;
  uv_buf_t buf;
  const struct sockaddr* addr;

  mrb_get_args(mrb, "So", &s, &a);
  mrb_str_modify(mrb, mrb_str_ptr(s));
  buf = uv_buf_init(RSTRING_PTR(s), RSTRING_LEN(s));
  addr = mrb_data_check_get_ptr(mrb, a, &mrb_uv_ip4addr_type);
  if (!addr) {
    mrb_data_get_ptr(mrb, a, &mrb_uv_ip6addr_type);
  }

  err = uv_udp_try_send((uv_udp_t*)&ctx->handle, &buf, 1, addr);
  mrb_uv_check_error(mrb, err);

  return mrb_fixnum_value(err);
}

#if !MRB_UV_CHECK_VERSION(1, 19, 0)
#define uv_udp_get_send_queue_size(u) ((u)->send_queue_size)
#define uv_udp_get_send_queue_count(u) ((u)->send_queue_count)
#endif

static mrb_value
mrb_uv_udp_send_queue_count(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  return mrb_fixnum_value(uv_udp_get_send_queue_count((uv_udp_t*)&ctx->handle));
}

static mrb_value
mrb_uv_udp_send_queue_size(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  return mrb_fixnum_value(uv_udp_get_send_queue_size((uv_udp_t*)&ctx->handle));
}

/*********************************************************
 * UV::Prepare
 *********************************************************/
static void
_uv_prepare_cb(uv_prepare_t* prepare)
{
  yield_handle_cb((mrb_uv_handle*) prepare->data, 0, NULL);
}

static mrb_value
mrb_uv_prepare_init(mrb_state *mrb, mrb_value self)
{
  mrb_value arg_loop = mrb_nil_value();
  mrb_uv_handle* context = NULL;
  uv_loop_t* loop;

  mrb_get_args(mrb, "|o", &arg_loop);
  loop = get_loop(mrb, &arg_loop);

  context = mrb_uv_handle_alloc(mrb, UV_PREPARE, self, arg_loop);

  mrb_uv_check_error(mrb, uv_prepare_init(loop, (uv_prepare_t*)&context->handle));
  return self;
}

static mrb_value
mrb_uv_prepare_start(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_value b = mrb_nil_value();
  uv_prepare_cb prepare_cb = _uv_prepare_cb;

  mrb_get_args(mrb, "&", &b);
  set_handle_cb(context, b);
  mrb_uv_check_error(mrb, uv_prepare_start((uv_prepare_t*)&context->handle, prepare_cb));
  return self;
}

static mrb_value
mrb_uv_prepare_stop(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);

  mrb_uv_check_error(mrb, uv_prepare_stop((uv_prepare_t*)&context->handle));
  return self;
}

/*********************************************************
 * UV::Async
 *********************************************************/
static void
_uv_async_cb(uv_async_t* async)
{
  yield_handle_cb((mrb_uv_handle*) async->data, 0, NULL);
}

static mrb_value
mrb_uv_async_init(mrb_state *mrb, mrb_value self)
{
  mrb_value arg_loop = mrb_nil_value();
  mrb_uv_handle* context = NULL;
  uv_loop_t* loop;
  mrb_value b;

  mrb_get_args(mrb, "&|o", &b, &arg_loop);
  loop = get_loop(mrb, &arg_loop);

  context = mrb_uv_handle_alloc(mrb, UV_ASYNC, self, arg_loop);

  set_handle_cb(context, b);
  mrb_uv_check_error(mrb, uv_async_init(loop, (uv_async_t*)&context->handle, _uv_async_cb));
  return self;
}

static mrb_value
mrb_uv_async_send(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_uv_check_error(mrb, uv_async_send((uv_async_t*)&context->handle));
  return self;
}

/*********************************************************
 * UV::Idle
 *********************************************************/
static mrb_value
mrb_uv_idle_init(mrb_state *mrb, mrb_value self)
{
  mrb_value arg_loop = mrb_nil_value();
  mrb_uv_handle* context = NULL;
  uv_loop_t* loop;

  mrb_get_args(mrb, "|o", &arg_loop);
  loop = get_loop(mrb, &arg_loop);

  context = mrb_uv_handle_alloc(mrb, UV_IDLE, self, arg_loop);

  mrb_uv_check_error(mrb, uv_idle_init(loop, (uv_idle_t*)&context->handle));
  return self;
}

static void
_uv_idle_cb(uv_idle_t* idle)
{
  yield_handle_cb((mrb_uv_handle*)idle->data, 0, NULL);
}

static mrb_value
mrb_uv_idle_start(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_value b = mrb_nil_value();

  mrb_get_args(mrb, "&", &b);
  set_handle_cb(context, b);
  mrb_uv_check_error(mrb, uv_idle_start((uv_idle_t*)&context->handle, mrb_nil_p(b)? NULL : _uv_idle_cb));
  return self;
}

static mrb_value
mrb_uv_idle_stop(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);

  mrb_uv_check_error(mrb, uv_idle_stop((uv_idle_t*)&context->handle));
  return self;
}

/*********************************************************
 * UV::TTY
 *********************************************************/
static mrb_value
mrb_uv_tty_init(mrb_state *mrb, mrb_value self)
{
  mrb_value arg_loop = mrb_nil_value();
  mrb_int arg_file, arg_readable;
  mrb_uv_handle* context = NULL;
  uv_loop_t* loop;

  mrb_get_args(mrb, "ii|o", &arg_file, &arg_readable, &arg_loop);
  loop = get_loop(mrb, &arg_loop);

  context = mrb_uv_handle_alloc(mrb, UV_TTY, self, arg_loop);

  mrb_uv_check_error(mrb, uv_tty_init(loop, (uv_tty_t*)&context->handle, arg_file, arg_readable));
  return self;
}

static mrb_value
mrb_uv_tty_set_mode(mrb_state *mrb, mrb_value self)
{
  mrb_int arg_mode = -1;
  mrb_value mode_val;
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);

  mrb_get_args(mrb, "o", &mode_val);

  if (mrb_fixnum_p(mode_val)) {
    arg_mode = mrb_fixnum(mode_val);
#if MRB_UV_CHECK_VERSION(1, 2, 0)
  } else if (mrb_symbol_p(mode_val)) {
    mrb_sym s = mrb_symbol(mode_val);
    if (s == mrb_intern_lit(mrb, "raw")) { arg_mode = UV_TTY_MODE_RAW; }
    else if (s == mrb_intern_lit(mrb, "normal")) { arg_mode = UV_TTY_MODE_NORMAL; }
    else if (s == mrb_intern_lit(mrb, "io")) { arg_mode = UV_TTY_MODE_IO; }
#endif
  }

  if (arg_mode == -1) {
    mrb_raisef(mrb, E_ARGUMENT_ERROR, "invalid tty mode: %S", mode_val);
  }

  return mrb_fixnum_value(uv_tty_set_mode((uv_tty_t*)&context->handle, arg_mode));
}

static mrb_value
mrb_uv_tty_reset_mode(mrb_state *mrb, mrb_value self)
{
  uv_tty_reset_mode();
  return self;
}

static mrb_value
mrb_uv_tty_get_winsize(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  int width = 0, height = 0;
  mrb_value ary;

  mrb_uv_check_error(mrb, uv_tty_get_winsize((uv_tty_t*)&context->handle, &width, &height));
  ary = mrb_ary_new(mrb);
  mrb_ary_push(mrb, ary, mrb_fixnum_value(width));
  mrb_ary_push(mrb, ary, mrb_fixnum_value(height));
  return ary;
}

/*********************************************************
 * UV::Process
 *********************************************************/
static void
_uv_exit_cb(uv_process_t* process, int64_t exit_status, int term_signal)
{
  mrb_value args[2];
  args[0] = mrb_fixnum_value(exit_status);
  args[1] = mrb_fixnum_value(term_signal);
  yield_handle_cb((mrb_uv_handle*)process->data, 2, args);
}

static mrb_value
get_hash_opt(mrb_state *mrb, mrb_value h, const char *str)
{
  mrb_value ret = mrb_hash_get(mrb, h, mrb_symbol_value(mrb_intern_cstr(mrb, str)));
  if (mrb_nil_p(ret)) {
    ret = mrb_hash_get(mrb, h, mrb_str_new_cstr(mrb, str));
  }
  return ret;
}

static mrb_value
mrb_uv_process_init(mrb_state *mrb, mrb_value self)
{
  mrb_value arg_opt = mrb_nil_value();

  mrb_get_args(mrb, "H", &arg_opt);

  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "options"), arg_opt);
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "stdout_pipe"), mrb_nil_value());
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "stderr_pipe"), mrb_nil_value());
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "stdin_pipe"), mrb_nil_value());

  return self;
}

static mrb_value
mrb_uv_process_spawn(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* context;
  mrb_value b;
  mrb_value options;
  mrb_value
      arg_file, arg_args, arg_env, arg_cwd, arg_uid, arg_gid, arg_detached,
      arg_windows_hide, arg_windows_verbatim_arguments, arg_stdio;
  mrb_value stdio_pipe[3];
  char cwd[PATH_MAX];
  size_t cwd_size = sizeof(cwd);
  int i, err;
  uv_stdio_container_t stdio[3];
  uv_process_options_t opt = {0};
  const char** args;
  mrb_value arg_loop = mrb_nil_value();
  uv_loop_t *loop;

  options = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "options"));
  arg_file = get_hash_opt(mrb, options, "file");
  arg_args = get_hash_opt(mrb, options, "args");
  arg_env = get_hash_opt(mrb, options, "env");
  arg_cwd = get_hash_opt(mrb, options, "cwd");
  arg_uid = get_hash_opt(mrb, options, "uid");
  arg_gid = get_hash_opt(mrb, options, "gid");
  arg_detached = get_hash_opt(mrb, options, "detached");
  arg_windows_verbatim_arguments = get_hash_opt(mrb, options, "windows_verbatim_arguments");
  arg_windows_hide = get_hash_opt(mrb, options, "windows_hide");
  arg_stdio = get_hash_opt(mrb, options, "stdio");
  stdio_pipe[0] = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "stdin_pipe"));
  stdio_pipe[1] = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "stdout_pipe"));
  stdio_pipe[2] = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "stderr_pipe"));

  mrb_get_args(mrb, "|o&", &arg_loop, &b);

  // stdio settings
  opt.stdio_count = 3;
  opt.stdio = stdio;
  if (mrb_bool(arg_stdio)) {
    int len;
    mrb_check_type(mrb, arg_stdio, MRB_TT_ARRAY);
    len = RARRAY_LEN(arg_stdio);
    if (len > 3) { len = 3; }
    for (i = 0; i < len; i++) {
      stdio_pipe[i] = RARRAY_PTR(arg_stdio)[i];
    }
    for (; i < 3; ++i) {
      stdio_pipe[i] = mrb_nil_value();
    }
  }
  for (i = 0; i < 3; ++i) {
    mrb_value obj = stdio_pipe[i];
    if (mrb_bool(obj)) {
      if (mrb_fixnum_p(obj)) {
        stdio[i].flags = UV_INHERIT_FD;
        stdio[i].data.fd = mrb_fixnum(obj);
      } else {
        mrb_uv_handle* pcontext = (mrb_uv_handle*)mrb_data_get_ptr(mrb, obj, &mrb_uv_handle_type);
        if (uv_is_active(&pcontext->handle)) {
          stdio[i].flags = UV_INHERIT_STREAM;
          stdio[i].data.stream = (uv_stream_t*)&pcontext->handle;
        } else {
          stdio[i].flags = UV_CREATE_PIPE;
          if (i == 0) { stdio[i].flags |= UV_READABLE_PIPE; }
          else { stdio[i].flags |= UV_WRITABLE_PIPE; }
          stdio[i].data.stream = (uv_stream_t*)&pcontext->handle;
        }
      }
    } else {
      stdio[i].flags = UV_IGNORE;
    }
  }

  // command path
  opt.file = mrb_string_value_ptr(mrb, arg_file);

  // command line arguments
  mrb_check_type(mrb, arg_args, MRB_TT_ARRAY);
  args = mrb_malloc(mrb, sizeof(char*) * (RARRAY_LEN(arg_args)+2));
  args[0] = opt.file;
  for (i = 0; i < RARRAY_LEN(arg_args); i++) {
    args[i+1] = mrb_string_value_ptr(mrb, mrb_ary_entry(arg_args, i));
  }
  args[i+1] = NULL;
  opt.args = (char**) args;

  // environment variables
  if (mrb_bool(arg_env)) {
    if (mrb_hash_p(arg_env)) {
      mrb_value keys = mrb_hash_keys(mrb, arg_env);
      opt.env = mrb_malloc(mrb, sizeof(char*) * (RARRAY_LEN(keys) + 1));
      for (i = 0; i < RARRAY_LEN(keys); ++i) {
        mrb_value str = mrb_str_dup(mrb, mrb_str_to_str(mrb, RARRAY_PTR(keys)[i]));
        str = mrb_str_cat_lit(mrb, str, "=");
        mrb_str_concat(mrb, str, mrb_hash_get(mrb, arg_env, RARRAY_PTR(keys)[i]));
        opt.env[i] = mrb_str_to_cstr(mrb, str);
      }
    } else {
      mrb_check_type(mrb, arg_env, MRB_TT_ARRAY);
      opt.env = mrb_malloc(mrb, sizeof(char*) * (RARRAY_LEN(arg_env) + 1));
      for (i = 0; i < RARRAY_LEN(arg_env); i++) {
        opt.env[i] = mrb_str_to_cstr(mrb, RARRAY_PTR(arg_env)[i]);
      }
    }
    opt.env[i] = NULL;
  } else {
    opt.env = NULL; /* inherit parent */
  }

  // current directory
  if (mrb_bool(arg_cwd)) {
    opt.cwd = mrb_str_to_cstr(mrb, arg_cwd);
  } else {
    uv_cwd(cwd, &cwd_size);
    opt.cwd = cwd;
  }

  // set flags
  opt.flags = 0;
  if (mrb_bool(arg_uid)) {
    opt.uid = mrb_int(mrb, arg_uid);
    opt.flags |= UV_PROCESS_SETUID;
  }
  if (mrb_bool(arg_gid)) {
    opt.gid = mrb_int(mrb, arg_gid);
    opt.flags |= UV_PROCESS_SETGID;
  }
  if (mrb_bool(arg_detached)) { opt.flags |= UV_PROCESS_DETACHED; }
  if (mrb_bool(arg_windows_hide)) { opt.flags |= UV_PROCESS_WINDOWS_HIDE; }
  if (mrb_bool(arg_windows_verbatim_arguments)) { opt.flags |= UV_PROCESS_WINDOWS_VERBATIM_ARGUMENTS; }

  opt.exit_cb = _uv_exit_cb;

  loop = get_loop(mrb, &arg_loop);
  context = mrb_uv_handle_alloc(mrb, UV_PROCESS, self, arg_loop);
  set_handle_cb(context, b);
  err = uv_spawn(loop, (uv_process_t*)&context->handle, &opt);
  mrb_free(mrb, args);
  mrb_free(mrb, opt.env);
  mrb_uv_check_error(mrb, err);
  return self;
}

static mrb_value
mrb_uv_process_kill(mrb_state *mrb, mrb_value self)
{
  mrb_int arg_signum;
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);

  mrb_get_args(mrb, "i", &arg_signum);

  return mrb_fixnum_value(uv_process_kill((uv_process_t*)&context->handle, arg_signum));
}

#if !MRB_UV_CHECK_VERSION(1, 19, 0)
#define uv_process_get_pid(p) ((p)->pid)
#endif

static mrb_value
mrb_uv_process_pid(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  return mrb_fixnum_value(uv_process_get_pid((uv_process_t*)&context->handle));
}

static mrb_value
mrb_uv_process_stdout_pipe_get(mrb_state *mrb, mrb_value self)
{
  return mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "stdout_pipe"));
}

static mrb_value
mrb_uv_process_stdout_pipe_set(mrb_state *mrb, mrb_value self)
{
  mrb_value arg;
  mrb_get_args(mrb, "o", &arg);
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "stdout_pipe"), arg);
  return self;
}

static mrb_value
mrb_uv_process_stdin_pipe_get(mrb_state *mrb, mrb_value self)
{
  return mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "stdin_pipe"));
}

static mrb_value
mrb_uv_process_stdin_pipe_set(mrb_state *mrb, mrb_value self)
{
  mrb_value arg;
  mrb_get_args(mrb, "o", &arg);
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "stdin_pipe"), arg);
  return self;
}

static mrb_value
mrb_uv_process_stderr_pipe_get(mrb_state *mrb, mrb_value self)
{
  return mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "stderr_pipe"));
}

static mrb_value
mrb_uv_process_stderr_pipe_set(mrb_state *mrb, mrb_value self)
{
  mrb_value arg;
  mrb_get_args(mrb, "o", &arg);
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "stderr_pipe"), arg);
  return self;
}

/*********************************************************
 * UV::Timer
 *********************************************************/
static mrb_value
mrb_uv_timer_init(mrb_state *mrb, mrb_value self)
{
  mrb_value arg_loop = mrb_nil_value();
  mrb_uv_handle* context = NULL;
  uv_loop_t* loop;

  mrb_get_args(mrb, "|o", &arg_loop);
  loop = get_loop(mrb, &arg_loop);

  context = mrb_uv_handle_alloc(mrb, UV_TIMER, self, arg_loop);

  mrb_uv_check_error(mrb, uv_timer_init(loop, (uv_timer_t*)&context->handle));
  return self;
}

static mrb_value
mrb_uv_timer_again(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);

  mrb_uv_check_error(mrb, uv_timer_again((uv_timer_t*)&context->handle));
  return self;
}

static void
_uv_timer_cb(uv_timer_t* timer)
{
  yield_handle_cb((mrb_uv_handle*)timer->data, 0, NULL);
}

static mrb_value
mrb_uv_timer_start(mrb_state *mrb, mrb_value self)
{
  mrb_int arg_timeout = 0, arg_repeat = 0;
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_value b;

  mrb_get_args(mrb, "&ii", &b, &arg_timeout, &arg_repeat);
  context->block = mrb_nil_value();
  set_handle_cb(context, b);
  mrb_uv_check_error(mrb, uv_timer_start((uv_timer_t*)&context->handle, _uv_timer_cb,
                                         arg_timeout, arg_repeat));
  return self;
}

static mrb_value
mrb_uv_timer_stop(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);

  mrb_uv_check_error(mrb, uv_timer_stop((uv_timer_t*)&context->handle));
  return self;
}

static mrb_value
mrb_uv_timer_repeat(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  return mrb_uv_from_uint64(mrb, uv_timer_get_repeat((uv_timer_t*)&ctx->handle));
}

static mrb_value
mrb_uv_timer_repeat_set(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_float f;
  mrb_get_args(mrb, "f", &f);
  return uv_timer_set_repeat((uv_timer_t*)&ctx->handle, (uint64_t)f), mrb_float_value(mrb, f);
}

/*********************************************************
 * UV::FS::Poll
 *********************************************************/
static void
_uv_fs_poll_cb(uv_fs_poll_t* handle, int status, const uv_stat_t* prev, const uv_stat_t* curr)
{
  mrb_uv_handle* context = (mrb_uv_handle*) handle->data;
  mrb_state* mrb = context->mrb;
  mrb_value args[3];
  args[0] = mrb_uv_create_status(mrb, status);
  args[1] = mrb_uv_create_stat(mrb, prev);
  args[2] = mrb_uv_create_stat(mrb, curr);
  yield_handle_cb(context, 3, args);
}

static mrb_value
mrb_uv_fs_poll_init(mrb_state *mrb, mrb_value self)
{
  mrb_value arg_loop = mrb_nil_value();
  mrb_uv_handle* context = NULL;
  uv_loop_t* loop;

  mrb_get_args(mrb, "|o", &arg_loop);
  loop = get_loop(mrb, &arg_loop);

  context = mrb_uv_handle_alloc(mrb, UV_FS_POLL, self, arg_loop);

  mrb_uv_check_error(mrb, uv_fs_poll_init(loop, (uv_fs_poll_t*)&context->handle));
  return self;
}

static mrb_value
mrb_uv_fs_poll_start(mrb_state *mrb, mrb_value self)
{
  char const *arg_path;
  mrb_value b;
  mrb_int arg_interval;
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);

  mrb_get_args(mrb, "&zi", &b, &arg_path, &arg_interval);
  set_handle_cb(context, b);
  return mrb_fixnum_value(uv_fs_poll_start(
      (uv_fs_poll_t*)&context->handle, _uv_fs_poll_cb, arg_path, arg_interval));
}

static mrb_value
mrb_uv_fs_poll_stop(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  return mrb_fixnum_value(uv_fs_poll_stop((uv_fs_poll_t*)&context->handle));
}

static mrb_value
mrb_uv_fs_poll_getpath(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  enum { BUF_SIZE = 128 };
  mrb_value buf = mrb_str_buf_new(mrb, BUF_SIZE);
  int res;
  size_t s = BUF_SIZE;
  char const *env;
  mrb_get_args(mrb, "z", &env);

  mrb_str_resize(mrb, buf, BUF_SIZE);

  res = uv_fs_poll_getpath((uv_fs_poll_t*)&context->handle, RSTRING_PTR(buf), &s);
  if (res == UV_ENOBUFS) {
    mrb_str_resize(mrb, buf, s);
    res = uv_fs_poll_getpath((uv_fs_poll_t*)&context->handle, RSTRING_PTR(buf), &s);
  }
  mrb_uv_check_error(mrb, res);

  mrb_str_resize(mrb, buf, s);
  return buf;
}

/*********************************************************
 * UV::Check
 *********************************************************/
static mrb_value
mrb_uv_check_init(mrb_state *mrb, mrb_value self)
{
  mrb_value l = mrb_nil_value();
  mrb_uv_handle *context;
  uv_loop_t *loop;
  mrb_get_args(mrb, "|o", &l);

  loop = get_loop(mrb, &l);
  context = mrb_uv_handle_alloc(mrb, UV_CHECK, self, l);
  mrb_uv_check_error(mrb, uv_check_init(loop, (uv_check_t*)&context->handle));
  return self;
}

static void
_uv_check_cb(uv_check_t *check)
{
  yield_handle_cb((mrb_uv_handle*)check->data, 0, NULL);
}

static mrb_value
mrb_uv_check_start(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_value b;
  mrb_get_args(mrb, "&", &b);
  set_handle_cb(context, b);
  mrb_uv_check_error(mrb, uv_check_start((uv_check_t*)&context->handle, _uv_check_cb));
  return self;
}

static mrb_value
mrb_uv_check_stop(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_uv_check_error(mrb, uv_check_stop((uv_check_t*)&context->handle));
  return self;
}

/*********************************************************
 * UV::Signal
 *********************************************************/
static void
_uv_signal_cb(uv_signal_t* handle, int signum)
{
  mrb_value const arg = mrb_fixnum_value(signum);
  yield_handle_cb((mrb_uv_handle*) handle->data, 1, &arg);
}

static mrb_value
mrb_uv_signal_init(mrb_state *mrb, mrb_value self)
{
  mrb_value arg_loop = mrb_nil_value();
  mrb_uv_handle* context = NULL;
  uv_loop_t* loop;

  mrb_get_args(mrb, "|o", &arg_loop);
  loop = get_loop(mrb, &arg_loop);

  context = mrb_uv_handle_alloc(mrb, UV_SIGNAL, self, arg_loop);

  mrb_uv_check_error(mrb, uv_signal_init(loop, (uv_signal_t*)&context->handle));
  return self;
}

static mrb_value
mrb_uv_signal_start(mrb_state *mrb, mrb_value self)
{
  mrb_int arg_signum;
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_value b;

  mrb_get_args(mrb, "&i", &b, &arg_signum);
  set_handle_cb(context, b);
  mrb_uv_check_error(mrb, uv_signal_start((uv_signal_t*)&context->handle, _uv_signal_cb, arg_signum));
  return self;
}

#if MRB_UV_CHECK_VERSION(1, 12, 0)

static mrb_value
mrb_uv_signal_start_oneshot(mrb_state *mrb, mrb_value self)
{
  mrb_int arg_signum;
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_value b = mrb_nil_value();
  uv_signal_cb signal_cb = _uv_signal_cb;

  mrb_get_args(mrb, "&i", &b, &arg_signum);

  if (mrb_nil_p(b)) {
    signal_cb = NULL;
  }
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "signal_cb"), b);

  return mrb_fixnum_value(uv_signal_start_oneshot((uv_signal_t*)&context->handle, signal_cb, arg_signum));
}

#endif

static mrb_value
mrb_uv_signal_stop(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  return mrb_fixnum_value(uv_signal_stop((uv_signal_t*)&context->handle));
}

static void
_uv_read_cb(uv_stream_t* stream, ssize_t nread, const uv_buf_t* buf)
{
  mrb_uv_handle* context = (mrb_uv_handle*) stream->data;
  mrb_state* mrb = context->mrb;
  mrb_value arg;

  mrb_gc_protect(mrb, context->block);

  if (nread < 0) {
    arg = mrb_uv_create_error(mrb, nread);
  } else {
    arg = mrb_str_new(mrb, buf->base, nread);
  }
  mrb_free(mrb, buf->base);
  yield_handle_cb(context, 1, &arg);
}

static mrb_value
mrb_uv_read_start(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_value b;

  mrb_get_args(mrb, "&", &b);
  set_handle_cb(context, b);
  mrb_uv_check_error(mrb, uv_read_start((uv_stream_t*)&context->handle, _uv_alloc_cb, _uv_read_cb));
  return self;
}

static mrb_value
mrb_uv_read_stop(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);

  mrb_uv_check_error(mrb, uv_read_stop((uv_stream_t*)&context->handle));
  return self;
}

static mrb_value
mrb_uv_write(mrb_state *mrb, mrb_value self)
{
  int err;
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_value b, arg_data, send_handle_val = mrb_nil_value(), ret;
  uv_buf_t buf;
  mrb_uv_req_t* req;
  uv_write_cb cb = (uv_write_cb)_uv_done_cb;

  mrb_get_args(mrb, "&S|o", &b, &arg_data, &send_handle_val);
  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_set_buf(req, &buf, arg_data);
  if (mrb_nil_p(req->block)) { cb = NULL; }
  if (mrb_nil_p(send_handle_val)) {
    err = uv_write(&req->req.write, (uv_stream_t*)&context->handle, &buf, 1, cb);
  } else {
    mrb_uv_handle *send_handle = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, send_handle_val, &mrb_uv_handle_type);
    if (send_handle->handle.type != UV_NAMED_PIPE && send_handle->handle.type != UV_TCP) {
      mrb_raisef(mrb, E_ARGUMENT_ERROR, "Unexpected send handle type: %S",
                 mrb_funcall(mrb, send_handle_val, "type", 0));
    }
    err = uv_write2(&req->req.write, (uv_stream_t*)&context->handle, &buf, 1,
                    (uv_stream_t*)&send_handle->handle, cb);
  }
  mrb_uv_req_check_error(mrb, req, err);
  return ret;
}

static mrb_value
mrb_uv_try_write(mrb_state *mrb, mrb_value self)
{
  uv_buf_t buf;
  mrb_value str;
  mrb_uv_handle *context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  int err;

  mrb_get_args(mrb, "S", &str);
  mrb_str_modify(mrb, mrb_str_ptr(str));
  buf = uv_buf_init(RSTRING_PTR(str), RSTRING_LEN(str));
  err = uv_try_write((uv_stream_t*)&context->handle, &buf, 1);
  if (err < 0) {
    mrb_uv_check_error(mrb, err);
  }
  if (err == 0) {
    return symbol_value_lit(mrb, "need_queue");
  } else {
    return mrb_fixnum_value(err);
  }
}

static mrb_value
mrb_uv_shutdown(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_value b, ret;
  mrb_uv_req_t *req;

  mrb_get_args(mrb, "&", &b);
  req = mrb_uv_req_current(mrb, b, &ret);
  mrb_uv_req_check_error(mrb, req, uv_shutdown(
      &req->req.shutdown, (uv_stream_t*)&context->handle, (uv_shutdown_cb)_uv_done_cb));
  return ret;
}

static void
_uv_connection_cb(uv_stream_t* uv_h, int status)
{
  mrb_uv_handle *h = (mrb_uv_handle*) uv_h->data;
  mrb_value b = mrb_iv_get(h->mrb, h->instance, mrb_intern_lit(h->mrb, "connection_cb"));
  mrb_value const arg = mrb_uv_create_status(h->mrb, status);
  mrb_yield_argv(h->mrb, b, 1, &arg);
}

static mrb_value
mrb_uv_listen(mrb_state *mrb, mrb_value self)
{
  mrb_int arg_backlog;
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_value b = mrb_nil_value();
  uv_connection_cb connection_cb = _uv_connection_cb;

  mrb_get_args(mrb, "&i", &b, &arg_backlog);
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "connection_cb"), b);
  mrb_uv_check_error(mrb, uv_listen((uv_stream_t*) &context->handle, arg_backlog, connection_cb));
  return self;
}

static mrb_value
mrb_uv_accept(mrb_state *mrb, mrb_value self)
{
  mrb_value c;
  mrb_uv_handle* context = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_uv_handle* new_context = NULL;

  c = mrb_obj_new(mrb, mrb_class(mrb, self), 0, NULL);
  Data_Get_Struct(mrb, c, &mrb_uv_handle_type, new_context);

  mrb_uv_check_error(mrb, uv_accept((uv_stream_t*) &context->handle, (uv_stream_t*) &new_context->handle));
  mrb_uv_gc_protect(mrb, c);
  return c;
}

static mrb_value
mrb_uv_readable(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  return mrb_bool_value(uv_is_readable((uv_stream_t*)&ctx->handle));
}

static mrb_value
mrb_uv_writable(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  return mrb_bool_value(uv_is_writable((uv_stream_t*)&ctx->handle));
}

#if !MRB_UV_CHECK_VERSION(1, 19, 0)
#define uv_stream_get_write_queue_size(s) ((s)->write_queue_size)
#endif

static mrb_value
mrb_uv_stream_write_queue_size(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle* ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  return mrb_fixnum_value(uv_stream_get_write_queue_size((uv_stream_t*)&ctx->handle));
}

/*
 * UV::FS::Event
 */
static mrb_value
mrb_uv_fs_event_init(mrb_state *mrb, mrb_value self)
{
  mrb_value l = mrb_nil_value();
  mrb_uv_handle *ctx;
  uv_loop_t *loop;
  mrb_get_args(mrb, "|o", &l);

  loop = get_loop(mrb, &l);
  ctx = mrb_uv_handle_alloc(mrb, UV_FS_EVENT, self, l);
  mrb_uv_check_error(mrb, uv_fs_event_init(loop, (uv_fs_event_t*)&ctx->handle));
  return self;
}

static void
_uv_fs_event_cb(uv_fs_event_t *ev, char const *filename, int events, int status)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)ev->data;
  mrb_state *mrb = ctx->mrb;
  mrb_value args[3];

  mrb_gc_protect(mrb, ctx->block);

  args[0] = mrb_str_new_cstr(mrb, filename);
  switch((enum uv_fs_event)events) {
  case UV_RENAME: args[1] = symbol_value_lit(mrb, "rename"); break;
  case UV_CHANGE: args[1] = symbol_value_lit(mrb, "change"); break;
  default: mrb_assert(FALSE);
  }
  args[2] = mrb_uv_create_status(mrb, status);
  yield_handle_cb(ctx, 3, args);
}

static mrb_value
mrb_uv_fs_event_start(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  char* path;
  mrb_int flags;
  mrb_value b;

  mrb_get_args(mrb, "&zi", &b, &path, &flags);
  set_handle_cb(ctx, b);
  mrb_uv_check_error(mrb, uv_fs_event_start((uv_fs_event_t*)&ctx->handle, _uv_fs_event_cb, path, flags));
  return self;
}

static mrb_value
mrb_uv_fs_event_stop(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_uv_check_error(mrb, uv_fs_event_stop((uv_fs_event_t*)&ctx->handle));
  return self;
}

static mrb_value
mrb_uv_fs_event_path(mrb_state *mrb, mrb_value self)
{
  char ret[PATH_MAX];
  size_t len = PATH_MAX;
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);

  mrb_uv_check_error(mrb, uv_fs_event_getpath((uv_fs_event_t*)&ctx->handle, ret, &len));
  return mrb_str_new_cstr(mrb, ret);
}

/*
 * UV::Poll
 */
static mrb_value
mrb_uv_poll_init(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx;
  mrb_value fd, l = mrb_nil_value();
  uv_loop_t *loop;
  mrb_get_args(mrb, "o|o", &fd, &l);

  loop = get_loop(mrb, &l);
  ctx = mrb_uv_handle_alloc(mrb, UV_POLL, self, l);
  mrb_uv_check_error(mrb, uv_poll_init(loop, (uv_poll_t*)&ctx->handle, mrb_uv_to_fd(mrb, fd)));
  return self;
}

static mrb_value
mrb_uv_poll_init_socket(mrb_state *mrb, mrb_value self)
{
  mrb_value sock, l = mrb_nil_value(), ret;
  mrb_uv_handle *ctx;
  uv_loop_t *loop;
  mrb_get_args(mrb, "o|o", &sock, &l);

  loop = get_loop(mrb, &l);
  ret = mrb_obj_value(mrb_data_object_alloc(mrb, mrb_class_ptr(self), NULL, NULL));
  ctx = mrb_uv_handle_alloc(mrb, UV_POLL, ret, l);
  mrb_uv_check_error(mrb, uv_poll_init_socket(loop, (uv_poll_t*)&ctx->handle, mrb_uv_to_socket(mrb, sock)));
  return ret;
}

static void
_uv_poll_cb(uv_poll_t *poll, int status, int events)
{
  mrb_uv_handle *h = (mrb_uv_handle*)poll->data;
  mrb_value args[2] = { mrb_fixnum_value(events), mrb_uv_create_status(h->mrb, status) };
  yield_handle_cb(h, 2, args);
}

static mrb_value
mrb_uv_poll_start(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  mrb_int ev;
  mrb_value b;

  mrb_get_args(mrb, "&i", &b, &ev);
  set_handle_cb(ctx, b);
  return mrb_uv_check_error(mrb, uv_poll_start((uv_poll_t*)&ctx->handle, ev, _uv_poll_cb)), self;
}

static mrb_value
mrb_uv_poll_stop(mrb_state *mrb, mrb_value self)
{
  mrb_uv_handle *ctx = (mrb_uv_handle*)mrb_uv_get_ptr(mrb, self, &mrb_uv_handle_type);
  return mrb_uv_check_error(mrb, uv_poll_stop((uv_poll_t*)&ctx->handle)), self;
}

void
mrb_mruby_uv_gem_init_handle(mrb_state *mrb, struct RClass *UV)
{
  struct RClass* _class_uv_timer;
  struct RClass* _class_uv_idle;
  struct RClass* _class_uv_async;
  struct RClass* _class_uv_prepare;
  struct RClass* _class_uv_handle;
  struct RClass* _class_uv_tcp;
  struct RClass* _class_uv_udp;
  struct RClass* _class_uv_pipe;
  struct RClass* _class_uv_tty;
  struct RClass* _class_uv_process;
  struct RClass* _class_uv_fs_poll;
  struct RClass* _class_uv_signal;
  struct RClass* _class_uv_stream;
  struct RClass* _class_uv_check;
  struct RClass* _class_uv_fs_event;
  struct RClass* _class_uv_poll;
  int const ai = mrb_gc_arena_save(mrb);

  _class_uv_handle = mrb_define_module_under(mrb, UV, "Handle");
  mrb_define_method(mrb, _class_uv_handle, "close", mrb_uv_close, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_handle, "closing?", mrb_uv_is_closing, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_handle, "active?", mrb_uv_is_active, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_handle, "ref", mrb_uv_ref, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_handle, "unref", mrb_uv_unref, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_handle, "has_ref?", mrb_uv_has_ref, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_handle, "data=", mrb_uv_data_set, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_handle, "data", mrb_uv_data_get, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_handle, "recv_buffer_size", mrb_uv_recv_buffer_size, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_handle, "recv_buffer_size=", mrb_uv_recv_buffer_size_set, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_handle, "send_buffer_size", mrb_uv_send_buffer_size, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_handle, "send_buffer_size=", mrb_uv_send_buffer_size_set, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_handle, "fileno", mrb_uv_fileno, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_handle, "loop", mrb_uv_handle_loop, MRB_ARGS_NONE());
#if MRB_UV_CHECK_VERSION(1, 19, 0)
  mrb_define_method(mrb, _class_uv_handle, "type", mrb_uv_handle_get_type, MRB_ARGS_NONE());
#endif
  mrb_define_method(mrb, _class_uv_handle, "type_name", mrb_uv_handle_type_name, MRB_ARGS_NONE());

  _class_uv_stream = mrb_define_module_under(mrb, UV, "Stream");
  mrb_include_module(mrb, _class_uv_stream, _class_uv_handle);
  mrb_define_method(mrb, _class_uv_stream, "write", mrb_uv_write, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_stream, "try_write", mrb_uv_try_write, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_stream, "shutdown", mrb_uv_shutdown, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_stream, "read_start", mrb_uv_read_start, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_stream, "read_stop", mrb_uv_read_stop, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_stream, "accept", mrb_uv_accept, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_stream, "listen", mrb_uv_listen, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_stream, "readable?", mrb_uv_readable, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_stream, "writable?", mrb_uv_writable, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_stream, "write_queue_size", mrb_uv_stream_write_queue_size, MRB_ARGS_NONE());

  _class_uv_tty = mrb_define_class_under(mrb, UV, "TTY", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_uv_tty, MRB_TT_DATA);
  mrb_include_module(mrb, _class_uv_tty, _class_uv_stream);
  mrb_define_method(mrb, _class_uv_tty, "initialize", mrb_uv_tty_init, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, _class_uv_tty, "set_mode", mrb_uv_tty_set_mode, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_tty, "mode=", mrb_uv_tty_set_mode, MRB_ARGS_REQ(1));
  mrb_define_module_function(mrb, _class_uv_tty, "reset_mode", mrb_uv_tty_reset_mode, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_tty, "get_winsize", mrb_uv_tty_get_winsize, MRB_ARGS_NONE());
#if MRB_UV_CHECK_VERSION(1, 2, 0)
  mrb_define_const(mrb, _class_uv_tty, "MODE_NORMAL", mrb_fixnum_value(UV_TTY_MODE_NORMAL));
  mrb_define_const(mrb, _class_uv_tty, "MODE_RAW", mrb_fixnum_value(UV_TTY_MODE_RAW));
  mrb_define_const(mrb, _class_uv_tty, "MODE_IO", mrb_fixnum_value(UV_TTY_MODE_IO));
#endif
  mrb_gc_arena_restore(mrb, ai);

  _class_uv_udp = mrb_define_class_under(mrb, UV, "UDP", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_uv_udp, MRB_TT_DATA);
  mrb_include_module(mrb, _class_uv_udp, _class_uv_handle);
  mrb_define_method(mrb, _class_uv_udp, "initialize", mrb_uv_udp_init, MRB_ARGS_OPT(2));
  mrb_define_method(mrb, _class_uv_udp, "open", mrb_uv_udp_open, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_udp, "set_membership", mrb_uv_udp_set_membership, MRB_ARGS_REQ(3));
  mrb_define_method(mrb, _class_uv_udp, "multicast_loop=", mrb_uv_udp_multicast_loop_set, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_udp, "multicast_ttl=", mrb_uv_udp_multicast_ttl_set, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_udp, "multicast_interface=", mrb_uv_udp_multicast_interface_set, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_udp, "broadcast=", mrb_uv_udp_broadcast_set, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_udp, "ttl=", mrb_uv_udp_ttl_set, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_udp, "recv_start", mrb_uv_udp_recv_start, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_udp, "recv_stop", mrb_uv_udp_recv_stop, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_udp, "send", mrb_uv_udp_send4, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, _class_uv_udp, "send6", mrb_uv_udp_send6, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, _class_uv_udp, "bind", mrb_uv_udp_bind4, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_udp, "bind6", mrb_uv_udp_bind6, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_udp, "getsockname", mrb_uv_udp_getsockname, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_udp, "sockname", mrb_uv_udp_getsockname, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_udp, "try_send", mrb_uv_udp_try_send, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_udp, "send_queue_count", mrb_uv_udp_send_queue_count, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_udp, "send_queue_size", mrb_uv_udp_send_queue_size, MRB_ARGS_NONE());
  mrb_define_const(mrb, _class_uv_udp, "LEAVE_GROUP", mrb_fixnum_value(UV_LEAVE_GROUP));
  mrb_define_const(mrb, _class_uv_udp, "JOIN_GROUP", mrb_fixnum_value(UV_JOIN_GROUP));
  mrb_gc_arena_restore(mrb, ai);

  _class_uv_process = mrb_define_class_under(mrb, UV, "Process", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_uv_process, MRB_TT_DATA);
  mrb_include_module(mrb, _class_uv_process, _class_uv_handle);
  mrb_define_method(mrb, _class_uv_process, "initialize", mrb_uv_process_init, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_process, "spawn", mrb_uv_process_spawn, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_process, "stdout_pipe=", mrb_uv_process_stdout_pipe_set, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_process, "stdout_pipe", mrb_uv_process_stdout_pipe_get, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_process, "stdin_pipe=", mrb_uv_process_stdin_pipe_set, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_process, "stdin_pipe", mrb_uv_process_stdin_pipe_get, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_process, "stderr_pipe=", mrb_uv_process_stderr_pipe_set, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_process, "stderr_pipe", mrb_uv_process_stderr_pipe_get, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_process, "kill", mrb_uv_process_kill, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_process, "pid", mrb_uv_process_pid, MRB_ARGS_NONE());
  mrb_gc_arena_restore(mrb, ai);

  _class_uv_signal = mrb_define_class_under(mrb, UV, "Signal", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_uv_signal, MRB_TT_DATA);
  mrb_include_module(mrb, _class_uv_signal, _class_uv_handle);
  mrb_define_method(mrb, _class_uv_signal, "initialize", mrb_uv_signal_init, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_signal, "start", mrb_uv_signal_start, MRB_ARGS_REQ(1));
#if MRB_UV_CHECK_VERSION(1, 12, 0)
  mrb_define_method(mrb, _class_uv_signal, "start_oneshot", mrb_uv_signal_start_oneshot, MRB_ARGS_REQ(1));
#endif
  mrb_define_method(mrb, _class_uv_signal, "stop", mrb_uv_signal_stop, MRB_ARGS_NONE());
  mrb_define_const(mrb, _class_uv_signal, "SIGINT", mrb_fixnum_value(SIGINT));
#ifdef SIGUSR1
  mrb_define_const(mrb, _class_uv_signal, "SIGUSR1", mrb_fixnum_value(SIGUSR1));
#endif
#ifdef SIGUSR2
  mrb_define_const(mrb, _class_uv_signal, "SIGUSR2", mrb_fixnum_value(SIGUSR2));
#endif
#ifdef SIGPROF
  mrb_define_const(mrb, _class_uv_signal, "SIGPROF", mrb_fixnum_value(SIGPROF));
#endif
#ifdef SIGPIPE
  mrb_define_const(mrb, _class_uv_signal, "SIGPIPE", mrb_fixnum_value(SIGPIPE));
#endif
#ifdef SIGBREAK
  mrb_define_const(mrb, _class_uv_signal, "SIGBREAK", mrb_fixnum_value(SIGBREAK));
#endif
  mrb_define_const(mrb, _class_uv_signal, "SIGHUP", mrb_fixnum_value(SIGHUP));
  mrb_define_const(mrb, _class_uv_signal, "SIGWINCH", mrb_fixnum_value(SIGWINCH));
  mrb_define_const(mrb, _class_uv_signal, "SIGILL", mrb_fixnum_value(SIGILL));
  mrb_define_const(mrb, _class_uv_signal, "SIGABRT", mrb_fixnum_value(SIGABRT));
  mrb_define_const(mrb, _class_uv_signal, "SIGFPE", mrb_fixnum_value(SIGFPE));
  mrb_define_const(mrb, _class_uv_signal, "SIGSEGV", mrb_fixnum_value(SIGSEGV));
  mrb_define_const(mrb, _class_uv_signal, "SIGTERM", mrb_fixnum_value(SIGTERM));
  mrb_define_const(mrb, _class_uv_signal, "SIGKILL", mrb_fixnum_value(SIGKILL));
  mrb_gc_arena_restore(mrb, ai);

  _class_uv_fs_poll = mrb_define_class_under(mrb, mrb_class_get_under(mrb, UV, "FS"), "Poll", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_uv_fs_poll, MRB_TT_DATA);
  mrb_include_module(mrb, _class_uv_fs_poll, _class_uv_handle);
  mrb_define_method(mrb, _class_uv_fs_poll, "initialize", mrb_uv_fs_poll_init, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_fs_poll, "start", mrb_uv_fs_poll_start, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, _class_uv_fs_poll, "stop", mrb_uv_fs_poll_stop, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_fs_poll, "path", mrb_uv_fs_poll_getpath, MRB_ARGS_NONE());
  mrb_gc_arena_restore(mrb, ai);

  _class_uv_timer = mrb_define_class_under(mrb, UV, "Timer", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_uv_timer, MRB_TT_DATA);
  mrb_include_module(mrb, _class_uv_timer, _class_uv_handle);
  mrb_define_method(mrb, _class_uv_timer, "initialize", mrb_uv_timer_init, MRB_ARGS_OPT(1));
  mrb_define_method(mrb, _class_uv_timer, "again", mrb_uv_timer_again, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_timer, "repeat", mrb_uv_timer_repeat, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_timer, "repeat=", mrb_uv_timer_repeat_set, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_timer, "start", mrb_uv_timer_start, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, _class_uv_timer, "stop", mrb_uv_timer_stop, MRB_ARGS_NONE());
  mrb_gc_arena_restore(mrb, ai);

  _class_uv_idle = mrb_define_class_under(mrb, UV, "Idle", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_uv_idle, MRB_TT_DATA);
  mrb_include_module(mrb, _class_uv_idle, _class_uv_handle);
  mrb_define_method(mrb, _class_uv_idle, "initialize", mrb_uv_idle_init, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_idle, "start", mrb_uv_idle_start, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_idle, "stop", mrb_uv_idle_stop, MRB_ARGS_NONE());
  mrb_gc_arena_restore(mrb, ai);

  _class_uv_async = mrb_define_class_under(mrb, UV, "Async", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_uv_async, MRB_TT_DATA);
  mrb_include_module(mrb, _class_uv_async, _class_uv_handle);
  mrb_define_method(mrb, _class_uv_async, "initialize", mrb_uv_async_init, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_async, "send", mrb_uv_async_send, MRB_ARGS_NONE());
  mrb_gc_arena_restore(mrb, ai);

  _class_uv_prepare = mrb_define_class_under(mrb, UV, "Prepare", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_uv_prepare, MRB_TT_DATA);
  mrb_include_module(mrb, _class_uv_prepare, _class_uv_handle);
  mrb_define_method(mrb, _class_uv_prepare, "initialize", mrb_uv_prepare_init, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_prepare, "start", mrb_uv_prepare_start, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_prepare, "stop", mrb_uv_prepare_stop, MRB_ARGS_NONE());
  mrb_gc_arena_restore(mrb, ai);

  _class_uv_tcp = mrb_define_class_under(mrb, UV, "TCP", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_uv_tcp, MRB_TT_DATA);
  mrb_include_module(mrb, _class_uv_tcp, _class_uv_stream);
  mrb_define_method(mrb, _class_uv_tcp, "initialize", mrb_uv_tcp_init, MRB_ARGS_OPT(2));
  mrb_define_method(mrb, _class_uv_tcp, "open", mrb_uv_tcp_open, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_tcp, "connect", mrb_uv_tcp_connect4, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, _class_uv_tcp, "connect6", mrb_uv_tcp_connect6, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, _class_uv_tcp, "bind", mrb_uv_tcp_bind4, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_tcp, "bind6", mrb_uv_tcp_bind6, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_tcp, "simultaneous_accepts=", mrb_uv_tcp_simultaneous_accepts_set, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_tcp, "keepalive=", mrb_uv_tcp_keepalive_set, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_tcp, "nodelay=", mrb_uv_tcp_nodelay_set, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_tcp, "simultaneous_accepts?", mrb_uv_tcp_simultaneous_accepts_get, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_tcp, "keepalive?", mrb_uv_tcp_keepalive_p, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_tcp, "keepalive_delay", mrb_uv_tcp_keepalive_delay, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_tcp, "nodelay?", mrb_uv_tcp_nodelay_get, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_tcp, "getpeername", mrb_uv_tcp_getpeername, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_tcp, "getsockname", mrb_uv_tcp_getsockname, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_tcp, "peername", mrb_uv_tcp_getpeername, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_tcp, "sockname", mrb_uv_tcp_getsockname, MRB_ARGS_NONE());
  mrb_gc_arena_restore(mrb, ai);

  _class_uv_pipe = mrb_define_class_under(mrb, UV, "Pipe", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_uv_pipe, MRB_TT_DATA);
  mrb_include_module(mrb, _class_uv_pipe, _class_uv_stream);
  mrb_define_method(mrb, _class_uv_pipe, "initialize", mrb_uv_pipe_init, MRB_ARGS_OPT(2));
  mrb_define_method(mrb, _class_uv_pipe, "open", mrb_uv_pipe_open, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_pipe, "connect", mrb_uv_pipe_connect, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, _class_uv_pipe, "bind", mrb_uv_pipe_bind, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_pipe, "pending_instances=", mrb_uv_pipe_pending_instances, MRB_ARGS_REQ(1));
#if MRB_UV_CHECK_VERSION(1, 3, 0)
  mrb_define_method(mrb, _class_uv_pipe, "peername", mrb_uv_pipe_getpeername, MRB_ARGS_NONE());
#endif
  mrb_define_method(mrb, _class_uv_pipe, "sockname", mrb_uv_pipe_getsockname, MRB_ARGS_NONE());
#if MRB_UV_CHECK_VERSION(1, 16, 0)
  mrb_define_method(mrb, _class_uv_pipe, "chmod", mrb_uv_pipe_chmod, MRB_ARGS_REQ(1));
#endif
  mrb_gc_arena_restore(mrb, ai);

  _class_uv_check = mrb_define_class_under(mrb, UV, "Check", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_uv_check, MRB_TT_DATA);
  mrb_include_module(mrb, _class_uv_check, _class_uv_handle);
  mrb_define_method(mrb, _class_uv_check, "initialize", mrb_uv_check_init, MRB_ARGS_OPT(1));
  mrb_define_method(mrb, _class_uv_check, "start", mrb_uv_check_start, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_check, "stop", mrb_uv_check_stop, MRB_ARGS_NONE());

  _class_uv_fs_event = mrb_define_class_under(mrb, mrb_class_get_under(mrb, UV, "FS"), "Event", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_uv_fs_event, MRB_TT_DATA);
  mrb_include_module(mrb, _class_uv_fs_event, _class_uv_handle);
  mrb_define_method(mrb, _class_uv_fs_event, "initialize", mrb_uv_fs_event_init, MRB_ARGS_OPT(1));
  mrb_define_method(mrb, _class_uv_fs_event, "start", mrb_uv_fs_event_start, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, _class_uv_fs_event, "stop", mrb_uv_fs_event_stop, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_uv_fs_event, "path", mrb_uv_fs_event_path, MRB_ARGS_NONE());
  mrb_define_const(mrb, _class_uv_fs_event, "WATCH_ENTRY", mrb_fixnum_value(UV_FS_EVENT_WATCH_ENTRY));
  mrb_define_const(mrb, _class_uv_fs_event, "STAT", mrb_fixnum_value(UV_FS_EVENT_STAT));
  mrb_define_const(mrb, _class_uv_fs_event, "RECURSIVE", mrb_fixnum_value(UV_FS_EVENT_RECURSIVE));
  mrb_define_const(mrb, _class_uv_fs_event, "CHANGE", symbol_value_lit(mrb, "change"));
  mrb_define_const(mrb, _class_uv_fs_event, "RENAME", symbol_value_lit(mrb, "rename"));

  _class_uv_poll = mrb_define_class_under(mrb, UV, "Poll", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_uv_poll, MRB_TT_DATA);
  mrb_include_module(mrb, _class_uv_poll, _class_uv_handle);
  mrb_define_method(mrb, _class_uv_poll, "initialize", mrb_uv_poll_init, MRB_ARGS_REQ(1) | MRB_ARGS_OPT(1));
  mrb_define_class_method(mrb, _class_uv_poll, "create_from_socket", mrb_uv_poll_init_socket, MRB_ARGS_REQ(1) | MRB_ARGS_OPT(1));
  mrb_define_method(mrb, _class_uv_poll, "start", mrb_uv_poll_start, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_uv_poll, "stop", mrb_uv_poll_stop, MRB_ARGS_NONE());
  mrb_define_const(mrb, _class_uv_poll, "READABLE", mrb_fixnum_value(UV_READABLE));
  mrb_define_const(mrb, _class_uv_poll, "WRITABLE", mrb_fixnum_value(UV_WRITABLE));
#if MRB_UV_CHECK_VERSION(1, 9, 0)
  mrb_define_const(mrb, _class_uv_poll, "DISCONNECT", mrb_fixnum_value(UV_DISCONNECT));
#endif
#if MRB_UV_CHECK_VERSION(1, 14, 0)
  mrb_define_const(mrb, _class_uv_poll, "PRIORITIZED", mrb_fixnum_value(UV_PRIORITIZED));
#endif

  mrb_define_const(mrb, UV, "READABLE", mrb_fixnum_value(UV_READABLE));
  mrb_define_const(mrb, UV, "WRITABLE", mrb_fixnum_value(UV_WRITABLE));
}
