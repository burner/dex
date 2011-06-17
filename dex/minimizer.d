module dex.minimizer;

import dex.state;

import hurt.conv.conv;
import hurt.container.dlst;
import hurt.container.list;
import hurt.container.set;
import hurt.container.map;
import hurt.container.multimap;

import std.stdio;

private void makeInitPartitions(DLinkedList!(State) oldStates, 
		MultiMap!(int,State) par, hurt.container.map.Map!(State,int) states) {
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
	Map!(State,int) states = new Map!(State,int)();
	makeInitPartitions(oldStates, par, states);
	assert(par.getSize() == states.getSize() 
		&& par.getSize() == oldStates.getSize(), 
		"not all states have been placed in a partitions");
	size_t oldSize = par.getCountKeys();
	assert(oldSize == 3, "there should be 3 partitions by now");
	outer: do {
		int[] keys = par.keys();
		foreach(it; keys) {
			List!(State) newGroup = new List!(State)();
			auto first = par.range(it);
			auto second = par.range(it);
			second++;
			while(second.isValid()) {
				foreach(jt; inputSet) {

				}
			}
		}
		
		
	} while(oldSize != par.getCountKeys());
	return null;	
}
