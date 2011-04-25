all: crude

#CFLAGS=-m64 -offsm -unittest -d-debug -gc
#CFLAGS=-m64 -offsm -unittest -debug -gc -debug=RegExDebug -debug=StateDebug
#CFLAGS=-m64 -offsm -unittest -debug -gc
CFLAGS=-m64 -offsm -unittest

FILES = dex/main.d dex/fsm.d dex/strutil.d  \
dex/regex.d dex/state.d dex/parseerror.d

crude:
	dmd $(FILES) $(CFLAGS) *.a -I../libhurt/ -gc
