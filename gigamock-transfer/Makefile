# Makefile

product=kit1zx
build=release/libs/osx
target=$(build)/$(product)
mruby_static_lib=mruby/build/host/lib/libmruby.a
mruby_static_lib_deps=$(shell find mruby -type f | grep -v 'mruby/build\|mruby/bin')
raylib_static_lib=$(build)/libraylib.a
raylib_static_lib_deps=$(shell find raylib-src -type f)
mrbc=mruby/bin/mrbc

sources = $(wildcard *.c)
objects = $(patsubst %,$(build)/%, $(patsubst %.c,%.o, $(sources)))
static_ruby_headers = $(patsubst %,$(build)/%, $(patsubst lib/%.rb,%.h, $(wildcard lib/*.rb)))
static_ruby_headers += $(patsubst %,$(build)/%, $(patsubst lib/desktop/%.rb,%.h, $(wildcard lib/desktop/*.rb)))
.SECONDARY: $(static_ruby_headers) $(objects)
#.PHONY: $(mruby_static_lib) $(raylib_static_lib)
objects += $(mruby_static_lib)
objects += $(raylib_static_lib)

LDFLAGS=-lm -lpthread -ldl -framework Cocoa -framework OpenGL -framework IOKit -framework CoreVideo

#TODO: remove GL_SILENCE_DEPRECATION
CFLAGS=-DPLATFORM_DESKTOP -DGL_SILENCE_DEPRECATION -Os -std=c99 -fdeclspec -Imruby/include -Iraylib-src -I$(build)

$(shell mkdir -p $(build))

run: $(target) $(sources)
	echo $(target)
	echo $(sources)

$(target): $(objects) $(sources)
	$(CC) $(CFLAGS) -o $@ $(objects) $(LDFLAGS)

$(build)/test.yml: $(target) config.ru
	$(target) > $@

clean:
	cd mruby && make clean
	cd raylib-src && make PLATFORM=PLATFORM_DESKTOP clean
	rm -R $(build)

$(build):
	mkdir -p $(build)

$(build)/%.o: %.c $(static_ruby_headers) $(sources)
	$(CC) $(CFLAGS) -c $< -o $@

$(mruby_static_lib): config/mruby.rb $(mruby_static_lib_deps)
	cd mruby && MRUBY_CONFIG=../config/mruby.rb make -j

$(raylib_static_lib): $(raylib_static_lib_deps)
	cd raylib-src && make -j PLATFORM=PLATFORM_DESKTOP -B

$(mrbc): $(mruby_static_lib)

$(build)/%.h: lib/desktop/%.rb $(mrbc)
	mruby/bin/mrbc -g -B $(patsubst $(build)/%.h,%, $@) -o $@ $<

$(build)/%.h: lib/%.rb $(mrbc)
	mruby/bin/mrbc -g -B $(patsubst $(build)/%.h,%, $@) -o $@ $<
