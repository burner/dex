module dex.main;

import dex.regex;

import std.stdio;

void main() {
	writeln("all unittest passed");
	RegEx r1 = new RegEx();
	assert(r1.createNFA("ab(b|s)"));
	r1.writeNFAGraph();
	return;
}
