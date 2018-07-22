# Makefile

product=wkndr
build=build/$(product)-build
target=$(build)/$(product)
mruby_static_lib=mruby/build/host/lib/libmruby.a
#mruby/build/host/mrbgems/mruby-uv/libuv-1.0.0/.libs/libuv.a
mrbc=mruby/bin/mrbc

sources = $(wildcard *.c)
objects = $(patsubst %,$(build)/%, $(patsubst %.c,%.o, $(sources)))
static_ruby_headers = $(patsubst %,$(build)/%, $(patsubst lib/%.rb,%.h, $(wildcard lib/*.rb)))
.SECONDARY: $(static_ruby_headers) $(objects)
objects += $(mruby_static_lib)

LDFLAGS=-lm -lpthread -ldl $(shell (uname | grep -q Darwin || echo -static) )

CFLAGS=-std=c99 -Imruby/include -I$(build)

#-I~/opt/include

$(shell mkdir -p $(build))

docker-build: $(target) $(sources)
#	(echo $(LDFLAGS) | grep -q static && docker build .) || echo you must build on linux
	ln -sf $(shell realpath $(target)) /usr/local/bin/wkndr.mruby

$(target): $(objects) $(sources)
	$(CC) -o $@ $(objects) $(LDFLAGS)

$(build)/test.yml: $(target) config.ru
	$(target) > $@

clean:
	cd mruby && make clean
	rm -R $(build)

$(build):
	mkdir -p $(build)

$(build)/%.o: %.c $(static_ruby_headers) $(sources)
	$(CC) $(CFLAGS) -c $< -o $@

$(mruby_static_lib): config/mruby.rb
	cd mruby && make clean && MRUBY_CONFIG=../config/mruby.rb make

$(mrbc): $(mruby_static_lib)

$(build)/%.h: lib/%.rb $(mrbc)
	mruby/bin/mrbc -g -B $(patsubst $(build)/%.h,%, $@) -o $@ $<
