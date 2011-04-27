module dex.minimizer;

import dex.state;

import hurt.container.vector;
import hurt.container.dlst;

import std.stdio;

public State merge(ref DLinkedList!(State) toMerge) {
	return null;
}

public DLinkedList!(State) minimize(DLinkedList!(State) oldStates) {
	bool changes = true;
	DLinkedList!(State) sameStates = new DLinkedList!(State)();
	//while(changes) {
		foreach(it; oldStates) {
			sameStates.clean();	
			sameStates.pushBack(it);
			foreach(jt; oldStates) {
				if(it.getStateId() == jt.getStateId()) {
					continue;
				}
				if(it.compare(jt)) {
					sameStates.pushBack(jt);
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
