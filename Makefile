all: fine

#CFLAGS=-m64 -offsm -unittest -d-debug -gc
#CFLAGS=-m64 -offsm -unittest -debug -gc -debug=RegExDebug -debug=StateDebug
CFLAGS=-m64 -unittest -debug -gc -I../libhurt/ -wi
#CFLAGS=-m64 -offsm -unittest

FILES = dex/main.d dex/fsm.d dex/strutil.d  \
dex/regex.d dex/state.d dex/parseerror.d dex/minimizer.d \

OBJS=dex.main.o dex.strutil.o dex.regex.o dex.state.o dex.parseerror.o \
dex.minimizer.o dex.emit.o dex.input.o

count:
	wc -l `find dex -name \*.d`

clean:
	rm *.o
	rm fsm

crude:
	dmd $(FILES) $(CFLAGS) ../libhurt/libhurt.a -I../libhurt/ -gc -fsm

fine: $(OBJS)
	dmd $(OBJS) $(CFLAGS) ../libhurt/libhurt.a -I../libhurt/ -gc -offsm

dex.main.o: dex/main.d dex.regex.o
	dmd $(CFLAGS) -c dex/main.d -ofdex.main.o

dex.input.o: dex/input.d dex.regex.o
	dmd $(CFLAGS) -c dex/input.d -ofdex.input.o

dex.emit.o: dex/emit.d dex.regex.o
	dmd $(CFLAGS) -c dex/emit.d -ofdex.emit.o

dex.strutil.o: dex/strutil.d
	dmd $(CFLAGS) -c dex/strutil.d -ofdex.strutil.o

dex.regex.o: dex/regex.d dex/state.d dex.strutil.o dex.minimizer.o
	dmd $(CFLAGS) -c dex/regex.d -ofdex.regex.o

dex.state.o: dex/state.d dex.strutil.o
	dmd $(CFLAGS) -c dex/state.d -ofdex.state.o

dex.parseerror.o: dex/parseerror.d
	dmd $(CFLAGS) -c dex/parseerror.d -ofdex.parseerror.o

dex.minimizer.o: dex/minimizer.d dex.state.o
	dmd $(CFLAGS) -c dex/minimizer.d -ofdex.minimizer.o
