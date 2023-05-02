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
  mruby_static_lib = mruby/build/heavy/lib/libmruby.a
  mruby_config = config/heavy.rb
else
  mruby_static_lib = mruby/build/emscripten/lib/libmruby.a
  mruby_config = config/emscripten.rb
endif

raylib_static_lib_deps=$(shell find raylib -type f 2> /dev/null)
raylib_static_lib=$(build)/libraylib.a

ode_static_lib_deps=$(shell find ode -type f -name "*.h" 2> /dev/null)
ode_static_lib=ode/ode/src/.libs/libode.a

ifeq ($(TARGET),desktop)
  msgpack_static_lib=mruby/build/heavy/mrbgems/mruby-simplemsgpack/lib/libmsgpackc.a
else
  msgpack_static_lib=mruby/build/emscripten/mrbgems/mruby-simplemsgpack/lib/libmsgpackc.a
endif

mrbc=mruby/build/host/bin/mrbc

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
endif

CFLAGS=$(OPTIM) -std=gnu99 -Wcast-align -Iode/include -Iinclude -Imruby/include -I$(build) -Iraylib/src -Imruby/build/repos/heavy/mruby-b64/include -Iraylib/src/external/glfw/include -D_POSIX_C_SOURCE=200112
CXXFLAGS=$(OPTIM) -Wcast-align -Iinclude -Iode/include -Imruby/include -I$(build) -Iraylib/src -Imruby/build/repos/heavy/mruby-b64/include -Iraylib/src/external/glfw/include

CFLAGS+=-DGRAPHICS_API_OPENGL_ES3 

######TODO: svga bootdisk
RAYLIB_PLATFORM_HEAVY=PLATFORM_DESKTOP
CFLAGS+=-DSUPPORT_CUSTOM_FRAME_CONTROL=1
CFLAGS+=-DMRB_USE_DEBUG_HOOK

ifeq ($(TARGET),desktop)
  CFLAGS+=-DTARGET_HEAVY
  CFLAGS+=-DPLATFORM_DESKTOP=1
else
  EMSCRIPTEN_FLAGS=$(OPTIM) -s USE_ZLIB=1 -s NO_EXIT_RUNTIME=0 -s USE_GLFW=3 -s RESERVED_FUNCTION_POINTERS=16 -s WASM=1 -s ALLOW_MEMORY_GROWTH=1 -s DEFAULT_LIBRARY_FUNCS_TO_INCLUDE='[$$allocate, $$ALLOC_NORMAL]'
  CFLAGS+=-DPLATFORM_WEB -fdeclspec
endif

$(target): $(objects) #$(sources)
ifeq ($(TARGET),desktop)
	$(CC) $(CFLAGS) -o $@ $(objects) $(LDFLAGS)
else
	$(CC) $(objects) -o $@ $(LDFLAGS) $(EMSCRIPTEN_FLAGS) -s EXPORTED_FUNCTIONS="['_main', '_handle_js_websocket_event', '_pack_outbound_tty', '_resize_tty', '_malloc', '_free']" -s EXPORTED_RUNTIME_METHODS='["allocate", "ccall", "cwrap", "addFunction", "getValue", "ALLOC_NORMAL"]' --preload-file resources
endif

$(build)/embed_static.h: $(mruby_static_lib) $(giga_static_js) $(giga_static_txt) $(giga_static_css) $(giga_static_ico)
	ruby gigamock-transfer/mkstatic-mruby-module.rb $(giga_static_js)  > $(build)/embed_static_js.rb
	ruby gigamock-transfer/mkstatic-mruby-module.rb $(giga_static_txt) > $(build)/embed_static_txt.rb
	ruby gigamock-transfer/mkstatic-mruby-module.rb $(giga_static_ico) > $(build)/embed_static_ico.rb
	ruby gigamock-transfer/mkstatic-mruby-module.rb $(giga_static_css) > $(build)/embed_static_css.rb
	$(mrbc) -B embed_static_js -o $(build)/embed_static_js.h $(build)/embed_static_js.rb
	$(mrbc) -B embed_static_txt -o $(build)/embed_static_txt.h $(build)/embed_static_txt.rb
	$(mrbc) -B embed_static_ico -o $(build)/embed_static_ico.h $(build)/embed_static_ico.rb
	$(mrbc) -B embed_static_css -o $(build)/embed_static_css.h $(build)/embed_static_css.rb
	cat $(build)/embed_static_*h > $(build)/embed_static.h

clean:
	cd mruby && make clean && rm -Rf build
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

$(mruby_static_lib): config/vanilla.rb ${mruby_config}
ifeq ($(TARGET),desktop)
	cd mruby && MRUBY_CONFIG=../config/heavy.rb $(MAKE)
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

#TODO: finish phsycs engine integration!
$(ode_static_lib): $(ode_static_lib_deps)
	cd ode && ./bootstrap && ./configure && $(MAKE)

#$(mrbc): $(mruby_static_lib)

$(build)/%.h: lib/desktop/%.rb $(mruby_static_lib)
	$(mrbc) -B $(patsubst $(build)/%.h,%, $@) -o $@ $<

$(build)/%.h: lib/%.rb $(mruby_static_lib)
	$(mrbc) -B $(patsubst $(build)/%.h,%, $@) -o $@ $<
