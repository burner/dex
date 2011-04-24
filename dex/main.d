module dex.main;

import dex.regex;

import std.stdio;

void main() {
	writeln("all unittest passed");
	RegEx r1 = new RegEx();
	assert(r1.createNFA("[a-z][a-z]*", 1));
	r1.cleanUp();
	assert(r1.createNFA("if", 2));
	r1.cleanUp();
	assert(r1.createNFA("immutable", 3));
	r1.cleanUp();
	assert(r1.createNFA("function", 4));
	r1.cleanUp();
	assert(r1.createNFA("delegate", 5));
	r1.cleanUp();
	assert(r1.createNFA("import", 6));
	r1.cleanUp();
	assert(r1.createNFA("module", 7));
	r1.cleanUp();
	assert(r1.createNFA("unittest", 8));
	r1.cleanUp();
	assert(r1.createNFA("char", 9));
	r1.cleanUp();
	assert(r1.createNFA("\\[", 10));
	r1.cleanUp();
	assert(r1.createNFA("\\]", 11));
	r1.cleanUp();
	writeln("nfa's created");
	r1.writeNFAGraph();
	writeln("nfa's graph created");
	r1.convertNfaToDfa();
	writeln("nfa to dfa convertions done");
	r1.writeDFAGraph();
	writeln("dfa's graph created");
	return;
}
