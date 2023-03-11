## Makefile

TARGET ?= desktop
TARGET_OS ?= $(shell uname)
OPTIM = -O0 -g
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
raylib_static_lib=$(build)/libraylib.a

ode_static_lib_deps=$(shell find ode -type f -name "*.h" 2> /dev/null)
ode_static_lib=ode/ode/src/.libs/libode.a

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
cxx_sources = $(wildcard src/*.cpp)
ifeq ($(TARGET),desktop)
sources += $(wildcard src/desktop/*.c)
endif

headers += $(wildcard include/*.h)

static_ruby_headers = $(patsubst %,$(build)/%, $(patsubst lib/%.rb,%.h, $(wildcard lib/*.rb)))
ifeq ($(TARGET),desktop)
static_ruby_headers += $(patsubst %,$(build)/%, $(patsubst lib/desktop/%.rb,%.h, $(wildcard lib/desktop/*.rb)))
static_ruby_headers += $(build)/embed_static.h
endif

giga_static_js = gigamock-transfer/static/morphdom.js gigamock-transfer/static/stringview.js gigamock-transfer/static/bridge.js
giga_static_txt = gigamock-transfer/static/robots.txt
giga_static_ico = gigamock-transfer/static/favicon.ico
giga_static_css = gigamock-transfer/static/wkndr.css 

objects += $(patsubst %,$(build)/%, $(patsubst %.c,%.o, $(sources)))
objects += $(patsubst %,$(build)/%, $(patsubst %.cpp,%.o, $(cxx_sources)))
objects += $(mruby_static_lib)
objects += $(raylib_static_lib)
objects += $(ode_static_lib)
objects += $(msgpack_static_lib)

.SECONDARY: $(static_ruby_headers) $(objects)
.PHONY: $(target)

ifeq ($(TARGET),desktop)
  LDFLAGS=-lm -lpthread -ldl -lpthread -lssl -lcrypto -lutil -lz $(shell pkg-config --libs libuv) -lX11 -lxcb -lXau -lXdmcp
  ###TODO: OSX platform switch
  #ifeq ($(TARGET_OS),Darwin)
  #  LDFLAGS=-lm -lpthread -ldl -lssl -lcrypto -framework Cocoa -framework OpenGL -framework IOKit -framework CoreVideo
  #endif
endif

CFLAGS=$(OPTIM) -std=gnu99 -Wcast-align -Iode/include -Iinclude -Imruby/include -I$(build) -Iraylib/src -Imruby/build/repos/host/mruby-b64/include -Iraylib/src/external/glfw/include -D_POSIX_C_SOURCE=200112
CXXFLAGS=$(OPTIM) -Wcast-align -Iinclude -Iode/include -Imruby/include -I$(build) -Iraylib/src -Imruby/build/repos/host/mruby-b64/include -Iraylib/src/external/glfw/include

CFLAGS+=-DGRAPHICS_API_OPENGL_ES3 
#CFLAGS+=-DGRAPHICS_API_OPENGL_ES2

######TODO: svga bootdisk
RAYLIB_PLATFORM_HEAVY=PLATFORM_DESKTOP
#RAYLIB_PLATFORM_HEAVY=PLATFORM_DRM
#LDFLAGS+=-lGLESv2 -lEGL -ldrm -lgbm
#CFLAGS+=-I/usr/include/libdrm 
CFLAGS+=-DSUPPORT_CUSTOM_FRAME_CONTROL=1

#TODO 
#-Imruby/build/mrbgems/mruby-b64/include 

ifeq ($(TARGET),desktop)
  #CFLAGS=$(OPTIM) -Wcast-align -D_POSIX_C_SOURCE=200112 -DTARGET_DESKTOP -DGRAPHICS_API_OPENGL_ES3 -D$(RAYLIB_TARGET_DEFINED) -std=c99 -Iinclude -Imruby/include -I$(build) -Imruby/build/repos/host/mruby-b64/include -Imruby/build/mrbgems/mruby-b64/include -Iraylib/src -Iraylib/src/external/glfw/include
  #ifeq ($(TARGET_OS),Darwin)
	#  #TODO
  #  #CFLAGS+=-I/usr/local/Cellar/openssl/1.0.2r/include
  #endif
  CFLAGS+=-DTARGET_HEAVY
  CFLAGS+=-DPLATFORM_DESKTOP=1
else
  #NOTE: SAFE_HEAP=1 breaks things, could be fixed possibly?? https://github.com/emscripten-core/emscripten/blob/main/site/source/docs/porting/Debugging.rst
  #EMSCRIPTEN_FLAGS=-O0 -s DEMANGLE_SUPPORT=1 -s ASSERTIONS=1 -s USE_ZLIB=1 -s SAFE_HEAP=0 -s WARN_UNALIGNED=1 -s ALLOW_MEMORY_GROWTH=1 -s NO_EXIT_RUNTIME=0 -s USE_GLFW=3 -s RESERVED_FUNCTION_POINTERS=128
  EMSCRIPTEN_FLAGS=-s USE_ZLIB=1 -s NO_EXIT_RUNTIME=0 -s USE_GLFW=3 -s RESERVED_FUNCTION_POINTERS=16 -s WASM=1 -s ALLOW_MEMORY_GROWTH=1 -s DEFAULT_LIBRARY_FUNCS_TO_INCLUDE='[$$allocate, $$ALLOC_NORMAL]'
  #CFLAGS=-Wcast-align -DPLATFORM_WEB -DGRAPHICS_API_OPENGL_ES3 -Iinclude -Imruby/include -I$(build) -Iraylib/src
  CFLAGS+=-DPLATFORM_WEB -fdeclspec
endif

$(target): $(objects) #$(sources)
ifeq ($(TARGET),desktop)
	$(CC) $(CFLAGS) -o $@ $(objects) $(LDFLAGS)
else
	$(CC) $(objects) -o $@ $(LDFLAGS) $(EMSCRIPTEN_FLAGS) -s EXPORTED_FUNCTIONS="['_main', '_handle_js_websocket_event', '_pack_outbound_tty', '_resize_tty']" -s EXPORTED_RUNTIME_METHODS='["ccall", "cwrap", "addFunction", "getValue"]' --preload-file resources
endif

$(build)/embed_static.h: $(mrbc) $(giga_static_js) $(giga_static_txt) $(giga_static_css) $(giga_static_ico)
	ruby gigamock-transfer/mkstatic-mruby-module.rb $(giga_static_js)  > $(build)/embed_static_js.rb
	ruby gigamock-transfer/mkstatic-mruby-module.rb $(giga_static_txt) > $(build)/embed_static_txt.rb
	ruby gigamock-transfer/mkstatic-mruby-module.rb $(giga_static_ico) > $(build)/embed_static_ico.rb
	ruby gigamock-transfer/mkstatic-mruby-module.rb $(giga_static_css) > $(build)/embed_static_css.rb
	mruby/bin/mrbc -B embed_static_js -o $(build)/embed_static_js.h $(build)/embed_static_js.rb
	mruby/bin/mrbc -B embed_static_txt -o $(build)/embed_static_txt.h $(build)/embed_static_txt.rb
	mruby/bin/mrbc -B embed_static_ico -o $(build)/embed_static_ico.h $(build)/embed_static_ico.rb
	mruby/bin/mrbc -B embed_static_css -o $(build)/embed_static_css.h $(build)/embed_static_css.rb
	cat $(build)/embed_static_*h > $(build)/embed_static.h

clean:
	#cd mruby && make clean && rm -Rf build
	cd raylib/src && make RAYLIB_RELEASE_PATH=../../$(build) PLATFORM=$(RAYLIB_PLATFORM_HEAVY) clean
	rm -R $(build)
	mkdir -p $(build)
	mkdir -p $(build)/src
	mkdir -p $(build)/src/desktop

$(build)/main.o: main.c $(static_ruby_headers)
	$(CC) $(CFLAGS) -c $< -o $@

$(build)/%.o: %.c #$(static_ruby_headers) $(sources) $(headers)
	$(CC) $(CFLAGS) -c $< -o $@

$(build)/%.o: %.cpp #$(static_ruby_headers) $(sources) $(headers)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(mruby_static_lib): config/mruby.rb
ifeq ($(TARGET),desktop)
	cd mruby && MRUBY_CONFIG=../config/mruby.rb $(MAKE)
else
	cd mruby && MRUBY_CONFIG=../config/emscripten.rb $(MAKE)
endif

$(raylib_static_lib): $(raylib_static_lib_deps)
ifeq ($(TARGET),desktop)
	echo FOOO
	cd raylib/src && RAYLIB_RELEASE_PATH=../../$(build) PLATFORM=$(RAYLIB_PLATFORM_HEAVY) $(MAKE) -B -e
else
	echo BAAR
	cd raylib/src && RAYLIB_RELEASE_PATH=../../$(build) PLATFORM=PLATFORM_WEB $(MAKE) -B -e
endif

$(ode_static_lib): $(ode_static_lib_deps)
ifeq ($(TARGET),desktop)
	echo FOOO
	cd ode && ./bootstrap && ./configure && $(MAKE)
	#RAYLIB_RELEASE_PATH=../../$(build) PLATFORM=$(RAYLIB_PLATFORM_HEAVY) $(MAKE) -B -e
else
	echo BAAR
	#cd raylib/src && RAYLIB_RELEASE_PATH=../../$(build) PLATFORM=PLATFORM_WEB $(MAKE) -B -e
	cd ode && ./bootstrap && ./configure && $(MAKE)
endif

build-mruby: $(mruby_static_lib)

$(mrbc): $(mruby_static_lib)

$(build)/%.h: lib/desktop/%.rb $(mrbc)
	mruby/bin/mrbc -B $(patsubst $(build)/%.h,%, $@) -o $@ $<

$(build)/%.h: lib/%.rb $(mrbc)
	mruby/bin/mrbc -B $(patsubst $(build)/%.h,%, $@) -o $@ $<
