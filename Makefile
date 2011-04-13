all: crude

#CFLAGS=-m64 -offsm -unittest -d-debug -gc
#CFLAGS=-m64 -offsm -unittest -debug -gc -debug=RegExDebug -debug=StateDebug
CFLAGS=-m64 -offsm -unittest -debug -gc 

FILES = dex/main.d dex/bitmap.d dex/fsm.d dex/list.d dex/strutil.d dex/set.d \
dex/multimap.d dex/regex.d dex/state.d dex/patternstate.d dex/parseerror.d

crude:
	#dmd dex/*.d -offsm -unittest libphobos2.a libhurt.a -I../libhurt/ -gc
	#ldc2 $(FILES) $(CFLAGS) *.a -I../libhurt/ -gc
	dmd $(FILES) $(CFLAGS) *.a -I../libhurt/ -gc
	#dmd $(FILES) -offsm -unittest *.a -I../libhurt/ -gc
