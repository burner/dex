module dex.emit;

import dex.state;

import hurt.container.iterator;
import hurt.container.set;
import hurt.string.stringbuffer;
import hurt.util.array;

import std.stream;
import std.process;

/* A function that writes a given graph to a file of name fileName.
 * Iterable is a container that implements opApply. The transitions of
 * the states inside the container should correspond to the character inside
 * the inputSet. Otherwise the transistion will not be displayed.
 */
void writeGraph(Iterable!(State) states, Set!(char) inputSet,
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
			state = pState.getTransition(jt);
			foreach(kt;state) {
				string stateId1 = (pState.toString());
				string stateId2 = (kt.toString());
				strLine.pushBack("\t" ~ stateId1 ~ " -> " ~ stateId2);
				strLine.pushBack("\t[label=\"" ~ jt ~ "\"];\n");
				append(strTable, strLine.getString());
				strLine.clear();
			}
		}	
	}

	append(strTable, "}");
	std.stream.File file = new std.stream.File(fileName ~ ".dot", 
		FileMode.OutNew);
	foreach(it;strTable) {
		file.writeString(it);
	}
	file.close();
	system("dot -T jpg " ~ fileName ~ ".dot > " ~ fileName ~ ".jpg");
}
