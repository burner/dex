module dex.minimizer;

import dex.state;

import hurt.conv.conv;
import hurt.container.vector;
import hurt.container.dlst;
import hurt.container.set;
import hurt.container.map;
import hurt.container.multimap;

import std.stdio;

private void makeInitPartitions(DLinkedList!(State) oldStates, 
		MultiMap!(int,State) par, Map!(State,int) states) {
	foreach(it; oldStates) {
		if(it.getStateId() == -1) {
			states.insert(it, 0);
			par.insert(0, it);
		} else if(it.isAccepting()) {
			states.insert(it, 1);
			par.insert(1, it);
		} else {
			states.insert(it, 2);
			par.insert(2, it);
		}
	}
}

public DLinkedList!(State) minimize(T)(DLinkedList!(State) oldStates, Set!(T) inputSet) {
	MultiMap!(int,State) par = new MultiMap!(int,State);
	Map!(State,int) states = new Map!(State,int);
	makeInitPartitions(oldStates, par, states);
	assert(par.getSize() == states.getSize() 
		&& par.getSize() == oldStates.getSize(), 
		"not all states have been placed in a partitions");
	return null;	
}
