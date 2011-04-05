all: crude
FILES = dex/main.d dex/bitmap.d dex/fsm.d dex/list.d dex/util.d dex/set.d \
dex/multimap.d dex/regex.d dex/state.d dex/patternstate.d

crude:
	#dmd dex/*.d -offsm -unittest libphobos2.a libhurt.a -I../libhurt/ -gc
	dmd $(FILES) -offsm -unittest *.a -I../libhurt/ -gc
	#dmd $(FILES) -offsm -unittest *.a -I../libhurt/ -gc
