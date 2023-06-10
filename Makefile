## Makefile

TARGET ?= desktop
TARGET_OS ?= $(shell uname)
OPTIM = -O0 -g
build=release

desktop_heavy_product=wkndr.mruby
desktop_heavy_target=$(build)/$(desktop_heavy_product)

wasm_product=wkndr.html
wasm_target=$(build)/$(wasm_product)

$(shell mkdir -p $(build) $(build)/desktop-heavy $(build)/wasm)

desktop_heavy_mruby_static_lib = mruby/build/heavy/lib/libmruby.a
desktop_heavy_mruby_config = config/heavy.rb

wasm_mruby_static_lib = mruby/build/emscripten/lib/libmruby.a
wasm_mruby_config = config/emscripten.rb

raylib_static_lib_deps=$(shell find raylib -type f 2> /dev/null)
desktop_heavy_raylib_static_lib=$(build)/desktop-heavy/libraylib.a
wasm_raylib_static_lib=$(build)/wasm/libraylib.a

ode_static_lib_deps=$(shell find ode -type f -name "*.h" 2> /dev/null)
ode_static_lib=ode/ode/src/.libs/libode.a

desktop_heavy_msgpack_static_lib=mruby/build/heavy/mrbgems/mruby-simplemsgpack/lib/libmsgpackc.a
wasm_msgpack_static_lib=mruby/build/emscripten/mrbgems/mruby-simplemsgpack/lib/libmsgpackc.a

mrbc=mruby/build/host/bin/mrbc

