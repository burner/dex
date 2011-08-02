module dex.emit;

import dex.state;

import hurt.container.iterator;

void writeMinDFAGraph(Iterable!(State) states) {
	string[] strNFATable = ["digraph{\n"];
	StringBuffer!(char) strNFALine = new StringBuffer!(char)(16);
	foreach(it;states) {
		if(it.acceptingState) {
			strNFALine.pushBack('\t').pushBack(it.toString());
			strNFALine.pushBack("\t[shape=doublecircle];\n");
			append(strNFATable, strNFALine.getString());
			strNFALine.clear();
		}
	}
	append(strNFATable, "\n");
	strNFALine.clear();

	// Record transitions
	foreach(pState;states) {
		State[] state;	

		foreach(jt;this.inputSet) {
			state = pState.getTransition(jt);
			foreach(kt;state) {
				string stateId1 = (pState.toString());
				string stateId2 = (kt.toString());
				strNFALine.pushBack("\t" ~ stateId1 ~ " -> " ~ stateId2);
				strNFALine.pushBack("\t[label=\"" ~ jt ~ "\"];\n");
				append(strNFATable, strNFALine.getString());
				strNFALine.clear();
			}
		}	
	}

	append(strNFATable, "}");
	std.stream.File file = new std.stream.File("minDfaGraph.dot", 
		FileMode.OutNew);
	foreach(it;strNFATable) {
		file.writeString(it);
	}
	file.close();
	system("dot -T jpg minDfaGraph.dot > minDfaGraph.jpg");
}
