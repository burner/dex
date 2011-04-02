all: crude
FILES = dex/main.d dex/bitmap.d dex/fsm.d dex/list.d dex/util.d dex/set.d \
dex/multimap.d

crude:
	#dmd dex/*.d -offsm -unittest libphobos2.a libhurt.a -I../libhurt/ -gc
	dmd $(FILES) -offsm -unittest libphobos2.a libhurt.a -I../libhurt/ -gc
	#dmd $(FILES) -offsm -unittest libhurt.a -I../libhurt/ -gc