sources += $(wildcard *.c)
sources += $(wildcard src/*.c)
cxx_sources = $(wildcard src/*.cpp)

desktop_sources = $(wildcard src/desktop/*.c)

headers += $(wildcard include/*.h)

static_ruby_headers = $(patsubst %,$(build)/%, $(patsubst lib/%.rb,%.h, $(wildcard lib/*.rb)))

desktop_heavy_static_ruby_headers = $(patsubst %,$(build)/%, $(patsubst lib/desktop/%.rb,%.h, $(wildcard lib/desktop/*.rb)))
desktop_heavy_static_ruby_headers += $(build)/embed_static.h

giga_static_js = gigamock-transfer/static/morphdom.js gigamock-transfer/static/stringview.js gigamock-transfer/static/bridge.js
giga_static_txt = gigamock-transfer/static/robots.txt
giga_static_ico = gigamock-transfer/static/favicon.ico
giga_static_css = gigamock-transfer/static/wkndr.css 

#objects += $(patsubst %,$(build)/%, $(patsubst %.c,%.o, $(sources)))
#objects += $(patsubst %,$(build)/%, $(patsubst %.cpp,%.o, $(cxx_sources)))
#objects += $(ode_static_lib)

desktop_heavy_objects += $(patsubst %,$(build)/desktop/%, $(patsubst %.c,%.o, $(sources)))
desktop_heavy_objects += $(patsubst %,$(build)/desktop/%, $(patsubst %.cpp,%.o, $(cxx_sources)))
desktop_heavy_objects += $(ode_static_lib)

desktop_heavy_objects += $(patsubst %,$(build)/desktop/%, $(patsubst %.c,%.o, $(desktop_sources)))
desktop_heavy_objects += $(desktop_heavy_mruby_static_lib)
desktop_heavy_objects += $(desktop_heavy_msgpack_static_lib)
desktop_heavy_objects += $(desktop_heavy_raylib_static_lib)

wasm_objects += $(patsubst %,$(build)/wasm/%, $(patsubst %.c,%.o, $(sources)))
wasm_objects += $(patsubst %,$(build)/wasm/%, $(patsubst %.cpp,%.o, $(cxx_sources)))
wasm_objects += $(ode_static_lib)

wasm_objects += $(wasm_mruby_static_lib)
wasm_objects += $(wasm_msgpack_static_lib)
wasm_objects += $(wasm_raylib_static_lib)

.SECONDARY: $(desktop_heavy_static_ruby_headers) $(objects)
.PHONY: $(desktop_heavy_target)

#LDFLAGS=-lm -lpthread -ldl -lpthread -lssl -lcrypto -lutil -lz $(shell pkg-config --libs libuv) -lX11 -lxcb -lXau -lXdmcp

LDFLAGS=-lpthread -lssl -lcrypto -lutil -lz $(shell pkg-config --libs libuv) -lGLESv2 -lEGL -lpthread -lrt -lm -lgbm -ldrm -ldl -latomic
#-lX11 -lxcb -lXau -lXdmcp

CFLAGS=$(OPTIM) -std=gnu99 -Wcast-align -Iode/include -Iinclude -Imruby/include -I$(build) -Iraylib/src -Imruby/build/repos/heavy/mruby-b64/include -Iraylib/src/external/glfw/include -D_POSIX_C_SOURCE=200112
CFLAGS += -std=gnu99 -DEGL_NO_X11
CFLAGS += -I/usr/include/libdrm

CXXFLAGS=$(OPTIM) -Wcast-align -Iinclude -Iode/include -Imruby/include -I$(build) -Iraylib/src -Imruby/build/repos/heavy/mruby-b64/include -Iraylib/src/external/glfw/include

#CFLAGS+=-DGRAPHICS_API_OPENGL_ES3 

######TODO: svga bootdisk
#RAYLIB_PLATFORM_HEAVY=PLATFORM_DESKTOP
RAYLIB_PLATFORM_HEAVY=PLATFORM_DRM
CFLAGS+=-DSUPPORT_CUSTOM_FRAME_CONTROL=1
CFLAGS+=-DMRB_USE_DEBUG_HOOK

#ifeq ($(TARGET),desktop)
#  CFLAGS+=-DTARGET_HEAVY
#  CFLAGS+=-DPLATFORM_DESKTOP=1
#else
  EMSCRIPTEN_FLAGS=$(OPTIM) -s USE_ZLIB=1 -s NO_EXIT_RUNTIME=0 -s USE_GLFW=3 -s RESERVED_FUNCTION_POINTERS=16 -s WASM=1 -s ALLOW_MEMORY_GROWTH=1 -s DEFAULT_LIBRARY_FUNCS_TO_INCLUDE='[$$allocate, $$ALLOC_NORMAL]'
  #CFLAGS+=-DPLATFORM_WEB -fdeclspec
#endif

$(desktop_heavy_target): $(desktop_heavy_objects)
	$(CC) $(CFLAGS) -o $@ $(desktop_heavy_objects) $(LDFLAGS)

$(wasm_target): $(wasm_objects)
	$(CC) $(wasm_objects) -o $@ $(EMSCRIPTEN_FLAGS) -s EXPORTED_FUNCTIONS="['_main', '_handle_js_websocket_event', '_pack_outbound_tty', '_resize_tty', '_malloc', '_free']" -s EXPORTED_RUNTIME_METHODS='["allocate", "ccall", "cwrap", "addFunction", "getValue", "ALLOC_NORMAL"]' --preload-file resources

$(build)/embed_static.h: $(mrbc) $(giga_static_js) $(giga_static_txt) $(giga_static_css) $(giga_static_ico)
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
	mkdir -p $(build)/desktop/src/desktop

$(build)/desktop/main.o: main.c $(static_ruby_headers) $(desktop_heavy_static_ruby_headers)
	echo one
	$(CC) $(CFLAGS) -DTARGET_HEAVY -DPLATFORM_DESKTOP=1 -c $< -o $@

$(build)/wasm/main.o: main.c $(static_ruby_headers) $(desktop_heavy_static_ruby_headers)
	echo two
	$(CC) $(CFLAGS) -DPLATFORM_WEB -c $< -o $@

$(build)/desktop/%.o: %.c
	echo three
	$(CC) $(CFLAGS) -DTARGET_HEAVY -DPLATFORM_DESKTOP=1 -c $< -o $@

$(build)/desktop/%.o: %.cpp
	echo seven
	$(CXX) $(CXXFLAGS) -DTARGET_HEAVY -DPLATFORM_DESKTOP=1 -c $< -o $@

$(build)/wasm/%.o: %.c
	echo four
	$(CC) $(CFLAGS) -DPLATFORM_WEB -c $< -o $@

$(build)/wasm/%.o: %.cpp
	echo six
	$(CXX) $(CXXFLAGS) -DPLATFORM_WEB -c $< -o $@

$(desktop_heavy_mruby_static_lib): config/vanilla.rb ${desktop_heavy_mruby_config}
	cd mruby && MRUBY_CONFIG=../$(desktop_heavy_mruby_config) $(MAKE)

$(desktop_heavy_raylib_static_lib): $(raylib_static_lib_deps)
	echo foo
	cd raylib/src && RAYLIB_RELEASE_PATH=../../$(build)/desktop-heavy PLATFORM=$(RAYLIB_PLATFORM_HEAVY) $(MAKE) -B -e

$(wasm_raylib_static_lib): $(raylib_static_lib_deps)
	echo five
	cd raylib/src && RAYLIB_RELEASE_PATH=../../$(build)/wasm PLATFORM=PLATFORM_WEB $(MAKE) -B -e

#TODO: finish phsycs engine integration!
$(ode_static_lib): $(ode_static_lib_deps)
	echo barsdsd
	cd ode && ./bootstrap && ./configure && $(MAKE)

$(mrbc): $(desktop_heavy_mruby_static_lib)

$(build)/%.h: lib/desktop/%.rb $(mruby_static_lib) $(mrbc)
	$(mrbc) -B $(patsubst $(build)/%.h,%, $@) -o $@ $<

$(build)/%.h: lib/%.rb $(mruby_static_lib) $(mrbc)
	$(mrbc) -B $(patsubst $(build)/%.h,%, $@) -o $@ $<
