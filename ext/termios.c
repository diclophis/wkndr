/*

  A termios library for Ruby.
  Copyright (C) 1999, 2000, 2002 akira yamada.

 */

#include "ruby.h"
#if defined(HAVE_RUBY_IO_H)
#include "ruby/io.h"
#else
#include "rubyio.h"
#endif
#include <termios.h>
#include <sys/ioctl.h>
#if defined(HAVE_SYS_IOCTL_H)
#include <unistd.h>
#endif
#include <string.h>


static VALUE mTermios;
static VALUE cTermios;
static VALUE tcsetattr_opt, tcflush_qs, tcflow_act;
static ID id_iflag, id_oflag, id_cflag, id_lflag, id_cc, id_ispeed, id_ospeed;

/*
 * Document-class: Termios::Termios
 *
 * Encupsalates termios parameters.
 *
 * See also: termios(3)
 */

/*
 * call-seq:
 *   termios.iflag = flag
 *
 * Updates input modes of the object.
 */
static VALUE
termios_set_iflag(self, value)
    VALUE self, value;
{
    rb_ivar_set(self, id_iflag, (value));

    return value;
}

void
Init_termios()
{
    VALUE ccindex, ccindex_names;
    VALUE iflags, iflags_names;
    VALUE oflags, oflags_names, oflags_choices;
    VALUE cflags, cflags_names, cflags_choices;
    VALUE lflags, lflags_names;
    VALUE bauds, bauds_names;
    VALUE ioctl_commands, ioctl_commands_names;
    VALUE modem_signals, modem_signals_names;
    VALUE pty_pkt_options, pty_pkt_options_names;
    VALUE line_disciplines, line_disciplines_names;

    /* module Termios */
    mTermios = rb_define_module("Termios");

    /* class Termios::Termios */
    cTermios = rb_define_class_under(mTermios, "Termios", rb_cObject);

    id_iflag  = rb_intern("@iflag");

    /* input modes */
    rb_define_attr(cTermios, "iflag",  1, 0);

    rb_define_method(cTermios, "iflag=",  termios_set_iflag,  1);
}
