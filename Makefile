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

#mruby_static_lib_deps=$(wildcard mruby/**/*.c) #$(shell find mruby -type f | grep -v 'mruby/build\|mruby/bin')

ifeq ($(TARGET),desktop)
  mruby_static_lib = mruby/build/host/lib/libmruby.a
else
  mruby_static_lib = mruby/build/emscripten/lib/libmruby.a
endif

raylib_static_lib_deps=$(shell find raylib -type f 2> /dev/null)

ifeq ($(TARGET),desktop)
  raylib_static_lib=$(build)/libraylib.a
else
  raylib_static_lib=$(build)/libraylib.bc
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

#ifeq ($(TARGET),desktop)
objects = $(patsubst %,$(build)/%, $(patsubst %.c,%.o, $(sources)))
#objects += $(patsubst %,$(build)/%, $(patsubst src/%.c,%.o, $(sources)))
#else
#objects = $(patsubst %,$(build)/emsc/%, $(patsubst %.c,%.o, $(sources)))
#endif

static_ruby_headers = $(patsubst %,$(build)/%, $(patsubst lib/%.rb,%.h, $(wildcard lib/*.rb)))
ifeq ($(TARGET),desktop)
static_ruby_headers += $(patsubst %,$(build)/%, $(patsubst lib/desktop/%.rb,%.h, $(wildcard lib/desktop/*.rb)))
static_ruby_headers += $(build)/embed_static.h
endif

giga_static_js = gigamock-transfer/static/morphdom.js gigamock-transfer/static/stringview.js gigamock-transfer/static/bridge.js 
giga_static_txt = gigamock-transfer/static/robots.txt
giga_static_ico = gigamock-transfer/static/favicon.ico
giga_static_css = gigamock-transfer/static/wkndr.css 

.SECONDARY: $(static_ruby_headers) $(objects)
objects += $(mruby_static_lib)
objects += $(raylib_static_lib)

##TODO: platform switch
ifeq ($(TARGET),desktop)
  #LDFLAGS=-lm -lpthread -ldl -lX11 -lpthread -lssl -lcrypto -lutil -lz
  LDFLAGS=-lm -lpthread -ldl -lpthread -lssl -lcrypto -lutil -lz $(shell pkg-config --libs libuv) -lX11 -lxcb -lXau -lXdmcp
  #ifeq ($(TARGET),desktop)
  ifeq ($(TARGET_OS),Darwin)
    LDFLAGS=-lm -lpthread -ldl -lssl -lcrypto -framework Cocoa -framework OpenGL -framework IOKit -framework CoreVideo
  endif
endif

RAYLIB_TARGET_DEFINED=PLATFORM_DESKTOP
ifeq ($(TARGET),desktop)
  #CFLAGS=-DTARGET_DESKTOP -D$(RAYLIB_TARGET_DEFINED) -Os -ggdb -std=c99 -Imruby/include -Iraylib-src -I$(build) -Imruby/build/mrbgems/mruby-b64/include
  #CFLAGS=-O3 -DTARGET_DESKTOP -DGRAPHICS_API_OPENGL_ES3 -DSUPPORT_GIF_RECORDING -D$(RAYLIB_TARGET_DEFINED) $(DEBUG) -std=c99 -Imruby/include -Iraylib-src/external/glfw/include -Iraylib-src -I$(build) -Imruby/build/repos/host/mruby-b64/include -Imruby/build/mrbgems/mruby-b64/include
  CFLAGS=-O3 -D_POSIX_C_SOURCE=200112 -DTARGET_DESKTOP -DGRAPHICS_API_OPENGL_ES3 -DSUPPORT_GIF_RECORDING -D$(RAYLIB_TARGET_DEFINED) $(DEBUG) -std=c99 -Iinclude -Imruby/include -I$(build) -Imruby/build/repos/host/mruby-b64/include -Imruby/build/mrbgems/mruby-b64/include -Iraylib/src
  ifeq ($(TARGET_OS),Darwin)
    CFLAGS+=-I/usr/local/Cellar/openssl/1.0.2r/include
  endif
else
  #LDFLAGS=-lm -lz
  EMSCRIPTEN_FLAGS=-s USE_ZLIB=1 -s NO_EXIT_RUNTIME=0 -O3 -s USE_GLFW=3 -s USE_WEBGL2=1 -s RESERVED_FUNCTION_POINTERS=1 #-s DISABLE_DEPRECATED_FIND_EVENT_TARGET_BEHAVIOR=1
  #EMSCRIPTEN_FLAGS=-s ASSERTIONS=1 -s NO_EXIT_RUNTIME=0 -g4 -s WASM=1 -s RESERVED_FUNCTION_POINTERS=1 -s DISABLE_DEPRECATED_FIND_EVENT_TARGET_BEHAVIOR=1
  #EMSCRIPTEN_FLAGS=-s ASSERTIONS=1 -s NO_EXIT_RUNTIME=1 -Os -s WASM=1 -s RESERVED_FUNCTION_POINTERS=32 -s DISABLE_DEPRECATED_FIND_EVENT_TARGET_BEHAVIOR=1
  #EMSCRIPTEN_FLAGS=-s RESERVED_FUNCTION_POINTERS=32
  #CFLAGS=$(EMSCRIPTEN_FLAGS) -DPLATFORM_WEB -DGRAPHICS_API_OPENGL_ES3 -s USE_GLFW=3 -s USE_WEBGL2=1 -s FULL_ES3=1 -Imruby/include -Iraylib-src -I$(build)
  CFLAGS=$(EMSCRIPTEN_FLAGS) -DPLATFORM_WEB -DGRAPHICS_API_OPENGL_ES3 -Iinclude -Imruby/include -I$(build) -Iraylib/src -s RESERVED_FUNCTION_POINTERS=32
#-    CFLAGS += -s USE_GLFW=3 -s USE_WEBGL2=1 -s FULL_ES3=1 -s WASM=1
#+    CFLAGS += -s USE_GLFW=3
endif

#run: $(target) $(sources)
#	echo $(target)
#	realpath $(target)

$(target): $(objects) $(sources)
ifeq ($(TARGET),desktop)
	$(CC) $(CFLAGS) -static -o $@ $(objects) $(LDFLAGS)
	#$(CC) $(CFLAGS) -o $@ $(objects) $(LDFLAGS)
else
	#$(CC) -o $@ $(objects) $(LDFLAGS) $(EMSCRIPTEN_FLAGS) -fdeclspec $(DEBUG) -s EXPORTED_FUNCTIONS="['_main', '_handle_js_websocket_event', '_pack_outbound_tty']" -s EXTRA_EXPORTED_RUNTIME_METHODS='["ccall", "cwrap", "addFunction", "getValue"]' -s TOTAL_MEMORY=32768000 -s ABORTING_MALLOC=0 --source-map-base https://localhost:8000/ --preload-file resources
	$(CC) -o $@ $(objects) $(LDFLAGS) $(EMSCRIPTEN_FLAGS) -fdeclspec $(DEBUG) -s EXPORTED_FUNCTIONS="['_main', '_handle_js_websocket_event', '_pack_outbound_tty', '_resize_tty']" -s EXTRA_EXPORTED_RUNTIME_METHODS='["ccall", "cwrap", "addFunction", "getValue"]' -s TOTAL_MEMORY=32768000 -s ABORTING_MALLOC=0 --source-map-base http://localhost:8000/
endif

#$(build)/test.yml: $(target) config.ru
#	$(target) > $@

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
	cd mruby && make clean && rm -Rf build
	cd raylib/src && make RAYLIB_RELEASE_PATH=../../$(build) PLATFORM=$(RAYLIB_TARGET_DEFINED) clean
	rm -R $(build)
	mkdir -p $(build)
	mkdir -p $(build)/src
	mkdir -p $(build)/src/desktop

#$(build):
#$(build)/src:

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
