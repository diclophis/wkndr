## Makefile

TARGET ?= desktop
TARGET_OS ?= $(shell uname)
DEBUG ?= -g
build=release

ifeq ($(TARGET),desktop)
  product=wkndr.mruby
else
  product=wkndr.html
endif
target=$(build)/$(product)

$(shell mkdir -p $(build))

ifeq ($(TARGET),desktop)
  mruby_static_lib = mruby/build/host/lib/libmruby.a
else
  mruby_static_lib = mruby/build/emscripten/lib/libmruby.a
endif

raylib_static_lib_deps=$(shell find raylib -type f 2> /dev/null)

ifeq ($(TARGET),desktop)
  raylib_static_lib=$(build)/libraylib.a
else
  raylib_static_lib=$(build)/libraylib.a
endif

ifeq ($(TARGET),desktop)
  msgpack_static_lib=mruby/build/host/mrbgems/mruby-simplemsgpack/lib/libmsgpackc.a
else
  msgpack_static_lib=mruby/build/emscripten/mrbgems/mruby-simplemsgpack/lib/libmsgpackc.a
endif

ifeq ($(TARGET),desktop)
  mrbc=mruby/bin/mrbc
else
  mrbc=mruby/build/host/bin/mrbc
endif

sources = $(wildcard *.c)
sources += $(wildcard src/*.c)
ifeq ($(TARGET),desktop)
sources += $(wildcard src/desktop/*.c)
endif

headers += $(wildcard include/*.h)

static_ruby_headers = $(patsubst %,$(build)/%, $(patsubst lib/%.rb,%.h, $(wildcard lib/*.rb)))
ifeq ($(TARGET),desktop)
static_ruby_headers += $(patsubst %,$(build)/%, $(patsubst lib/desktop/%.rb,%.h, $(wildcard lib/desktop/*.rb)))
static_ruby_headers += $(build)/embed_static.h
endif

giga_static_js = gigamock-transfer/static/morphdom.js gigamock-transfer/static/stringview.js gigamock-transfer/static/xterm-dist/xterm.js gigamock-transfer/static/xterm-dist/fit/xterm-addon-fit.js gigamock-transfer/static/bridge.js
giga_static_txt = gigamock-transfer/static/robots.txt
giga_static_ico = gigamock-transfer/static/favicon.ico
giga_static_css = gigamock-transfer/static/xterm-dist/xterm.css gigamock-transfer/static/wkndr.css 

objects += $(patsubst %,$(build)/%, $(patsubst %.c,%.o, $(sources)))
objects += $(mruby_static_lib)
objects += $(raylib_static_lib)
objects += $(msgpack_static_lib)

.SECONDARY: $(static_ruby_headers) $(objects)
.PHONY: $(target)

##TODO: platform switch
ifeq ($(TARGET),desktop)
  LDFLAGS=-lm -lpthread -ldl -lpthread -lssl -lcrypto -lutil -lz $(shell pkg-config --libs libuv) -lX11 -lxcb -lXau -lXdmcp
  ifeq ($(TARGET_OS),Darwin)
    LDFLAGS=-lm -lpthread -ldl -lssl -lcrypto -framework Cocoa -framework OpenGL -framework IOKit -framework CoreVideo
  endif
endif

RAYLIB_TARGET_DEFINED=PLATFORM_DESKTOP
#TODO: svga bootdisk RAYLIB_TARGET_DEFINED=PLATFORM_DRM
ifeq ($(TARGET),desktop)
  CFLAGS=-Wcast-align -O3 -D_POSIX_C_SOURCE=200112 -DTARGET_DESKTOP -DGRAPHICS_API_OPENGL_ES3 -D$(RAYLIB_TARGET_DEFINED) $(DEBUG) -std=c99 -Iinclude -Imruby/include -I$(build) -Imruby/build/repos/host/mruby-b64/include -Imruby/build/mrbgems/mruby-b64/include -Iraylib/src -Iraylib/src/external/glfw/include
  ifeq ($(TARGET_OS),Darwin)
    CFLAGS+=-I/usr/local/Cellar/openssl/1.0.2r/include
  endif
else
  #NOTE: SAFE_HEAP=1 breaks things, could be fixed possibly?? https://github.com/emscripten-core/emscripten/blob/main/site/source/docs/porting/Debugging.rst
  EMSCRIPTEN_FLAGS=-O0 -g3 -gsource-map -s DEMANGLE_SUPPORT=1 -s ASSERTIONS=1 -s USE_ZLIB=1 -s SAFE_HEAP=0 -s WARN_UNALIGNED=1 -s ALLOW_MEMORY_GROWTH=1 -s NO_EXIT_RUNTIME=0 -s USE_GLFW=3 -s RESERVED_FUNCTION_POINTERS=128
  CFLAGS=-Wcast-align -DPLATFORM_WEB -DGRAPHICS_API_OPENGL_ES3 -Iinclude -Imruby/include -I$(build) -Iraylib/src
endif

$(target): $(objects) $(sources)
ifeq ($(TARGET),desktop)
	$(CC) $(CFLAGS) -o $@ $(objects) $(LDFLAGS)
else
	$(CC) $(objects) -o $@ $(LDFLAGS) $(EMSCRIPTEN_FLAGS) -fdeclspec $(DEBUG) -s WASM=1 -s EXPORTED_FUNCTIONS="['_main', '_handle_js_websocket_event', '_pack_outbound_tty', '_resize_tty']" -s EXPORTED_RUNTIME_METHODS='["ccall", "cwrap", "addFunction", "getValue"]' -s TOTAL_MEMORY=65536000 -s ABORTING_MALLOC=1 -s DETERMINISTIC=1 --source-map-base http://localhost:8000/ --preload-file resources
endif

$(build)/embed_static.h: $(mrbc) $(giga_static_js) $(giga_static_txt) $(giga_static_css) $(giga_static_ico)
	ruby gigamock-transfer/mkstatic-mruby-module.rb $(giga_static_js)  > $(build)/embed_static_js.rb
	ruby gigamock-transfer/mkstatic-mruby-module.rb $(giga_static_txt) > $(build)/embed_static_txt.rb
	ruby gigamock-transfer/mkstatic-mruby-module.rb $(giga_static_ico) > $(build)/embed_static_ico.rb
	ruby gigamock-transfer/mkstatic-mruby-module.rb $(giga_static_css) > $(build)/embed_static_css.rb
	mruby/bin/mrbc $(DEBUG) -B embed_static_js -o $(build)/embed_static_js.h $(build)/embed_static_js.rb
	mruby/bin/mrbc $(DEBUG) -B embed_static_txt -o $(build)/embed_static_txt.h $(build)/embed_static_txt.rb
	mruby/bin/mrbc $(DEBUG) -B embed_static_ico -o $(build)/embed_static_ico.h $(build)/embed_static_ico.rb
	mruby/bin/mrbc $(DEBUG) -B embed_static_css -o $(build)/embed_static_css.h $(build)/embed_static_css.rb
	cat $(build)/embed_static_*h > $(build)/embed_static.h

clean:
	cd mruby && make clean && rm -Rf build && git checkout 1e1d2964972eda9dd0317dfa422311e5c5b80783
	cd raylib/src && make RAYLIB_RELEASE_PATH=../../$(build) PLATFORM=$(RAYLIB_TARGET_DEFINED) clean
	rm -R $(build)
	mkdir -p $(build)
	mkdir -p $(build)/src
	mkdir -p $(build)/src/desktop

$(build)/%.o: %.c $(static_ruby_headers) $(sources) $(headers)
	$(CC) $(CFLAGS) -c $< -o $@

$(mruby_static_lib): config/mruby.rb
ifeq ($(TARGET),desktop)
	cd mruby && MRUBY_CONFIG=../config/mruby.rb $(MAKE)
else
	cd mruby && MRUBY_CONFIG=../config/emscripten.rb $(MAKE)
endif

$(raylib_static_lib): $(raylib_static_lib_deps)
ifeq ($(TARGET),desktop)
	cd raylib/src && RAYLIB_RELEASE_PATH=../../$(build) PLATFORM=$(RAYLIB_TARGET_DEFINED) $(MAKE) -B -e
else
	cd raylib/src && RAYLIB_RELEASE_PATH=../../$(build) $(MAKE) PLATFORM=PLATFORM_WEB -B -e
endif

build-mruby: $(mruby_static_lib)

$(mrbc): $(mruby_static_lib)

$(build)/%.h: lib/desktop/%.rb $(mrbc)
	mruby/bin/mrbc $(DEBUG) -B $(patsubst $(build)/%.h,%, $@) -o $@ $<

$(build)/%.h: lib/%.rb $(mrbc)
	mruby/bin/mrbc $(DEBUG) -B $(patsubst $(build)/%.h,%, $@) -o $@ $<
