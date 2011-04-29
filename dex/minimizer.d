module dex.minimizer;

import dex.state;

import hurt.conv.conv;
import hurt.container.vector;
import hurt.container.dlst;
import hurt.container.multimap;

import std.stdio;

public State merge(T)(ref DLinkedList!(State) toMerge) {
	State begin = toMerge.popFront();
	State ret = new State(begin.getStateId());
	// save all the accepting States
	foreach(it; toMerge) {
		foreach(jt; it.getAcceptingStates().values()) {
			ret.setAcceptingState(jt);
		}
	}

	// fix all the old transtion to the member of toMerge
	T[] keys = begin.getTransitions().keys();	
	foreach(it; keys) {
		State[] u = begin.getTransition(it);	
		outer: foreach(jt; u) {
			foreach(kt; toMerge) {
				if(jt.getStateId() == kt.getStateId()) {
					ret.addTransition(it, ret);
					continue outer;
				}
			}
			ret.addTransition(it, jt);
		}
	}
	return ret;
}

public void changeTransition(DLinkedList!(State) oldStates, 
		DLinkedList!(State) mergedStates, State toSetTo) {
	foreach(it; oldStates) {
		foreach(jt; mergedStates) {
			it.overrideTransition(jt, toSetTo);
		}
	}
}

public DLinkedList!(State) minimize(T)(DLinkedList!(State) oldStates) {
	bool changes = true;
	// list names should be clear
	DLinkedList!(State) copy = new DLinkedList!(State)(oldStates);
	DLinkedList!(State) ret = new DLinkedList!(State)();
	DLinkedList!(State) sameStates = new DLinkedList!(State)();

	// the first state should be saved allways
	ret.pushBack(copy.popFront());

	State tmp;
	while(!copy.empty()) {
		sameStates.clean();	
		sameStates.pushBack(copy.popFront());
		tmp = sameStates.begin().getValue();
		for(auto it = copy.begin(); it.isValid();) {
			if(tmp.compare(*it)) {
				sameStates.pushBack(copy.remove(it));
			} else {
				it++;
			}
		}
		if(sameStates.getSize() > 1) {
			State merged = merge!(T)(sameStates);
			ret.pushBack(merged);
			changeTransition(copy, sameStates, merged);
			changeTransition(ret, sameStates, merged);
		} else {
			ret.pushBack(tmp);
		}
		assert(check(ret, copy));
	}
	return ret;
}

public bool check(DLinkedList!(State) merged, DLinkedList!(State) toMerge) {
	//writeln("\n\n");
	//foreach(it; merged)
	//	write(it.getStateId, " ");
	//writeln(":merged");
	//foreach(it; toMerge)
	//	write(it.getStateId, " ");
	//writeln(":toMerge");
	
	foreach(it; merged) {
		MultiMap!(char, State) tmp = it.getTransitions();
		label: foreach(jt; tmp.keys()) {
			State[] tsa = tmp.find(jt);
			if(tsa.length != 1) {
				assert(0, "epislon");
			}
			State ts = tsa[0];
			foreach(kt; merged) {
				if(ts.getStateId() == kt.getStateId()) {
					continue label;
				}
			}
			foreach(kt; toMerge) {
				if(ts.getStateId() == kt.getStateId()) {
					continue label;
				}
			}
			assert(0, conv!(int,string)(it.getStateId()) ~ "state not valid any more");
		}
	}
	foreach(it; toMerge) {
		MultiMap!(char, State) tmp = it.getTransitions();
		label: foreach(jt; tmp.keys()) {
			State[] tsa = tmp.find(jt);
			if(tsa.length != 1) {
				assert(0, "epislon");
			}
			State ts = tsa[0];
			foreach(kt; merged) {
				if(ts == kt) {
					continue label;
				}
			}
			foreach(kt; toMerge) {
				if(ts == kt) {
					continue label;
				}
			}
			assert(0, conv!(int,string)(it.getStateId()) ~ "state not valid any more");
		}
	}
	return true;
}
