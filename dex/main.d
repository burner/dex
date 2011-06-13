module dex.main;

import dex.regex;

import std.stdio;

void main() {
	writeln("all unittest passed");
	RegEx r1 = new RegEx();
	writeln("regex object created");
	//assert(r1.createNFA("[a-z][a-z]*", 1));
	//r1.cleanUp();
	assert(r1.createNFA("[:digit:]", 2));
	r1.cleanUp();
	assert(r1.createNFA("function", 3));
	r1.cleanUp();
	assert(r1.createNFA("delegate", 4));
	r1.cleanUp();
	r1.cleanUp();
	writeln("nfa's created");
	r1.writeNFAGraph();
	writeln("nfa's graph created");
	r1.convertNfaToDfa();
	writeln("nfa to dfa convertions done");
	r1.writeDFAGraph();
	writeln("dfa's graph created");
	writeln("next up minimize");
	//r1.minimize();
	writeln("dfa minimized");
	return;
}
