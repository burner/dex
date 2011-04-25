module dex.main;

import dex.regex;

import std.stdio;

long getTicks() {
	asm {
		naked;
		rdtsc;
		ret;
	}
}

void main() {
	writeln("all unittest passed");
	long st = getTicks();
	RegEx r1 = new RegEx();
	assert(r1.createNFA("[:digit:]*l"));
	r1.cleanUp();
	writeln(getTicks() - st);	
	assert(r1.createNFA("[:digit:]*u"));
	r1.cleanUp();
	assert(r1.createNFA("[:digit:]*lu"));
	r1.cleanUp();
	assert(r1.createNFA("[:digit:]*"));
	r1.cleanUp();
	assert(r1.createNFA("0x[:odigit:]*"));
	writeln("nfa's created");
	r1.writeNFAGraph();
	writeln("nfa's graph created");
	r1.convertNfaToDfa();
	writeln("nfa to dfa convertions done");
	r1.writeDFAGraph();
	writeln("dfa's graph created");
	return;
}
