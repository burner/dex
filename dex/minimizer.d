module dex.minimizer;

import dex.state;

import hurt.container.vector;
import hurt.container.dlst;

import std.stdio;

public State merge(ref Vector!(State) toMerge) {

}

public DLinkedList!(State) minimize(DLinkedList!(State) oldStates) {
	bool changes = true;
	Vector!(State) sameStates = new Vector!(State)(32);
	//while(changes) {
		foreach(it; oldStates) {
			sameStates.clean();	
			sameStates.append(it);
			foreach(jt; oldStates) {
				if(it.getStateId() == jt.getStateId()) {
					continue;
				}
				if(it.compare(jt)) {
					sameStates.append(jt);
				}
			}
			if(sameStates.getSize() > 1) {
				writeln(it.getStateId(), " has ", sameStates.getSize(), 
					" brother");
			}
		}
	//}
	return null;
}
