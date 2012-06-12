src = Split('''
dex/emit.d
dex/main.d
dex/regex.d
dex/strutil.d
dex/input.d
dex/minimizer.d
dex/parseerror.d
dex/state.d
''')

env = Environment()
env.Program("fsm", src, TARGET_ARCH='x86_64', DFLAGS = Split("-m64 -unittest -gc -g -I../libhurt"), LIBPATH="../libhurt/", LIBS=["m", "hurt", "pthread", "rt", "phobos2"])
