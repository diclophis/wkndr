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

objects = $(patsubst %,$(build)/%, $(patsubst %.c,%.o, $(sources)))

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
.PHONY: $(target)

objects += $(mruby_static_lib)
objects += $(raylib_static_lib)

##TODO: platform switch
ifeq ($(TARGET),desktop)
  LDFLAGS=-lm -lpthread -ldl -lpthread -lssl -lcrypto -lutil -lz $(shell pkg-config --libs libuv) -lX11 -lxcb -lXau -lXdmcp
  ifeq ($(TARGET_OS),Darwin)
    LDFLAGS=-lm -lpthread -ldl -lssl -lcrypto -framework Cocoa -framework OpenGL -framework IOKit -framework CoreVideo
  endif
endif

RAYLIB_TARGET_DEFINED=PLATFORM_DESKTOP
ifeq ($(TARGET),desktop)
  CFLAGS=-O3 -D_POSIX_C_SOURCE=200112 -DTARGET_DESKTOP -DGRAPHICS_API_OPENGL_ES3 -D$(RAYLIB_TARGET_DEFINED) $(DEBUG) -std=c99 -Iinclude -Imruby/include -I$(build) -Imruby/build/repos/host/mruby-b64/include -Imruby/build/mrbgems/mruby-b64/include -Iraylib/src
  ifeq ($(TARGET_OS),Darwin)
    CFLAGS+=-I/usr/local/Cellar/openssl/1.0.2r/include
  endif
else
  EMSCRIPTEN_FLAGS=-s USE_ZLIB=1 -s NO_EXIT_RUNTIME=0 -O3 -s USE_GLFW=3 -s USE_WEBGL2=1 -s RESERVED_FUNCTION_POINTERS=1 #-s DISABLE_DEPRECATED_FIND_EVENT_TARGET_BEHAVIOR=1
  CFLAGS=$(EMSCRIPTEN_FLAGS) -DPLATFORM_WEB -DGRAPHICS_API_OPENGL_ES3 -Iinclude -Imruby/include -I$(build) -Iraylib/src -s RESERVED_FUNCTION_POINTERS=32
endif

$(target): $(static_ruby_headers) $(objects) $(sources)
ifeq ($(TARGET),desktop)
	$(CC) $(CFLAGS) -o $@ $(objects) $(LDFLAGS)
else
	$(CC) -o $@ $(objects) $(LDFLAGS) $(EMSCRIPTEN_FLAGS) -fdeclspec $(DEBUG) -s EXPORTED_FUNCTIONS="['_main', '_handle_js_websocket_event', '_pack_outbound_tty', '_resize_tty']" -s EXTRA_EXPORTED_RUNTIME_METHODS='["ccall", "cwrap", "addFunction", "getValue"]' -s TOTAL_MEMORY=655360000 -s ABORTING_MALLOC=0 --source-map-base http://localhost:8000/ --preload-file resources
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
	cd mruby && make clean && rm -Rf build
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
