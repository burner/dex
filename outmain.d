import hurt.time.stopwatch;

void main() {
	StopWatch sw;	
	sw.start();
	DLexer dl = new DLexer("test2");
	dl.run();
	printfln("lexing took %f seconds", sw.stop());
}
