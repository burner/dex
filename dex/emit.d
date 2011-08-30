module dex.emit;

import dex.state;

import hurt.conv.conv;
import hurt.container.iterator;
import hurt.container.set;
import hurt.container.isr;
import hurt.string.stringbuffer;
import hurt.string.formatter;
import hurt.util.array;
import hurt.string.utf;
import hurt.io.stdio;
import hurt.io.stream;
import std.process;

void writeTable(Iterable!(State) states, Set!(dchar) inputSet,
		string filename) {
	hurt.io.stream.File file = new hurt.io.stream.File(filename ~ ".tab", 
		FileMode.OutNew);

	int howManyBlanks = 0;
	size_t size = states.getSize();
	while(size > 0) {
		howManyBlanks++;
		size /= 10;
	}
	assert(howManyBlanks >= 1);

	StringBuffer!(dchar) sb = new StringBuffer!(dchar)();
	
	ISRIterator!(dchar) it = inputSet.begin();
	for(int i = 0; i < howManyBlanks; i++)
		sb.pushBack(' ');

	for(; it.isValid(); it++) {
		for(int i = 0; i < howManyBlanks; i++)
			sb.pushBack(' ');

		sb.pushBack(*it);	
	}
	file.writeString(conv!(dstring,string)(sb.getString()));
	file.write('\n');
	sb.clear();

	foreach(it; states) {
		sb.pushBack(format!(char,dchar)("%" ~ conv!(int,string)(howManyBlanks)
			~ "d", it.getStateId()));

		ISRIterator!(dchar) cit = inputSet.begin();
		for(; cit.isValid(); cit++) {
			sb.pushBack(' ');
			assert(it !is null);
			State next = it.getSingleTransition(*cit);
			int nextId = next is null ? -1 : next.getStateId();

			sb.pushBack(format!(char,dchar)("%" ~ 
				conv!(int,string)(howManyBlanks) ~ "d", nextId));
		}
		sb.pushBack('\n');
		file.writeString(conv!(dstring,string)(sb.getString()));
		sb.clear();
	}
	
	file.close();
}

/* A function that writes a given graph to a file of name fileName.
 * Iterable is a container that implements opApply. The transitions of
 * the states inside the container should correspond to the character inside
 * the inputSet. Otherwise the transistion will not be displayed.
 */
void writeGraph(Iterable!(State) states, Set!(dchar) inputSet,
		string fileName) {
	string[] strTable = ["digraph{\n"];
	StringBuffer!(char) strLine = new StringBuffer!(char)(16);
	foreach(it;states) {
		if(it.acceptingState) {
			strLine.pushBack('\t').pushBack(it.toString());
			strLine.pushBack("\t[shape=doublecircle];\n");
			append(strTable, strLine.getString());
			strLine.clear();
		}
	}
	append(strTable, "\n");
	strLine.clear();

	// Record transitions
	foreach(pState;states) {
		State[] state;	

		state = pState.getTransition(0);
		foreach(jt;state) {
			string stateId1 = (pState.toString());
			string stateId2 = (jt.toString());
			strLine.pushBack("\t" ~ stateId1 ~ " -> " ~ stateId2);
			strLine.pushBack("\t[label=\"epsilon\"];\n");
			append(strTable, strLine.getString());
			strLine.clear();
		}

		foreach(jt; inputSet) {
			dchar[1] inChar;
			inChar[0] = jt;
			string inputDChar = toUTF8(inChar);
			state = pState.getTransition(jt);
			foreach(kt;state) {
				string stateId1 = (pState.toString());
				string stateId2 = (kt.toString());
				strLine.pushBack("\t" ~ stateId1 ~ " -> " ~ stateId2);
				//strLine.pushBack("\t[label=\"" ~ jt ~ "\"];\n");
				strLine.pushBack("\t[label=\"" ~ inputDChar ~ "\"];\n");
				append(strTable, strLine.getString());
				strLine.clear();
			}
		}	
	}

	append(strTable, "}");
	hurt.io.stream.File file = new hurt.io.stream.File(fileName ~ ".dot", 
		FileMode.OutNew);
	foreach(it;strTable) {
		file.writeString(it);
	}
	file.close();
	system("dot -T jpg " ~ fileName ~ ".dot > " ~ fileName ~ ".jpg");
}
