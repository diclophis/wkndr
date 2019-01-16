## Makefile

TARGET ?= desktop

ifeq ($(TARGET),desktop)
  product=wkndr.mruby
else
  product=wkndr.html
endif
build=release
target=$(build)/$(product)

$(shell mkdir -p $(build))

mruby_static_lib_deps=$(wildcard mruby/**/*.c) #$(shell find mruby -type f | grep -v 'mruby/build\|mruby/bin')

ifeq ($(TARGET),desktop)
  mruby_static_lib="mruby/build/host/lib/libmruby.a"
else
  mruby_static_lib="mruby/build/emscripten/lib/libmruby.a"
endif

raylib_static_lib_deps=$(shell find raylib-src -type f)

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

#ifeq ($(TARGET),desktop)
objects = $(patsubst %,$(build)/%, $(patsubst %.c,%.o, $(sources)))
#else
#objects = $(patsubst %,$(build)/emsc/%, $(patsubst %.c,%.o, $(sources)))
#endif

static_ruby_headers = $(patsubst %,$(build)/%, $(patsubst lib/%.rb,%.h, $(wildcard lib/*.rb)))

ifeq ($(TARGET),desktop)
static_ruby_headers += $(patsubst %,$(build)/%, $(patsubst lib/desktop/%.rb,%.h, $(wildcard lib/desktop/*.rb)))
endif

.SECONDARY: $(static_ruby_headers) $(objects)
objects += $(mruby_static_lib)
objects += $(raylib_static_lib)

#TODO: platform switch
ifeq ($(TARGET),desktop)
  LDFLAGS=-lm -lpthread -ldl -lX11 -lpthread -lssl -lcrypto -lutil
  #ifeq ($(TARGET),desktop)
  #LDFLAGS=-lm -lpthread -ldl -framework Cocoa -framework OpenGL -framework IOKit -framework CoreVideo
endif

ifeq ($(TARGET),desktop)
  CFLAGS=-DPLATFORM_DESKTOP -Os -std=c99 -Imruby/include -Iraylib-src -I$(build) -Imruby/build/mrbgems/mruby-b64/include
  #TODO: remove GL_SILENCE_DEPRECATION
  #OSX  CFLAGS=-DPLATFORM_DESKTOP -DGL_SILENCE_DEPRECATION -Os -std=c99 -fdeclspec -Imruby/include -Iraylib-src -I$(build)
else
  EMSCRIPTEN_FLAGS=-s EMTERPRETIFY_ADVISE=1 -s NO_EXIT_RUNTIME=0 -s STACK_OVERFLOW_CHECK=1 -s ASSERTIONS=2 -s SAFE_HEAP=1 -s SAFE_HEAP_LOG=0 -s WASM=1 -s EMTERPRETIFY=0
  #EMSCRIPTEN_FLAGS=""
  #CFLAGS=$(EMSCRIPTEN_FLAGS) -DPLATFORM_WEB -s USE_GLFW=3 -std=c99 -fdeclspec -Imruby/include -Iraylib-src -I$(build)
  CFLAGS=$(EMSCRIPTEN_FLAGS) -DPLATFORM_WEB -s USE_GLFW=3 -Imruby/include -Iraylib-src -I$(build)
endif

run: $(target) $(sources)
	echo $(target)
	realpath $(target)

$(target): $(objects) $(sources)
ifeq ($(TARGET),desktop)
	$(CC) $(CFLAGS) -o $@ $(objects) $(LDFLAGS)
else
	$(CC) -o $@ $(objects) $(LDFLAGS) $(EMSCRIPTEN_FLAGS) -fdeclspec -s USE_GLFW=3 -g4 -s EXPORTED_FUNCTIONS="['_main', '_debug_print', '_pack_outbound_tty']" -s EXTRA_EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]' -s TOTAL_MEMORY=167772160 #--shell-file shell.html --preload-file resources
endif

$(build)/test.yml: $(target) config.ru
	$(target) > $@

clean:
	cd mruby && make clean && rm -Rf build
	cd raylib-src && make RAYLIB_RELEASE_PATH=../$(build) PLATFORM=PLATFORM_DESKTOP clean
	rm -R $(build)

$(build):
	mkdir -p $(build)

$(build)/%.o: %.c $(static_ruby_headers) $(sources)
	$(CC) $(CFLAGS) -c $< -o $@

$(mruby_static_lib): config/mruby.rb $(mruby_static_lib_deps)
ifeq ($(TARGET),desktop)
	cd mruby && MRUBY_CONFIG=../config/mruby.rb $(MAKE) -j
else
	cd mruby && MRUBY_CONFIG=../config/emscripten.rb $(MAKE) -j
endif

$(raylib_static_lib): $(raylib_static_lib_deps)
ifeq ($(TARGET),desktop)
	cd raylib-src && RAYLIB_RELEASE_PATH=../$(build) PLATFORM=PLATFORM_DESKTOP $(MAKE) -B -e -j
else
	cd raylib-src && RAYLIB_RELEASE_PATH=../$(build) $(MAKE) PLATFORM=PLATFORM_WEB -B -e -j
endif

cheese: $(mruby_static_lib)

$(mrbc): $(mruby_static_lib)

$(build)/%.h: lib/desktop/%.rb $(mrbc)
	mruby/bin/mrbc -g -B $(patsubst $(build)/%.h,%, $@) -o $@ $<

$(build)/%.h: lib/%.rb $(mrbc)
	mruby/bin/mrbc -g -B $(patsubst $(build)/%.h,%, $@) -o $@ $<




