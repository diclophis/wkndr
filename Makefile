## Makefile

product=wkndr.mruby
build=release
target=$(build)/$(product)

$(shell mkdir -p $(build))

mruby_static_lib_deps=$(shell find mruby -type f | grep -v 'mruby/build\|mruby/bin')
#TODO: platform switch
mruby_static_lib=mruby/build/host/lib/libmruby.a
#mruby_static_lib=mruby/build/emscripten/lib/libmruby.a

raylib_static_lib_deps=$(shell find raylib-src -type f)
#TODO: platform switch
raylib_static_lib=$(build)/libraylib.a
#raylib_static_lib=$(build)/libraylib.bc

#TODO: platform switch
mrbc=mruby/bin/mrbc
#mrbc=mruby/build/host/bin/mrbc

sources = $(wildcard *.c)
objects = $(patsubst %,$(build)/%, $(patsubst %.c,%.o, $(sources)))
static_ruby_headers = $(patsubst %,$(build)/%, $(patsubst lib/%.rb,%.h, $(wildcard lib/*.rb)))
#TODO: platform switch
static_ruby_headers += $(patsubst %,$(build)/%, $(patsubst lib/desktop/%.rb,%.h, $(wildcard lib/desktop/*.rb)))
.SECONDARY: $(static_ruby_headers) $(objects)
objects += $(mruby_static_lib)
objects += $(raylib_static_lib)


#TODO: platform switch
LDFLAGS=-lm -lpthread -ldl -lX11 -lpthread -lssl -lcrypto -lutil
#OSX LDFLAGS=-lm -lpthread -ldl -framework Cocoa -framework OpenGL -framework IOKit -framework CoreVideo

#TODO: platform switch
CFLAGS=-DPLATFORM_DESKTOP -Os -std=c99 -Imruby/include -Iraylib-src -I$(build) -Imruby/build/mrbgems/mruby-b64/include
#TODO: remove GL_SILENCE_DEPRECATION
#OSX  CFLAGS=-DPLATFORM_DESKTOP -DGL_SILENCE_DEPRECATION -Os -std=c99 -fdeclspec -Imruby/include -Iraylib-src -I$(build)
#EMS EMSCRIPTEN_FLAGS=-s NO_EXIT_RUNTIME=0 -s STACK_OVERFLOW_CHECK=1 -s ASSERTIONS=2 -s SAFE_HEAP=1 -s SAFE_HEAP_LOG=0 -s WASM=1 -s EMTERPRETIFY=0
#EMS CFLAGS=$(EMSCRIPTEN_FLAGS) -DPLATFORM_WEB -s USE_GLFW=3 -std=c99 -fdeclspec -Imruby/include -Iraylib-src -I$(build

run: $(target) $(sources)
	echo $(target)
	realpath $(target)

$(target): $(objects) $(sources)
	$(CC) $(CFLAGS) -o $@ $(objects) $(LDFLAGS)

#TODO: platform switch
#$(target): shell.html $(objects) $(sources)
#	$(CC) -o $@ $(objects) $(LDFLAGS) $(EMSCRIPTEN_FLAGS) -fdeclspec -s USE_GLFW=3 -g4 -s EXPORTED_FUNCTIONS="['_main', '_debug_print']" -s EXTRA_EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]' --source-map-base $(map_base) -s TOTAL_MEMORY=167772160 --shell-file shell.html --preload-file resources

$(build)/test.yml: $(target) config.ru
	$(target) > $@

#TODO: platform switch
#EMS: cd raylib-src && make PLATFORM=PLATFORM_WEB clean
clean:
	cd mruby && make clean
	cd raylib-src && make PLATFORM=PLATFORM_DESKTOP clean
	rm -R $(build)

$(build):
	mkdir -p $(build)

$(build)/%.o: %.c $(static_ruby_headers) $(sources)
	$(CC) $(CFLAGS) -c $< -o $@

#TODO: platform switch... why????
$(mruby_static_lib): config/mruby.rb $(mruby_static_lib_deps)
	cd mruby && MRUBY_CONFIG=../config/mruby.rb make -j

#TODO: platform switch
#EMS: cd raylib-src && make -j PLATFORM=PLATFORM_WEB -B
$(raylib_static_lib): $(raylib_static_lib_deps)
	cd raylib-src && RAYLIB_RELEASE_PATH=../$(build) PLATFORM=PLATFORM_DESKTOP make -e -j -B

#TODO: platform switch
$(mrbc): $(mruby_static_lib)

$(build)/%.h: lib/desktop/%.rb $(mrbc)
	mruby/bin/mrbc -g -B $(patsubst $(build)/%.h,%, $@) -o $@ $<

$(build)/%.h: lib/%.rb $(mrbc)
	mruby/bin/mrbc -g -B $(patsubst $(build)/%.h,%, $@) -o $@ $<





## Makefile
#
#product=wkndr
#build=build/$(product)-build
#target=$(build)/$(product)
#mruby_static_lib=mruby/build/host/lib/libmruby.a
##mruby/build/host/mrbgems/mruby-uv/libuv-1.0.0/.libs/libuv.a
#mrbc=mruby/bin/mrbc
#
#sources = $(wildcard *.c)
#objects = $(patsubst %,$(build)/%, $(patsubst %.c,%.o, $(sources)))
#static_ruby_headers = $(patsubst %,$(build)/%, $(patsubst lib/%.rb,%.h, $(wildcard lib/*.rb)))
#.SECONDARY: $(static_ruby_headers) $(objects)
#objects += $(mruby_static_lib)
#
#LDFLAGS=-lm -lpthread -ldl $(shell (uname | grep -q Darwin || echo -static) )
#
#CFLAGS=-std=c99 -Imruby/include -I$(build)
#
##-I~/opt/include
#
#$(shell mkdir -p $(build))
#
#docker-build: $(target) $(sources)
#	ln -sf $(shell realpath $(target)) /usr/local/bin/wkndr.mruby
#
#$(target): $(objects) $(sources)
#	$(CC) -o $@ $(objects) $(LDFLAGS)
#
#$(build)/test.yml: $(target) config.ru
#	$(target) > $@
#
#clean:
#	cd mruby && make clean
#	rm -R $(build)
#
#$(build):
#	mkdir -p $(build)
#
#$(build)/%.o: %.c $(static_ruby_headers) $(sources)
#	$(CC) $(CFLAGS) -c $< -o $@
#
#$(mruby_static_lib): config/mruby.rb
#	cd mruby && make clean && MRUBY_CONFIG=../config/mruby.rb make
#
#$(mrbc): $(mruby_static_lib)
#
#$(build)/%.h: lib/%.rb $(mrbc)
#	mruby/bin/mrbc -g -B $(patsubst $(build)/%.h,%, $@) -o $@ $<
