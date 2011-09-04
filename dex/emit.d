module dex.emit;

import dex.state;
import dex.minimizer;

import hurt.algo.sorting;
import hurt.container.isr;
import hurt.container.iterator;
import hurt.container.map;
import hurt.container.set;
import hurt.container.vector;
import hurt.conv.conv;
import hurt.io.stdio;
import hurt.io.stream;
import hurt.string.formatter;
import hurt.string.stringbuffer;
import hurt.string.utf;
import hurt.util.array;
import std.process;

void writeTable(MinTable min, Iterable!(State) states, Set!(dchar) inputSet,
		string filename) {
	hurt.io.stream.File file = new hurt.io.stream.File(filename ~ ".tab", 
		FileMode.OutNew);

	sortVector!(State)(cast(Vector!(State))states, 
		function(in State a, in State b) { 
		return a.getStateId() < b.getStateId(); });

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

	for(int i = 0; i < howManyBlanks; i++)
		sb.pushBack(' ');
	for(int i = 0; i < inputSet.getSize(); i++) {
		sb.pushBack(format!(char,dchar)("%" ~ 
			conv!(int,string)(howManyBlanks+1) ~ "d", i));
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

	file.write('\n');
	file.write('\n');

	sb.pushBack(format!(char,dchar)("%" ~ conv!(int,string)(9)
		~ "s", "input"));

	ISRIterator!(MapItem!(dchar,Column)) rit = min.inputChar.begin();
	for(; rit.isValid(); rit++) {
		for(int i = 0; i < howManyBlanks; i++)
			sb.pushBack(' ');

		sb.pushBack((*rit).getKey());	
	}
	sb.pushBack('\n');
	file.writeString(conv!(dstring,string)(sb.getString()));
	sb.clear();

	rit = min.inputChar.begin();
	sb.pushBack(format!(char,dchar)("%" ~ conv!(int,string)(9)
		~ "s", "column"));

	for(; rit.isValid(); rit++) {
		sb.pushBack(format!(char,dchar)("%" ~ 
			conv!(int,string)(howManyBlanks+1) ~ "d", (*rit).getData().idx));
	}
	sb.pushBack('\n');
	file.writeString(conv!(dstring,string)(sb.getString()));
	sb.clear();

	file.write('\n');
	sb.pushBack(format!(char,dchar)("%" ~ conv!(int,string)(9)
		~ "s", "state"));

	foreach(idx, sit; min.state) {
		sb.pushBack(format!(char,dchar)("%3d", idx));
	}
	sb.pushBack('\n');
	file.writeString(conv!(dstring,string)(sb.getString()));
	sb.clear();

	sb.pushBack(format!(char,dchar)("%" ~ conv!(int,string)(9)
		~ "s", "row"));

	foreach(idx, sit; min.state) {
		sb.pushBack(format!(char,dchar)("%3d", sit));
	}

	sb.pushBack('\n');
	sb.pushBack('\n');
	file.writeString(conv!(dstring,string)(sb.getString()));
	sb.clear();

	sb.pushBack(format!(char,dchar)("%" ~ conv!(int,string)(4)
		~ "s", " "));
	for(int i = 0; i < min.table[0].getSize(); i++) {
		sb.pushBack(format!(char,dchar)("%3d", i));
	}
	sb.pushBack('\n');
	file.writeString(conv!(dstring,string)(sb.getString()));
	sb.clear();

	foreach(idx, rit; min.table) {
		sb.pushBack(format!(char,dchar)("%" ~ conv!(int,string)(4)
			~ "d", idx));
		foreach(s; rit) {
			sb.pushBack(format!(char,dchar)("%3d", s));
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
